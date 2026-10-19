create or replace 
PACKAGE BODY                                                                                                                                                                                                       DKA_IPO_SSTR_IVALUA_PKG                                                                                                                                                                                                                                                                                                                                                                                                                                                                                                
AS
--------------------------------------------------------------------------------
-- Capgemini
-- Projet           :
-- Nom              : DKA_IPO_SSTR_IVALUA_PKG.pks
-- Description      : interface entrante des contrat SSTR depuis ivalua vers Oracle
-- Auteur           : Kaltoum HANNACH
-- Date de création : 08/10/2024
-- Commentaires     :
--------------------------------------------------------------------------------
  g_package                 VARCHAR2(30)  := 'DKA_IPO_SSTR_IVALUA_PKG';
  g_sqlerrm                 VARCHAR2(500) := NULL;

  g_user                    NUMBER        := fnd_profile.value('USER_ID');
  g_request_id              NUMBER        := fnd_global.conc_request_id;
  g_request_loader          NUMBER;
  g_enreg_a_traite          NUMBER := 0;
  g_enreg_rejete            NUMBER := 0;
  g_enreg_succes            NUMBER := 0;
  g_statut_fin              VARCHAR2(50);
 -- g_tab_doublons            t_doublons;
  g_tab_erreurs             t_erreurs;
  g_doublons                NUMBER := 0;
  g_erreurs                 NUMBER := 0;
  g_File_Name               DKA_IPOCTR_SSTR_IVALUA.File_Name%Type;
/*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  /*============================================================================*/
Procedure Writeout(P_message IN VARCHAR2) IS
  L_procedure VARCHAR2(30) := 'writeout';
  v_etape   VARCHAR2(100);
BEGIN

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);

EXCEPTION
  WHEN OTHERS THEN
   
    G_sqlerrm := SUBSTR(SQLERRM, 1, 200);
    Fnd_File.put_line(Fnd_File.LOG,
    '-------------------- ERREUR --------------------');
    Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || G_package);
    Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || L_procedure);
    Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
    Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || v_etape);
    Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
END writeout;
  /*==============================================================================*/
  -- Procedure         : SORTIE_TRAITEMENT
  -- Description       : Procédure pour purger les tables de tarvail
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  /*=================================================================================*/
  PROCEDURE SORTIE_TRAITEMENT
  IS
    l_procedure                   VARCHAR2(30) := 'sortie_traitement';
    l_message                     VARCHAR2(2000);
    v_NUM_COMMANDE DKA_IPOCTR_SSTR_IVALUA.NUM_COMMANDE%TYPE;
    v_file_name DKA_IPOCTR_SSTR_IVALUA.file_name%TYPE;

    CURSOR cur_err_mess IS
    SELECT dih.NUM_CONTRAT,dih.VERSION_CONTRAT,dih.NUM_COMMANDE,dih.VERSION_COMMANDE,dih.file_name,dpm.source,dih.line_num,dpm.message_text,dih.RECORD_ID, dpm.column_name,dpm.Table_name
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCTR_SSTR_IVALUA    dih
    WHERE dpm.REQUEST_ID     = g_request_id
    --AND   dih.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCTR_SSTR_IVALUA'
    AND   dih.record_id  = dpm.table_id
  and dpm.message_type='E'
  and dih.statut = 'REJECTED'
   -- ORDER BY dih.NUM_COMMANDE
    ;
 
  BEGIN
    writeout('                                                                ');
    writeout('                                                                ');
    writeout('BILAN :');
    writeout('-------');
    writeout('                                                                ');
    writeout('NIVEAU Contrat SSTR IVALUA :');
    writeout('. Nombre d''enregistrements à traiter (nouveaux et rejets)          : '||g_enreg_a_traite);
    writeout('. Nombre d''enregistrements rejetés (phase validation)              : '||g_enreg_rejete );
    writeout('. Nombre d''enregistrements traités avec succès                     : '||g_enreg_succes  );
    writeout('                                                                          ');
    
    FOR rec_erreur IN cur_err_mess LOOP
    
    DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                      'DKA_IPO_SSTR_IVALUA', --prog_name
                                      'IPOCTR_SSTR_IVALUA',               --source
                                       'DKA_IPOCTR_SSTR_IVALUA', --'DKA_IPOCTR_SSTR_IVALUA' ,   --table_name
                                       rec_erreur.RECORD_ID,  --table_id
                                       rec_erreur.column_name,  --column_name
                                       NULL, -- rec_oi_err.Table_name,--'PO_HEADERS_INTERFACE', --column_value
                                       'E',                       --message_type
                                       rec_erreur.Table_name||' : '||rec_erreur.message_text                   --message_text
                                    );

      g_erreurs := g_erreurs + 1;
      
      g_tab_erreurs(g_erreurs).NUM_CONTRAT := rec_erreur.NUM_CONTRAT;
      g_tab_erreurs(g_erreurs).VERSION_CONTRAT  := rec_erreur.VERSION_CONTRAT;
      g_tab_erreurs(g_erreurs).NUM_COMMANDE        := rec_erreur.NUM_COMMANDE;
      g_tab_erreurs(g_erreurs).VERSION_COMMANDE  := rec_erreur.VERSION_COMMANDE;
      g_tab_erreurs(g_erreurs).file_name        := rec_erreur.file_name;
      g_tab_erreurs(g_erreurs).line_num         := rec_erreur.line_num;
      g_tab_erreurs(g_erreurs).source           := rec_erreur.source;
      g_tab_erreurs(g_erreurs).ivalua_line_id   := rec_erreur.RECORD_ID;
      g_tab_erreurs(g_erreurs).message_text     := rec_erreur.message_text;
    END LOOP;
    writeout( 'Liste des rejets de validation :');
    writeout( '---------------------');
    IF g_tab_erreurs.count > 0 THEN

     FOR i IN g_tab_erreurs.first..g_tab_erreurs.last LOOP
        l_message := 'Contrat n° ' ||g_tab_erreurs(i).NUM_CONTRAT ||' / RECORD_ID '||g_tab_erreurs(i).ivalua_line_id ||' : ';

        writeout(l_message || g_tab_erreurs(i).message_text);
       
      END LOOP;
    ELSE
      writeout('Aucun contrant en erreur');
    END IF;

    writeout('                                                                          ');
    writeout('                                                                          ');
    EXCEPTION
    WHEN OTHERS THEN
      --pn_retcode   := 2;
      --pv_errbuf    := 'SORTIE_TRAITEMENT : ' ||SQLERRM;
     -- DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure SORTIE_TRAITEMENT : '||SQLERRM);
  END SORTIE_TRAITEMENT;


   /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie IS

  l_procedure                  VARCHAR2(30) := 'E';
  l_message                    VARCHAR2(2000);

  BEGIN
    writeout('+-------------------------------------------------------------------------+');
    writeout('COMPTE-RENDU DU TRAITEMENT «DKA : Import des contrats SSTR depuis iValua»');
    writeout('Traitement n° : '||g_request_id);
    writeout('Programme lancé le : '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
   
  END entete_de_sortie;
  /*============================================================================*/
  /* Fonction          : fin_de_sortie                                      */
  /* Description       : fin de la sortie                 */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE fin_de_sortie IS

  l_procedure                   VARCHAR2(30) := 'fin_de_sortie';
  l_message                    VARCHAR2(2000);

  BEGIN
    writeout('');
    writeout('');

    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('Programme terminé le : '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
    writeout('                                                                           ');
    writeout('+-------------------------------------------------------------------------+');
  END fin_de_sortie;

  /*==============================================================================*/
  -- Procedure         : UPDATE_RECORD
  -- Description       : Procédure pour MAJ les tables de tarvail après chargement
  -- Parametres entree : p_request_id ( id traitement chargement ( DKA_IPOCDEIVALUA_LOADER)
  -- Parametres sortie : AUCUN

/*=================================================================================*/
PROCEDURE UPDATE_RECORD (pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         p_request_id IN NUMBER )IS

  l_message                     VARCHAR2(2000);
  BEGIN

  ----- Insertion table reporting les nv enregistrements 
  Begin
  Insert into DKA_IPOCTR_SSTR_IVALUA_REPORT (
                                              NUM_CONTRAT	             
                                            ,VERSION_CONTRAT	            
                                            ,DATE_DEBUT_PERIODE	           
                                            ,DATE_FIN_PERIODE	            
                                            ,NUM_COMMANDE	                 
                                            ,VERSION_COMMANDE	          
                                            ,MONTANT_CONTRAT                
                                            ,DATE_RESILIATION	             
                                            ,CREATION_DATE                 
                                            ,CREATED_BY                      
                                            ,LAST_UPDATE_DATE                
                                            ,LAST_UPDATED_BY                      
                                            ,STATUT	                                 
                                            ,FILE_NAME	                       
                                            ,LINE_NUM	                   
                                            ,RECORD_ID	                     
                                            ,LOADER_REQUEST_ID	
                                            ,request_Id)            
                                        select NUM_CONTRAT	             
                                              ,VERSION_CONTRAT	            
                                              ,DATE_DEBUT_PERIODE	           
                                              ,DATE_FIN_PERIODE	            
                                              ,NUM_COMMANDE	                 
                                              ,VERSION_COMMANDE	          
                                              ,MONTANT_CONTRAT                
                                              ,DATE_RESILIATION	             
                                              ,CREATION_DATE                 
                                              ,CREATED_BY                      
                                              ,LAST_UPDATE_DATE                
                                              ,LAST_UPDATED_BY                      
                                              ,STATUT	                                 
                                              ,FILE_NAME	                       
                                              ,LINE_NUM	                   
                                              ,RECORD_ID	                     
                                              ,LOADER_REQUEST_ID 
                                              ,g_Request_Id
                                        FROM DKA_IPOCTR_SSTR_IVALUA
                                       WHERE LOADER_REQUEST_ID = p_request_id;
        EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_004');
      DKA_TOOLS_PKG.put_log_message(l_message);
    End;  
  
  ----- Insertion table historique les nv enregistrements 
  Begin
  Insert into DKA_IPOCTR_SSTR_IVALUA_HIST (
                                              NUM_CONTRAT	             
                                            ,VERSION_CONTRAT	            
                                            ,DATE_DEBUT_PERIODE	           
                                            ,DATE_FIN_PERIODE	            
                                            ,NUM_COMMANDE	                 
                                            ,VERSION_COMMANDE	          
                                            ,MONTANT_CONTRAT                
                                            ,DATE_RESILIATION	             
                                            ,CREATION_DATE                 
                                            ,CREATED_BY                      
                                            ,LAST_UPDATE_DATE                
                                            ,LAST_UPDATED_BY                      
                                            ,STATUT	                                 
                                            ,FILE_NAME	                       
                                            ,LINE_NUM	                   
                                            ,RECORD_ID	                     
                                            ,LOADER_REQUEST_ID
                                            ,request_Id)            
                                        select NUM_CONTRAT	             
                                              ,VERSION_CONTRAT	            
                                              ,DATE_DEBUT_PERIODE	           
                                              ,DATE_FIN_PERIODE	            
                                              ,NUM_COMMANDE	                 
                                              ,VERSION_COMMANDE	          
                                              ,MONTANT_CONTRAT                
                                              ,DATE_RESILIATION	             
                                              ,CREATION_DATE                 
                                              ,CREATED_BY                      
                                              ,LAST_UPDATE_DATE                
                                              ,LAST_UPDATED_BY                      
                                              ,STATUT	                                 
                                              ,FILE_NAME	                       
                                              ,LINE_NUM	                   
                                              ,RECORD_ID	                     
                                              ,LOADER_REQUEST_ID 
                                              ,g_Request_id
                                        FROM DKA_IPOCTR_SSTR_IVALUA
                                       WHERE LOADER_REQUEST_ID = p_request_id;
        EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_003');
      DKA_TOOLS_PKG.put_log_message(l_message);
    End;  
  Commit;
     EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'UPDATE_RECORD : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure UPDATE_RECORD : EXCEPTION OTHERS :'||SQLERRM);
 
  END UPDATE_RECORD;
  /*==============================================================================*/
  -- Procedure         : LANCE_CHARGEMENT_FICHIER
  -- Description       : Procédure pour lancer le cahrgement des tables de tarvail
  -- Parametres entree : AUCUN
  -- Parametres sortie : AUCUN
  /*=================================================================================*/
PROCEDURE LANCE_CHARGEMENT_FICHIER  (pv_errbuf  IN OUT VARCHAR2,
                                     pn_retcode OUT NUMBER
                                      ) IS

  l_procedure                   VARCHAR2(30) := 'LANCE_CHARGEMENT_FICHIER';
  l_message                     VARCHAR2(2000);
  l_request_id                  NUMBER;
  l_application_code            VARCHAR2(50) := 'DKA';
  l_conc_program                VARCHAR2(50) := 'DKA_IPOCTR_SSTR_IVALUA_LOADER';
  l_execute_code                BOOLEAN;
  l_req_interval                NUMBER := 30;
  l_req_max_wait                NUMBER := 999999;
  l_req_phase                   VARCHAR2(255);
  l_req_status                  VARCHAR2(255);
  l_req_dev_phase               VARCHAR2(255);
  l_req_dev_status              VARCHAR2(255);
  l_status                      VARCHAR2(255);
  l_req_message                 VARCHAR2(255);
  vf_errbuf                     VARCHAR2(500);
  vf_retcode                    NUMBER;
  vb_state                       BOOLEAN;
  BEGIN
    l_message := l_procedure || '- 01 - Debut';
    Fnd_File.put_line(Fnd_File.LOG, l_message);

    l_message := l_procedure || '- 02 - Submit Request';
    Fnd_File.put_line(Fnd_File.LOG, l_message);

    DBMS_OUTPUT.put_line ('Ajout du param');
    vb_state := FND_REQUEST.SET_OPTIONS(numeric_characters=>'.,');

    l_request_id := FND_REQUEST.submit_request(l_application_code,
                                                l_conc_program,
                                                '',
                                                SYSDATE,
                                                FALSE
                                                );


    COMMIT;
    IF l_request_id != 0 THEN
        l_message := l_procedure||' - 03 - Attente fin traitement';
        DKA_TOOLS_PKG.put_log_message(l_message);
        l_execute_code := FND_CONCURRENT.WAIT_FOR_REQUEST( REQUEST_ID => l_request_id
                                                         , INTERVAL   => l_req_interval
                                                         , MAX_WAIT   => l_req_max_wait
                                                         , PHASE      => l_req_phase
                                                         , STATUS     => l_req_status
                                                         , DEV_PHASE  => l_req_dev_phase
                                                         , DEV_STATUS => l_req_dev_status
                                                         , MESSAGE    => l_req_message
                                                         );

        IF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'WARNING' THEN
        l_status := 'Avertissement';
            l_message := l_procedure||' - 04a - Traitement terminé en avertissement';
            DKA_TOOLS_PKG.put_log_message(l_message);
            pn_retcode := 1;
        ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
        l_status := 'Erreur';
            l_message := l_procedure||' - 04b - Traitement terminé en erreur';
            DKA_TOOLS_PKG.put_log_message(l_message);
            pn_retcode := 2;
        ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
        l_status := 'Normal';
            l_message := l_procedure||' - 04b - Traitement terminé normal';
            DKA_TOOLS_PKG.put_log_message(l_message);
            Fnd_File.put_line(Fnd_File.LOG, l_message);
            pn_retcode := 0;
            g_request_loader :=l_request_id;
      -- Vérification de l'unicité des données/MAJ du champ RECORD_ID:
            UPDATE_RECORD(vf_errbuf ,
                          vf_retcode ,
                          l_request_id)
                             ;
            IF vf_retcode = 2 THEN
              pn_retcode := 2 ;
            END IF;

        END IF;
    ELSE
        l_message := l_procedure||' - 03 - Erreur lors du lancement du traitement';
        DKA_TOOLS_PKG.put_log_message(l_message);
        DBMS_OUTPUT.PUT_LINE(l_message);
        pn_retcode := 2;

    END IF;
COMMIT;
    writeout('CHARGEMENT DU FICHIER :');
    writeout('-----------------------');
    writeout('. Numéro du traitement de chargement du fichier : '||l_request_id);
    writeout('. Statut de fin : Terminé/'||l_status);
    writeout('                                                                           ');
    writeout('                                                                           ');
   /* IF g_tab_doublons.count > 0 THEN
    ---Annulation du chargement car l'unicité des contrats par fichier n'est pas respectée.
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTRSSTR_003');
    pn_retcode := 2; 
      writeout(l_message);
      writeout('                                                    ');
      writeout('                                                    ');
      l_message := 'LA LISTES DES DOUBLONS:';
      writeout(l_message);
      writeout('-------------------------');
      writeout( RPAD('N° contrat',35)||RPAD('N° verion contrat',35)||RPAD('N° commande',35)||RPAD('N° verion commande',35)||RPAD('id ligne IVALUA ',35)||RPAD('Table ',50));
      writeout( RPAD('-----------',35)||RPAD('-----------',35)||RPAD('-----------',35)||RPAD('-----------',35)||RPAD('----------------',35)||RPAD('----------------',50));
      FOR i IN g_tab_doublons.first..g_tab_doublons.last LOOP
        l_message := RPAD(g_tab_doublons(i).NUM_CONTRAT,35)||RPAD(g_tab_doublons(i).VERSION_CONTRAT,35)|| RPAD(g_tab_doublons(i).NUM_COMMANDE,35)||RPAD(g_tab_doublons(i).VERSION_COMMANDE,35)||RPAD(g_tab_doublons(i).ivalua_line_id,35)||RPAD(g_tab_doublons(i).nom_table,50);
        writeout(l_message);
      END LOOP;
      writeout('                                                    ');
      writeout('                                                    ');
    END IF;
    */
   EXCEPTION
    WHEN OTHERS THEN
   --   pn_retcode   := 2;
      pv_errbuf    := 'LANCE_CHARGEMENT_FICHIER : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure LANCE_CHARGEMENT_FICHIER : EXCEPTION OTHERS '||SQLERRM);
 
END LANCE_CHARGEMENT_FICHIER;
  /*============================================================================*/
 -- Procedure         : PURGE_DONNEE_TRAITEE
 -- Description       : préparer les donneés de la table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 /*===============================================================================*/
PROCEDURE PURGE_DONNEE_TRAITEE(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='PURGE_DONNEE_TRAITEE';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;

  BEGIN
    DKA_TOOLS_PKG.put_log_message('Purge des enregistrements précédemment traités avec succès par l''interface des tables spécifiques');
    DELETE FROM DKA_IPOCTR_SSTR_IVALUA  WHERE STATUT in ( 'COMPLETE');

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      v_message := 'ERROR lors de la préparation des données'||SQLERRM ;
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'PURGE_DONNEE_TRAITEE'
                                     , NULL
                                     , NULL
                                     , NULL
                                     , NULL
                                     ,'E'
                                     ,v_message
                                    );
  END PURGE_DONNEE_TRAITEE ;
  /*============================================================================*/
 -- Procedure         : PREPARATION_DONNEE
 -- Description       : préparer les donneés de la table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 /*===============================================================================*/
PROCEDURE PREPARATION_DONNEE(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='PREPARATION_DONNEE';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;
  v_po_a_recycler        Number; 


  CURSOR donnee_a_recycler IS
  SELECT *
  FROM DKA_IPOCTR_SSTR_IVALUA
  WHERE STATUT NOT IN ('NEW','COMPLETE');
  v_CTR_a_recycler  DKA_IPOCTR_SSTR_IVALUA.NUM_CONTRAT%type;
  v_VCTR_a_recycler  DKA_IPOCTR_SSTR_IVALUA.VERSION_CONTRAT%type;
  

  BEGIN
    DKA_TOOLS_PKG.put_log_message('Recyclage des enregistrements remplacés par une nouvelle version');
    FOR rec_a_recycler IN donnee_a_recycler
    LOOP
      BEGIN
        Select RECORD_ID
        INTO   v_po_a_recycler
        From DKA_IPOCTR_SSTR_IVALUA
        Where NUM_CONTRAT = rec_a_recycler.NUM_CONTRAT
        And  VERSION_CONTRAT = rec_a_recycler.VERSION_CONTRAT
        And  NUM_COMMANDE =  rec_a_recycler.NUM_COMMANDE
        And  VERSION_COMMANDE = rec_a_recycler.VERSION_COMMANDE
        AND   STATUT = 'NEW';
      EXCEPTION
        WHEN OTHERS THEN
          v_po_a_recycler:= NULL;
      END;
      IF v_po_a_recycler IS NOT NULL
      THEN

        UPDATE DKA_IPOCTR_SSTR_IVALUA_REPORT
        SET STATUT ='DELETED'
        ,   LAST_UPDATE_DATE  = SYSDATE
        ,   LAST_UPDATED_BY    = g_user
        WHERE NUM_CONTRAT = rec_a_recycler.NUM_CONTRAT
         And  VERSION_CONTRAT = rec_a_recycler.VERSION_CONTRAT
         And RECORD_ID = rec_a_recycler.RECORD_ID ;


        
        DELETE FROM DKA_IPOCTR_SSTR_IVALUA
        WHERE NUM_CONTRAT = rec_a_recycler.NUM_CONTRAT
         And  VERSION_CONTRAT = rec_a_recycler.VERSION_CONTRAT
         AND RECORD_ID = rec_a_recycler.RECORD_ID 
         AND   STATUT != 'NEW';


       END IF;

    END LOOP;


    DKA_TOOLS_PKG.put_log_message('Nettoyage liées aux enregistrements en erreur');
    DELETE FROM DKA_PROGRAM_MESSAGES
    WHERE PROG_NAME  = 'DKA_IPOCTR_SSTR_IVALUA'
    AND   request_id != g_request_id;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      v_message := 'ERROR lors de la préparation des données'||SQLERRM ;
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'PREPARATION_DONNEE'
                                     , NULL
                                     , NULL
                                     , NULL
                                     , NULL
                                     ,'E'
                                     ,v_message
                                    );

  END PREPARATION_DONNEE;
 /*============================================================================*/
 -- Procedure         : MAJ_DONNEE_ATRAITEE
 -- Description       :
 -- Parametres entree :
 -- Parametres sortie : AUCUN
/*===============================================================================*/
  PROCEDURE MAJ_DONNEE_ATRAITEE(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='MAJ_DONNEE_ATRAITEE';

  BEGIN
    SELECT COUNT(*)
    INTO   g_enreg_a_traite
    FROM   DKA_IPOCTR_SSTR_IVALUA;

    UPDATE DKA_IPOCTR_SSTR_IVALUA
    SET    request_id = g_request_id;

EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'MAJ_DONNEE_ATRAITEE : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure MAJ_DONNEE_ATRAITEE : EXCEPTION OTHERS '||SQLERRM);

  END MAJ_DONNEE_ATRAITEE;


  /*============================================================================*/
 -- Procedure         : DETERMINATION_ACTION
 -- Description       : déterminer les action à effectuer sur chaque donnee de la
 --                     table de travail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
/*===============================================================================*/
PROCEDURE DETERMINATION_ACTION(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

 v_procedure            VARCHAR2(30):='DETERMINATION_ACTION';
 v_etape                VARCHAR2(500);
 v_message              VARCHAR2(500) := null;



  BEGIN
    v_etape := 'Mise à jour enregistrement contart par l''action à metre en place Update ou Create';
    DKA_TOOLS_PKG.put_log_message(v_etape);

  --CREATION Contrat
    UPDATE DKA_IPOCTR_SSTR_IVALUA disit
    SET ACTION = 'CREATE'
    ,   LAST_UPDATE_DATE  = SYSDATE
    ,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
    Where  Not exists ( Select 1
                       From DKA_SPO_CONTRAT_SSTR_IVALUA disi
                      Where disit.NUM_CONTRAT = disi.NUM_CONTRAT
                        And disit.VERSION_CONTRAT  = disi.VERSION_CONTRAT
                        And disit.NUM_COMMANDE        = disi.NUM_COMMANDE
                        And disit.VERSION_COMMANDE = disi.VERSION_COMMANDE
                    ) 
         ;
  --MISE A JOUR Action enrg Contrat
    UPDATE DKA_IPOCTR_SSTR_IVALUA disit
    SET  ACTION = 'UPDATE'
    ,   LAST_UPDATE_DATE  = SYSDATE
    ,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
    WHERE 
       Exists ( Select 1
                       From DKA_SPO_CONTRAT_SSTR_IVALUA disi
                      Where disit.NUM_CONTRAT = disi.NUM_CONTRAT
                        And disit.VERSION_CONTRAT  = disi.VERSION_CONTRAT
                        And disit.NUM_COMMANDE        = disi.NUM_COMMANDE
                        And disit.VERSION_COMMANDE = disi.VERSION_COMMANDE
                    );
EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'DETERMINATION_ACTION : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure DETERMINATION_ACTION : EXCEPTION OTHERS '||SQLERRM);

     END DETERMINATION_ACTION;
  /*============================================================================*/
 -- Procedure         : VALIDATION_DONNEES
 -- Description       : valider les données de la table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
/*===============================================================================*/
PROCEDURE VALIDATION_DONNEES(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

  CURSOR C_DONNEE IS
  SELECT * FROM DKA_IPOCTR_SSTR_IVALUA
          WHERE STATUT IN ('NEW','REJECTED')
  FOR UPDATE;
  v_procedure             VARCHAR2(30):='VALIDATION_DONNEES';
  v_etape                 VARCHAR2(500);
  v_message               VARCHAR2(500) := null;
  l_message               VARCHAR2(2000);
  v_exist_po              Number; 
  v_Org_Id                Number;
  v_po_header_Id          Number;
  v_flag_erreur_ctr       BOOLEAN;

 



BEGIN
---- Contrôle d'obligation
    FOR rec_donnee IN C_DONNEE  LOOP
     -- g_enreg_a_traite_entete := g_enreg_a_traite_entete + 1;
      v_flag_erreur_ctr := FALSE;
      v_etape:= 'N° du contrat SSTR';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      DKA_TOOLS_PKG.put_log_message('debut boucle contrat n°:'
      ||rec_donnee.NUM_CONTRAT ||' et numéro de verion '|| rec_donnee.VERSION_CONTRAT);


    v_etape:= 'Contrôle N° du contrat SSTR';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.NUM_CONTRAT IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT01');
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'NUM_CONTRAT' --pv_column_name
                                     ,rec_donnee.NUM_CONTRAT --pv_column_val
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;
    v_etape:= 'Contrôle N° de renouvellement du contrat SSTR';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.VERSION_CONTRAT IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT02');
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'VERSION_CONTRAT' --pv_column_name
                                     ,rec_donnee.VERSION_CONTRAT --pv_column_val
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;
    v_etape:= 'Contrôle Date de début de la période contrat SSTR';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.DATE_DEBUT_PERIODE IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT03');
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'DATE_DEBUT_PERIODE' --pv_column_name
                                     ,rec_donnee.DATE_DEBUT_PERIODE --pv_column_val
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;
    v_etape:= 'Contrôle Date de fin de la période contrat SSTR';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.Date_Fin_Periode IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT04');
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'Date_Fin_Periode' --pv_column_name
                                     ,rec_donnee.Date_Fin_Periode --pv_column_val
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;

    v_etape:= 'Contrôle Numéro de commande SSTR pour la période';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.NUM_COMMANDE IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT05','DATE_DEBUT_PERIODE',rec_donnee.DATE_DEBUT_PERIODE,'DATE_FIN_PERIODE',rec_donnee.Date_Fin_Periode);

      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'NUM_COMMANDE' --pv_column_name
                                     ,rec_donnee.NUM_COMMANDE --pv_column_value
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;
    v_etape:= 'Contrôle N° de version de la commande SST';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.VERSION_COMMANDE IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT06');
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'VERSION_COMMANDE' --pv_column_name
                                     ,rec_donnee.VERSION_COMMANDE --pv_column_value
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;
    
       v_etape:= 'Contrôle Montant du contrat pour la période ';
    DKA_TOOLS_PKG.put_log_message(v_etape);

    IF rec_donnee.MONTANT_CONTRAT IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT07');
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'MONTANT_CONTRAT' --pv_column_name
                                     ,rec_donnee.MONTANT_CONTRAT --pv_column_value
                                     ,'E'
                                     ,l_message
                                 );
      DKA_TOOLS_PKG.put_log_message(l_message);
      v_flag_erreur_ctr := TRUE;
    END IF;

----- Contrôle de coherence de données dans le systeme oracle 
    v_etape:= 'Contrôle de l''existence du numéro de commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    BEGIN
      SELECT  po_header_Id , Org_Id
      INTO   v_po_header_Id, v_org_Id
      FROM   Po_Headers_All pha
      WHERE  pha.Segment1 = rec_donnee.NUM_COMMANDE ;
      
      SELECT  count(*)
      INTO   v_exist_po
      FROM   Po_Headers_All pha
      WHERE  pha.Segment1 = rec_donnee.NUM_COMMANDE ;
      
      
     Exception when No_Data_Found Then
       v_po_header_Id := null;
	   v_exist_po := 0;
     
    END ;
    IF v_exist_po = 0  and rec_donnee.NUM_COMMANDE is not null THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCTR_SSTR_VT08','NUM_COMMANDE',rec_donnee.NUM_COMMANDE);
        
        DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCTR_SSTR_IVALUA'
                                     , rec_donnee.record_id
                                     ,'NUM_COMMANDE' --pv_column_name
                                     ,rec_donnee.NUM_COMMANDE --pv_column_value
                                     ,'E'
                                     ,l_message
                                      );
        DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_ctr := TRUE;
    END IF ;

    --Mise à jour des tables après validation
    IF NOT v_flag_erreur_ctr THEN
      --MAJ de la table de travail
      UPDATE  DKA_IPOCTR_SSTR_IVALUA
      SET STATUT = 'VALIDATED'
      ,   request_id     = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
      ,   LAST_UPDATED_BY    = g_user
      ,    Org_Id = v_Org_Id
      ,  Commande_Id =  v_po_header_Id
     
      WHERE CURRENT OF c_donnee;

    ELSE
      DKA_TOOLS_PKG.put_log_message('Erreur :');
      
      --MAJ de la table de travail
      UPDATE DKA_IPOCTR_SSTR_IVALUA
      SET STATUT ='REJECTED'
      ,   request_id = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
      ,   LAST_UPDATED_BY    = g_user
      WHERE CURRENT OF C_DONNEE;

  END IF;




  END LOOP; -- end loop C_DONNEE_ENTETE

  COMMIT;
EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'VALIDATION_DONNEES : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure VALIDATION_DONNEES : EXCEPTION OTHERS ');

END VALIDATION_DONNEES;

/*======================================================================================================*/
  --  Nom           : IMPORT_DONNEES
  --  Description   : Procédure d'import des données dans les table spcifique des contrat SSTR DKA_SPO_CONTRAT_SSTR_IVALUA
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur
/*=========================================================================================================*/
  PROCEDURE IMPORT_DONNEES(pv_errbuf        OUT VARCHAR2,
                           pn_retcode       OUT NUMBER
                          )
  IS
  CURSOR C_CTR_ACREER IS
  SELECT DIH.*
  FROM DKA_IPOCTR_SSTR_IVALUA DIH
  WHERE   dih.ACTION in ( 'CREATE')
  AND   dih.statut IN ('VALIDATED')
  order by NUM_CONTRAT, VERSION_CONTRAT, NUM_COMMANDE, VERSION_COMMANDE 
  For Update;
 

  CURSOR C_CTR_AMAJ IS
  SELECT DIH.*
  FROM DKA_IPOCTR_SSTR_IVALUA DIH
  WHERE dih.ACTION = 'UPDATE'
  AND   dih.statut IN ('VALIDATED')

  FOR UPDATE;

  V_DKA_SPO_CONTRAT_SSTR_IVALUA_ID NUMBER;

  v_procedure              VARCHAR2(30):='IMPORT_DONNEES';
  v_etape                  VARCHAR2(500);
  v_Po_Header_Id           Number;
  v_Org_Id                 Number;
 

  BEGIN
    v_etape := 'Insertion dans la table DKA_SPO_CONTRAT_SSTR_IVALUA';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    FOR REC_CTR_ACREER IN C_CTR_ACREER  LOOP
      DKA_TOOLS_PKG.put_log_message('Initialiser la séquence utilisé pour le champ numéro de la ligne');
    ---  INIT_SEQUENCE;
      DKA_TOOLS_PKG.put_log_message('contrat à importer: '||REC_CTR_ACREER.NUM_CONTRAT ||' Version Contrat: '||REC_CTR_ACREER.VERSION_CONTRAT||' Num Commande: '||REC_CTR_ACREER.VERSION_COMMANDE||' Num verion Commande:'||REC_CTR_ACREER.VERSION_COMMANDE);
      SELECT DKA_SPO_CONTRAT_SSTR_IVALUA_S.NEXTVAL
      INTO   V_DKA_SPO_CONTRAT_SSTR_IVALUA_ID
      FROM DUAL;
      ---- Recuperation Id Commande et Org_Id
      Begin
      Select Po_Header_Id , Org_Id  into v_Po_Header_Id , v_Org_Id from Po_Headers_All where Segment1 = REC_CTR_ACREER.NUM_COMMANDE;
      Exception when Others then
       DKA_TOOLS_PKG.put_log_message('Proplème pour detrrmier l''id de la commande pour les numeéro '||REC_CTR_ACREER.NUM_COMMANDE ||' Dans la table po_headers_all');
      End;
      
      DKA_TOOLS_PKG.put_log_message('V_DKA_SPO_CONTRAT_SSTR_IVALUA_ID: '||V_DKA_SPO_CONTRAT_SSTR_IVALUA_ID);
      INSERT INTO DKA_SPO_CONTRAT_SSTR_IVALUA
        (  ID_CONTRAT
          , NUM_CONTRAT
          ,VERSION_CONTRAT
          ,DATE_DEBUT_PERIODE
          ,Date_Fin_Periode
          ,Id_Commande
          ,NUM_COMMANDE
          ,VERSION_COMMANDE
          ,MONTANT_CONTRAT
          ,DATE_RESILIATION
          ,CREATION_DATE
          ,CREATED_BY 
          ,LAST_UPDATE_DATE
          ,LAST_UPDATED_BY
          ,Org_Id
         
        )
        VALUES
       (  V_DKA_SPO_CONTRAT_SSTR_IVALUA_ID
          ,REC_CTR_ACREER.NUM_CONTRAT
          ,REC_CTR_ACREER.VERSION_CONTRAT
          ,REC_CTR_ACREER.DATE_DEBUT_PERIODE
          ,REC_CTR_ACREER.Date_Fin_Periode
          ,v_Po_Header_Id
          ,REC_CTR_ACREER.NUM_COMMANDE
          ,REC_CTR_ACREER.VERSION_COMMANDE
          ,REC_CTR_ACREER.MONTANT_CONTRAT
          ,REC_CTR_ACREER.DATE_RESILIATION
          ,REC_CTR_ACREER.CREATION_DATE
          ,REC_CTR_ACREER.CREATED_BY 
          ,REC_CTR_ACREER.LAST_UPDATE_DATE
          ,REC_CTR_ACREER.LAST_UPDATED_BY
          ,v_Org_Id
        );

     begin
        DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_IPOCTR_SSTR_IVALUA');
        UPDATE DKA_IPOCTR_SSTR_IVALUA
        SET STATUT   ='COMPLETE' 
        WHERE NUM_CONTRAT = REC_CTR_ACREER.NUM_CONTRAT
          And VERSION_CONTRAT=  REC_CTR_ACREER.VERSION_CONTRAT 
          And NUM_COMMANDE= REC_CTR_ACREER.NUM_COMMANDE
          And VERSION_COMMANDE = REC_CTR_ACREER.VERSION_COMMANDE;

      exception when others then
          DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_IPOCTR_SSTR_IVALUA a échoué');
      end;

    END LOOP; --FIN LOOP C_CMD_ACREER
   ------ mise à jour  contrat
   FOR REC_CTR_AMAJ IN C_CTR_AMAJ  LOOP
   
   Begin
   UPDATE DKA_SPO_CONTRAT_SSTR_IVALUA
      SET 
          DATE_DEBUT_PERIODE      = REC_CTR_AMAJ.DATE_DEBUT_PERIODE
          ,Date_Fin_Periode      = REC_CTR_AMAJ.Date_Fin_Periode
          ,MONTANT_CONTRAT  = REC_CTR_AMAJ.MONTANT_CONTRAT
          ,DATE_RESILIATION  = REC_CTR_AMAJ.DATE_RESILIATION
          ,CREATION_DATE         = REC_CTR_AMAJ.CREATION_DATE
          ,CREATED_BY            = REC_CTR_AMAJ.CREATED_BY 
          ,LAST_UPDATE_DATE      = REC_CTR_AMAJ.LAST_UPDATE_DATE
          ,LAST_UPDATED_BY       = REC_CTR_AMAJ.LAST_UPDATED_BY
     
      
        
     WHERE NUM_CONTRAT = REC_CTR_AMAJ.NUM_CONTRAT
          And VERSION_CONTRAT=  REC_CTR_AMAJ.VERSION_CONTRAT 
          And NUM_COMMANDE= REC_CTR_AMAJ.NUM_COMMANDE
          And VERSION_COMMANDE = REC_CTR_AMAJ.VERSION_COMMANDE;
   

    exception when others then
          DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_SPO_CONTRAT_SSTR_IVALUA a échoué');
      end;
      
       begin
        DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_IPOCTR_SSTR_IVALUA');
        UPDATE DKA_IPOCTR_SSTR_IVALUA
        SET STATUT   ='COMPLETE' 
        WHERE NUM_CONTRAT = REC_CTR_AMAJ.NUM_CONTRAT
          And VERSION_CONTRAT=  REC_CTR_AMAJ.VERSION_CONTRAT 
          And NUM_COMMANDE= REC_CTR_AMAJ.NUM_COMMANDE
          And VERSION_COMMANDE = REC_CTR_AMAJ.VERSION_COMMANDE;

      exception when others then
          DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_IPOCTR_SSTR_IVALUA a échoué');
      end;

      
 END LOOP; --FIN LOOP C_CTR_AMAJ
  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'IMPORT_DONNEES : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure IMPORT_DONNEES : EXCEPTION OTHERS ');

  END IMPORT_DONNEES;


 
  /*============================================================================*/
 -- Procedure         : ENREGISTREMENT_COMPTEUR
 -- Description       :
 -- Parametres entree :
 -- Parametres sortie : AUCUN

/*===============================================================================*/
  PROCEDURE ENREGISTREMENT_COMPTEUR(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS
  BEGIN
    SELECT COUNT(*)
    INTO   g_enreg_succes
    FROM   DKA_IPOCTR_SSTR_IVALUA
    WHERE  STATUT = 'COMPLETE'
    AND    request_id = g_request_id;

 

    SELECT COUNT(*)
    INTO   g_enreg_rejete
    FROM   DKA_IPOCTR_SSTR_IVALUA
    WHERE  STATUT = 'REJECTED'
    AND    request_id = g_request_id;
EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'ENREGISTREMENT_COMPTEUR : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure ENREGISTREMENT_COMPTEUR : EXCEPTION OTHERS ');

  END;
   /*==============================================================================*/
  -- Procedure         : UPDATE_RECORD2
  -- Description       : Procédure pour MAJ les tables de tarvail à la fin de traitement
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
/*=================================================================================*/
  PROCEDURE UPDATE_RECORD2 (pv_errbuf  IN OUT VARCHAR2
                            ,pn_retcode OUT NUMBER
                            ,p_request_id IN NUMBER 
                          )IS
                           
  cursor cur_crt IS ( Select * From DKA_SPO_CONTRAT_SSTR_IVALUA );
  Cursor cur_crt1 Is ( Select * From  DKA_IPOCTR_SSTR_IVALUA Where Request_Id = p_Request_Id);

  BEGIN
  FOR rec_crt in cur_crt LOOP
  
    update DKA_IPOCTR_SSTR_IVALUA_REPORT
    set
    DKA_SPO_CONTRAT_SSTR_IVALUA_Id  = rec_crt.ID_Contrat    
    ,Org_Id = rec_crt.org_Id 
    ,COMMANDE_ID = rec_crt.ID_COMMANDE      
    ,LAST_UPDATE_DATE = SYSDATE                
    ,LAST_UPDATED_BY            = g_user
    WHERE  NUM_CONTRAT =rec_crt.NUM_CONTRAT
    And VERSION_CONTRAT =rec_crt.VERSION_CONTRAT
    And NUM_COMMANDE = rec_crt.NUM_COMMANDE
    And VERSION_COMMANDE = rec_crt.VERSION_COMMANDE;

  END LOOP;
  Commit;
  FOR rec_crt1 in cur_crt1 LOOP
   update DKA_IPOCTR_SSTR_IVALUA_REPORT
    set
     STATUT                = rec_crt1.STATUT         
    ,Action              = rec_crt1.Action   
    ,LAST_UPDATE_DATE = SYSDATE                
    ,LAST_UPDATED_BY            = g_user
    WHERE record_Id            = rec_crt1.Record_id;
   End Loop;  
  
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'UPDATE_RECORD2 : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure UPDATE_RECORD2 : EXCEPTION OTHERS ');


  END UPDATE_RECORD2;
  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
/*=========================================================================================================*/
PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
               pn_retcode OUT NUMBER,
               p_recyclage IN VARCHAR2) IS
  v_phase                VARCHAR2(500);
  v_etape                VARCHAR2(500);
  vf_errbuf              VARCHAR2(500);
  vf_retcode             NUMBER;
  v_responsibility_id        NUMBER;
  v_application_id           NUMBER;
BEGIN
  pn_retcode := 0;
  v_phase := 'PHASE Préliminaire';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  entete_de_sortie;
  PURGE_DONNEE_TRAITEE(vf_errbuf ,
                      vf_retcode );
  IF  vf_retcode = 1  THEN
       pn_retcode := 1;
  END IF ;

  v_phase := 'PHASE  INITIALISATION DES VARIABLES';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  --init (vf_errbuf, vf_retcode);
  IF vf_retcode != 0 THEN
    vf_errbuf    := 'INIT - ' || vf_errbuf;
    Dka_Tools_Pkg.put_outdebug_message( CHR(10)||vf_errbuf);
    RETURN;
  END IF;

  IF p_recyclage = 'N' THEN
  v_phase := 'PHASE chargement des tables de travail';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  DBMS_OUTPUT.PUT_LINE(v_phase);
  LANCE_CHARGEMENT_FICHIER  (vf_errbuf ,
                             vf_retcode );
    IF  vf_retcode = 2 THEN
       pn_retcode := 2;
    ELSIF vf_retcode = 1 THEN
     pn_retcode := 1;
  END IF ;
  END IF;

  v_phase := 'PHASE Préparation des données';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  PREPARATION_DONNEE(vf_errbuf ,
                     vf_retcode  );

  IF  vf_retcode = 1 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;

  MAJ_DONNEE_ATRAITEE(vf_errbuf, vf_retcode);

  v_phase := 'PHASE Detérmination des actions';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  DETERMINATION_ACTION(vf_errbuf ,
                       vf_retcode  );
  IF  vf_retcode = 1 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;


  v_phase := 'PHASE Validation des données';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  VALIDATION_DONNEES(vf_errbuf ,
                     vf_retcode  );
  IF  vf_retcode = 1 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;


   v_phase := 'PHASE IMPORT des données';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  IMPORT_DONNEES(vf_errbuf,
                 vf_retcode)  ;
  IF  vf_retcode = 2 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;

  ENREGISTREMENT_COMPTEUR(vf_errbuf, vf_retcode);

  v_phase := 'PHASE  Mise à jour des tables reporting/historique';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  UPDATE_RECORD2(vf_errbuf,vf_retcode ,g_request_Id);

  SORTIE_TRAITEMENT;

  IF pn_retcode = 2 THEN
    pv_errbuf := 'ATTENTION : Erreur bloquante : '||pv_errbuf;
    g_statut_fin := 'Erreur';
  ELSIF  (pn_retcode = 1 OR g_tab_erreurs.count > 0) THEN
    pv_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
    pn_retcode := 1;
    g_statut_fin := 'Avertissement';
  ELSE
    pv_errbuf := 'Fin normale du traitement - Aucun rejet.';
    pn_retcode := 0;
    g_statut_fin := 'Fin normale';
   END IF;

  writeout(pv_errbuf);
  fin_de_sortie;
  EXCEPTION
    WHEN OTHERS THEN
      pn_retcode   := 2;
      pv_errbuf    := 'MAIN : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
      DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure MAIN : EXCEPTION OTHERS ');


END  MAIN;

END DKA_IPO_SSTR_IVALUA_PKG;
/
SHOW ERRORS;
EXIT