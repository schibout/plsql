    CREATE OR REPLACE PACKAGE BODY DKA_SPOCHARGCATLG_PKG
    AS

    --------------------------------------------------------------------------------------------
    -- $Id: DKA_SPOCHARGCATLG_PKG.pkb 271 2018-01-17 10:13:20 $
    -- CAPGEMINI
    -- PROJET            : DALKIA Oracle Applications (Helios R12)
    -- NOM               : DKA_SPOCHARGCATLG_PKG.pkb
    -- DESCRIPTION       : DKA_SPOCHARGCATLG_PKG package body :
    ---
    --- AUTEUR           : R. BELAYACHI (CAPGEMINI)
    --- DATE DE CREATION : 17/01/2018
    --- DOC. ASSOCIEE    :
    -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
    --------------------------------------------------------------------------------------------
    --- HISTORIQUE DES MODIFICATIONS
    --- Date       Qui Description
    --- ---------- --- -------------------------------------------------------------------------
    --- 04/03/2018 RBE SPE210 - Chargement catalogue
    --- 04/03/2018 RBE artf3045111 - INC0258745 PROB duplication / désactivation de sites d'achat sur des catalogues. certains sites ne sont pas pris en compt
    --- 18/02/2019 RBE INC0290779 - Correctif fusion datafix et Batch de nuit/correctif duplication
    --- 01/03/2019 RBE INC0294958 - Prendre en compte désactivation dans le batch de nuit
    --------------------------------------------------------------------------------------------

    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    gv_conc_program_id      NUMBER:=Fnd_Global.conc_program_id;
    gv_conc_request_id      NUMBER:=Fnd_Global.conc_request_id;
    gv_prog_appl_id         NUMBER:=Fnd_Global.prog_appl_id;
    gv_RESP_NAME            VARCHAR2(100):=fnd_global.RESP_NAME;
    

    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PRIVEES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -------------------------------------------------------------------------------------------------------------------
    --  Nom           : INSERT_MESSAGE
    --  Description   : Procédure pour inserer un message dans la table temporaire
    --
    --  PARAMETRES    :
    --  pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --  pn_retcode                      Sortie                  status du traitement en sortie
    --  pn_org_id                       Entrée                  id de l'unite operationnelle
    --  pv_org_name                     Entrée                  nom de l'unite operationnelle
    --  pv_site_code                    Entrée                  code du site fournisseur
    --  pv_statut                       Entrée                  statut
    --  pv_message                      Entrée                  message
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    -------------------------------------------------------------------------------------------------------------------
        PROCEDURE INSERT_MESSAGE (
            pv_errbuf       IN OUT   VARCHAR2,
            pn_retcode      OUT      NUMBER,
            pn_org_id       IN       NUMBER,
            pv_org_name     IN       VARCHAR2,
            pv_order_num    IN       VARCHAR2,
            pv_site_code    IN       VARCHAR2,
            pv_statut       IN       VARCHAR2,
            pv_message      IN       VARCHAR2
        )
        IS
        vv_mesg                VARCHAR2(500);
        BEGIN
            
            INSERT INTO DKA_SPOCHARGCATLG_TMP 
                   (ORG_NAME,
                    ORG_ID,
                    ORDER_NUM,
                    VENDOR_SITE_CODE,
                    STATUT,
                    MESSAGE,
                    CREATION_DATE,
                    CREATED_BY,
                    LAST_UPDATE_DATE,
                    LAST_UPDATED_BY,
                    LOAD_REQUEST_ID
                    )
            VALUES (
                    pv_org_name,
                    pn_org_id,
                    pv_order_num,
                    pv_site_code,
                    pv_statut,
                    pv_message,
                    SYSDATE,
                    FND_GLOBAL.user_id,
                    SYSDATE,
                    FND_GLOBAL.user_id,
                    gv_conc_request_id
                    );

            EXCEPTION
            WHEN OTHERS
            THEN
                vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
                pv_errbuf     := vv_mesg;
                pn_retcode    := 2;
        END;
        
    -------------------------------------------------------------------------------------------------------------------
    --  Nom           : INSERT_MESSAGE
    --  Description   : Procédure pour inserer un message dans la table temporaire
    --
    --  PARAMETRES    :
    --  pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --  pn_retcode                      Sortie                  status du traitement en sortie
    --  pn_org_id                       Entrée                  id de l'unite operationnelle
    --  pv_org_name                     Entrée                  nom de l'unite operationnelle
    --  pv_site_code                    Entrée                  code du site fournisseur
    --  pv_statut                       Entrée                  statut
    --  pv_message                      Entrée                  message
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    -------------------------------------------------------------------------------------------------------------------
        PROCEDURE EDIT_REPORT (
            pv_errbuf       IN OUT   VARCHAR2,
            pn_retcode      OUT      NUMBER,
            pv_program      IN       VARCHAR2,
            pn_po_header_id IN       NUMBER,
            pv_action       IN       VARCHAR2,
            pv_perimetre    IN       VARCHAR2
        )
        IS

        CURSOR cur_message 
        IS 
        SELECT * FROM DKA_SPOCHARGCATLG_TMP
        ORDER BY statut,org_name,vendor_site_code,order_num
        ;
        v_conc_program_name        fnd_concurrent_programs.concurrent_program_name%TYPE;
        v_user_conc_program_name   fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
        vv_segment1                PO_HEADERS_ALL.segment1%TYPE;
        vv_ou_cmd                  hr_operating_units.name%TYPE;
        --v_org_name                 hr_operating_units.name%TYPE;
        vv_mesg                    VARCHAR2(500);
        cv_line                    VARCHAR2 (500);
            
        BEGIN

            ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
            BEGIN
                SELECT fcp.concurrent_program_name,
                       fcpt.user_concurrent_program_name
                INTO   v_conc_program_name,
                       v_user_conc_program_name
                FROM   fnd_concurrent_programs fcp,
                       fnd_concurrent_programs_tl fcpt
                WHERE  fcp.application_id = gv_prog_appl_id
                AND    fcp.concurrent_program_id = gv_conc_program_id
                AND    fcpt.application_id = gv_prog_appl_id
                AND    fcpt.concurrent_program_id = gv_conc_program_id
                AND    ROWNUM = 1;
            EXCEPTION
                WHEN OTHERS
                THEN
                    v_user_conc_program_name    := '???????????????????????';
                    v_conc_program_name         := '???????';
            END;
            
            IF pn_po_header_id IS NOT NULL THEN
                
                SELECT pha.segment1,hou.name
                INTO vv_segment1,vv_ou_cmd
                FROM PO_HEADERS_ALL pha ,HR_OPERATING_UNITS hou
                WHERE pha.po_header_id = pn_po_header_id 
                AND   pha.org_id = hou.organization_id;
            END IF;
            
            IF pv_program = 'DKA_SPODUPLCOG' THEN
                cv_line := 'Nom de la responsabilité : ' || gv_RESP_NAME;
                Fnd_File.put_line (Fnd_File.output, CHR(10)||cv_line);
            END IF;
            cv_line := 'Id du traitement : ' || to_char(gv_conc_request_id);
            Fnd_File.put_line (Fnd_File.output, cv_line);
            cv_line := 'Date             : ' || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS');
            Fnd_File.put_line (Fnd_File.output, cv_line);
            cv_line := 'Traitement       : ' || v_user_conc_program_name;
            Fnd_File.put_line (Fnd_File.output, cv_line);
            IF pv_program = 'DKA_SPODUPLCOG' THEN
                --cv_line := 'Traitement       : ' || v_user_conc_program_name;
                --Fnd_File.put_line (Fnd_File.output, cv_line);
                cv_line := 'Commande ouverte : ' ||vv_segment1||' ('||vv_ou_cmd||')';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                cv_line := 'Action           : ' ||pv_action||' sur ' || pv_perimetre;
                Fnd_File.put_line (Fnd_File.output, cv_line);
                Fnd_File.put_line (Fnd_File.output, '');
                cv_line := '              COMPTE-RENDU DE DUPLICATION DE COMMANDE OUVERTE';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                Fnd_File.put_line (Fnd_File.output, '');
                
                cv_line := RPAD('Unité Opérationnelle',20)||'   Site fournisseur   Statut     Message';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                cv_line := '--------------------   ----------------   ------     --------';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                
                FOR rec_cur_message IN cur_message
                LOOP
                    cv_line := RPAD(NVL(rec_cur_message.org_name,' '),20,' ') ||'   '|| RPAD(NVL(rec_cur_message.vendor_site_code,' '),16,' ') || '   ' ||RPAD(NVL(rec_cur_message.statut,' '),9,' ') ||'  ' || rec_cur_message.message ;
                    Fnd_File.put_line (Fnd_File.output, cv_line);
                END LOOP;
            ELSE
                Fnd_File.put_line (Fnd_File.output, '');
                cv_line := '    COMPTE-RENDU DE DUPLICATION DES SITES FOURNISSEURS SUR LES COMMANDES OUVERTES GLOBALES';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                Fnd_File.put_line (Fnd_File.output, '');
                
                cv_line := RPAD('Unité Opérationnelle',20)||'   Site fournisseur  Num Commande  Statut    Message';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                cv_line := '--------------------   ----------------  ------------  ------    --------';
                Fnd_File.put_line (Fnd_File.output, cv_line);
                
                FOR rec_cur_message IN cur_message
                LOOP
                    cv_line := RPAD(NVL(rec_cur_message.org_name,' '),20,' ') ||'   '|| RPAD(NVL(rec_cur_message.vendor_site_code,' '),16,' ')||'  '|| RPAD(NVL(rec_cur_message.order_num,' '),12,' ') || '  ' ||RPAD(NVL(rec_cur_message.statut,' '),9,' ') ||' ' || rec_cur_message.message ;
                    Fnd_File.put_line (Fnd_File.output, cv_line);
                END LOOP;
            END IF;
            
            EXCEPTION
            WHEN OTHERS
            THEN
                vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
                pv_errbuf     := vv_mesg;
                pn_retcode    := 2;
        END;
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- FONCTIONS ET PROCEDURES PUBLIQUES
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    -------------------------------------------------------------------------------------------------------------------
    --  Nom           : duplicate_orders
    --  Description   : Procédure pour le traitement de duplication des commandes ouvertes globales
    --
    --  PARAMETRES    :
    --  pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --  pn_retcode                      Sortie                  status du traitement en sortie
    --  pn_po_header_id                 Entrée                  id de la commande ouverte
    --  pv_action                       Entrée                  action Ã  effectuer par le traitement
    --  pv_perimetre                    Entrée                  perimetre de l'action
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    -------------------------------------------------------------------------------------------------------------------
        PROCEDURE duplicate_orders (
            pv_errbuf       IN OUT   VARCHAR2,
            pn_retcode      OUT      NUMBER,
            pn_po_header_id IN       NUMBER,
            pv_action       IN       VARCHAR2,
            pv_perimetre    IN       VARCHAR2
        )
        IS
        
        CURSOR cur_sites (p_org_id NUMBER)
        IS  SELECT vendor_site_id ,vendor_site_code,PURCHASING_SITE_FLAG --rbe artf3045111
            FROM PO_VENDOR_SITES_ALL 
            WHERE ORG_ID =  p_org_id
         --   AND PURCHASING_SITE_FLAG = 'Y'  --rbe artf3045111
            AND NVL(INACTIVE_DATE,SYSDATE+1) > SYSDATE 
            AND vendor_id = (SELECT vendor_id FROM PO_HEADERS_ALL WHERE PO_HEADER_ID  = pn_po_header_id)
        ;
        
        vn_user_id             NUMBER:=fnd_global.user_id;
        vn_responsibility_id   NUMBER;
        vn_application_id      NUMBER;
        vn_request_id          NUMBER;
        vv_mesg                VARCHAR2(500);
        
        v_exist                VARCHAR2(10);
        v_ORG_ASSIGNMENT_ID    NUMBER;
        v_ENABLED_FLAG         VARCHAR2(10);
        v_count_sites          NUMBER:=0;
        v_update_po            BOOLEAN:=FALSE;
        v_num_commande         PO_HEADERS_ALL.segment1%TYPE;
        v_org_id               HR_OPERATING_UNITS.organization_id%TYPE;
        v_org_name             HR_OPERATING_UNITS.name%TYPE;
        v_revision_num         PO_HEADERS_ALL.revision_num%TYPE;
        v_api_message_error     VARCHAR2 (1000);
        v_api_errors            PO_API_ERRORS_REC_TYPE;
        v_result_api            NUMBER := 0;
        v_return_status         VARCHAR2(100);
        l_new_revision_num      PO_HEADERS.revision_num%TYPE;
        l_message               VARCHAR2(50);
        l_return_status         VARCHAR2(1);
        Vv_item_key             PO_HEADERS_ALL.WF_ITEM_KEY%TYPE   := NULL;
        Vv_item_type            PO_HEADERS_ALL.WF_ITEM_TYPE%TYPE  := NULL;
        Vv_Workflow_Process     PO_DOCUMENT_TYPES_ALL.WF_APPROVAL_PROCESS%TYPE;
        Vn_preparer_id          NUMBER:= 0;
        v_agent_id              PO_HEADERS_ALL.agent_id%TYPE;
        l_changes               PO_CHANGES_REC_TYPE;
        v_first_ORG_ASSIGNMENT_ID NUMBER := 0;
        v_vendor_site_id        NUMBER; --RBE INC0290779
        BEGIN
        
            dka_Tools_Pkg.put_log_message('Purge de la table de travail DKA_SPOCHARGCATLG_TMP');
            DELETE FROM DKA_SPOCHARGCATLG_TMP;
            dka_Tools_Pkg.put_log_message('Nombre de lignes supprimées : '||SQL%ROWCOUNT);
            
            
            dka_Tools_Pkg.put_log_message('Recherche des unités opérationnelles pour le périmetre : '||pv_perimetre);
            
            BEGIN
                SELECT pha.segment1,hou.organization_id,hou.name,pha.revision_num,agent_id,pgos.ORG_ASSIGNMENT_ID,pha.vendor_site_id
                INTO v_num_commande,v_org_id,v_org_name,v_revision_num,v_agent_id,v_first_ORG_ASSIGNMENT_ID,v_vendor_site_id
                FROM PO_HEADERS_ALL pha ,HR_OPERATING_UNITS hou,PO_GA_ORG_ASSIGNMENTS pgos
                WHERE pha.po_header_id = pn_po_header_id 
                AND pha.org_id = hou.organization_id
                AND pgos.PO_HEADER_ID = pha.po_header_id
                AND pgos.ORGANIZATION_ID = pha.ORG_ID
                AND pgos.VENDOR_SITE_ID  = pha.vendor_site_id
                AND rownum = 1 ;
            EXCEPTION
            WHEN OTHERS THEN
                SELECT pha.segment1,hou.organization_id,hou.name,pha.revision_num,agent_id,pha.vendor_site_id --RBE INC0290779
                INTO v_num_commande,v_org_id,v_org_name,v_revision_num,v_agent_id,v_vendor_site_id --RBE INC0290779
                FROM PO_HEADERS_ALL pha ,HR_OPERATING_UNITS hou
                WHERE pha.po_header_id = pn_po_header_id 
                AND pha.org_id = hou.organization_id
                AND rownum = 1 ;
                
                v_first_ORG_ASSIGNMENT_ID := -1;
            END;
            
            FOR rec_cur_org IN (
                                  SELECT ORGANIZATION_ID,name FROM HR_OPERATING_UNITS
                                  WHERE name like DECODE(pv_perimetre,'TOUT',name,pv_perimetre||'%')
                                  )
            LOOP
                v_count_sites := 0;
                FOR rec_cur_sites IN cur_sites (rec_cur_org.ORGANIZATION_ID)
                LOOP
                    
                    --v_count_sites := v_count_sites + 1; --rbe artf3045111
                    IF      Pv_ACTION = 'Duplication' 
                        AND rec_cur_sites.PURCHASING_SITE_FLAG = 'Y' 
                        AND NOT (rec_cur_sites.vendor_site_id != v_vendor_site_id AND rec_cur_org.ORGANIZATION_ID = v_org_id) --RBE INC0290779
                    THEN --RBE artf3045111
                    
                        v_count_sites := v_count_sites + 1; --RBE artf3045111
                        v_exist := 'FALSE';
                        BEGIN
                            SELECT ORG_ASSIGNMENT_ID,ENABLED_FLAG
                            INTO v_ORG_ASSIGNMENT_ID,v_ENABLED_FLAG
                            FROM PO_GA_ORG_ASSIGNMENTS
                            WHERE PO_HEADER_ID  = pn_po_header_id
                            AND ORGANIZATION_ID = rec_cur_org.ORGANIZATION_ID
                            AND VENDOR_SITE_ID  = rec_cur_sites.vendor_site_id
                            ;
                            v_exist := 'TRUE';
                            
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_exist := 'FALSE';
                        WHEN OTHERS THEN
                            vv_mesg := SQLERRM;
                        END;
                        
                        IF v_exist = 'FALSE' THEN
                            INSERT INTO PO_GA_ORG_ASSIGNMENTS
                                   (PO_HEADER_ID           
                                   ,ORGANIZATION_ID        
                                   ,ENABLED_FLAG           
                                   ,VENDOR_SITE_ID         
                                   ,LAST_UPDATE_DATE       
                                   ,LAST_UPDATED_BY        
                                   ,CREATION_DATE          
                                   ,CREATED_BY             
                                   ,LAST_UPDATE_LOGIN      
                                   ,PURCHASING_ORG_ID      
                                   ,ORG_ASSIGNMENT_ID                    
                                    )
                            VALUES (pn_po_header_id
                                   ,rec_cur_org.ORGANIZATION_ID
                                   ,'Y'
                                   ,rec_cur_sites.vendor_site_id
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,SYSDATE
                                   ,FND_GLOBAL.USER_ID
                                   ,FND_GLOBAL.LOGIN_ID
                                   ,rec_cur_org.ORGANIZATION_ID
                                   ,PO_GA_ORG_ASSIGNMENTS_S.NEXTVAL
                                   );
                            v_update_po := TRUE;       
                            vv_mesg := 'Activation effectuée sur le couple UO/Site fournisseur';
                            INSERT_MESSAGE (
                                pv_errbuf,
                                pn_retcode,
                                rec_cur_org.organization_id,
                                rec_cur_org.name,
                                v_num_commande,
                                rec_cur_sites.vendor_site_code,
                                'Activé',
                                vv_mesg);
                        ELSIF v_ENABLED_FLAG = 'Y' THEN
                            vv_mesg := 'Commande ouverte déjà  activée pour le couple UO/Site fournisseur';
                            INSERT_MESSAGE (
                                pv_errbuf,
                                pn_retcode,
                                rec_cur_org.organization_id,
                                rec_cur_org.name,
                                v_num_commande,
                                rec_cur_sites.vendor_site_code,
                                'Erreur',
                                vv_mesg);
                        ELSIF v_ENABLED_FLAG = 'N' THEN
                            UPDATE PO_GA_ORG_ASSIGNMENTS
                            SET  ENABLED_FLAG = 'Y'
                                ,LAST_UPDATE_DATE = SYSDATE       
                                ,LAST_UPDATED_BY = FND_GLOBAL.USER_ID        
                            WHERE ORG_ASSIGNMENT_ID = v_ORG_ASSIGNMENT_ID;
                            v_update_po := TRUE;
                            vv_mesg := 'Réactivation effectuée pour le couple UO/Site fournisseur';
                            INSERT_MESSAGE (
                                pv_errbuf,
                                pn_retcode,
                                rec_cur_org.organization_id,
                                rec_cur_org.name,
                                v_num_commande,
                                rec_cur_sites.vendor_site_code,
                                'Activé',
                                vv_mesg);
                        END IF;
                    ELSIF Pv_ACTION = 'Désactivation' THEN
                        v_count_sites := v_count_sites + 1; --RBE artf3045111
                        v_exist := 'FALSE';
                        BEGIN
                            SELECT ORG_ASSIGNMENT_ID,ENABLED_FLAG
                            INTO v_ORG_ASSIGNMENT_ID,v_ENABLED_FLAG
                            FROM PO_GA_ORG_ASSIGNMENTS
                            WHERE PO_HEADER_ID  = pn_po_header_id
                            AND ORGANIZATION_ID = rec_cur_org.ORGANIZATION_ID
                            AND VENDOR_SITE_ID  = rec_cur_sites.vendor_site_id
                            ;
                            v_exist := 'TRUE';
                            
                        EXCEPTION
                        WHEN NO_DATA_FOUND THEN
                            v_exist := 'FALSE';
                        WHEN OTHERS THEN
                            vv_mesg := SQLERRM;
                        END;

                        IF v_exist = 'TRUE' THEN
                            IF v_ENABLED_FLAG = 'N' THEN
                                vv_mesg := 'Couple UO/Site fournisseur déja désactivé';

                                INSERT_MESSAGE (
                                pv_errbuf,
                                pn_retcode,
                                rec_cur_org.organization_id,
                                rec_cur_org.name,
                                v_num_commande,
                                rec_cur_sites.vendor_site_code,
                                'Erreur',
                                vv_mesg);
                            ELSE
                                IF v_first_ORG_ASSIGNMENT_ID != v_ORG_ASSIGNMENT_ID THEN
                                    UPDATE PO_GA_ORG_ASSIGNMENTS
                                    SET  ENABLED_FLAG = 'N'
                                        ,LAST_UPDATE_DATE = SYSDATE       
                                        ,LAST_UPDATED_BY = FND_GLOBAL.USER_ID        
                                    WHERE ORG_ASSIGNMENT_ID = v_ORG_ASSIGNMENT_ID;
                                    v_update_po := TRUE;
                                    vv_mesg := 'Désactivation effectuée pour le couple UO/Site fournisseur';
                                    INSERT_MESSAGE (
                                    pv_errbuf,
                                    pn_retcode,
                                    rec_cur_org.organization_id,
                                    rec_cur_org.name,
                                    v_num_commande,
                                    rec_cur_sites.vendor_site_code,
                                    'Désactivé',
                                    vv_mesg);
                                END IF;
                            END IF;
                        ELSE
                            vv_mesg := 'Couple  UO/Site fournisseur n''existe pas ';
                            INSERT_MESSAGE (
                                pv_errbuf,
                                pn_retcode,
                                rec_cur_org.organization_id,
                                rec_cur_org.name,
                                v_num_commande,
                                rec_cur_sites.vendor_site_code,
                                'Erreur',
                                vv_mesg);
                        END IF;
                    END IF;
                END LOOP;
                
                IF v_count_sites = 0 THEN
                    vv_mesg := 'Aucun site fournisseur trouvé pour cette unité opérationnelle';
                    INSERT_MESSAGE (
                        pv_errbuf,
                        pn_retcode,
                        rec_cur_org.organization_id,
                        rec_cur_org.name,
                        v_num_commande,
                        NULL,
                        'Erreur',
                        vv_mesg);
                END IF;
            END LOOP;
            
            -- Si il y a des modifications il faut lancer approbation de la commande
            IF v_update_po = TRUE THEN
                
                --Lancer approbation
                
                dka_Tools_Pkg.put_log_message('Mise à jour de la commande : '||v_num_commande);
                UPDATE PO_HEADERS_ALL 
                SET REVISION_NUM = revision_num+1,
                    AUTHORIZATION_STATUS = 'REQUIRES REAPPROVAL',
                    APPROVED_FLAG       = 'R',
                    LAST_UPDATED_BY     = fnd_global.user_id,
                    LAST_UPDATE_DATE    = SYSDATE,
                    SUBMIT_DATE         = NULL
                WHERE po_header_id= pn_po_header_id;
                

                -- Excéution du worflow d'approbation POAPPRV
                dka_Tools_Pkg.put_log_message('Lancer workflow approbation de commande : '||v_num_commande);

                mo_global.init ('PO');
                mo_global.set_policy_context ('S', v_org_id);

                SELECT pn_po_header_id || '-' ||to_char(po_wf_itemkey_s.NEXTVAL)
                INTO vv_item_key 
                FROM dual;

                --Calling po_reqapproval_init1.start_wf_process

                po_reqapproval_init1.start_wf_process(
                          ItemType => 'POAPPRV'
                        , ItemKey => vv_item_key
                        , WorkflowProcess => 'POAPPRV_TOP'
                        , ActionOriginatedFrom => 'PO_FORM'
                        , DocumentID => pn_po_header_id
                        , DocumentNumber => v_num_commande
                        , PreparerID => v_agent_id
                        , DocumentTypeCode => 'PA'
                        , DocumentSubtype => 'BLANKET'
                        , SubmitterAction => 'APPROVE'
                        , forwardToID => NULL
                        , forwardFromID => NULL
                        , DefaultApprovalPathID => NULL
                        , Note => NULL
                        , PrintFlag => 'N'
                        , FaxFlag => 'N'
                        , FaxNumber => NULL
                        , EmailFlag => 'N'
                        , EmailAddress => NULL
                        , CreateSourcingRule => 'N'
                        , ReleaseGenMethod => 'N'
                        , UpdateSourcingRule => 'N'
                        , MassUpdateReleases => 'N'
                        , RetroactivePriceChange => 'N'
                        , OrgAssignChange => 'N'
                        , CommunicatePriceChange => 'N'
                        , p_Background_Flag => 'N'
                        , p_Initiator => NULL
                        , p_xml_flag => NULL
                        , FpdsngFlag => 'N'
                        , p_source_type_code => NULL); 
                                    
                dka_Tools_Pkg.put_log_message('Fin workflow approbation de commande');
                
            END IF;
            
            dka_Tools_Pkg.put_log_message('Editer le compte-rendu ');
            EDIT_REPORT (
                    pv_errbuf,
                    pn_retcode,
                    'DKA_SPODUPLCOG',
                    pn_po_header_id,
                    pv_action,
                    pv_perimetre
                    );
        
            EXCEPTION
            WHEN OTHERS
            THEN
                vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
                pv_errbuf     := vv_mesg;
                pn_retcode    := 2;
        END;


    -------------------------------------------------------------------------------------------------------------------
    --  Nom           : duplicate_sites
    --  Description   : Procédure pour le traitement DKA : Mise à jour des rattachements 
    --                                               de sites fournisseurs sur 
    --                                               commande ouverte globale
    --
    --  PARAMETRES    :
    --  pv_errbuf                       Entrée/Sortie           retour de message eventuel
    --  pn_retcode                      Sortie                  status du traitement en sortie
    --
    --  VALEUR RETOURNEE :
    --     Description       : code retour de validité
    --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
    -------------------------------------------------------------------------------------------------------------------
        PROCEDURE duplicate_sites (
            pv_errbuf       IN OUT   VARCHAR2,
            pn_retcode      OUT      NUMBER
        )
        IS

        -- Declaration du type tableau    
        
        TYPE rec_commande IS RECORD (
                po_header_id        NUMBER,
                segment1            VARCHAR2(100),
                agent_id            NUMBER,
                org_id              NUMBER,
                ORG_ASSIGNMENT_ID   NUMBER
                );
        TYPE type_commande IS TABLE OF rec_commande
        INDEX BY BINARY_INTEGER;
        type_commande_tab type_commande; --- Tableau de stockage des commandes 
        v_num NUMBER:=0;
        
        v_cmd_existe BOOLEAN:= FALSE;
    
        vd_date_exec        DATE;
        
        --Cursor des sites d'achat modifies depuis le dernier lancement
        CURSOR cur_sites
        IS  SELECT vendor_id, vendor_site_id ,vendor_site_code,org_id,hou.name org_name
            FROM PO_VENDOR_SITES_ALL pvs , hr_operating_units hou
            WHERE 1 =  1
            AND pvs.org_id = hou.organization_id
            AND pvs.PURCHASING_SITE_FLAG = 'Y' 
            AND NVL(pvs.INACTIVE_DATE,SYSDATE+1) > SYSDATE 
            AND pvs.LAST_UPDATE_DATE > vd_date_exec
        ;
        
        --RBE INC0294958
        --Cursor des sites inactifs ou non d'achat modifies depuis le dernier lancement
        CURSOR cur_sites_inactifs
        IS  SELECT vendor_id, vendor_site_id ,vendor_site_code,org_id,hou.name org_name
            FROM PO_VENDOR_SITES_ALL pvs , hr_operating_units hou
            WHERE 1 =  1
            AND pvs.org_id = hou.organization_id
            AND (pvs.PURCHASING_SITE_FLAG = 'N' 
            OR NVL(pvs.INACTIVE_DATE,SYSDATE) < SYSDATE) 
            AND pvs.LAST_UPDATE_DATE > vd_date_exec
            AND EXISTS (SELECT 1 FROM PO_GA_ORG_ASSIGNMENTS
                        WHERE vendor_site_id  = pvs.vendor_site_id
                        AND  ENABLED_FLAG = 'Y'
                        AND ORGANIZATION_ID = pvs.ORG_ID
                        )
        ;
        
        --cursor des commandes concernes par la duplication
        CURSOR cur_cmd (pn_vendor_id NUMBER,pn_org_id NUMBER) 
        IS
        SELECT PHA.*,hou.name org_name,pgo.ORG_ASSIGNMENT_ID
        FROM PO_HEADERS_ALL PHA , HR_OPERATING_UNITS HOU,PO_GA_ORG_ASSIGNMENTS pgo
        WHERE PHA.TYPE_LOOKUP_CODE = 'BLANKET'
        AND PHA.GLOBAL_AGREEMENT_FLAG = 'Y'
        AND PHA.AUTHORIZATION_STATUS = 'APPROVED'
        AND NVL(PHA.CLOSED_DATE,SYSDATE+1) > SYSDATE
        AND NVL(PHA.CLOSED_CODE,'NA') NOT IN ('CLOSED','FINALLY CLOSED')
        AND PHA.org_id = HOU.organization_id
        AND pha.vendor_id = pn_vendor_id
        AND pgo.PO_HEADER_ID = pha.po_header_id
        AND pgo.ORGANIZATION_ID = pha.ORG_ID
        AND pgo.VENDOR_SITE_ID  = pha.vendor_site_id
        ;
        
       --RBE INC0294958
       --cursor des commandes concernes par la desactivation
        CURSOR cur_cmd_desac (pn_VENDOR_SITE_ID NUMBER,pn_org_id NUMBER) 
        IS
        SELECT PHA.*,hou.name org_name,pgo.ORG_ASSIGNMENT_ID
        FROM PO_HEADERS_ALL PHA , HR_OPERATING_UNITS HOU,PO_GA_ORG_ASSIGNMENTS pgo
        WHERE PHA.TYPE_LOOKUP_CODE = 'BLANKET'
        AND PHA.GLOBAL_AGREEMENT_FLAG = 'Y'
        AND PHA.AUTHORIZATION_STATUS = 'APPROVED'
        AND NVL(PHA.CLOSED_DATE,SYSDATE+1) > SYSDATE
        AND NVL(PHA.CLOSED_CODE,'NA') NOT IN ('CLOSED','FINALLY CLOSED')
        AND PHA.org_id = HOU.organization_id
        AND pgo.VENDOR_SITE_ID = pn_VENDOR_SITE_ID
        AND pgo.PO_HEADER_ID = pha.po_header_id
      --  AND pgo.ORGANIZATION_ID = pha.ORG_ID
      --  AND pgo.VENDOR_SITE_ID  = pha.vendor_site_id
        AND pgo.ORGANIZATION_ID = pn_org_id
        ;        
        
        vn_user_id             NUMBER:=fnd_global.user_id;
        vn_responsibility_id   NUMBER;
        vn_application_id      NUMBER;
        vn_request_id          NUMBER;
        vv_mesg                VARCHAR2(500);
        
        v_exist                VARCHAR2(10);
        v_ORG_ASSIGNMENT_ID    NUMBER;
        v_ENABLED_FLAG         VARCHAR2(10);
        v_count_sites          NUMBER:=0;

        Vr_Data                 Dka_Parameters%ROWTYPE;
        vv_errbuf               VARCHAR2 (500) := NULL;
        vn_retcode              NUMBER         := 0;
        v_api_message_error     VARCHAR2 (1000);
        v_api_errors            PO_API_ERRORS_REC_TYPE;
        v_revision_num          PO_HEADERS_ALL.revision_num%TYPE;
        v_result_api            NUMBER := 0;
        v_update_po             BOOLEAN:=FALSE;
        v_return_status         VARCHAR2(100);
        l_need_new_revision     boolean := FALSE;
        l_new_revision_num      PO_HEADERS.revision_num%TYPE;
        l_message               VARCHAR2(50);
        l_return_status         VARCHAR2(1);
        Vv_item_key             PO_HEADERS_ALL.WF_ITEM_KEY%TYPE   := NULL;
        Vv_item_type            PO_HEADERS_ALL.WF_ITEM_TYPE%TYPE  := NULL;
        Vv_Workflow_Process     PO_DOCUMENT_TYPES_ALL.WF_APPROVAL_PROCESS%TYPE;
        Vn_preparer_id NUMBER:= 0;
        v_agent_id              PO_HEADERS_ALL.agent_id%TYPE;
        v_count                 NUMBER:=0;
        BEGIN

            dka_Tools_Pkg.put_log_message('Purge de la table de travail DKA_SPOCHARGCATLG_TMP');
            DELETE FROM DKA_SPOCHARGCATLG_TMP;
            dka_Tools_Pkg.put_log_message('Nombre de lignes supprimées : '||SQL%ROWCOUNT);
            
            dka_Tools_Pkg.put_log_message('Recuperation de la date de dernière exécution');
            
            Dka_Tools_Pkg.get_parameter('DKA_SPODUPSITECOG',
                                        'DATE_EXECUTION',
                                        Vr_Data,
                                        vn_retcode,
                                        vv_errbuf);
                                           
            IF vn_retcode != 0 THEN
              dka_Tools_Pkg.put_log_message('Erreur lors de la récupération de la date de dernière exécution');
              dka_Tools_Pkg.put_log_message(vv_errbuf);
              pn_retcode := 2;
              RETURN;
            
            END IF;                              
                                       
            vd_date_exec  := Vr_Data.date_Value;
            
            dka_Tools_Pkg.put_log_message('Date de dernière exécution : '||to_char(vd_date_exec,'DD/MM/YYYY HH24:MI:SS'));

            
            dka_Tools_Pkg.put_log_message('Mise à jour de la date de dernière exécution');
            UPDATE DKA_PARAMETERS
            SET date_value = SYSDATE
            WHERE program_code = 'DKA_SPODUPSITECOG'
            AND PARAMETER_NAME = 'DATE_EXECUTION';
            
            
            dka_Tools_Pkg.put_log_message('Recherche des sites actifs ');

            FOR rec_cur_sites IN cur_sites
            LOOP
                v_count_sites := v_count_sites + 1;
                FOR rec_cur_cmd IN cur_cmd (rec_cur_sites.vendor_id,rec_cur_sites.org_id)
                LOOP
                    --RBE INC0290779
                    v_update_po := FALSE;
                    IF NOT (rec_cur_cmd.org_id = rec_cur_sites.org_id AND rec_cur_cmd.vendor_site_id != rec_cur_sites.vendor_site_id)
                    THEN
                        SELECT count(1)
                        into v_count
                        FROM PO_GA_ORG_ASSIGNMENTS PGO , HR_OPERATING_UNITS HOU , HR_OPERATING_UNITS HOU_ass
                        WHERE pgo.PO_HEADER_ID  = rec_cur_cmd.po_header_id
                        AND  pgo.ENABLED_FLAG = 'Y'
                        --AND ORGANIZATION_ID != pha.ORG_ID
                        --AND pgo.organization_id = rec_cur_sites.org_id
                        AND pgo.organization_id = HOU_ass.organization_id
                        AND hou.organization_id = rec_cur_sites.org_id
                        AND substr(hou_ass.name,1,3) = substr(hou.name,1,3)
                        ;
                        
                        IF v_count > 0 THEN
                            v_exist := 'FALSE';
                            BEGIN
                                SELECT ORG_ASSIGNMENT_ID,ENABLED_FLAG
                                INTO v_ORG_ASSIGNMENT_ID,v_ENABLED_FLAG
                                FROM PO_GA_ORG_ASSIGNMENTS
                                WHERE PO_HEADER_ID  = rec_cur_cmd.po_header_id
                                AND ORGANIZATION_ID = rec_cur_sites.ORG_ID
                                AND VENDOR_SITE_ID  = rec_cur_sites.vendor_site_id
                                ;
                                v_exist := 'TRUE';
                            
                            EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                v_exist := 'FALSE';
                            WHEN OTHERS THEN
                                vv_mesg := SQLERRM;
                            END;
                        
                            IF v_exist = 'TRUE' THEN
                                IF v_ENABLED_FLAG = 'Y' THEN
                                    vv_mesg := 'Couple UO/Site fournisseur déja activé';
                                    INSERT_MESSAGE (
                                        pv_errbuf,
                                        pn_retcode,
                                        rec_cur_sites.org_id,
                                        rec_cur_sites.org_name,
                                        rec_cur_cmd.segment1,
                                        rec_cur_sites.vendor_site_code,
                                        'Erreur',
                                        vv_mesg);
                                ELSE
                                    UPDATE PO_GA_ORG_ASSIGNMENTS
                                    SET  ENABLED_FLAG = 'Y'
                                        ,LAST_UPDATE_DATE = SYSDATE       
                                        ,LAST_UPDATED_BY = FND_GLOBAL.USER_ID  
                                    WHERE ORG_ASSIGNMENT_ID = v_ORG_ASSIGNMENT_ID;
                                    v_update_po := TRUE;
                                    vv_mesg := 'Réactivation effectuée pour le couple UO/Site fournisseur';
                                    INSERT_MESSAGE (
                                        pv_errbuf,
                                        pn_retcode,
                                        rec_cur_sites.org_id,
                                        rec_cur_sites.org_name,
                                        rec_cur_cmd.segment1,
                                        rec_cur_sites.vendor_site_code,
                                        'Erreur',
                                        vv_mesg);
                                END IF;
                            ELSE
                                INSERT INTO PO_GA_ORG_ASSIGNMENTS
                                       (PO_HEADER_ID           
                                       ,ORGANIZATION_ID        
                                       ,ENABLED_FLAG           
                                       ,VENDOR_SITE_ID         
                                       ,LAST_UPDATE_DATE       
                                       ,LAST_UPDATED_BY        
                                       ,CREATION_DATE          
                                       ,CREATED_BY             
                                       ,LAST_UPDATE_LOGIN      
                                       ,PURCHASING_ORG_ID      
                                       ,ORG_ASSIGNMENT_ID                    
                                        )
                                VALUES (rec_cur_cmd.po_header_id
                                       ,rec_cur_sites.ORG_ID
                                       ,'Y'
                                       ,rec_cur_sites.vendor_site_id
                                       ,SYSDATE
                                       ,FND_GLOBAL.USER_ID
                                       ,SYSDATE
                                       ,FND_GLOBAL.USER_ID
                                       ,FND_GLOBAL.LOGIN_ID
                                       ,rec_cur_sites.ORG_ID
                                       ,PO_GA_ORG_ASSIGNMENTS_S.NEXTVAL
                                       );
                                    v_update_po := TRUE;
                                    vv_mesg := 'Activation effectuée sur le couple UO/Site fournisseur';
                                    INSERT_MESSAGE (
                                        pv_errbuf,
                                        pn_retcode,
                                        rec_cur_sites.org_id,
                                        rec_cur_sites.org_name,
                                        rec_cur_cmd.segment1,
                                        rec_cur_sites.vendor_site_code,
                                        'Activé',
                                        vv_mesg);
                            END IF;
                        ELSE
                            --vv_mesg := 'Unité opérationnelle inactive sur cette commande';
                            vv_mesg := 'Région non rattachée pour cette commande';
                            INSERT_MESSAGE (
                                pv_errbuf,
                                pn_retcode,
                                rec_cur_sites.org_id,
                                rec_cur_sites.org_name,
                                rec_cur_cmd.segment1,
                                rec_cur_sites.vendor_site_code,
                                'Erreur',
                                vv_mesg);
                        END IF;
                        
                        IF v_update_po = TRUE THEN

                            v_cmd_existe := FALSE;
                            IF type_commande_tab.count > 0 THEN 
                                FOR i IN type_commande_tab.first .. type_commande_tab.last LOOP
                                    IF type_commande_tab(i).po_header_id = rec_cur_cmd.po_header_id THEN
                                        v_cmd_existe := TRUE;
                                    END IF;
                                END LOOP;
                            END IF;
                            IF v_cmd_existe = FALSE THEN
                                v_num := v_num + 1;
                                type_commande_tab(v_num).po_header_id := rec_cur_cmd.po_header_id;
                                type_commande_tab(v_num).segment1     := rec_cur_cmd.segment1;
                                type_commande_tab(v_num).agent_id     := rec_cur_cmd.agent_id;
                                type_commande_tab(v_num).org_id       := rec_cur_cmd.org_id;
                                type_commande_tab(v_num).ORG_ASSIGNMENT_ID  := rec_cur_cmd.ORG_ASSIGNMENT_ID;
                            END IF;
                        END IF; 
                    END IF;
                END LOOP;

            END LOOP; --sites actifs
            
            -- RBE INC0294958
            -- Pour les sites inactifs ou non d'achat
            dka_Tools_Pkg.put_log_message('Recherche des sites inactifs ou non d''achat  ');

            FOR rec_cur_sites_inactifs IN cur_sites_inactifs
            LOOP
                v_count_sites := v_count_sites + 1;
                FOR rec_cur_cmd_desac IN cur_cmd_desac (rec_cur_sites_inactifs.vendor_site_id,rec_cur_sites_inactifs.org_id)
                LOOP
                    UPDATE PO_GA_ORG_ASSIGNMENTS
                    SET  ENABLED_FLAG = 'N'
                        ,LAST_UPDATE_DATE = SYSDATE       
                        ,LAST_UPDATED_BY = FND_GLOBAL.USER_ID  
                    WHERE ORG_ASSIGNMENT_ID = rec_cur_cmd_desac.ORG_ASSIGNMENT_ID;
                    v_update_po := TRUE;
                    vv_mesg := 'Désactivation effectuée pour le couple UO/Site fournisseur';
                    INSERT_MESSAGE (
                        pv_errbuf,
                        pn_retcode,
                        rec_cur_sites_inactifs.org_id,
                        rec_cur_sites_inactifs.org_name,
                        rec_cur_cmd_desac.segment1,
                        rec_cur_sites_inactifs.vendor_site_code,
                        'Désactivé',
                        vv_mesg);
                        
                        v_cmd_existe := FALSE;
                        IF type_commande_tab.count > 0 THEN 
                            FOR i IN type_commande_tab.first .. type_commande_tab.last LOOP
                                IF type_commande_tab(i).po_header_id = rec_cur_cmd_desac.po_header_id THEN
                                    v_cmd_existe := TRUE;
                                END IF;
                            END LOOP;
                        END IF;
                        IF v_cmd_existe = FALSE THEN
                            v_num := v_num + 1;
                            type_commande_tab(v_num).po_header_id := rec_cur_cmd_desac.po_header_id;
                            type_commande_tab(v_num).segment1     := rec_cur_cmd_desac.segment1;
                            type_commande_tab(v_num).agent_id     := rec_cur_cmd_desac.agent_id;
                            type_commande_tab(v_num).org_id       := rec_cur_cmd_desac.org_id;
                            type_commande_tab(v_num).ORG_ASSIGNMENT_ID  := rec_cur_cmd_desac.ORG_ASSIGNMENT_ID;
                        END IF;
                        
                END LOOP; --cmd
                
            END LOOP; --sites inactifs
            
            
            IF v_count_sites = 0 THEN
                vv_mesg := 'Aucun site fournisseur trouvé';
                INSERT_MESSAGE (
                    pv_errbuf,
                    pn_retcode,
                    NULL,
                    NULL,
                    NULL,
                    NULL,
                    'Erreur',
                    vv_mesg);
            END IF;

            IF v_num > 0 THEN
                FOR j IN type_commande_tab.first .. type_commande_tab.last LOOP
                    
                    dka_Tools_Pkg.put_log_message('Mise à jour de la commande : '||type_commande_tab(j).segment1);
                    UPDATE PO_HEADERS_ALL 
                    SET REVISION_NUM = revision_num+1,
                        AUTHORIZATION_STATUS = 'REQUIRES REAPPROVAL',
                        APPROVED_FLAG       = 'R',
                        LAST_UPDATED_BY     = fnd_global.user_id,
                        LAST_UPDATE_DATE    = SYSDATE,
                        SUBMIT_DATE         = NULL
                    WHERE po_header_id = type_commande_tab(j).po_header_id;
                    

                    -- Excéution du worflow d'approbation POAPPRV
                    dka_Tools_Pkg.put_log_message('Lancer workflow approbation de commande : '||type_commande_tab(j).segment1);

                    mo_global.init ('PO');
                    mo_global.set_policy_context ('S', type_commande_tab(j).org_id);

                    SELECT type_commande_tab(j).po_header_id || '-' ||to_char(po_wf_itemkey_s.NEXTVAL)
                    INTO vv_item_key 
                    FROM dual;

                    --Calling po_reqapproval_init1.start_wf_process

                    po_reqapproval_init1.start_wf_process(
                              ItemType => 'POAPPRV'
                            , ItemKey => vv_item_key
                            , WorkflowProcess => 'POAPPRV_TOP'
                            , ActionOriginatedFrom => 'PO_FORM'
                            , DocumentID => type_commande_tab(j).po_header_id
                            , DocumentNumber => type_commande_tab(j).segment1
                            , PreparerID => type_commande_tab(j).agent_id
                            , DocumentTypeCode => 'PA'
                            , DocumentSubtype => 'BLANKET'
                            , SubmitterAction => 'APPROVE'
                            , forwardToID => NULL
                            , forwardFromID => NULL
                            , DefaultApprovalPathID => NULL
                            , Note => NULL
                            , PrintFlag => 'N'
                            , FaxFlag => 'N'
                            , FaxNumber => NULL
                            , EmailFlag => 'N'
                            , EmailAddress => NULL
                            , CreateSourcingRule => 'N'
                            , ReleaseGenMethod => 'N'
                            , UpdateSourcingRule => 'N'
                            , MassUpdateReleases => 'N'
                            , RetroactivePriceChange => 'N'
                            , OrgAssignChange => 'N'
                            , CommunicatePriceChange => 'N'
                            , p_Background_Flag => 'N'
                            , p_Initiator => NULL
                            , p_xml_flag => NULL
                            , FpdsngFlag => 'N'
                            , p_source_type_code => NULL); 
                                        
                    dka_Tools_Pkg.put_log_message('Fin workflow approbation de commande');

                END LOOP;
            END IF;

            dka_Tools_Pkg.put_log_message('Editer le compte-rendu ');
            EDIT_REPORT (
                pv_errbuf,
                pn_retcode,
                'DKA_SPODUPSITECOG',
                NULL,
                NULL,
                NULL
                );
                    
            EXCEPTION
            WHEN OTHERS
            THEN
                vv_mesg       := vv_mesg || CHR (10) || SUBSTR (SQLERRM, 1, 400);
                pv_errbuf     := vv_mesg;
                pn_retcode    := 2;
        END;

    END DKA_SPOCHARGCATLG_PKG; -- Package body
    /
    SHOW ERRORS;
    EXIT;

