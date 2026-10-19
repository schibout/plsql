CREATE OR REPLACE PACKAGE BODY DKA_FUSPORECVTOTAL_PKG IS
  --
   --
  ---PROD------------------------------------------------------------------------------------------------------------
  -- CAPGEMINI
  -- PROJET             : DALKIA Oracle Applications
  -- NOM                : DKA_SPORECEP_FRAISPORT.pkb
  -- DESCRIPTION        : DKA_SPORECEP_FRAISPORT package body :
  ---
  --- AUTEUR            : Samir EL OUAHABI
  --- DATE DE CREATION  : 13/09/2019
  --- DOC. ASSOCIEE     :
  -- COMMENTAIRE        : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- 
  ---------------------------------------------------------------------------------------------------------------

  ----- Déclaration des variables globales du package -----
  gv_status_code      VARCHAR2(15) := 'PENDING';
  gv_source_code      VARCHAR2(15) := 'VENDOR';
  gv_transaction_new  VARCHAR2(15) := 'NEW';
  gv_transaction_type VARCHAR2(15) := 'RECEIVE';
  gv_mode_code        VARCHAR2(15) := 'BATCH';
  gv_auto_transact    VARCHAR2(15) := 'DELIVER';
  gv_user_id          NUMBER := fnd_global.user_id;
  gv_login_id         NUMBER := fnd_global.login_id;
  l_group_id          NUMBER;
  count_cmd           NUMBER;

  -----------------------------------------------------------------
  -- NOM         : put_line_log
  -- DESCRIPTION : Ecrit une ligne dans le fichier log du traitement
  -----------------------------------------------------------------
  PROCEDURE put_line_log(pv_buffer IN VARCHAR2) IS
  BEGIN
    fnd_file.put_line(fnd_file.log, pv_buffer);
  EXCEPTION
    WHEN OTHERS THEN
      NULL; -- on ne fait rien
  END put_line_log;

  -----------------------------------------------------------------
  -- NOM         : put_line_out
  -- DESCRIPTION : Ecrit une ligne dans le fichier out du traitement
  -----------------------------------------------------------------
  PROCEDURE put_line_out(pv_buffer IN VARCHAR2) IS
  BEGIN
    fnd_file.put_line(fnd_file.output, pv_buffer);
  EXCEPTION
    WHEN OTHERS THEN
      NULL; -- on ne fait rien
  END put_line_out;
----
/*
 *************************************************************************
 * PROCEDURE NAME : Launch_OI
 * 
 * DESCRIPTION
 *  Procédure de lancement du Programme maître de l'interface receptions
 *
 * PARAMETERS
 * ==========
 * NAME               DESCRIPTION
.* -----------------  ------------------------------------------------------
 * p_ou              Unité opérationnelle
 * p_errbuf          Retour de message éventuel
 * p_retcode         Statut du traitement en sortie
 * 
 ************************************************************************
 */
 
  PROCEDURE Launch_OI(p_errbuf            OUT VARCHAR2,
                      p_retcode           OUT NUMBER
                          ) 
  IS
    v_phase                  VARCHAR2 (100);
    v_status                 VARCHAR2 (100);
    v_dev_phase              VARCHAR2 (100);
    v_dev_status             VARCHAR2 (100);
    v_message                VARCHAR2 (100);
     V_Batch_Source_Id        NUMBER;
    
    vn_tempo                 NUMBER := 20;   
    vn_request_id            Fnd_Concurrent_Requests.Request_Id%Type;
    TYPE t_request_id        IS TABLE OF PLS_INTEGER;
    va_request_id            t_request_id := t_request_id();
    vn_nb_traitements        PLS_INTEGER := 0;

  BEGIN
  
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Launch_OI');    
    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 
                                     'Lancement de l''interface des receptions : ');

    fnd_file.put_line(fnd_file.OUTPUT, CHR(10));
    fnd_file.put_line(fnd_file.OUTPUT, 'LANCEMENT DE L''INTERFACE DES RECEPTIONS :');
    fnd_file.put_line(fnd_file.OUTPUT, '----------------------');
          
    -- Calcul des statistiques sur les tables standards
    fnd_stats.gather_table_stats('PO', 'RCV_HEADERS_INTERFACE', dbms_stats.auto_sample_size);
    fnd_stats.gather_table_stats('PO', 'RCV_TRANSACTIONS_INTERFACE', dbms_stats.auto_sample_size);
          
    ---------------------------------------------------
    -- Lancement du traitement de l'interface des receptions --
    ---------------------------------------------------    
          
    FOR rec_group_id IN (SELECT DISTINCT group_id 
                           FROM rcv_headers_interface
                          WHERE processing_status_code = 'PENDING'
                       ORDER BY group_id) LOOP
           
                                                            
      -- Lancement du traitement Programme maître de l'interface receptions
      vn_request_id := fnd_request.submit_request( application => 'PO',
                                                   program     => 'RVCTP',
                                                   description => NULL,
                                                   start_time  => NULL,
                                                   sub_request => FALSE,
                                                   Argument1   => 'BATCH',
                                                   Argument2   => rec_group_id.group_id 		
                          );
            
      IF vn_request_id = 0 THEN
              
        p_retcode    := 2;
        fnd_file.put_line(fnd_file.LOG, 'ERREUR : Le traitement de l''interface des receptions a échoué' || CHR(10) ||
                                        'PROGRAMME  : RAXMTR');
        Fnd_File.put_line (Fnd_File.OUTPUT, '====> ERREUR : Le traitement de l''interface des receptions a échoué');
                  
      ELSE
              
        COMMIT;
        Fnd_File.put_line(Fnd_File.LOG, '=> REQUEST ID= ' || vn_request_id);            
        Fnd_File.put_line(Fnd_File.OUTPUT, '. Numéro du traitement de l''interface des receptions : ' || vn_request_id);  
                    
        --Stockage des numéros de traitements
        va_request_id.extend;
        vn_nb_traitements := vn_nb_traitements + 1;
        va_request_id(vn_nb_traitements) := vn_request_id;
                  
      END IF;
              
    END LOOP;
        
    -- Attente de la fin du traitement
    FOR i IN 1..vn_nb_traitements LOOP
      IF NOT (Fnd_Concurrent.wait_for_request (va_request_id(i), vn_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message))
      THEN                        
          p_errbuf  := v_Message;
          Fnd_file.put_line(Fnd_file.log, 'request_id = '||va_request_id(i)||' ERREUR : Attente de la fin du programme de l''interface des receptions : Fin du traitement' || CHR(10) ||
                                          'MESSAGE : ' || v_Message || CHR(10) );  
      END IF;
                       
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') 
      THEN          
          Fnd_File.put_line(Fnd_File.LOG, 'request_id = '||va_request_id(i)||'COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
          Fnd_File.put_line(Fnd_File.OUTPUT, 'request_id = '||va_request_id(i)||'. Statut de fin : ' || v_phase || '/' || v_status);

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING')
      THEN
          Fnd_File.put_line (Fnd_File.LOG, 'Fin du traitement de l''interface des receptions en warning '|| va_request_id(i));
          p_retcode    := 1;

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL')  
      THEN
          p_retcode := 1;--2;
          p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des receptions : '||v_Message;

          fnd_file.put_line(fnd_file.LOG, 'ERREUR : Fin anormale du traitement de l''interface des receptions '|| va_request_id(i)  || CHR(10) ||
                                          'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                          'MESSAGE : ' || v_message || CHR(10) );
          Fnd_File.put_line (Fnd_File.OUTPUT, '===> ERREUR : Fin anormale du traitement de l''interface des receptions '||va_request_id(i));
      END IF;
    END LOOP;
        
        Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Launch_OI');    
  
  EXCEPTION
        WHEN OTHERS
        THEN
            p_retcode   := 2;
            p_errbuf    := 'Launch_OI : ' ||SQLERRM;
            Fnd_File.put_line (Fnd_File.LOG, p_errbuf);
            Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Launch_OI : EXCEPTION OTHERS ');
  END Launch_OI; 



  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insert_rcv_headers
  --  Description   : Procédure d'insertion d'une ligne dans l'interface des entêtes
  --
  --  PARAMETRES    :pn_header_id              Entrée
  --
  --                 pn_montant_calculé        Sortie
  --                 pv_errbuf                 Entrée/Sortie    message d'erreur
  --                 pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  -----------------------------------------------------------------------------------------------------------  
  PROCEDURE insert_rcv_headers(pn_vendor_id      IN NUMBER,
                               pn_vendor_site_id IN NUMBER,
                               pn_org_id         IN NUMBER, --RBE MigR12
							   pn_rec_num        IN VARCHAR2,
                               pv_errbuf         OUT VARCHAR2,
                               pn_retcode        IN OUT NUMBER)

   IS

  BEGIN
    
    -- Insertion d'une ligne dans la table RCV_HEADERS_INTERFACE
    INSERT INTO rcv_headers_interface
      (header_interface_id,
       group_id,
	   --receipt_num,
       processing_status_code,
       receipt_source_code,
       transaction_type,
       vendor_id,
       vendor_site_id,
       org_id, --RBE MigR12
       validation_flag,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       last_update_login,
       expected_receipt_date)
    VALUES
      (rcv_headers_interface_s.NEXTVAL,
       l_group_id , -- rcv_interface_groups_s.NEXTVAL,
	   --pn_rec_num,
       gv_status_code,
       gv_source_code,
       gv_transaction_new, -- SELO --gv_transaction_type, -- 
       pn_vendor_id, -- vendor_id
       pn_vendor_site_id, -- vendor_site_id
       pn_org_id, --RBE MigR12
       'Y',
       SYSDATE,
       gv_user_id,
       SYSDATE,
       gv_user_id,
       gv_login_id,
       SYSDATE);

  EXCEPTION
    WHEN OTHERS THEN
      put_line_log('Erreur lors de l insertion RHI : ' || SQLERRM(SQLCODE));
      pv_errbuf  := 'DKA_FUSPORECVTOTAL_PKG.insert_rcv_headers' || SQLERRM;
      pn_retcode := 1;
  END insert_rcv_headers;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : insert_rcv_transactions
  --  Description   : Procédure d'insertion d'une ligne dans l'interface des lignes de réception
  --
  --  PARAMETRES    :pn_header_id              Entrée
  --
  --                 pn_montant_calculé        Sortie
  --                 pv_errbuf                 Entrée/Sortie    message d'erreur
  --                 pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
  --
  --  VALEUR RETOURNEE :
  --     Description       : ************************
  --     Valeurs possibles : ************************
  ---------------------------------------------------------------------------------------------------------------

  PROCEDURE insert_rcv_transactions(pn_quantity                IN NUMBER,
                                    pv_uom                     IN VARCHAR2,
                                    pv_description             IN VARCHAR2,
                                    pn_vendor_id               IN NUMBER,
                                    pn_vendor_site_id          IN NUMBER,
                                    pn_header_id               IN NUMBER,
                                    pn_line_id                 IN NUMBER,
                                    pn_line_location_id        IN NUMBER,
                                    pn_ship_to_organization_id IN NUMBER,
                                    pn_ship_to_location_id     IN NUMBER,
                                    pv_errbuf                  OUT VARCHAR2,
                                    pn_retcode                 IN OUT NUMBER)

   IS

  BEGIN

    -- Insertion d'une ligne dans la table RCV_TRANSACTIONS_INTERFACE
    INSERT INTO rcv_transactions_interface
      (interface_transaction_id,
       group_id,
       transaction_type,
       transaction_date,
       processing_status_code,
       processing_mode_code,
       transaction_status_code,
       quantity,
       unit_of_measure,
       item_description,
       auto_transact_code,
       receipt_source_code,
       vendor_id,
       vendor_site_id,
       source_document_code,
       po_header_id,
       po_line_id,
       po_line_location_id,
       header_interface_id,
       validation_flag,
       ship_to_location_id,
       to_organization_id,
       deliver_to_location_id,
       creation_date,
       created_by,
       last_update_date,
       last_updated_by,
       last_update_login,
       expected_receipt_date)
    VALUES
      (rcv_transactions_interface_s.NEXTVAL,
       l_group_id , --rcv_interface_groups_s.CURRVAL,
       gv_transaction_type,
       SYSDATE,
       gv_status_code,
       gv_mode_code,
       gv_status_code,
       pn_quantity,
       pv_uom,
       pv_description,
       gv_auto_transact,
       gv_source_code,
       pn_vendor_id,
       pn_vendor_site_id,
       'PO',
       pn_header_id,
       pn_line_id,
       pn_line_location_id,
       rcv_headers_interface_s.CURRVAL,
       'Y',
       pn_ship_to_location_id,
       pn_ship_to_organization_id,
       pn_ship_to_location_id,
       SYSDATE,
       gv_user_id,
       SYSDATE,
       gv_user_id,
       gv_login_id,
       SYSDATE);

  EXCEPTION
    WHEN OTHERS THEN
      put_line_log('Erreur lors de l insertion RTI : ' || SQLERRM(SQLCODE));
      pn_retcode := 1;
      pv_errbuf  := 'DKA_SPORECEP_FRAISPORT_PKG.insert_rcv_transactions' ||
                    SQLERRM;
  END insert_rcv_transactions;


  --------------------------------------------------------------------------------------------------------------
  --  Nom           : wait_GLPOS
  --  Description   : Attente de la fin d'execution du traitement GLPOS soumis
  --
  --  PARAMETRES    :
  --  pv_errbuf                 Entrée/Sortie      message d'erreur
  --  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
  --  VALEUR RETOURNEE :
  --     N/A
  --     Description       :
  --     Valeurs possibles :
  ---------------------------------------------------------------------------------------------------------------

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

    IF NOT vb_trash
    THEN
      pv_errbuf := pv_errbuf || 'Pb dans l attente wait_RVCTP';
    END IF;

    IF vv_status = 'Erreur'
    THEN
      pv_errbuf := pv_errbuf || vv_message;
    END IF;
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'sortie de wait_RVCTP avec erreur EXCEPTION OTHERS:' ||
                    SQLERRM;
      pn_retcode := 2;
  END wait_rvctp;

  ------------------------------------------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure principale enchaînant l'ensemble des autres procédures
  --
  --  PARAMETRES :
  --    pv_errbuf                   Entrée/Sortie       retour de message eventuel
  --    pn_retcode                  Sortie          status du traitement en sortie
  --
  --  VALEUR RETOURNEE :
  --     Description       : code retour de validité
  --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
  -----------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf      OUT VARCHAR2,
                 pn_retcode     IN OUT NUMBER
				 ) IS

    l_vendor_id               NUMBER;
    l_vendor_site_id          NUMBER;
    l_org_id                  NUMBER; 
    l_quantity                NUMBER;
    l_uom                     po_lines_all.unit_meas_lookup_code%TYPE;
    l_description             po_lines_all.item_description%TYPE;
    l_po_line_id              NUMBER;
    l_po_line_location_id     NUMBER;
    vn_request_id             NUMBER;
    l_batch_id                NUMBER;
    l_ship_to_organization_id NUMBER;
    l_ship_to_location_id     NUMBER;
    l_count                   NUMBER;
    l_step                    VARCHAR2(50);
	l_Is_Received		      NUMBER;
	l_Count_received          NUMBER;
	v_errbuf                  VARCHAR2(2500);
    v_retcode                 NUMBER;
	l_count_ins_cmd           NUMBER;
	l_count_err_cmd           NUMBER;
	g_nb_entetes_group        NUMBER;
	rec_param dka_parameters%ROWTYPE;

  CURSOR cur_commande  IS
    -- SELO
	select ph.po_header_id pn_commande_id,
           ph.org_id, ph.segment1
      FROM PO_HEADERS_ALL ph,
           DKA_SPOFUSION_HEADERS_TMP dsht
     where ph.type_lookup_code        = 'STANDARD'
	   AND NVL(ph.closed_code,'OPEN') = 'OPEN'
	   AND NVL(ph.cancel_flag,'N')    = 'N'
	   AND authorization_status       = 'APPROVED'
	   AND dsht.Document_num_new = ph.segment1
       AND instr(dsht.Document_num_new, 'ST') > 0
	   AND dsht.org_id in (SELECT HOU.organization_id
							 FROM HR_ORGANIZATION_UNITS HOU,
								  DKA_STRANSCO_LINES DSTL,
								  DKA_STRANSCO_HEADERS DSTH
							WHERE DSTL.SET_ID = DSTH.SET_ID
							  AND HOU.NAME = DSTL.PARAM1_VALUE
							  AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
							  AND DSTL.ENABLE = 'Y'
							  AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
							  AND DSTL.return_value = (select name 
							                             from Hr_organization_units 
														where organization_id = ph.org_id) 
						   -- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
						   )    
	    AND not exists (SELECT distinct 1 
                          FROM rcv_shipment_lines
                         WHERE po_header_id = ph.po_header_id);


    CURSOR cur_ligne_commande (pn_commande_id NUMBER) IS
         SELECT ph.vendor_id,
                ph.vendor_site_id,
                pll.quantity,
                pl.unit_meas_lookup_code,
                pl.item_description,
                pl.po_line_id,
                pll.ship_to_organization_id,
                pll.ship_to_location_id,
                pll.line_location_id
           FROM po_headers_all ph, 
		        po_lines_all pl, 
				po_line_locations_all pll
          WHERE ph.po_header_id = pn_commande_id AND
                ph.po_header_id = pl.po_header_id AND
                pl.po_line_id = pll.po_line_id AND
                ph.po_header_id = pll.po_header_id;

    CURSOR Liste_Erreur  IS
	select table_name, Column_name, error_message, pov.VENDOR_NAME, povsa.VENDOR_SITE_CODE
	  from PO_INTERFACE_ERRORS pie, rcv_headers_interface hh, po_vendors pov ,PO_VENDOR_SITES_ALL povsa  
	 where pie.interface_type = 'RCV-856'
	   and interface_header_id in (select header_interface_id
									 from rcv_headers_interface bb
									where bb.processing_status_code = 'ERROR') 
	   and hh.header_interface_id=pie.interface_header_id
	   and table_name = upper('rcv_headers_interface')
	   and hh.vendor_site_id= povsa.VENDOR_SITE_ID
	   and hh.vendor_id= pov.vendor_id
    ;		
		

    CURSOR Liste_transac_Err  IS
	select table_name, Column_name, error_message, pie.interface_transaction_id, cmd.segment1, lin.line_num
          from PO_INTERFACE_ERRORS pie, rcv_transactions_interface hh ,
               po_headers_all cmd , po_lines_all lin
		 where  pie.interface_type = 'RCV-856'
		   and pie.interface_header_id in (select header_interface_id
										 from rcv_headers_interface bb
									    where bb.processing_status_code = 'ERROR') 
           and hh.interface_transaction_id=pie.interface_line_id
           and  table_name = upper('rcv_transactions_interface')
           and hh.po_header_id= cmd.po_header_id
           and hh.po_line_id = lin.po_line_id
           ;
  BEGIN
    -- initialisation des compteurs:
    l_count_ins_cmd :=0;
	l_count_err_cmd :=0;
	
    -- Suppression des lignes erronees dans l interface
	put_line_log('<<<< Etape suppression des tables interface >>>>');
	  delete  from rcv_transactions_interface hh
			  where hh.header_interface_id in (select bb.header_interface_id 
												 from rcv_headers_interface bb
												 where bb.processing_status_code = 'ERROR');
                                     

      delete from PO_INTERFACE_ERRORS pie   
			where pie.interface_type = 'RCV-856'
			  and interface_header_id in (select header_interface_id
											from rcv_headers_interface bb
										   where bb.processing_status_code = 'ERROR'); 

	  
      delete from rcv_headers_interface bb
            where bb.processing_status_code = 'ERROR';
  
      commit;
	put_line_log('<<<< reccuperation group_id >>>>');	
    SELECT rcv_interface_groups_s.nextval 
      INTO l_group_id 
      FROM dual;
	
	count_cmd := 0;
	
	put_line_log('<<<< reccuperation NB_ENTETE_GROUP_ID >>>>');	
      Dka_Tools_Pkg.get_parameter(  'DKA_IMPTRECPO',
                                    'NB_ENTETE_GROUP_ID',
                                    rec_param,
                                    pn_retcode,
                                    v_errbuf); 									
									
         IF pn_retcode != 0 THEN
           v_errbuf := 'init : g_nb_entetes_group - ' || v_errbuf;
           RETURN;
        END IF;									
        g_nb_entetes_group := rec_param.number_value;
		
	
    FOR rec_cmd IN cur_commande  LOOP
    pn_retcode := 0;

    l_step := 'APPROUVE';
	
	l_count_received:= 0;
 
    l_step := 'INIT';
	put_line_log('<<<< reccuperation des infos sur la commande >>>>');	
    SELECT ph.vendor_id, ph.vendor_site_id, ph.org_id 
      INTO l_vendor_id, l_vendor_site_id, l_org_id 
      FROM po_headers_all ph
     WHERE ph.po_header_id = rec_cmd.pn_commande_id;
	 
    count_cmd := count_cmd + 1;
	
	-- Récupération des variables de la table des paramètres
      
	
	if count_cmd > g_nb_entetes_group then
	   count_cmd :=  0;
	   SELECT rcv_interface_groups_s.nextval 
		 INTO l_group_id 
		 FROM dual;
	end if;
    -- Insertion des infos de la table des entêtes
    l_step := 'HEADER';
	put_line_log('<<<< Etape: lancement de la procedure insert_rcv_headers >>>>');		
    insert_rcv_headers(l_vendor_id,
                       l_vendor_site_id,
                       l_org_id,
					   rec_cmd.segment1,
                       pv_errbuf,
                       pn_retcode);

    IF pn_retcode != 0
    THEN
      RETURN;
    END IF;
	l_count_ins_cmd := l_count_ins_cmd + 1;


    FOR rec_ligne_commande IN cur_ligne_commande (rec_cmd.pn_commande_id) LOOP
      BEGIN
       -- Insertion des infos de la table des lignes
	   	put_line_log('<<<< Etape: lancement de la procedure insert_rcv_transactions >>>>');	
       insert_rcv_transactions(rec_ligne_commande.quantity,
                               rec_ligne_commande.unit_meas_lookup_code,
                               rec_ligne_commande.item_description,
                               rec_ligne_commande.vendor_id,
                               rec_ligne_commande.vendor_site_id,
                               rec_cmd.pn_commande_id,
                               rec_ligne_commande.po_line_id,
                               rec_ligne_commande.line_location_id,
                               rec_ligne_commande.ship_to_organization_id,
                               rec_ligne_commande.ship_to_location_id,
                               pv_errbuf,
                               pn_retcode);

        IF pn_retcode != 0
        THEN
           RETURN;
        END IF;
        END;
      END LOOP;

    COMMIT;

    -- Lancement de l'interface standard
    put_line_log('');
    put_line_log('<<<< LANCEMENT DE L''INTERFACE STANDARD RVCTP >>>>');

  /*  SELECT rcv_interface_groups_s.CURRVAL
      INTO l_batch_id
      FROM dual;

    --pn_batch_id := l_batch_id;

    Vn_Request_Id := Fnd_Request.Submit_Request('PO' -- APPLICATION SHORT NAME
                                                       ,
                                                        'RVCTP' -- CONCURRENT PROGRAM NAME
                                                       ,
                                                        NULL -- DESCRIPTION
                                                       ,
                                                        NULL -- START
                                                       ,
                                                        FALSE -- SUB_REQUEST
                                                        -- ARGUMENTS
                                                       ,
                                                        'BATCH' -- mode
                                                       ,
                                                        l_batch_id -- batch_id
                                                        );

    -- Validation pour soumettre le traitement
    COMMIT;
   
     IF Vn_Request_Id = 0 THEN
      pv_errbuf := '!!!! Erreur lors de la soumission du programme d''import des réceptions. ';
      dka_tools_pkg.put_outdebug_message(Pv_errbuf);
      dka_tools_pkg.put_outdebug_message(Fnd_Message.Get);
      -- Sortie en erreur
      pn_Retcode := 2;
    END IF;

    -- Attente fin du traitement
    put_line_log('>>>> Attente fin de l''interface standard RVCTP');
    wait_rvctp(pv_errbuf, pn_retcode, Vn_Request_Id);
    put_line_log('<<<< SORTIE DE L''INTERFACE STANDARD RVCTP >>>>');

    select count(*)
	  into l_count
      from PO_INTERFACE_ERRORS   
	 where interface_type = 'RCV-856'   
	   and batch_id = l_batch_id;

    IF (l_count > 0) THEN
       pn_retcode := 1;
       pv_errbuf := 'Pas de réception';
    END IF;
		begin
			SELECT distinct 1
			  into l_Is_Received
			  FROM rcv_shipment_lines
			 WHERE po_header_id =rec_cmd.pn_commande_id;
			 
			l_count_received:=l_count_received+1;
			put_line_out('La commande '|| rec_cmd.segment1|| ' est correctement receptionnée');
		
		EXCEPTION
		WHEN OTHERS THEN
		  null;
		END;
	
	*/
	END LOOP;
    
	      -- Lancement du programme standard 
    put_line_log('<<<< Etape: lancement de la procedure Launch_OI >>>>');	
    Launch_OI(v_errbuf,
              v_retcode
              );
    IF v_retcode = 2 
	THEN
	    pn_retcode := 2;
	END IF;
  
  put_line_log('<<<< Etape: Compteur des erreurs >>>>');	
		
		Select count(*) into  l_count_err_cmd
	  	  from rcv_headers_interface bb
	     where bb.processing_status_code = 'ERROR'
	;
	
    l_count := l_count_ins_cmd - l_count_err_cmd ;
	
	Fnd_File.put_line (Fnd_File.OUTPUT, chr(10));
	Fnd_File.put_line (Fnd_File.OUTPUT, '========== BILAN =========='||chr(10));
	
	Fnd_File.put_line (Fnd_File.OUTPUT, '===> Nbre de réception traitées avec succès : '||l_count);
	Fnd_File.put_line (Fnd_File.OUTPUT, '===> Nbre de réception en erreur : '||l_count_err_cmd);
	Fnd_File.put_line (Fnd_File.OUTPUT, chr(10));
	Fnd_File.put_line (Fnd_File.OUTPUT, '===> Liste des erreurs de l open interface');
    
    FOR rec_Liste_Erreur IN Liste_Erreur LOOP
        BEGIN
           Fnd_File.put_line (Fnd_File.OUTPUT, 'Vendor : '||rec_Liste_Erreur.VENDOR_NAME || ' - Site : '|| rec_Liste_Erreur.VENDOR_SITE_CODE ||' - Table : '||rec_Liste_Erreur.table_name || ' - Colonne : '|| rec_Liste_Erreur.Column_name ||
		                                       
                                    		   ' - '|| rec_Liste_Erreur.error_message );
        END;
    END LOOP;
	 FOR rec_Liste_Erreur IN Liste_transac_Err LOOP
        BEGIN
           Fnd_File.put_line (Fnd_File.OUTPUT, 'Commande : '||rec_Liste_Erreur.segment1 || ' - Line : '|| rec_Liste_Erreur.line_num ||' - Table : '||rec_Liste_Erreur.table_name || ' - Colonne : '|| rec_Liste_Erreur.Column_name ||
		                                       
                                    		   ' - '|| rec_Liste_Erreur.error_message );
        END;
    END LOOP;
    
    Fnd_File.put_line (Fnd_File.OUTPUT, '===> Fin');	
 EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      pn_retcode := 2;
      pv_errbuf  := 'main' || l_step || ':' || substr(SQLERRM, 1, 80);
  END main;

END DKA_FUSPORECVTOTAL_PKG;

/
SHOW ERROR
EXIT
