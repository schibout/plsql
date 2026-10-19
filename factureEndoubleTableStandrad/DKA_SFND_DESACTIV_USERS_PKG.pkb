CREATE OR REPLACE PACKAGE BODY DKA_SARRGLTPRLV_AUTO_PKG
IS

---------------------------------------------------------------------------------------------------------------
--- NOM               : DKA_SARRGLTPRLV_AUTO_PKG.pkb
--- DESCRIPTION       : Automatisation des pr閘鑦ements clients
---
--- AUTEUR            : Sara CHARKAOUI
--- DATE DE CREATION  : 26/09/2019
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
---------------------------------------------------------------------------------------------------------------
--- Date         Qui  Description
--- ----------   ---  --------------------------------------------------------------------------------------------
--- 26/09/2019   SCH  Creation
---------------------------------------------------------------------------------------------------------------

  gv_expediteur       VARCHAR2(150);
    gv_conn             VARCHAR2(30);
    g_step              VARCHAR2(500);
    gv_base             v$database.name%TYPE;
    gn_amt              BINARY_INTEGER := 672 * 3;
    BOUNDARY            CONSTANT VARCHAR2(256) := '=_NextPart_DC7E1BB5_1105_4DB3_BAE3_2A6208EB099D';
    FIRST_BOUNDARY      CONSTANT VARCHAR2(256) := '--' || BOUNDARY ||
                                                  utl_tcp.CRLF;
    LAST_BOUNDARY       CONSTANT VARCHAR2(256) := '--' || BOUNDARY || '--' ||
                                                  utl_tcp.CRLF;
    MULTIPART_MIME_TYPE CONSTANT VARCHAR2(256) := 'multipart/mixed; boundary=' ||
                                                  BOUNDARY;
    MAX_LINE_WIDTH PLS_INTEGER := 54;


-- Variable d'exception :
    e_envoi_mail  EXCEPTION;
    e_mail        EXCEPTION;
    e_nom_etat    EXCEPTION;

-- Variable contenant l'ent每陋te et le corps du mail.
    gv_objet VARCHAR2(4000);
    gv_corps VARCHAR2(4000);
    gv_filename VARCHAR2(500);


/*===================================================================================================
--  Nom           : wait_GLPOS
--  Description   : Attente de la fin d'execution du traitement GLPOS soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entr閑/Sortie      message d'erreur
--  pn_retcode                Entr閑/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
--==================================================================================================*/

  PROCEDURE wait_rvctp(pv_errbuf             IN OUT VARCHAR2,
                       pn_retcode            IN OUT NUMBER,
                       pn_request_id_porvctp IN NUMBER) IS

    vb_trash      BOOLEAN;
    vv_phase      VARCHAR2(50);
    vv_status     VARCHAR2(50);
    vv_dev_phase  VARCHAR2(50);
    vv_dev_status VARCHAR2(50);
    vv_message    VARCHAR2(50);

  BEGIN

    -- Attente de la fin d'execution des programmes
    vb_trash := fnd_concurrent.wait_for_request(pn_request_id_porvctp, -- REQUEST_ID
                                                10, -- INTERVAL
                                                0, -- MAX_WAIT (pas de delai)
                                                vv_phase, -- PHASE
                                                vv_status, -- STATUS
                                                vv_dev_phase, -- DEV_PHASE
                                                vv_dev_status, -- DEV_STATUS
                                                vv_message -- MESSAGE
                                                );

     Fnd_File.put_line(Fnd_File.LOG,'WAIT: Le statut du program: vv_status' || vv_status);

    IF NOT vb_trash
    THEN
      pv_errbuf := pv_errbuf || 'Pb dans l attente wait_RVCTP';
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Le traitement termine en Warning');
      Fnd_File.put_line(Fnd_File.LOG,'Le traitement termine en Warning');
      pn_retcode:=1;
  ELSE
    IF UPPER(vv_status) = 'NORMAL'
    THEN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Le traitement termine Normalement');
      Fnd_File.put_line(Fnd_File.LOG,'Le traitement termine Normalement');
    pn_retcode:=0;

    ELSIF UPPER(vv_status) = 'WARNING'
    THEN
      --pv_errbuf := pv_errbuf || vv_message;
       FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Le traitement se termine en Warning');
       Fnd_File.put_line(Fnd_File.LOG,'Le traitement se termine en Warning');
       pn_retcode:=1;


    ELSIF UPPER(vv_status) = 'ERROR'
    THEN
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Le traitement termine en Erreur');
     Fnd_File.put_line(Fnd_File.LOG,'Le traitement termine en ERREUR');
     pn_retcode:=2;

    ELSE
     FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'Le traitement ne se termine pas normalement');
     Fnd_File.put_line(Fnd_File.LOG,'Le traitement ne se termine pas normalement');
     pn_retcode:=2;

    END IF;
  END IF;

  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de wait_RVCTP avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;

  END wait_rvctp;


/*==========================================================================
-- Procedure         : MAIN1
-- Description       : LANCEMENT de l'etat ETA121
-- Parametres entree : P_DATE    IN DATE       : une date d'閏h閍nce
--                   : P_REGION  IN VARCHAR2   : une REGION
-- Parametres sortie : AUCUN
-- Remarques         :
--==========================================================================*/
PROCEDURE MAIN1(   pv_errbuf    IN OUT   VARCHAR2,
             pn_retcode   OUT      NUMBER,
             P_DATE      IN  VARCHAR2,
             P_REGION    IN  VARCHAR2
           ) IS

  l_application_code      VARCHAR2(300)   := 'DKA';
  l_conc_program        VARCHAR2(300) := 'DKAR_AR_FACNLETRREES';
  l_conc_program_1      VARCHAR2(300) := 'DKA_SARRGLTPRLV_MAIL';
  l_request_id_1        NUMBER;
  l_request_id              NUMBER;

  l_layout          boolean;

  cn_tempo           CONSTANT NUMBER          := 20;

BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DEBUT: lancement du traitement ETA121');
    Fnd_File.put_line(Fnd_File.LOG,'DEBUT: lancement du traitement ETA121');


    l_layout:=fnd_request.add_layout (
                      template_appl_name   => 'DKA',
                      template_code        => 'DKAR_AR_FACNLETRREES',
                      template_language    => 'fr', --Use language from template definition
                      template_territory   => 'F', --Use territory from template definition
                      output_format        => 'EXCEL' --Use output format from template definition
                        );


    l_request_id := FND_REQUEST.submit_request( l_application_code,
                          l_conc_program,
                          null,
                          SYSDATE,
                          FALSE,
                          P_DATE,
                          P_REGION,
                          '',
                          '',
                          ''
                          );
              COMMIT;
    Fnd_File.put_line(Fnd_File.LOG,'resultat du FND_REQUEST.submit_request: l_request_id ' || l_request_id);

    wait_rvctp(pv_errbuf, pn_retcode, l_request_id);


--IF l_request_id IS NOT NULL THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DEBUT: lancement du traitement Envoi des 閠ats pour le prelevement automatique ');
    l_request_id_1 := FND_REQUEST.submit_request( l_application_code,
                          l_conc_program_1,
                          null,
                          SYSDATE,
                          FALSE,
                          l_request_id,
                          P_REGION,
                          P_DATE
                          );
    COMMIT;

        Fnd_File.put_line(Fnd_File.LOG,'resultat du FND_REQUEST.submit_request:  l_request_id ' || l_request_id_1);

    wait_rvctp(pv_errbuf, pn_retcode, l_request_id_1);

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'FIN: lancement du traitement Envoi des etats pour le prelevement automatique ');

EXCEPTION
   WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG,'-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG,SQLERRM);
      pv_errbuf := SQLERRM;
      pn_retcode :=2;
      
END MAIN1;

/*==========================================================================
-- Procedure         : MAIN2
-- Description       : LANCEMENT de l'etat ETA122
-- Parametres entree : P_DATE    IN DATE       : une date d'echeance
--                   : P_REGION  IN VARCHAR2   : une REGION
-- Parametres sortie : AUCUN
-- Remarques         :
--==========================================================================*/

PROCEDURE MAIN2( pv_errbuf    IN OUT   VARCHAR2,
           pn_retcode      OUT   NUMBER,
           P_DATE     IN     VARCHAR2,
           P_REGION     IN       VARCHAR2
           ) IS

  l_application_code      VARCHAR2(300)   := 'DKA';
  l_conc_program        VARCHAR2(300) := 'DKA_RAR_PRELEVCLINET';
  l_conc_program_1      VARCHAR2(300) := 'DKA_SARRGLTPRLV_MAIL';
  l_request_id_1        NUMBER;
  l_request_id              NUMBER;

  l_layout          boolean;

  cn_tempo           CONSTANT NUMBER          := 20;

BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DEBUT: lancement du traitement ETA122');
    Fnd_File.put_line(Fnd_File.LOG,'DEBUT: lancement du traitement ETA122');


    l_layout:=fnd_request.add_layout (
                      template_appl_name   => 'DKA',
                      template_code        => 'DKA_RAR_PRELEVCLINET',
                      template_language    => 'fr', --Use language from template definition
                      template_territory   => 'F', --Use territory from template definition
                      output_format        => 'EXCEL' --Use output format from template definition
                        );


    l_request_id := FND_REQUEST.submit_request( l_application_code,
                          l_conc_program,
                          null,
                          SYSDATE,
                          FALSE,
                          P_DATE,
                          P_REGION,
                          '',
                          '',
                          ''
                          );
              COMMIT;
    Fnd_File.put_line(Fnd_File.LOG,'resultat du FND_REQUEST.submit_request: l_request_id ' || l_request_id);

    wait_rvctp(pv_errbuf, pn_retcode, l_request_id);


--IF l_request_id IS NOT NULL THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DEBUT: lancement du traitement Envoi des etats pour le prelevement automatique ');
    l_request_id_1 := FND_REQUEST.submit_request( l_application_code,
                          l_conc_program_1,
                          null,
                          SYSDATE,
                          FALSE,
                          l_request_id,
                          P_REGION,
                          P_DATE
                          );
    COMMIT;

        Fnd_File.put_line(Fnd_File.LOG,'resultat du FND_REQUEST.submit_request:  l_request_id ' || l_request_id_1);

    wait_rvctp(pv_errbuf, pn_retcode, l_request_id_1);

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'FIN: lancement du traitement Envoi des etats pour le prelevement automatique ');


EXCEPTION
   WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG,'-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG,SQLERRM);
      pv_errbuf := SQLERRM;
      pn_retcode :=2;

END MAIN2;

/*==========================================================================
-- Procedure         : MAIN2
-- Description       : LANCEMENT de l'etat ETA122
-- Parametres entree : P_DATE    IN DATE       : une date d'echeance
--                   : P_REGION  IN VARCHAR2   : une REGION
-- Parametres sortie : AUCUN
-- Remarques         :
--==========================================================================*/
PROCEDURE MAIN3( pv_errbuf    IN OUT   VARCHAR2,
           pn_retcode      OUT   NUMBER,
           P_DATE     IN     VARCHAR2,
           P_REGION     IN       VARCHAR2
           ) IS

  l_application_code      VARCHAR2(300)   := 'DKA';
  l_conc_program        VARCHAR2(300) := 'DKA_RAR_PRELEVCLINETDEF';
  l_conc_program_1      VARCHAR2(300) := 'DKA_SARRGLTPRLV_MAIL';
  l_request_id_1        NUMBER;
  l_request_id              NUMBER;

  l_layout          boolean;

  cn_tempo           CONSTANT NUMBER          := 20;

BEGIN
    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DEBUT: lancement du traitement ETA123');
    Fnd_File.put_line(Fnd_File.LOG,'DEBUT: lancement du traitement ETA123');


    l_layout:=fnd_request.add_layout (
                      template_appl_name   => 'DKA',
                      template_code        => 'DKA_RAR_PRELEVCLINETDEF',
                      template_language    => 'fr', --Use language from template definition
                      template_territory   => 'F', --Use territory from template definition
                      output_format        => 'EXCEL' --Use output format from template definition
                        );


    l_request_id := FND_REQUEST.submit_request( l_application_code,
                          l_conc_program,
                          null,
                          SYSDATE,
                          FALSE,
                          P_DATE,
                          P_REGION,
                          '',
                          '',
                          ''
                          );
              COMMIT;
    Fnd_File.put_line(Fnd_File.LOG,'resultat du FND_REQUEST.submit_request: l_request_id ' || l_request_id);

    wait_rvctp(pv_errbuf, pn_retcode, l_request_id);


--IF l_request_id IS NOT NULL THEN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'DEBUT: lancement du traitement Envoi des etats pour le prelevement automatique ');
    l_request_id_1 := FND_REQUEST.submit_request( l_application_code,
                          l_conc_program_1,
                          null,
                          SYSDATE,
                          FALSE,
                          l_request_id,
                          P_REGION,
                          P_DATE
                          );
    COMMIT;

        Fnd_File.put_line(Fnd_File.LOG,'resultat du FND_REQUEST.submit_request:  l_request_id ' || l_request_id_1);

    wait_rvctp(pv_errbuf, pn_retcode, l_request_id_1);

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, 'FIN: lancement du traitement Envoi des etats pour le prelevement automatique ');

EXCEPTION
   WHEN OTHERS THEN
      Fnd_File.put_line(Fnd_File.LOG,'-------------------- ERREUR --------------------');
      Fnd_File.put_line(Fnd_File.LOG,SQLERRM);
      pv_errbuf := SQLERRM;
      pn_retcode :=2;

END MAIN3;
/*=================================================================
--  Nom           : INIT
--  Description   : procedure d'initialisation
--
--  PARAMETRES :
--
--
--=================================================================*/

PROCEDURE init(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) IS

        rec_param dka_parameters%ROWTYPE;
        e_expediteur_vide EXCEPTION;

    BEGIN
        --Init des variables de sortie
        p_retcode := 0;
        p_errbuf  := '';

        Dka_Tools_Pkg.get_parameter('SARRGLTPRLV',
                                    'EXPEDITEUR_MAIL',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_expediteur := rec_param.varchar2_value;

        IF gv_expediteur IS NULL THEN
            RAISE e_expediteur_vide;
        END IF;

        SELECT name INTO gv_base FROM v$database;

        Dka_Tools_Pkg.get_parameter('SARRGLTPRLV',
                                    'SMTP_CONNECTION',
                                    rec_param,
                                    p_errbuf,
                                    p_retcode);
        gv_conn := rec_param.varchar2_value;

        --Reinit des variables de sortie
        p_retcode := 0;
        p_errbuf  := '';

    EXCEPTION
        WHEN e_expediteur_vide THEN
            p_errbuf := 'Aucun expediteur trouve';
            DKA_TOOLS_PKG.put_log_message(p_errbuf);
            p_retcode := 2;
        WHEN OTHERS THEN
            p_errbuf := 'Erreur procedure INIT :' || g_step || chr(10) ||
                        SQLERRM;
            DKA_TOOLS_PKG.put_log_message(p_errbuf);
            p_retcode := 2;
    END init;

/*=================================================================
  --  Nom           : OUT_MSG
  --  Description   : procedure d'affichage des messages
  --
  --  PARAMETRES :
  --   p_message          texte a imprimer dans la sortie
  --
--=================================================================*/

PROCEDURE out_msg(p_message in varchar2) IS
BEGIN
  -- Ecriture dans le fichier de sortie
  fnd_file.put_line(fnd_file.output, p_message);

END out_msg;

/*=================================================================
--  Nom           : LOG_MSG
--  Description   : procedure d'affichage des messages
--
--  PARAMETRES :
--   p_message      texte a imprimer dans le log
--
--=================================================================*/

PROCEDURE log_msg(p_message in varchar2) IS
        l_message VARCHAR2(1000);
BEGIN

        l_message := SUBSTR(p_message, 1, 1000);

        IF (l_message IS NULL) THEN
            l_message := TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
        END IF;

        fnd_file.put_line(fnd_file.LOG, l_message);
END log_msg;

/*=================================================================
--  Nom           : write_boundary
--  Description   : Proc每漏dure
--
--  PARAMETRES :
--=================================================================*/
PROCEDURE write_boundary(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE) IS
BEGIN
        IF (last) THEN
            utl_smtp.write_data(conn, LAST_BOUNDARY);
        ELSE
            utl_smtp.write_data(conn, FIRST_BOUNDARY);
        END IF;
END write_boundary;

/*=================================================================
--  Nom           : begin_attachment
--  Description   : Proc每漏dure
--
--  PARAMETRES :
--=================================================================*/
PROCEDURE begin_attachment(conn         IN OUT NOCOPY utl_smtp.connection,
                           mime_type    IN VARCHAR2 DEFAULT 'text/plain',
                           inline       IN BOOLEAN DEFAULT TRUE,
                           filename     IN VARCHAR2 DEFAULT NULL,
                           transfer_enc IN VARCHAR2 DEFAULT NULL) IS
BEGIN
        write_boundary(conn);
        utl_smtp.write_raw_data(conn,
                                utl_raw.cast_to_raw('Content-Type: ' ||
                                                    mime_type ||
                                                    utl_tcp.CRLF));
        IF (filename IS NOT NULL) THEN
            IF (inline) THEN
                utl_smtp.write_raw_data(conn,
                                        utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                            'inline; filename="' ||
                                                            filename || '"' ||
                                                            utl_tcp.CRLF));
            ELSE
                utl_smtp.write_raw_data(conn,
                                        utl_raw.cast_to_raw('Content-Disposition: ' ||
                                                            'attachment; filename="' ||
                                                            filename || '"' ||
                                                            utl_tcp.CRLF));
            END IF;
        END IF;
        IF (transfer_enc IS NOT NULL) THEN
            utl_smtp.write_raw_data(conn,
                                    utl_raw.cast_to_raw('Content-Transfer-Encoding: ' ||
                                                        transfer_enc ||
                                                        utl_tcp.CRLF));
        END IF;
        utl_smtp.write_data(conn, utl_tcp.CRLF);
END begin_attachment;

/*=================================================================
    --  Nom           : end_attachment
    --  Description   : Proc每漏dure
    --
    --  PARAMETRES :
=================================================================*/

PROCEDURE end_attachment(conn IN OUT NOCOPY utl_smtp.connection,
                             last IN BOOLEAN DEFAULT FALSE) IS
    BEGIN
        utl_smtp.write_data(conn, utl_tcp.CRLF || utl_tcp.CRLF);
        IF (last) THEN
            write_boundary(conn, last);
        END IF;
END end_attachment;

/*================================================================================================================
-- Procedure         : GET_NOM_ETAT
-- Description       : Fonction pour r閏up閞er le nom de l'閠at 酄 partir de son request_id
-- Parametres entree : P_Req_Id    IN NUMBER : le numero de traitement
--               Pv_Errbuf   IN OUT    : Message d'avertissement
--             Pn_Retcode  IN OUT    : Code erreur
--
-- Parametres sortie : AUCUN
-- Remarques         :
--================================================================================================================*/
FUNCTION get_nom_etat(P_Req_Id   IN NUMBER,
  Pv_Errbuf  IN OUT VARCHAR2,
           Pn_Retcode IN OUT NUMBER) RETURN VARCHAR2 IS
  vv_trt FND_CONCURRENT_PROGRAMS.CONCURRENT_PROGRAM_NAME%TYPE;
BEGIN

 SELECT fcp.concurrent_program_name
    INTO vv_trt
    FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
   WHERE fcr.concurrent_program_id = fcp.concurrent_program_id
     AND fcr.request_id = p_req_id;

  CASE vv_trt
    WHEN 'DKAR_AR_FACNLETRREES' THEN
      RETURN 'ETA121';
    WHEN 'DKA_RAR_PRELEVCLINET' THEN
      RETURN 'ETA122';
    WHEN 'DKA_RAR_PRELEVCLINETDEF' THEN
      RETURN 'ETA123';
    ELSE
      RETURN 'ETA121';
  END CASE;

EXCEPTION
  WHEN OTHERS THEN
    pn_retcode := 2;
    pv_errbuf  := 'Erreur procedure GET_NOM_ETAT :'|| g_step ||chr(10)||SQLERRM;
    log_msg(pv_errbuf);
END get_nom_etat;
/*=================================================================
--  Nom           : envoi_avec_fichier
--  Description   : Envoi du message avec fichier.
--
--  PARAMETRES    :
--          Pv_Errbuf    IN OUT     Message d'avertissement
--          Pn_Retcode   IN OUT     Code erreur
--          P_Date     IN         date echeance
--          P_Req_Id     IN         id du traitement
--          P_Region   IN         region
--=================================================================*/
PROCEDURE envoi_avec_fichier(Pv_Errbuf   IN OUT VARCHAR2,
                             Pn_Retcode  IN OUT NUMBER,
                             P_Date    IN VARCHAR2,
                             P_Req_Id    IN NUMBER,
               P_Region    IN VARCHAR2) IS
        l_mesg     VARCHAR2(4000);
        l_conn     UTL_SMTP.CONNECTION;
        l_file     BFILE;
    V_FILEDIR  VARCHAR2(3000);
        l_file_len PLS_INTEGER;
        l_modulo   PLS_INTEGER;
        l_pieces   PLS_INTEGER;
        l_filepos  PLS_INTEGER := 1; /* pointeur pour le fichier */
        l_buf      RAW(2100);
        l_data     RAW(2100);
        l_chunks   PLS_INTEGER;
        vr_reply   UTL_SMTP.REPLY;
    vv_adresses    VARCHAR2(32000);
    vb_adress_valide NUMBER;
    e_pas_destinataire EXCEPTION;
    v_grant    VARCHAR2(1000);

    vv_nom_etat VARCHAR2(30);


    CURSOR cur_file_name(P_Req_Id NUMBER) IS

      SELECT  SUBSTR(OUTFILE_NAME, INSTR(OUTFILE_NAME,'/',-1) + 1, 200)  FILE_NAME,
          outfile_name,
          fcp.concurrent_program_name || '_' || fcr.request_id || '_1.xls' excel_file
      FROM  fnd_concurrent_requests fcr, FND_CONCURRENT_PROGRAMS fcp
      WHERE   fcr.concurrent_program_id = fcp.concurrent_program_id
          and fcr.request_id = P_Req_Id;

        rec_file_name cur_file_name%ROWTYPE;

          CURSOR c_liste_destinataire IS
               SELECT ffvv.description adresse, ffvv.flex_value
                 FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                WHERE ffvs.flex_value_set_name = 'DKA_ENVOI_MAIL_REGION'
                  AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                  AND ffvv.enabled_flag = 'Y'
                  and ffvv.flex_value = P_Region
                  AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND
                      NVL(ffvv.end_date_active, SYSDATE)
            ;

    BEGIN

    vb_adress_valide := 0;
        g_step := 'ENVOI_AVEC_FICHIER 000 : DEBUT - RECHERCHE DU NOM DU TRAITEMENT';
        log_msg(g_step);
        vv_nom_etat := get_nom_etat(p_req_id, pv_errbuf, pn_retcode);

        IF Pn_Retcode != 0 THEN
            g_step := 'ENVOI_MAIL 001 : ERROR - RECUPERATION DU NOM DU TRAITEMENT';
            raise e_nom_etat;
        END IF;

        g_step := 'ENVOI_AVEC_FICHIER 001 : RECHERCHE DE L''OBJET DU MAIL.';
        log_msg(g_step);
        gv_objet := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_'||vv_nom_etat||'_TITRE'/*,
                                              ' ',
                                              NULL*/);
        g_step   := 'ENVOI_AVEC_FICHIER 002 : RECHERCHE DU CORPS DU MAIL.';
        log_msg(g_step);

        gv_corps := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_'||vv_nom_etat||'_CORPS',
                                              'DATE_ECHEANCE',
                                              TO_CHAR(to_date(P_Date,'yyyy/mm/dd hh24:mi:SS'), 'DD/MM/YYYY'),
                                              'REGION',
                                              P_Region);

        g_step := 'ENVOI_AVEC_FICHIER 003 : CONNEXION.';
    log_msg(g_step);
        l_conn := utl_smtp.open_connection(gv_conn, 25);

        g_step := 'ENVOI_AVEC_FICHIER 004 : DEBUT CONSTRUCTION MAIL.';
    log_msg(g_step);
        utl_smtp.helo(l_conn, gv_conn);

        vr_reply := utl_smtp.mail(l_conn, gv_expediteur);
        g_step   := 'REPLY MAIL : ' || vr_reply.code || ' - ' ||
                    vr_reply.text;
    log_msg(g_step);

      g_step := 'SEND_MAIL 003 : LISTE DESTINATAIRE';
      log_msg(g_step);
      FOR ligne IN c_liste_destinataire LOOP

         vr_reply := utl_smtp.rcpt(l_conn, '<' || ligne.adresse || '>');

         g_step := 'REPLY RCPT : ' || vr_reply.code || ' - ' ||
              vr_reply.text;
         log_msg(g_step);

         IF vr_reply.code != '250' THEN
          g_step := 'SEND_MAIL E03 : ERREUR SUR DESTINATAIRE : ' ||
                 ligne.adresse;
          log_msg(g_step);
          IF vb_adress_valide = 0 THEN
             vr_reply := utl_smtp.rcpt(l_conn, '<' ||
                          gv_expediteur || '>');

             g_step := 'REPLY RCPT : ' || vr_reply.code ||
                  ' - ' || vr_reply.text;
             log_msg(g_step);
             vv_adresses      := vv_adresses || ';' ||
                       gv_expediteur;
             vb_adress_valide := 1;
          END IF;
         ELSE
          vv_adresses := vv_adresses || ';' || ligne.adresse;
         END IF;

      END LOOP;

      --On retire le 1er ;
      IF LENGTH(vv_adresses) > 1 THEN
         vv_adresses := SUBSTR(vv_adresses, 2);
         log_msg(substr('Adresse(s) destinataire(s)  : ' ||
                vv_adresses, 1, 255));

      ELSE
         RAISE e_pas_destinataire;
      END IF;


        utl_smtp.open_data(l_conn);
        l_mesg := 'Date: ' || to_char(systimestamp, 'dd Mon yyyy hh24:mi:ss tzhtzm', 'NLS_DATE_LANGUAGE=American') || utl_tcp.CRLF ||
                  'From: ' || gv_expediteur || utl_tcp.CRLF ||
          'To: ' || vv_adresses/*gv_plat_appro_mail*/ || utl_tcp.CRLF ||
          'Subject:' || gv_objet || utl_tcp.CRLF ||
          'Reply-To: ' || gv_expediteur || utl_tcp.CRLF ||
          'Return-Path: ' || gv_expediteur || utl_tcp.CRLF ||
                  'MIME-Version: 1.0' || utl_tcp.CRLF ||
          'Content-Type: ' || MULTIPART_MIME_TYPE || utl_tcp.CRLF || utl_tcp.CRLF;
        utl_smtp.write_data(l_conn, l_mesg);

        -- Insertion du corps du message
        BEGIN
            begin_attachment(conn => l_conn, mime_type => 'text/html');
            utl_smtp.write_data(l_conn, gv_corps);
            end_attachment(conn => l_conn);
        END;

        OPEN cur_file_name(P_Req_Id);
        LOOP
            FETCH cur_file_name
                INTO rec_file_name;
            EXIT WHEN cur_file_name%NOTFOUND;

            gn_amt      := 672 * 3;
            l_filepos := 1;

            gv_filename := Dka_Tools_Pkg.get_message('DKA',
                                              'DKA_'||vv_nom_etat||'_FICHIER');

            begin_attachment(conn         => l_conn,
                             mime_type    => 'text/csv',
                             inline       => TRUE,
                             filename     => gv_filename || '_'||P_Region||'_'||TO_CHAR(to_date(P_Date,'yyyy/mm/dd hh24:mi:SS'), 'DD-MM-YYYY')||'.xls', --rec_file_name.excel_file,--rec_file_name.FILE_NAME,
                             transfer_enc => 'base64');

      BEGIN

        /*
        select  d.directory_name
          INTO V_FILEDIR
        from (SELECT length(OUTFILE_NAME) - length( SUBSTR(OUTFILE_NAME, INSTR(OUTFILE_NAME,'/',-1) + 1, 200)) FILE_NAME, OUTFILE_NAME, request_id FROM   FND_CONCURRENT_REQUESTS ) req, all_directories d
        where SUBSTR(req.OUTFILE_NAME,1,req.FILE_NAME-1) = directory_path
          and req.request_id =P_Req_Id
          and rownum <2; */
        
        g_step := 'SEND_MAIL 03b : Recuperation repertoire';
        log_msg(g_step);
          
        SELECT d.directory_name
          INTO V_FILEDIR
          FROM all_directories d
         WHERE DIRECTORY_NAME = 'DKA_SARENCAIS_FILE_OUT_DIR';

        g_step := 'SEND_MAIL 4 :  file '|| V_FILEDIR ;
        log_msg(g_step);
      END;
      g_step := 'SEND_MAIL 5.9 :  name file '|| rec_file_name.excel_file;
      log_msg(g_step);

      l_file     := BFILENAME(V_FILEDIR, rec_file_name.excel_file);

      g_step := 'SEND_MAIL 6 :  l_file ' || V_FILEDIR ||'---'|| rec_file_name.excel_file;
      log_msg(g_step);


            l_file_len := dbms_lob.getlength(l_file);
            l_modulo   := mod(l_file_len, gn_amt);
            l_pieces   := trunc(l_file_len / gn_amt);
            l_buf      := NULL;

      IF (l_modulo <> 0) THEN
              l_pieces := l_pieces + 1;
            END IF;

            dbms_lob.fileopen(l_file, dbms_lob.file_readonly);
            dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
            l_data := NULL;
            FOR i IN 1 .. l_pieces LOOP
             log_msg('Step 1');
                l_filepos  := i * gn_amt + 1;
                l_file_len := l_file_len - gn_amt;
                l_data     := utl_raw.concat(l_data, l_buf);
                l_chunks   := trunc(utl_raw.length(l_data) /
                                    MAX_LINE_WIDTH);

                IF (i <> l_pieces) THEN
                    l_chunks := l_chunks - 1;
                END IF;
        log_msg('Step 2');
                utl_smtp.write_raw_data(l_conn,
                                        utl_encode.base64_encode(l_data));
        log_msg('Step 3');
                l_data := NULL;
                IF (l_file_len < gn_amt AND l_file_len > 0) THEN
                    gn_amt := l_file_len;
                END IF;

                IF l_pieces > 1 THEN
        log_msg('Step 4');
                    dbms_lob.read(l_file, gn_amt, l_filepos, l_buf);
          log_msg('Step 5');
                END IF;
            END LOOP;
      log_msg('Step 6');
            dbms_lob.fileclose(l_file);
      log_msg('Step 7');
            end_attachment(conn => l_conn);
      log_msg('Step 8');
        END LOOP;
        CLOSE cur_file_name;
        log_msg('Step 9');
        utl_smtp.close_data(l_conn);
    log_msg('Step 10');
        utl_smtp.quit(l_conn);
    log_msg('Step 11');
        g_step := 'ENVOI_AVEC_FICHIER 005 ==> Mail BdC envoye a adresse : ' ||
                  vv_adresses;
        log_msg(g_step);

        g_step := 'ENVOI_AVEC_FICHIER 099 : FIN';
        log_msg(g_step);
    EXCEPTION
       WHEN e_pas_destinataire THEN
               --Fermeture de la connexion
               IF l_conn.host IS NOT NULL THEN
                    vr_reply := utl_smtp.quit(l_conn);
               END IF;

               Pv_Errbuf  := 'Pas de destinataire';
               Pn_Retcode := 2;
               Dka_Tools_Pkg.Put_Debug_Message(Pv_Errbuf);
               RAISE;
         WHEN e_nom_etat THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : PAS DE TRAITEMENT CORRESPONDANT AU REQUEST_ID '|| P_Req_Id || ' / ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            Pv_Errbuf  := 'ENVOI_AVEC_FICHIER 099 - ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
            RAISE;
    END envoi_avec_fichier;


/*===================================================================================
  --  NOM           : EDITION_OUTPUT_MAIL
  --  DESCRIPTION   : procedure d'edition du fichier de sortie pour l'envoi par mail
  --
  --  PARAMETRES :
  --
  --  P_RETCODE             code retour out
  --  P_ERRBUF              description de l'erreur out
  --  P_REQ_ID        request_id du traitement p每拧re
--==================================================================================*/
  PROCEDURE edition_output_mail(p_errbuf        OUT VARCHAR2,
                                p_retcode       OUT NUMBER,
                    p_req_id       IN NUMBER,
                P_Region       IN VARCHAR2) IS

   l_appl       fnd_application.application_short_name%TYPE;
   l_prgm_name  fnd_conc_req_summary_v.PROGRAM%TYPE;

   l_out        VARCHAR2(4000);
   l_ligne      VARCHAR2(100) := '---------------------------------------------------------------';

   -- Curseur de recherche de l'ensemble des adresses mail de destination :
   CURSOR cur_mail IS
    select ffv.flex_value, ffv.FLEX_VALUE_MEANING, ffv.DESCRIPTION
          from fnd_flex_values_vl ffv, fnd_flex_value_sets ffvs
         where ffvs.flex_value_set_id = ffv.flex_value_set_id
           and ffvs.flex_value_set_name = 'DKA_ENVOI_MAIL_REGION'
           and ffv.ENABLED_FLAG = 'Y'
       and ffv.flex_value = P_Region
           and nvl(ffv.START_DATE_ACTIVE, trunc(SYSDATE)) <=
               trunc(SYSDATE)
           and nvl(ffv.END_DATE_ACTIVE, trunc(SYSDATE)) >=
               trunc(SYSDATE)
           and ffv.SUMMARY_FLAG = 'N';


   rec_mail cur_mail%ROWTYPE;
  BEGIN

    g_step  := 'EDITION_OUTPUT_MAIL 000 : DEBUT';
    log_msg(g_step);

     --Recuperation des informations
     BEGIN
    --R每漏cup每漏ration du nom de la base de donn每漏es.
    SELECT name
    INTO gv_base
    FROM v$database;

      --Recuperation du nom de l'application.
      SELECT fa.application_short_name
      INTO l_appl
      FROM fnd_application fa
      WHERE fa.application_id = fnd_profile.VALUE('RESP_APPL_ID');

      --Recuperation du nom du programme.
      SELECT v.PROGRAM
      INTO l_prgm_name
      FROM fnd_conc_req_summary_v v
      WHERE v.REQUEST_ID =  fnd_global.CONC_REQUEST_ID;

    EXCEPTION
     WHEN OTHERS THEN
      l_appl := '';
    END;


    --ENTETE
    l_out := 'Environnement   : '||gv_base||chr(10)||
             'Application     : '||l_appl||chr(10)||
             'Programme       : '||l_prgm_name||chr(10)||
             'Utilisateur     : '||fnd_profile.VALUE('USERNAME')||chr(10)||
             'Date            : '||to_char(SYSDATE,'DD/MM/YYYY HH24:MI:SS')||chr(10);
    out_msg(l_out);

    out_msg(l_ligne);

    --CORPS
  l_out := 'Parametre :';out_msg(l_out);
  l_out := '-----------';out_msg(l_out);
  l_out := 'Numero du traitement a traiter : '||p_req_id;out_msg(l_out);
  out_msg(l_ligne);
  l_out := 'E-mail de destination : ';out_msg(l_out);
  l_out := '------------------------';out_msg(l_out);
  OPEN cur_mail;
         LOOP
             FETCH cur_mail
                 INTO rec_mail;
       EXIT WHEN cur_mail%NOTFOUND;
        l_out := rec_mail.DESCRIPTION;out_msg(l_out);
       END LOOP;
  CLOSE cur_mail;
  out_msg(l_ligne);
  l_out := 'MAIL :';out_msg(l_out);
  l_out := '------';out_msg(l_out);
  l_out := 'OBJET : ' || gv_objet;out_msg(l_out);
  out_msg(gv_corps);

    g_step  := 'EDITION_OUTPUT_MAIL 999 : FIN';
    log_msg(g_step);

  EXCEPTION
   WHEN OTHERS THEN
    p_retcode := 2;
    p_errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL :'|| g_step ||chr(10)||SQLERRM;
    log_msg(p_errbuf);
  END edition_output_mail;

/*================================================================================================================
-- Procedure         : ENVOI_MAIL
-- Description       : Proc閐ure principale du traitement "DKA : Envoi des 閠ats pour le pr閘鑦ement automatique"
-- Parametres entree : P_Req_Id    IN NUMBER : le numero de traitement
--               Pv_Errbuf   IN OUT    : Message d'avertissement
--             Pn_Retcode  IN OUT    : Code erreur
--             P_Region    IN        : REGION
--             P_Date      IN        : date echeance
--
-- Parametres sortie : AUCUN
-- Remarques         :
--================================================================================================================*/

PROCEDURE ENVOI_MAIL(Pv_Errbuf  IN OUT VARCHAR2,
           Pn_Retcode IN OUT NUMBER,
           P_Req_Id   IN NUMBER,
           P_Region   IN VARCHAR2,
           P_Date   IN VARCHAR2) IS

    e_edition_output_mail EXCEPTION;

    BEGIN

        g_step := 'ENVOI_MAIL 000 : DEBUT';
        log_msg(g_step);


        -- Initialisation des variables d'envoi de mail :
        g_step := 'ENVOI_MAIL 001 : INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
        log_msg(g_step);
        init(Pv_Errbuf, Pn_Retcode);
        IF Pn_Retcode != 0 THEN
            g_step := 'ENVOI_MAIL 001 : ERROR - INITIALISATION DES VARIABLES D''ENVOI DE MAIL.';
            raise e_envoi_mail;
        END IF;


                  -- Initialisation du message contenant un fichier.
                g_step := 'ENVOI_MAIL 002 : ENVOI DU MESSAGE AVEC FICHIER.';
                log_msg(g_step);
                envoi_avec_fichier(Pv_Errbuf,
                                   Pn_Retcode,
                   P_Date,
                   P_Req_Id,
                   P_Region
                 );

    ----------------------------------------------------------------
    --Edition fichier de sortie
    ----------------------------------------------------------------
    g_step := 'ENVOI_MAIL 003 : EDITION FICHIER DE SORTIE.';
    log_msg(g_step);
    edition_output_mail(Pv_Errbuf,Pn_Retcode,P_Req_Id, P_Region);
    IF Pn_Retcode != 0 THEN
      RAISE e_edition_output_mail;
    END IF;
        g_step := 'ENVOI_MAIL 999 : FIN';
        log_msg(g_step);
    EXCEPTION
    WHEN e_edition_output_mail THEN
      Pv_Errbuf  := 'Erreur procedure EDITION_OUTPUT_MAIL';
      Pn_Retcode := 2;
      log_msg(Pv_Errbuf);
        WHEN e_mail THEN
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
        WHEN e_envoi_mail THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;
        WHEN OTHERS THEN
            log_msg('ERREUR - ' || g_step);
            Pv_Errbuf := 'ERREUR : ' || SQLERRM;
            log_msg(Pv_Errbuf);
            Pn_Retcode := 2;

  END ENVOI_MAIL;


END DKA_SARRGLTPRLV_AUTO_PKG;
/
SHOW ERRORS
EXIT
