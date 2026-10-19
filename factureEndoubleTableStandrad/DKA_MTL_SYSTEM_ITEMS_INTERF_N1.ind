CREATE OR REPLACE PACKAGE BODY DKA_OPEN_INTERFACE_AP_EAI_PKG AS

     ------------------------------------------------------------------------
     -- $Id: DKA_OPEN_INTERFACE_AP_EAI.pkb
     -- Capgemini
     -- Nom              : DKA_OPEN_INTERFACE_AP_EAI.pkb
     -- Description      : Corps du package DKA_OPEN_INTERFACE_AP_EAI
     -- Auteur           : Coudrier Benjamin
     -- Date de création : 10/11/2014
     -- Doc. associée    :
     -- Commentaires     : a exécuter sous SQLPLUS avec l'utilisateur APPS
     ------------------------------------------------------------------------
     -- Historique
     -- Date       Qui Description
     -- ---------- --- ------------------------------------------------------
     -- 2015/10/19 JJA OGE6729 : Gestion des notes de débits
     -- 2016/03/15 JWY OGE6721 : Gestion des acomptes
     -- 2016/11/29 MEG artf2052652
	 -- 2017/02/27 EFL artf2109466 : Optimisation. 
	 --                Tous les traitements DKA_OPEN_INTERFACE_AP_EAI sont lances en parallele avec la meme table de travail DKA_OPEN_INTERFACE_AP_EAI
     --                ->  Ajout de l'org_id dans la table et filtre de l'org lors des acces a la table. 	 
     -- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
     -- 2018/09/03 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
     -- 2018/09/05 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
     -- 2018/10/11 MEN artf3038490 : Correctif "Gestion des acomptes" - SPE188 et COM001
     -- 2019/03/13 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
     -- 30/04/2020 AAM artf07219745 enlever le critère unité opérationnelle lors du contrôle de doublon	 
     -- ---------- --- ------------------------------------------------------

     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     -- CONSTANTES ET VARIABLES PRIVEES
     --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
     cn_set_of_books_id NUMBER /*:= Fnd_Profile.VALUE('GL_SET_OF_BKS_ID')*/;
     cn_org_id          NUMBER;
     gv_step            VARCHAR2(500);
     gn_user_id         fnd_user.user_id%TYPE;

     -----------------------------------------------------------------
     --  Nom           : OUT_MSG
     --  Description   : procedure d'affichage des messages
     --
     --  PARAMETRES :
     --   p_message          texte a imprimer dans la sortie
     --
     -----------------------------------------------------------------
     PROCEDURE out_msg(p_message in varchar2) IS
     BEGIN
          -- Ecriture dans le fichier de sortie
          fnd_file.put_line(fnd_file.output, p_message);
     END out_msg;

     -----------------------------------------------------------------
     --  Nom           : LOG_MSG
     --  Description   : procedure d'affichage des messages
     --
     --  PARAMETRES :
     --   p_message      texte a imprimer dans le log
     --
     -----------------------------------------------------------------
     PROCEDURE log_msg(p_message in varchar2) IS
          l_message VARCHAR2(1000);
     BEGIN

          l_message := SUBSTR(p_message, 1, 1000);

          IF (l_message IS NULL) THEN
               l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
          END IF;

          fnd_file.put_line(fnd_file.LOG, l_message);
     END log_msg;

     ---------------------------------------------------------------------------------------------------
     --  Nom           : get_user_eai
     --  Description   : Fonction retournant l'identifiant de l'utilisateur EAI
     ---------------------------------------------------------------------------------------------------
     FUNCTION get_user_eai RETURN NUMBER IS
          vn_user_id NUMBER;
     BEGIN
          SELECT USER_ID
            INTO vn_user_id
            FROM fnd_user fu
           WHERE fu.user_name = 'EAI'   
             AND SYSDATE BETWEEN fu.start_date AND
                 nvl(fu.end_date, SYSDATE);
          RETURN vn_user_id;
     EXCEPTION
          WHEN OTHERS THEN
               vn_user_id := 0;
               RETURN vn_user_id;
     END get_user_eai;

     ---------------------------------------------------------------------------------------------------------------
     --  Nom           : run_import
     --  Description   : lancement procédure standard du traitement standard APXIIMPT
     --                  de l'open interface avec la procédure du package standard
     --                  FND_REQUEST.SUBMIT_REQUEST
     --
     --  PARAMETRES    :pv_source       Entrée
     --                 pn_group_id     Entrée
     --                 pv_hold_code    Entrée
     --                 pn_request_id   Sortie
     --          pv_status   Sortie
     --                 pv_errbuf       Sortie    message d'erreur
     --                 pn_retcode      Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
     --
     --  VALEUR RETOURNEE :
     --     Description       : ************************
     --     Valeurs possibles : ************************
     ---------------------------------------------------------------------------------------------------------------
     PROCEDURE run_import(pv_source     IN VARCHAR2,
                          pn_group_id   IN NUMBER,
                          pv_hold_code  IN VARCHAR2,
                          pn_request_id OUT NUMBER,
                          pv_status     OUT VARCHAR2,
                          pv_errbuf     OUT VARCHAR2,
                          pn_retcode    OUT NUMBER) IS

          e_error EXCEPTION;
     BEGIN
          gv_step := 'RUN_IMPORT 001 - Initialisation des variables locales.';
          log_msg(gv_step);
          pv_errbuf  := NULL;
          pn_retcode := 0;

          gv_step := 'RUN_IMPORT 002 - Lancement du traitement "DKA : Import des donné depuis l''open Interface AP".';
          log_msg(gv_step);
          pn_request_id := Fnd_Request.submit_request('SQLAP',    --APPLICATION
                                                      'APXIIMPT', --PROGRAM
                                                      NULL,       --PROGRAM_NAME
                                                      NULL,       --START_TIME
                                                      FALSE,      --SUB_REQUEST
                                                      --fnd_profile.value('ORG_ID'),  --ARGUMENT0 : unité opétionnelle
                                                      cn_org_id,   --ARGUMENT0 : unité opétionnelle
                                                      pv_source,  --ARGUMENT1 : origine
                                                      pn_group_id, --ARGUMENT2 : group
                                                      'N/A',        --ARGUMENT3 : nom lot de facture 
                                                      pv_hold_code, --ARGUMENT4 : code bloquage
                                                      NULL,         --ARGUMENT5 : motif de blocage
                                                      NULL,         --ARGUMENT6 : date GL
                                                      'N',          --ARGUMENT7 : purger
                                                      NULL,         --ARGUMENT8 : Activer analyse
                                                      NULL,         --ARGUMENT9 : Activer diagnostic
                                                      'N',          --ARGUMENT10 : synthetiser l'etat
                                                      1000,       --ARGUMENT11 : point de validation
                                                      Fnd_Global.user_id, --ARGUMENT12 : user_id
                                                      Fnd_Global.login_id --ARGUMENT13 : login_id
                                                      );

          gv_step := 'RUN_IMPORT 003 - Validation pour que les GTS puissent prendre la demande';
          log_msg(gv_step);
          COMMIT;

          IF pn_request_id = 0 THEN
               gv_step := 'RUN_IMPORT 004 - Impossible de lancer le Traitement';
               log_msg(gv_step);
               pv_status := 'en erreur';
               RAISE e_error;
          END IF;
          
          pv_status := NULL;
          /* On n'attend plus la fin de chaque traitement
          IF NOT
              fnd_concurrent.wait_for_request(pn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message) THEN
               gv_step   := 'RUN_IMPORT 004 - Erreur de traitement';
               pv_status := 'en erreur';
               RAISE e_error;
          ELSE
               IF vv_dstatus = 'WARNING' THEN
                    gv_step   := 'RUN_IMPORT 004 - Traitement termine en Warning';
                    pv_status := 'avertissement';
                    RAISE e_error;
               ELSIF vv_dstatus != 'NORMAL' THEN
                    gv_step   := 'RUN_IMPORT 004 - Traitement termine en Erreur';
                    pv_status := 'en erreur';
                    RAISE e_error;
               END IF;
          END IF;
          gv_step   := 'RUN_IMPORT 004 - Fin normale';
          pv_status := 'normal';
          */

          gv_step := 'RUN_IMPORT 005 => Numéro du traitement : ' ||
                     TO_CHAR(pn_request_id);
          log_msg(gv_step);
          
          gv_step := 'RUN_IMPORT 999 - FIN NORMAL';
          log_msg(gv_step);
     EXCEPTION
          WHEN e_error THEN
               log_msg(gv_step);
               gv_step := 'RUN_IMPORT 999 - FIN ERROR';
               log_msg(gv_step);
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'procédure run_import : ' || SQLERRM(SQLCODE);
               log_msg(pv_errbuf);
     END run_import;

     -----------------------------------------------------------------
     --  NOM           : EDITION_OUTPUT_ENTETE
     --  DESCRIPTION   : procedure d'edition du fichier de sortie
     --
     --  PARAMETRES :
     --
     --  P_RETCODE             code retour out
     --  P_ERRBUF              description de l'erreur out
     --
     -----------------------------------------------------------------
     PROCEDURE edition_output_entete(vn_nb_fac_maj_waiting IN NUMBER,
                                     vn_nb_fac_wai_null    IN NUMBER,
									 vn_org_id             IN NUMBER,
                                     p_errbuf              OUT VARCHAR2,
                                     p_retcode             OUT NUMBER) IS

          l_out VARCHAR2(4000);
          -- Parcours des enregistrements présnts dans la table d'interface AP.
          CURSOR cur_traitement_import IS
               SELECT * FROM DKA_OPEN_INTERFACE_AP_EAI where org_id = vn_org_id;

          rec_traitement_import cur_traitement_import%ROWTYPE;
     BEGIN
          --Init des variables de sortie

          gv_step := 'EDITION_OUTPUT 000 : DEBUT';
          log_msg(gv_step);

          l_out := vn_nb_fac_maj_waiting ||
                   ' factures MAJ avec le statut "WAITING"' || chr(10) ||
                   vn_nb_fac_wai_null ||
                   ' factures qui sont passees du statut "WAITING" a "NULL"' ||
                   chr(10) || 'Traitement : .' || chr(10);
          out_msg(l_out);

          FOR rec_traitement_import IN cur_traitement_import LOOP
               l_out := 'Traitement n° ' || rec_traitement_import.REQUEST_ID ||
                        ' terminé ' || rec_traitement_import.STATUS;
               out_msg(l_out);
          END LOOP;

          gv_step := 'EDITION_OUTPUT 999 : FIN';
          log_msg(gv_step);

     EXCEPTION
          WHEN OTHERS THEN
               p_retcode := 2;
               p_errbuf  := 'Erreur procedure EDITION_OUTPUT :' || gv_step ||
                            chr(10) || SQLERRM;
               log_msg(p_errbuf);
     END edition_output_entete;

     -----------------------------------------------------------------
     --  NOM           : main
     --  DESCRIPTION   : Procédure principale du traitement
     --
     --  PARAMETRES   :   pv_retcode                Code retour.
     --                   pn_errbuf                 Description de l'erreur.
     -----------------------------------------------------------------
     PROCEDURE main(pv_errbuf OUT VARCHAR2, 
                    pn_retcode OUT NUMBER,
                    pn_org_id IN NUMBER) IS
          --org_name              varchar(50); 
          -- Variable compteur :
          vn_nb_fac_maj_waiting NUMBER;
          vn_nb_fac_wai_null    NUMBER;
          
          vn_count_doublon NUMBER;
          
          -- 2016/03/15 JWY OGE6721 : Gestion des acomptes : Recuperation des trios Source / Origine / Group_id
          CURSOR cur_source_origine IS
               SELECT DISTINCT AII.SOURCE,
                      AII.ATTRIBUTE9 ORIGINE,
                      AII.GROUP_ID,
                      AII.ORG_ID organization
                 FROM AP_INVOICES_INTERFACE AII
                WHERE AII.SOURCE = 'AMONTS'
                  AND AII.CREATED_BY = gn_user_id
                  AND (AII.STATUS != 'PROCESSED' OR AII.STATUS IS NULL)
                  AND AII.ORG_ID = cn_org_id 
                  order by 1,2,3;

          -- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
          -- Parcours des enregistrements présents dans la table d'interface AP.
          CURSOR cur_ap_interface IS
               SELECT AII.INVOICE_ID,
                      AII.GL_DATE,
                      AII.ATTRIBUTE9 ORIGINE,
                      substr(AII.DOC_CATEGORY_CODE, 1, 4) SOCIETE,
                      substr(AII.PAY_GROUP_LOOKUP_CODE, 8) TYPE_FOURNISSEUR,
                      AII.VENDOR_ID,
                      AII.STATUS,
                      AII.GROUP_ID,
                      AII.SOURCE, 
                      AII.ORG_ID organization,
                      AII.invoice_num,
                      AII.vendor_site_code,
                      AII.vendor_site_id,
                      AII.invoice_date,
                      AII.invoice_amount,
                      AII.vendor_num,
                      AII.rowid rid
                 FROM AP_INVOICES_INTERFACE AII
                WHERE AII.SOURCE = 'AMONTS'
                  AND AII.CREATED_BY = gn_user_id
                  AND (AII.STATUS != 'PROCESSED' OR AII.STATUS IS NULL)
                  AND AII.ORG_ID = cn_org_id 
                ORDER BY AII.ATTRIBUTE9,
                         substr(AII.DOC_CATEGORY_CODE, 1, 4),
                         --AII.ORG_ID,
                         substr(AII.PAY_GROUP_LOOKUP_CODE, 8);

          CURSOR cur_traitement_import IS
               SELECT * FROM DKA_OPEN_INTERFACE_AP_EAI
			   WHERE org_id = cn_org_id;
         
          -- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
          -- 2018/09/03 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent    
         CURSOR cur_error IS
          select invoice_id, invoice_num from ap_invoices_interface aii where aii.vendor_num like '%DOUBLON' 
          and aii.vendor_site_id = -999 and aii.status = 'REJECTED' AND aii.source = 'AMONTS'
          and NOT EXISTS (select 'x' from ap_interface_rejections air
                          where air.parent_id = aii.invoice_id and air.reject_lookup_code = 'DUPLICATE INVOICE NUMBER');


          --rec_gl_interface cur_gl_interface%ROWTYPE;
          rec_traitement_import cur_traitement_import%ROWTYPE;

          vn_group_id         ap_invoices_interface.group_id%TYPE;
          vv_code_blocage     DKA_STRANSCO_LINES.RETURN_VALUE%TYPE;
          vv_attribute9       AP_INVOICES_INTERFACE.ATTRIBUTE9%TYPE;
          vv_societe          AP_INVOICES_INTERFACE.DOC_CATEGORY_CODE%TYPE;
          vv_type_fournisseur AP_INVOICES_INTERFACE.PAY_GROUP_LOOKUP_CODE%TYPE;
          vn_request_id       NUMBER;
          vv_status           VARCHAR2(100);
          vn_present_gi       NUMBER;
          vn_period_open      NUMBER;
          
          ln_traitements_non_termine NUMBER;
          lb_continue                BOOLEAN;
          
          -- Variable de type exception.
          e_main       EXCEPTION;
          e_periode    EXCEPTION;
          e_err_org_id EXCEPTION;

     BEGIN
	     
       cn_org_id := pn_org_id;
       
       gv_step := 'Organisation : ' || cn_org_id;
       log_msg(gv_step);
       
       BEGIN

          SELECT hou.set_of_books_id
            INTO cn_set_of_books_id
            FROM hr_operating_units hou
           WHERE hou.organization_id = cn_org_id;
          
       EXCEPTION
         WHEN OTHERS THEN
           RAISE e_err_org_id; 
       
       END;

          --gv_step := 'Organisation : ' || fnd_profile.value('ORG_ID') || ' _ ' || org_name|| ' _ Livre : ' || cn_set_of_books_id;
          gv_step := 'Livre : ' || cn_set_of_books_id;
          log_msg(gv_step);
		  
          gv_step := 'MAIN 000 - Initialisation de l''ensemble des variables.';
          log_msg(gv_step);
          vn_nb_fac_maj_waiting := 0;
          vn_nb_fac_wai_null    := 0;
          vn_request_id         := 0;
          vv_attribute9         := ' ';
          vv_societe            := ' ';
          vv_type_fournisseur   := ' ';
          vv_status             := ' ';

          gv_step := 'MAIN 001 - Suppression des enregistrements dans la table de travail DKA_OPEN_INTERFACE_AP_EAI.';
          log_msg(gv_step);
          DELETE DKA_OPEN_INTERFACE_AP_EAI WHERE Org_Id = cn_org_id;
          COMMIT;

          gv_step := 'MAIN 002 - Recherche de l''identifiant de l''utilisateur EAI.';
          log_msg(gv_step);
          gn_user_id := get_user_eai();

          --11/10/2018
          /* 2016/03/15 JWY OGE6721 : Gestion des acomptes */
          --gv_step := 'MAIN 002b - Recherche des trios Source/Origine/Groupe';
          --log_msg(gv_step);
          --FOR rec_s_o IN cur_source_origine LOOP
          --    gv_step := '           Source : '||rec_s_o.source||' / Origine : '||rec_s_o.origine||' / Groupe : '||rec_s_o.group_id;
          --    log_msg(gv_step);
          --    DKA_AP_TOOLS_PKG.apply_fonction(pv_errbuf,pn_retcode,'OI_'||rec_s_o.origine,rec_s_o.source,rec_s_o.origine,rec_s_o.group_id,cn_org_id);
          --END LOOP;

          gv_step := 'MAIN 003 - Parcours des lignes AP dans la table d''interface pour la source AMONTS, l''utilisateur EAI et le statut different de ''PROCESSED''.';
          log_msg(gv_step);

          FOR rec_ap_interface IN cur_ap_interface LOOP

               gv_step := 'MAIN 003.1 - Vérifier si la facture est présents sur une période AP ouverte ou fermé';
               log_msg(gv_step);
               vn_period_open := 0;
			   vv_code_blocage := NULL;
               BEGIN
                    SELECT count(1)
                      INTO vn_period_open
                      FROM gl_period_statuses gps
                     WHERE gps.ledger_id = cn_set_of_books_id
                       AND gps.application_id = 200
                       AND gps.closing_status in ('O', 'C')
                       AND rec_ap_interface.GL_DATE BETWEEN gps.start_date AND gps.end_date;
               EXCEPTION
                    WHEN OTHERS THEN
                         vn_period_open := 0;
               END;

               IF vn_period_open > 0 THEN
                    gv_step := 'MAIN 003.2 - Si la date comptable de la facture AP est comprise dans une période ouverte.';
                    log_msg(gv_step);

                    IF rec_ap_interface.STATUS = 'REJECTED' THEN
                         gv_step := 'MAIN 003.2.a - Recherche de la presence de l''identifiant du groupe dans la table de travail.';
                         log_msg(gv_step);
                         BEGIN
                              SELECT count(1)
                                INTO vn_present_gi
                                FROM DKA_OPEN_INTERFACE_AP_EAI
                               WHERE GROUP_ID = rec_ap_interface.GROUP_ID
							     AND ORG_ID = cn_org_id;
                         EXCEPTION
                              WHEN OTHERS THEN
                                   vn_present_gi := 0;
                         END;

                         IF vn_present_gi = 0 THEN
                              gv_step := 'MAIN 003.2.b - Recherche du code blocage pour la facture ' ||
                                         rec_ap_interface.INVOICE_ID || '.';
                              log_msg(gv_step);
                              BEGIN
                                   SELECT decode(DSL.RETURN_VALUE, 'Aucun', NULL, DSL.RETURN_VALUE)
                                     INTO vv_code_blocage
                                     FROM DKA_STRANSCO_HEADERS DSH,
                                          DKA_STRANSCO_LINES   DSL
                                    WHERE DSH.SET_ID = DSL.SET_ID
                                      AND DSH.SET_NAME = 'AP_HOLD_CODE'
                                      AND DSL.PARAM1_VALUE = rec_ap_interface.ORIGINE
                                      AND DSL.PARAM2_VALUE =
                                          (SELECT APS.VENDOR_TYPE_LOOKUP_CODE --RGH : Migration R12 : remplacer PO_VENDORS par AP_SUPPLIERS
                                             FROM AP_SUPPLIERS APS
                                            WHERE APS.VENDOR_ID =
                                                  rec_ap_interface.VENDOR_ID);
                              EXCEPTION
                                   WHEN OTHERS THEN
                                        vv_code_blocage := NULL;
                              END;

                              gv_step := 'MAIN 003.2.c - Insertion des enregistrements dans la table de travail DKA_OPEN_INTERFACE_AP_EAI.';
                              log_msg(gv_step);
                              INSERT INTO DKA_OPEN_INTERFACE_AP_EAI
                                   (GROUP_ID,
                                    SET_OF_BOOK_ID,
                                    REQUEST_ID,
                                    STATUS,
                                    CODE_BLOCAGE,
                                    SOURCE,
                                    DATE_INSERTION,
									ORG_ID)
                              VALUES
                                   (rec_ap_interface.GROUP_ID,
                                    cn_set_of_books_id,
                                    NULL,
                                    NULL,
                                    vv_code_blocage,
                                    rec_ap_interface.SOURCE,
                                    SYSDATE,
									cn_org_id);
                              COMMIT;
                         END IF;

                    ELSE
                         gv_step := 'MAIN 003.2.a - Recherche du code blocage pour la facture ' ||
                                    rec_ap_interface.INVOICE_ID || '.';
                         log_msg(gv_step);
                         BEGIN
                              SELECT decode(DSL.RETURN_VALUE, 'Aucun', NULL, DSL.RETURN_VALUE)
                                INTO vv_code_blocage
                                FROM DKA_STRANSCO_HEADERS DSH,
                                     DKA_STRANSCO_LINES   DSL
                               WHERE DSH.SET_ID = DSL.SET_ID
                                 AND DSH.SET_NAME = 'AP_HOLD_CODE'
                                 AND DSL.PARAM1_VALUE =
                                     rec_ap_interface.ORIGINE
                                 AND DSL.PARAM2_VALUE =
                                     (SELECT APS.VENDOR_TYPE_LOOKUP_CODE --RGH : Migration R12 : remplacer PO_VENDORS par AP_SUPPLIERS
                                        FROM AP_SUPPLIERS APS
                                       WHERE APS.VENDOR_ID =
                                             rec_ap_interface.VENDOR_ID);
                         EXCEPTION
                              WHEN OTHERS THEN
                                   vv_code_blocage := NULL;
                         END;

                         IF vv_attribute9 != rec_ap_interface.ORIGINE OR
                            vv_societe != rec_ap_interface.SOCIETE OR
                            vv_type_fournisseur != rec_ap_interface.TYPE_FOURNISSEUR THEN

                              vv_attribute9       := rec_ap_interface.ORIGINE;
                              vv_societe          := rec_ap_interface.SOCIETE;
                              vv_type_fournisseur := rec_ap_interface.TYPE_FOURNISSEUR;

                              gv_step := 'MAIN 003.2.b - Generation du nouvel identifiant de groupe.';
                              log_msg(gv_step);
                              SELECT ap_interface_groups_s.NEXTVAL
                                INTO vn_group_id
                                FROM DUAL;

                              INSERT INTO DKA_OPEN_INTERFACE_AP_EAI
                                   (GROUP_ID,
                                    SET_OF_BOOK_ID,
                                    REQUEST_ID,
                                    STATUS,
                                    CODE_BLOCAGE,
                                    SOURCE,
                                    DATE_INSERTION,
									ORG_ID)
                              VALUES
                                   (vn_group_id,
                                    cn_set_of_books_id,
                                    NULL,
                                    NULL,
                                    vv_code_blocage,
                                    rec_ap_interface.SOURCE,
                                    SYSDATE,
									cn_org_id);
                              
							  COMMIT;
                         END IF;

                         IF rec_ap_interface.STATUS = 'WAITING' THEN
                              vn_nb_fac_wai_null := vn_nb_fac_wai_null + 1;
                         END IF;

                         gv_step := 'MAIN 003.2.c - Mise a jour de l''identifiant de groupe.';
                         log_msg(gv_step);
                         UPDATE AP_INVOICES_INTERFACE AII
                            SET AII.STATUS   = NULL,
                                AII.GROUP_ID = vn_group_id
                          WHERE AII.INVOICE_ID =
                                rec_ap_interface.INVOICE_ID;
                         COMMIT;
                    END IF;
                    
                    -- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
                    -- 2018/09/03 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
                    SELECT count(*)
                    INTO  vn_count_doublon
                    FROM  ap_invoices_all api,
                          ap_suppliers pv,
                          ap_supplier_sites pvs
                    WHERE 1=1 --api.org_id = pn_org_id 30/04/2020 AAM artf07219745 enlever le critère unité opérationnelle lors du contrôle de doublon
                    AND api.invoice_num = rec_ap_interface.invoice_num
                    AND api.vendor_id = pv.vendor_id
                    /*AND ( pvs.vendor_site_code  != NVL(rec_ap_interface.vendor_site_code, 'NULL') 
                      OR pvs.vendor_site_id != rec_ap_interface.vendor_site_id )*/ --AAM artf07219745 enlever le critère site fournisseur lors du contrôle de doublon
                    AND pvs.vendor_id = pv.vendor_id
                    --AND pv.segment1 = rec_ap_interface.vendor_num
                    AND pv.vendor_id = rec_ap_interface.vendor_id
                    AND api.invoice_date = rec_ap_interface.invoice_date
                    AND api.invoice_amount = rec_ap_interface.invoice_amount;
                    
                    IF vn_count_doublon > 0 THEN
                      UPDATE AP_INVOICES_INTERFACE AII
                      SET AII.vendor_site_id = -999,
                          AII.vendor_site_code = NULL,
						  -- 2019/03/13 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent	 
						  AII.vendor_num = AII.vendor_num || decode(instr(nvl(vendor_num,'Z'), 'DOUBLON'),0, ' - DOUBLON', '')
                      WHERE AII.rowid = rec_ap_interface.rid;
                    END IF;

               ELSIF rec_ap_interface.STATUS != 'WAITING' OR
                     rec_ap_interface.STATUS IS NULL THEN
                    gv_step := 'MAIN 003.2 - Si la date comptable de la facture AP n''est pas comprise dans une période ouverte.';
                    log_msg(gv_step);
                    UPDATE AP_INVOICES_INTERFACE AII
                       SET AII.STATUS = 'WAITING'
                     WHERE AII.INVOICE_ID = rec_ap_interface.INVOICE_ID;
                    COMMIT;
                    gv_step := 'MAIN 003.3 - Mise ?jour du statut de la facture ' ||
                               rec_ap_interface.INVOICE_ID ||
                               ' a la valeur WAITING.';
                    log_msg(gv_step);
                    vn_nb_fac_maj_waiting := vn_nb_fac_maj_waiting + 1;
               END IF;
          END LOOP;

         --11/10/2018
          /* 2016/03/15 JWY OGE6721 : Gestion des acomptes */
          gv_step := 'MAIN 003.3 - Recherche des trios Source/Origine/Groupe';
          log_msg(gv_step);
          FOR rec_s_o IN cur_source_origine LOOP
              gv_step := '           Source : '||rec_s_o.source||' / Origine : '||rec_s_o.origine||' / Groupe : '||rec_s_o.group_id;
              log_msg(gv_step);
              DKA_AP_TOOLS_PKG.apply_fonction(pv_errbuf,pn_retcode,'OI_'||rec_s_o.origine,rec_s_o.source,rec_s_o.origine,rec_s_o.group_id,cn_org_id);
          END LOOP;

          gv_step := 'MAIN 004 - Execution de l''ensemble des traitements d''integration.';
          log_msg(gv_step);
          FOR rec_traitement_import IN cur_traitement_import LOOP
               gv_step := 'MAIN 004.a - APXIIMPT Group_Id = ' ||
                          rec_traitement_import.group_id;
               log_msg(gv_step);
               run_import(rec_traitement_import.SOURCE, rec_traitement_import.GROUP_ID, rec_traitement_import.CODE_BLOCAGE, vn_request_id, vv_status, pv_errbuf, pn_retcode);

               gv_step := 'MAIN 004.b - Mise a jour de la table DKA_OPEN_INTERFACE_AP_EAI.';
               log_msg(gv_step);
               UPDATE DKA_OPEN_INTERFACE_AP_EAI DOI
                  SET DOI.REQUEST_ID = vn_request_id,
                      DOI.STATUS     = vv_status
                WHERE DOI.GROUP_ID = rec_traitement_import.GROUP_ID
				  AND DOI.ORG_ID = cn_org_id;

               COMMIT;
          END LOOP;
 
          --> JJA - 2015/10/19
          gv_step := 'MAIN 004B - Gestion des notes de débit';
          log_msg(gv_step);
          UPDATE ap_invoices_all
          SET    invoice_type_lookup_code = 'DEBIT',
                 attribute11              = NULL
          WHERE  invoice_type_lookup_code = 'CREDIT'
             AND attribute11              = 'DEBIT';

          gv_step := 'MAIN 004B - Mise a jour de '||SQL%ROWCOUNT||' facture(s)';
          log_msg(gv_step);
          --> JJA - 2015/10/19
          
          --Attente de la fin de tous les traitements
          lb_continue := TRUE;
          while lb_continue LOOP
            
             SELECT COUNT(1)
              INTO ln_traitements_non_termine
              FROM dka_open_interface_ap_eai doiae,
                   fnd_concurrent_requests   fcr
             WHERE doiae.request_id = fcr.request_id
			   AND doiae.org_id =  cn_org_id
               AND nvl(fcr.phase_code,'#') != 'C';
             
             IF ln_traitements_non_termine > 0 THEN
               gv_step := 'MAIN 005 - Traitements en cours : '||ln_traitements_non_termine;
               log_msg(gv_step);
               dbms_lock.sleep(30); --on attend 30 secondes               
             ELSE               
               lb_continue := FALSE;
             END IF;
             
          END LOOP; 

          --Mise a jour des statuts des traitements
          UPDATE DKA_OPEN_INTERFACE_AP_EAI DOI
              SET DOI.STATUS     = (SELECT flv.meaning stat_code
                                    FROM fnd_concurrent_requests   fcr,
                                         fnd_lookup_values_vl flv
                                   WHERE fcr.request_id = DOI.request_id 
                                     AND flv.lookup_code = fcr.status_code
                                     AND flv.lookup_type = 'CP_STATUS_CODE'
                                     AND flv.view_application_id = 0)
		  WHERE org_id =  cn_org_id ;
      
      
          -- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Contrôle doublon facture AP sur site différent
          FOR rec_error IN cur_error LOOP
                 
            INSERT INTO ap_interface_rejections
            (parent_table,
             parent_id,
             reject_lookup_code,
             last_updated_by,
             last_update_date,
             last_update_login,
             created_by,
             creation_date)
            VALUES
            ('AP_INVOICES_INTERFACE',
             rec_error.invoice_id,
             'DUPLICATE INVOICE NUMBER',
             fnd_global.user_id,
             SYSDATE,
             fnd_global.login_id,
             fnd_global.user_id,
             SYSDATE);
          END LOOP;

          gv_step := 'MAIN 005 - Creation de la sortie du traitement.';
          log_msg(gv_step);
          edition_output_entete(vn_nb_fac_maj_waiting, vn_nb_fac_wai_null,cn_org_id, pv_errbuf, pn_retcode);

          gv_step := 'MAIN 999 - Fin Main.';

     EXCEPTION
          WHEN e_err_org_id THEN
               pn_retcode := 2;
               pv_errbuf  := 'Impossible de recuperer le ledger_id' ||
                             chr(10) || SQLERRM;
               log_msg(pv_errbuf);
               gv_step := 'MAIN ERROR - Impossible de recuperer le ledger_id';
               log_msg(gv_step);
          WHEN e_periode THEN
               pn_retcode := 2;
               pv_errbuf  := 'La periode AP en cours n''existe pas ou n''est pas ouverte ' ||
                             chr(10) || SQLERRM;
               log_msg(pv_errbuf);
               gv_step := 'MAIN ERROR - La periode AP en cours n''existe pas ou n''est pas ouverte.';
               log_msg(gv_step);
          WHEN OTHERS THEN
               pn_retcode := 2;
               pv_errbuf  := 'MAIN 999 - ERROR - ' || SQLERRM;
               log_msg('Etape: ' || gv_step);
               log_msg(pv_errbuf);
     END;

END DKA_OPEN_INTERFACE_AP_EAI_PKG;
/
show errors;
exit
