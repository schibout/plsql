CREATE OR REPLACE PACKAGE BODY DKA_SARAVIPRELEV_PKG AS
  ------------------------------------------------------------------------------------------
  -- $$
  -- CAPGEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SARAVIPRELEV_PKG.pkb
  -- DESCRIPTION       : DKA_SARAVIPRELEV_PKG package body :
  --
  -- AUTEUR           : Benjamin Coudrier (CAPGEMINI)
  -- DATE DE CREATION : 17/12/2013
  -- DOC. ASSOCIEE    :
  -- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
  ------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- 23/02/2021 ARA EDB282 - Enrichissement de l'avis de prélèvement (Migration vers XML publisher) et envoi par mail

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  gv_expediteur VARCHAR2(150);
  gv_conn       VARCHAR2(30);
    
  gv_base       v$database.name%TYPE;

  -- Message d'information.
  g_step        VARCHAR2(500);

  -- Variable contenant l'entête et le corps du mail.
  gv_objet      VARCHAR2(4000);
  gv_corps      VARCHAR2(4000);

  -- Variable contenant les noms abrégés des traitements :
  gv_rarprel_pdf    CONSTANT VARCHAR2(25) := 'DKA_RARPREL_PDF';
  gv_sarprel_attach CONSTANT VARCHAR2(25) := 'DKA_SARPREL_ATTACH';

  -- Variable contenant les informations de mise à jour :
  cn_user_id  CONSTANT NUMBER := fnd_profile.value('USER_ID');
  cn_login_id CONSTANT NUMBER := fnd_profile.value('LOGIN_ID');

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

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

  -------------------------------------------------------------------------------------
  --  Nom           : lance_trait_pdf
  --  Description   : procedure d'exécution de traitement de création du fichier avis de prélèvement
  --
  --  PARAMETRES    :
  --  Pn_Cash_Receipt_ID  IN        Identifiant du prélèvement
  --  Pv_prog_name        IN        Nom du programme
  --  Pv_Errbuf           IN OUT    Message d'avertissement
  --  Pn_Retcode          IN OUT    Code erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
  ------------------------------------------------------------------------------------
  PROCEDURE lance_trait_pdf(Pn_Cash_Receipt_ID IN NUMBER,
                            Pn_org_id          IN NUMBER,
                            Pv_prog_name       IN VARCHAR2,
                            Pv_Errbuf          IN OUT VARCHAR2,
                            Pn_Retcode         IN OUT NUMBER)
  IS
  
    cn_tempo   CONSTANT NUMBER := 10;
    e_error    EXCEPTION;
    
    vv_prog_application_short_name VARCHAR(30);
    vn_request_id                  NUMBER(15);
    vv_rphase                      VARCHAR2(80);
    vv_rstatus                     VARCHAR2(80);
    vv_dphase                      VARCHAR2(30);
    vv_dstatus                     VARCHAR2(30);
    vv_message                     VARCHAR2(240);
    l_layout        BOOLEAN;
    
  BEGIN
    g_step := 'LANCE_TRAIT_PDF 000 : DEBUT';
    log_msg(g_step);
  
    -- Recherche de l'application propriétaire du traitement. --
    g_step := 'LANCE_TRAIT_PDF 001 : RECHERCHE DES INFORMATIONS LIEES AU PROGRAMME D''ENVOI PAR MAIL.';
    BEGIN
      SELECT fa.application_short_name
      INTO vv_prog_application_short_name
      FROM fnd_concurrent_programs fcp
      JOIN fnd_application         fa on(fa.application_id = fcp.application_id)
      WHERE fcp.concurrent_program_name = Pv_prog_name;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_error;
        g_step := 'LANCE_TRAIT_PDF 001 - ERREUR : Impossible de trouver l''application propriétaire.';
        log_msg(g_step);
    END;
  
    /*vn_request_id := fnd_request.submit_request(application => vv_prog_application_short_name,
                                                program     => Pv_prog_name,
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE,
                                                argument1   => pn_cash_receipt_id);*/
    -- ARA
    l_layout := fnd_request.add_layout(template_appl_name => 'DKA',
                                         template_code      => 'DKA_RARPREL_PDF',
                                         template_language  => 'fr', --Use language from template definition
                                         template_territory => 'F', --Use territory from template definition
                                         output_format      => 'PDF' --Use output format from template definition
                                         );
    
    vn_request_id := fnd_request.submit_request(application => vv_prog_application_short_name,
                                                program     => Pv_prog_name,
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE,
                                                argument1   => pn_cash_receipt_id);
    
    g_step := 'LANCE_TRAIT_PDF 002 :Validation pour que les GTS puissent prendre la demande.';
    log_msg(g_step);
    COMMIT;
  
    IF vn_request_id = 0 THEN
      DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
      RAISE e_error;
    END IF;
  
    DBMS_OUTPUT.put_line('Traitement numero : ' || TO_CHAR(vn_request_id));
  
    IF NOT fnd_concurrent.wait_for_request(vn_request_id,
                                           cn_tempo,
                                           0,
                                           vv_rphase,
                                           vv_rstatus,
                                           vv_dphase,
                                           vv_dstatus,
                                           vv_message) THEN
      RAISE e_error;
    ELSE
      IF vv_dstatus = 'WARNING' THEN
        DBMS_OUTPUT.put_line(CHR(10) || '>>> Traitement termine en Warning ');
        RAISE e_error;
      ELSIF vv_dstatus != 'NORMAL' THEN
        DBMS_OUTPUT.put_line(CHR(10) || '>>> Traitement termine en Erreur ');
        RAISE e_error;
      END IF;
    END IF;
    
    g_step := 'LANCE_TRAIT_PDF 999 : FIN';
    log_msg(g_step);
  
    INSERT INTO DKA_SARPREL_ATTACH_TMP
      (REQUEST_ID,
       CASH_RECEPT_ID,
       CREATED_BY,
       CREATION_DATE,
       LAST_UPDATED_BY,
       LAST_UPDATE_DATE,
       ORG_ID)
    VALUES
      (vn_request_id,
       Pn_Cash_Receipt_ID,
       cn_user_id,
       SYSDATE,
       cn_user_id,
       SYSDATE,
       Pn_org_id);
  
  EXCEPTION
    WHEN e_error THEN
      g_step     := '';
      Pv_Errbuf  := g_step;
      Pn_Retcode := 2;
    WHEN OTHERS THEN
      g_step := 'LANCE_TRAIT_PDF 999 - ERREUR : ' || Pv_prog_name ||' ==> ERREUR : ' || SQLERRM;
      log_msg(g_step);
      Pv_Errbuf  := g_step;
      Pn_Retcode := 2;
  END lance_trait_pdf;

  -------------------------------------------------------------------------------------
  --  Nom           : lance_trait
  --  Description   : procedure d'exécution de traitement
  --
  --  PARAMETRES    :
  -- Pv_prog_name    IN      Nom du programme
  --  Pv_Errbuf           IN OUT      Message d'avertissement
  --  Pn_Retcode          IN OUT      Code erreur
  --  VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : true=traitement sans erreur, false=traitement en erreur
  ------------------------------------------------------------------------------------
  PROCEDURE lance_trait(Pv_prog_name IN VARCHAR2,
                        Pv_Errbuf    IN OUT VARCHAR2,
                        Pn_Retcode   IN OUT NUMBER)
  IS
  
    cn_tempo   CONSTANT NUMBER := 20;
    e_error    EXCEPTION;
    
    vv_prog_application_short_name VARCHAR(30);
    vn_request_idd                  NUMBER(15);
    vv_rphase                      VARCHAR2(80);
    vv_rstatus                     VARCHAR2(80);
    vv_dphase                      VARCHAR2(30);
    vv_dstatus                     VARCHAR2(30);
    vv_message                     VARCHAR2(240);
    
  BEGIN
    g_step := 'LANCE_TRAIT 000 : DEBUT';
    log_msg(g_step);
  
    -- Recherche de l'application propriétaire du traitement. --
    g_step := 'LANCE_TRAIT 001 : RECHERCHE DES INFORMATIONS LIEES AU PROGRAMME D''ENVOI PAR MAIL.';
    BEGIN
      SELECT fa.application_short_name
      INTO vv_prog_application_short_name
      FROM fnd_concurrent_programs fcp
      JOIN fnd_application         fa on(fa.application_id = fcp.application_id)
      WHERE fcp.concurrent_program_name = Pv_prog_name;
    EXCEPTION
      WHEN OTHERS THEN
        RAISE e_error;
        g_step := 'LANCE_TRAIT 001 - ERREUR : Impossible de trouver l''application propriétaire.';
        log_msg(g_step);
    END;
  
    vn_request_idd := fnd_request.submit_request(application => vv_prog_application_short_name,
                                                program     => Pv_prog_name,
                                                description => NULL,
                                                start_time  => NULL,
                                                sub_request => FALSE);
    
    g_step        := 'LANCE_TRAIT 002 :Validation pour que les GTS puissent prendre la demande.';
    log_msg(g_step);
    COMMIT;
  
    IF vn_request_idd = 0 THEN
      DBMS_OUTPUT.put_line('Impossible de lancer le Traitement ');
      RAISE e_error;
    END IF;
  
    DBMS_OUTPUT.put_line('Traitement numero : ' || TO_CHAR(vn_request_idd));
  
    IF NOT fnd_concurrent.wait_for_request(vn_request_idd,
                                           cn_tempo,
                                           0,
                                           vv_rphase,
                                           vv_rstatus,
                                           vv_dphase,
                                           vv_dstatus,
                                           vv_message) THEN
      RAISE e_error;
    ELSE
      IF vv_dstatus = 'WARNING' THEN
        DBMS_OUTPUT.put_line(CHR(10) ||
                             '>>> Traitement termine en Warning ');
        RAISE e_error;
      ELSIF vv_dstatus != 'NORMAL' THEN
        DBMS_OUTPUT.put_line(CHR(10) ||
                             '>>> Traitement termine en Erreur ');
        RAISE e_error;
      END IF;
    END IF;
    g_step := 'LANCE_TRAIT 999 : FIN';
    log_msg(g_step);
  EXCEPTION
    WHEN e_error THEN
      g_step     := '';
      Pv_Errbuf  := g_step;
      Pn_Retcode := 2;
    WHEN OTHERS THEN
      g_step := 'LANCE_TRAIT 999 - ERREUR : ' || Pv_prog_name ||
                ' ==> ERREUR : ' || SQLERRM;
      log_msg(g_step);
      Pv_Errbuf  := g_step;
      Pn_Retcode := 2;
  END lance_trait;

  -----------------------------------------------------------------
  --  NOM           : EDITION_OUTPUT
  --  DESCRIPTION   : procedure d'edition du fichier de sortie
  --
  --  PARAMETRES :
  --
  --  P_RETCODE             code retour out
  --  P_ERRBUF              description de l'erreur out
  -----------------------------------------------------------------
  PROCEDURE edition_output(p_errbuf  OUT VARCHAR2, 
                           p_retcode OUT NUMBER) IS
  
    l_appl      fnd_application.application_short_name%TYPE;
    l_prgm_name fnd_conc_req_summary_v.PROGRAM%TYPE;
    l_conc_program     VARCHAR2(50) := 'DKA_RAR_PRELEVBQUE';
    l_out   VARCHAR2(4000);
    l_ligne VARCHAR2(100) := '---------------------------------------------------------------';
  
    CURSOR cur_avis_prelevement(pv_status VARCHAR2) IS
    SELECT distinct DST.CASHRECEIPTID,
                    DST.REMIT_REFERENCE,
                    DST.CUSTOMER_NAME,
                    DST.RECEIPT_REFERENCE,
                    DST.REMIT_AMOUNT
    FROM DKA_SARAUTOPRELEV_TMP DST
    WHERE DST.STATUS = pv_status
    ORDER BY DST.CASHRECEIPTID;
    
    rec_avis_prelevement cur_avis_prelevement%ROWTYPE;
    --vv_status            DKA_IEOAPSAT01_APIMP_HDR.STATUS%TYPE;
    vv_status VARCHAR2(30);
  
  BEGIN
  
    g_step := 'EDITION_OUTPUT 000 : DEBUT';
    log_msg(g_step);
    vv_status := 'PRINT';
    --Recuperation des informations
    BEGIN
      --Récupération du nom de la base de données.
      SELECT name INTO gv_base FROM v$database;
    
      --Recuperation du nom de l'application.
      SELECT fa.application_short_name
      INTO l_appl
      FROM fnd_application fa
      WHERE fa.application_id = fnd_profile.VALUE('RESP_APPL_ID');
    
      --Recuperation du nom du programme.
      SELECT v.PROGRAM
      INTO l_prgm_name
      FROM fnd_conc_req_summary_v v
      WHERE v.REQUEST_ID = fnd_global.CONC_REQUEST_ID;
    
    EXCEPTION
      WHEN OTHERS THEN
        l_appl := '';
    END;
  
    --ENTETE
    l_out := 'Environnement   : ' || gv_base || chr(10) ||
             'Application     : ' || l_appl || chr(10) ||
             'Programme       : ' || l_prgm_name || chr(10) ||
             'Utilisateur     : ' || fnd_profile.VALUE('USERNAME') ||chr(10) ||
             'Date            : ' || to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || chr(10);
    out_msg(l_out);
    out_msg(l_ligne);
  
    --CORPS
    l_out := 'Liste des prélèvements :';
    out_msg(l_out);
    l_out := '-------------------------';
    out_msg(l_out);
    l_out := '| ' || RPAD('Identifiant du prélèvement', 26) || ' | ' ||
             RPAD('Numéro du prélèvement', 30) || ' | ' ||
             RPAD('Nom du Client', 50) || ' | ' || RPAD('Montant', 15) || ' |';
    out_msg(l_out);
    OPEN cur_avis_prelevement(vv_status);
    LOOP
      FETCH cur_avis_prelevement INTO rec_avis_prelevement;
      EXIT WHEN cur_avis_prelevement%NOTFOUND;
      l_out := '| ' || RPAD(rec_avis_prelevement.CASHRECEIPTID, 26) ||
               ' | ' || RPAD(rec_avis_prelevement.RECEIPT_REFERENCE, 30) ||
               ' | ' || RPAD(rec_avis_prelevement.CUSTOMER_NAME, 50) ||
               ' | ' || RPAD(rec_avis_prelevement.REMIT_AMOUNT, 15) || ' |';
      out_msg(l_out);
      l_out := chr(10) || chr(10) || l_ligne;
      out_msg(l_out);
    END LOOP;
    CLOSE cur_avis_prelevement;
    out_msg(l_ligne);
  
    g_step := 'EDITION_OUTPUT 999 : FIN';
    log_msg(g_step);
  
  EXCEPTION
    WHEN OTHERS THEN
      p_retcode := 2;
      p_errbuf  := 'Erreur procedure EDITION_OUTPUT :' || g_step || chr(10) ||
                   SQLERRM;
      log_msg(p_errbuf);
  END edition_output;

  ----------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : procédure principale
  --
  --
  --  PARAMETRES :
  --    p_errbuf     Entrée/Sortie   Message d'erreur
  --    p_retcode  Sortie      Code d'erreur
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
  ----------------------------------------------------------------------------

  PROCEDURE main(p_errbuf  IN OUT VARCHAR2, 
                 p_retcode    OUT NUMBER)
  IS
    
    
    
    CURSOR cur_avis_prelevement(pv_status VARCHAR2) IS
    SELECT distinct DST.CASHRECEIPTID,
                    DST.REMIT_REFERENCE,
                    DST.CUSTOMER_NAME,
                    DST.RECEIPT_REFERENCE,
                    DST.REMIT_AMOUNT,
                    DST.ORG_ID
    FROM DKA_SARAUTOPRELEV_TMP DST
    WHERE DST.STATUS = pv_status
    ORDER BY DST.CASHRECEIPTID;
  
    rec_avis_prelevement  cur_avis_prelevement%ROWTYPE;
    vn_request_id         NUMBER;
    vn_org_id             NUMBER := fnd_profile.value('ORG_ID');
    --vv_status            DKA_IEOAPSAT01_APIMP_HDR.STATUS%TYPE;
    vv_status             VARCHAR2(30);
    pv_errbuf             VARCHAR2(200);
    pn_retcode            NUMBER;
  
    e_main      EXCEPTION;
    e_boucle    EXCEPTION;
  
  BEGIN
    g_step := 'MAIN 000 : DEBUT';
    log_msg(g_step);
    
    -- Initialisation des variables d'envoi de mail :
    g_step := 'MAIN 001 : INITIALISATION DES VARIABLES.';
    log_msg(g_step);
    EXECUTE IMMEDIATE 'DELETE FROM DKA_SARPREL_ATTACH_TMP';
    vv_status := 'PRINT';
  
    OPEN cur_avis_prelevement(vv_status);
    LOOP
      FETCH cur_avis_prelevement INTO rec_avis_prelevement;
      EXIT WHEN cur_avis_prelevement%NOTFOUND;
      BEGIN
        pn_retcode := 0;
        g_step := 'MAIN 002 : LANCEMENT DU TRAITEMENT VE : Création du fichier avis de prelevement.';
        log_msg(g_step);
        lance_trait_pdf(rec_avis_prelevement.cashreceiptid,
                        rec_avis_prelevement.org_id,
                        gv_rarprel_pdf,
                        pv_errbuf,
                        pn_retcode);
      
        IF pn_retcode != 0 THEN
          g_step := 'MAIN 002 : ERREUR - ERREUR LORS DE L''EXECUTION DU TRAITEMENT VE : Création du fichier avis de prelevement.';
          RAISE e_boucle;
        END IF;
      EXCEPTION
        WHEN e_boucle THEN
          p_errbuf  := g_step;
          p_retcode := 1;
      END;
    END LOOP;
    CLOSE cur_avis_prelevement;
    -- Commit les informations présentent dans la table de travail DKA_SARPREL_ATTACH_TMP
    COMMIT;
    
    
    g_step := 'MAIN 003 : LANCEMENT DU TRAITEMENT VE : Rattachement de l''avis de prelevement au règlement AR.';
    log_msg(g_step);
    lance_trait(gv_sarprel_attach,
                pv_errbuf, 
                pn_retcode);
  
    g_step := 'MAIN 004 : EDITION FICHIER DE SORTIE.';
    log_msg(g_step);
  
    --procedure d'edition de la sortie
    edition_output(pv_errbuf, pn_retcode);
    IF pn_retcode != 0 THEN
      RAISE e_main;
    END IF;
    g_step := 'MAIN 999 - FIN.';
    log_msg(g_step);
  EXCEPTION
    WHEN e_main THEN
      p_errbuf := g_step || SQLERRM;
      log_msg(pv_errbuf);
      p_retcode := 2;
    WHEN OTHERS THEN
      p_errbuf := 'MAIN 999 - ERREUR : PROCEDURE MAIN ' || SQLERRM;
      log_msg(pv_errbuf);
      p_retcode := 2;
  END main;

END DKA_SARAVIPRELEV_PKG;
/
SHOW ERRORS 

EXIT
