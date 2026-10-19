create or replace PACKAGE BODY DKA_FUSPOGENIMG_PKG IS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_FUSPOGENIMG_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : SELO / SOCIETE : CAPGEMINI                           -
    -- DATE    : 11/09/2019                                               -
    ---------------------------------------------------------------------
    -- APPELE PAR :  REPRISE DES COMMANDES                          -
    -- FONCTION   :  EDB215A _Traitement de génération des bons de commande                                                                      -
    --                                                                   -
    
     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    -- CONSTANTES ET VARIABLES PRIVEES
    --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    g_user_id                      fnd_user.user_id%TYPE;
    g_login_id                     fnd_logins.login_id%TYPE;
    g_org_id                       hr_all_organization_units.organization_id%TYPE;
    g_request_id                   fnd_concurrent_requests.request_id%TYPE;
    g_qty_precision   VARCHAR2 (30);
    g_user_name fnd_user.user_name%TYPE;
    g_tempo                        NUMBER;

    /*
    *************************************************************************
    * PROCEDURE NAME : init
    *
    * DESCRIPTION
    *  Procédure d'initialisation des variables globales
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */

    PROCEDURE init (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS

        v_procedure         VARCHAR2(30);
        program_error       EXCEPTION;
        rec_param           dka_parameters%ROWTYPE;

    BEGIN

        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init');


        ----------------------------------
        -- Initialisation des variables --
        ----------------------------------
        p_errbuf  := NULL;
        p_retcode := 0;
        v_procedure := 'INIT';


        ------------------------
        -- Variables globales --
        ------------------------

        g_login_id                      := fnd_global.login_id;
        g_request_id                    := fnd_global.conc_request_id;
        g_user_id                       := fnd_global.user_id;
        g_user_name                     := fnd_global.user_name ;
        fnd_profile.get ('REPORT_QUANTITY_PRECISION', g_qty_precision);
        g_tempo        := 20;



    EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := v_procedure ||': '||SQLERRM;
    END init;


     /*
    *************************************************************************
    * PROCEDURE NAME : init_environement
    *
    * DESCRIPTION
    *  Procédure d'initialisation de l'environnement
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    ************************************************************************
    */
/*
    PROCEDURE init_environement (
        p_errbuf    OUT      VARCHAR2,
        p_retcode   OUT      NUMBER
        )
    IS
        v_resp_id                               NUMBER;
        v_resp_appl_id                          NUMBER;
    BEGIN

        --Fnd_File.put_line (Fnd_File.log, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Debut init_environement');

        p_retcode   := 0;

        fnd_global.apps_initialize(g_user_id, v_resp_id, v_resp_appl_id);

        -- Initialiser org_id
        --Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin init_environement');
    EXCEPTION
        WHEN program_error THEN
             Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf);
        WHEN NO_DATA_FOUND THEN
            p_retcode   := 1;
            p_errbuf    := 'init_environement responsabilité introuvable: '||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, 'ERREUR : ' || p_errbuf ||' pour L''UO ' ||g_org_id);
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'init_environement: '||SQLERRM;

    END init_environement;    */

    /*
    *************************************************************************
    * PROCEDURE NAME : main
    *
    * DESCRIPTION
    *  Procédure principale 
    *
    * PARAMETERS
    * ==========
    * NAME              DESCRIPTION
    .* ----------------- ------------------------------------------------------
    * p_errbuf         Retour de message éventuel
    * p_retcode        Statut du traitement en sortie
    * p_region          région
    ************************************************************************
    */

    PROCEDURE main(p_errbuf       IN OUT  VARCHAR2,
                 p_retcode      OUT     NUMBER--,
                -- p_region      IN      VARCHAR2
             )
    IS

        v_package                    VARCHAR2(30)  := 'DKA_FUSPOGENIMG_PKG';
        v_nom_traitement             VARCHAR2(200) := 'DKA : Génération image commande';
        v_current_program_unit   VARCHAR2(30);
        v_errbuf                 VARCHAR2(2500);
        v_retcode                NUMBER;
        v_success               BOOLEAN;
        v_request_id            NUMBER  := 0;
        v_exception             EXCEPTION;
        v_procedure                  VARCHAR2(30)    := 'main';
        v_message                    VARCHAR2(500);
        v_region                VARCHAR2(10);--artf2149649 
        v_sqlerrm               VARCHAR2(250) := NULL;
        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
		NBR_BC                   number;
        
        TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
        num_trait_list num_traitement;
        
        v_cpt INTEGER := 0;

        CURSOR c_commande IS
            SELECT po_header_id,
                    segment1,
                    po_headers_all.org_id,
                    name
            FROM po_headers_all,
			     DKA_SPOFUSION_HEADERS_TMP DSHT,
                 hr_operating_units
            WHERE NOT EXISTS
              (SELECT fad.document_id,
                fad.pk1_value ,
                fdt.media_id
              FROM fnd_attached_documents fad,
                fnd_documents_tl fdt,
                fnd_documents fd,
                fnd_document_categories fdc,
                fnd_document_datatypes fdd
              WHERE fad.entity_name = 'PO_HEADERS'
              AND fdt.document_id   = fad.document_id
              AND fd.document_id    = fdt.document_id
              AND fd.category_id    = fdc.category_id
              AND fd.datatype_id    = fdd.datatype_id
              AND fdd.name          = 'FILE'
              AND fdt.description   = 'BON DE COMMANDE'
              AND fdc.name          = 'PO Internal'
              AND pk1_value         = TO_CHAR (po_header_id)
              )
            AND authorization_status = 'APPROVED'
            AND po_headers_all.org_id = organization_id
			and DSHT.document_num_new=po_headers_all.segment1
			and DSHT.org_id_absorbante=organization_id --86
			AND po_headers_all.type_lookup_code <> 'CONTRACT'
           -- AND name LIKE NVL(v_region, name)
		  -- and po_headers_all.org_id = nvl(p_region,po_headers_all.org_id)
		   ;
            --AND po_header_id in (17459,17448,5992,2)            ;test YWA

    BEGIN

        p_retcode   := 0;
        p_errbuf   := NULL;
        v_message   := 'Début procédure main';

        /*============================================================================================*/
        /*Initialisation des variables*/
        /*============================================================================================*/
        v_procedure   := 'Init';
        Fnd_File.put_line (Fnd_File.output, 'Initiation des variables');
        Init(v_errbuf, v_retcode);
        IF v_retcode = 2 THEN
            p_errbuf  := v_errbuf;
            p_retcode := v_retcode;
            RAISE v_exception;
        END IF;

        -- Initialization des journaux --
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'DKA : Génération image commande DKA_FUSPOGENIMG_PKG');
        Fnd_File.put_line (Fnd_File.LOG,'=======================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement : ' || TO_CHAR(g_request_id));
         -- Initialization de la sortie --
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'DKA : Génération image commande DKA_FUSPOGENIMG_PKG');
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Date de lancement    : ' || TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output,'Numéro de traitement : ' || TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.output,'Libelle du login OA '||FND_GLOBAL.USER_NAME);

        -- param user
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');
        Fnd_File.put_line (Fnd_File.output,'Paramètres utilisateur :');
       -- Fnd_File.put_line (Fnd_File.output,p_region);
        Fnd_File.put_line (Fnd_File.output,'=======================================================================');


        -- Entete fichier log
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');
        Fnd_File.put_line (Fnd_File.LOG,'Numéro de traitement '||TO_CHAR(g_request_id));
        Fnd_File.put_line (Fnd_File.LOG,'Libelle du login OA '||FND_GLOBAL.USER_NAME);
        Fnd_File.put_line (Fnd_File.LOG,'==========================================================================');

        Fnd_File.put_line (Fnd_File.output,'==========================================================================');
        Fnd_File.put_line (Fnd_File.output,v_nom_traitement);
        Fnd_File.put_line (Fnd_File.output,'==========================================================================');


       
        
		NBR_BC:=0;
		
        FOR c IN c_commande LOOP


            -- Appel au jeu de traitements
            v_message        := 'Appel au jeu de traitements';
            Dka_Tools_Pkg.put_outdebug_message(v_message);
            v_success := fnd_submit.set_request_set('DKA','DKA_GENBDCRPCMD');

            IF (v_success) THEN

                -- positionnement du contexte pour la phase
                fnd_submit.set_org_id(c.org_id);

                -- appel du programme DKA : Imprimer bon de commande (Portrait PDF)


                v_message        := 'appel du programme DKA : Imprimer bon de commande (Portrait PDF) STAGE10';
                Dka_Tools_Pkg.put_outdebug_message(v_message);

                v_success := fnd_submit.submit_program (
                                  'DKA'
                                 ,'DKA_SPOBON_PDF'
                                 ,'STAGE10'
                                 ,'R'
                                 ,NULL
                                 ,c.segment1
                                 ,c.segment1
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,NULL
                                 ,'Y'
                                 ,NULL
                                 ,g_user_id
                                 ,g_qty_precision
                                 ,'N'
                                 ,NULL
                                 ,'Y'
                                 ,'N'
                               );



                IF (v_success) THEN
                    -- appel du programme	DKA : Stockage de l'image du bon de commande

                    -- positionnement du contexte pour la phase
                    fnd_submit.set_org_id(c.org_id);

                    v_message        := 'appel du programme	DKA : Stockage de l''image du bon de commande';
                    Dka_Tools_Pkg.put_outdebug_message(v_message);
                    v_success := fnd_submit.submit_program ('DKA'
                                                            ,'DKA_SPOBON_STOCIMG'
                                                            ,'STAGE20'
                                                            );
                    IF (v_success) THEN
                        v_message        := 'appel du programme	DKA : Stockage de l''image du bon de commande== ok ';
                        Dka_Tools_Pkg.put_outdebug_message(v_message);
                        v_request_id := fnd_submit.submit_set(null,FALSE);
                        COMMIT;
                        v_cpt := v_cpt + 1;
                        num_trait_list(v_cpt) := v_request_id;
                        v_message        := 'request_id : ' || TO_CHAR (v_request_id);
                        Dka_Tools_Pkg.put_outdebug_message(v_message);
                    ELSE
                        v_message        := 'Erreur de l''appel du programme	DKA : Stockage de l''image du bon de commande pour la commande '||c.segment1;
                        Dka_Tools_Pkg.put_outdebug_message(v_message);
                    END IF; --SUBMIT
                ELSE
                    v_message        := 'Erreur de l''appel du programme DKA : Imprimer bon de commande (Portrait PDF) STAGE10 pour la commande '||c.segment1;
                    Dka_Tools_Pkg.put_outdebug_message(v_message);
                END IF; --STAGE20
            
            ELSE
               v_message        := 'Erreur de l''appel au jeu de traitements pour la commande '||c.segment1;
               Dka_Tools_Pkg.put_outdebug_message(v_message); 
            
            END IF; --STAGE10


            v_message        := 'FIN jeu de traitement pour la commande '||c.segment1;
            Dka_Tools_Pkg.put_outdebug_message(v_message);
        END LOOP;
        
        -- Attente de la fin des jeu de traitements
        FOR var IN 1 .. v_cpt LOOP
            Fnd_File.put_line(Fnd_File.OUTPUT,'. Numéro du jeu de traitement : ' ||num_trait_list(var));

            IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
                p_errbuf := v_message;
                Fnd_file.put_line(Fnd_file.log,
                                  'ERREUR : Attente de la fin du jeu de traitement  ' ||CHR(10) || 'MESSAGE : ' || v_message || CHR(10));
            END IF;

            IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
                Fnd_File.put_line(Fnd_File.LOG,'COMPLETION= ' || v_dev_phase || '/' ||v_dev_status);
                Fnd_File.put_line(Fnd_File.OUTPUT,'. Statut de fin : ' || v_phase || '/' ||v_status);
				
				NBR_BC := NBR_BC +1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
                Fnd_File.put_line(Fnd_File.LOG,'Fin du jeu de traitements en warning ' ||num_trait_list(var));
                Fnd_File.put_line(Fnd_File.OUTPUT,'Fin du jeu de traitement en warning ' ||num_trait_list(var));
                p_retcode := 1;

            ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
                p_retcode := 1;  
                p_errbuf  := 'ERREUR : Fin anormale du jeu de traitement : ' ||v_message;

                fnd_file.put_line(fnd_file.LOG,'ERREUR : Fin anormale du jeu de traitement ' ||
                                  num_trait_list(var) || CHR(10) || 'Phase/Statut : ' ||
                                  v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                  'MESSAGE : ' || v_message || CHR(10));
                Fnd_File.put_line(Fnd_File.OUTPUT,'===> ERREUR : Fin anormale du jeu de traitement ' ||num_trait_list(var));
            END IF;
        END LOOP;
        
		
		Fnd_File.put_line(Fnd_File.OUTPUT,'Nombre de bons de commandes générés ' ||NBR_BC);
        Fnd_File.put_line (Fnd_File.Log,'fin boucle des commandes');

        Fnd_File.put_line (Fnd_File.Log,'Fin normale');
    EXCEPTION
        WHEN v_exception THEN
            --p_retcode := 2;
            --p_errbuf  := 'Erreur EXCEPTION v_exception dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.output,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.output,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.output,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.output,'Exception : v_exception');
            Fnd_File.put_line (Fnd_File.output,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG,'Cause     : '||p_errbuf);
            Fnd_File.put_line (Fnd_File.output,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.output, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure '||v_procedure||' : EXCEPTION v_exception ');
            Fnd_File.put_line (Fnd_File.LOG, '==> Fin de la procédure '||v_procedure||' : EXCEPTION v_exception ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

       WHEN OTHERS THEN
            v_sqlerrm := SUBSTR(SQLERRM,1,200);
            p_retcode := 2;
            p_errbuf  := 'Erreur technique sur le composant dans pkg.proc/fonc '||v_package||'.'||v_procedure;
            Fnd_File.put_line (Fnd_File.output,'-------------------- ERREUR --------------------');
            Fnd_File.put_line (Fnd_File.output,'Package   : '||v_package);
            Fnd_File.put_line (Fnd_File.output,'Procédure : '||v_procedure);
            Fnd_File.put_line (Fnd_File.output,'Exception : OTHERS');
            Fnd_File.put_line (Fnd_File.output,'Message   : '||v_message);
            Fnd_File.put_line (Fnd_File.LOG, CHR(10)||p_errbuf);
            Fnd_File.put_line (Fnd_File.output,'Cause     : '||v_sqlerrm);
            Fnd_File.put_line (Fnd_File.output,'------------------------------------------------');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            Fnd_File.put_line (Fnd_File.LOG,'Traitement '||v_nom_traitement||' terminé en erreur         ');
            Fnd_File.put_line (Fnd_File.LOG,'=========================================================================');
            ROLLBACK;

    END main;

END DKA_FUSPOGENIMG_PKG;

/
SHOW ERRORS
EXIT
