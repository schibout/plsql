create or replace PACKAGE BODY DKA_IPOCDE_IVALUA_PKG IS
--------------------------------------------------------------------------------
-- $Id: DKA_IPOCDE_IVALUA_PKG.pkb  $
-- Capgemini
-- Projet           :
-- Nom              : DKA_IPOCDE_IVALUA_PKG.pks
-- Description      : Corps du package DKA_IPOCDE_IVALUA_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 21/05/2020
-- Commentaires     :
--------------------------------------------------------------------------------
-- Date de modification : 29/04/2021
-- Commentaires         : SELO : artf07455137 INC0536680 - INT088 - Commandes Ivalua : Problème détermination code projet
--------------------------------------------------------------------------------
-- Date de modification : 29/04/2021
-- Commentaires         : SELO : artf07455147 INC0536669 - INT088 - Commandes Ivalua - Problème d''insertion d''une ligne de frais de port en mise à jour lors d''un avenant
--------------------------------------------------------------------------------
-- Date de modification : 29/04/2021
-- Commentaires         : SELO : tracker50786 - INC0538812 : Erreur en cas de pb d''unicité
--------------------------------------------------------------------------------
-- Date de modification : 08/09/2021
-- Commentaires         : ARA : INC0580800 - INT088 - Import des commandes Ivalua en erreur - Problème de caractère décimal
--------------------------------------------------------------------------------
-- Date de modification : 22/09/2022
-- Commentaires         : SELO EDB301
--------------------------------------------------------------------------------
-- Date de modification : 25/11/2021
-- Commentaires         : SHA EDB310 - IEDB310 - DPE20210029 - Import des commandes annulées
--------------------------------------------------------------------------------
-- Date de modification : 09/03/2022
-- Commentaires         : SHA CR76 - D@CShop - Rendre modifiables certains champs de la commande
--------------------------------------------------------------------------------
-- Date de modification : 05/12/2023
-- Commentaires         : BNZ : KDFI-1374 - Correction du programme "DKA : Import des commandes depuis iValua"
--------------------------------------------------------------------------------
-- Date de modification : 14/03/2025
-- Commentaires         : BNZ : KDFI-1979 - TASK - Correctif interface commande - Annulation"
--------------------------------------------------------------------------------
  g_package                 VARCHAR2(30)  := 'DKA_IPOCDE_IVALUA_PKG';
  g_sqlerrm                 VARCHAR2(500) := NULL;
  g_retproc                 NUMBER        := 0;
  g_user                    NUMBER        := fnd_profile.value('USER_ID');
  g_request_id              NUMBER        := fnd_global.conc_request_id;
  g_request_loader          NUMBER;
  gv_description            VARCHAR2(250);
  gn_category_id            NUMBER;
  gn_default_value1         NUMBER;
  gn_default_value2         NUMBER;
  gv_datatype_name          VARCHAR2(30) := 'WEB_PAGE';
  gn_datatype_id            NUMBER;
  gv_entity_name            VARCHAR2(30) := 'PO_HEADERS';
  gn_org_id                 hr_all_organization_units.organization_id%TYPE;
  gn_batch_id               NUMBER;
  g_enreg_a_traite_entete   NUMBER := 0;
  g_enreg_entete_rejete1    NUMBER := 0;
  g_enreg_entete_warning    NUMBER := 0;
  g_enreg_entete_rejete2    NUMBER := 0;
  g_enreg_entete_succes     NUMBER := 0;
  g_enreg_a_traite_line     NUMBER := 0;
  g_enreg_line_rejete1      NUMBER := 0;
  g_enreg_line_rejete2      NUMBER := 0;
  g_enreg_line_succes       NUMBER := 0;
  g_enreg_ligne_rejet       NUMBER := 0;
  g_enreg_ligne_warning     NUMBER := 0;
  g_enreg_a_traite_orph     NUMBER := 0;
  g_enreg_ignore            NUMBER := 0;
  g_entete_ignore           NUMBER := 0;
  g_line_complete           NUMBER := 0;
  g_enreg_a_traite_lineT    NUMBER := 0;
  g_statut_fin              VARCHAR2(50);
  g_tab_doublons            t_doublons;
  g_tab_erreurs             t_erreurs;
  g_tab_avertissements      t_erreurs;
  g_tab_approb              t_approbation;
  g_approb                  NUMBER := 0;
  g_doublons                NUMBER := 0;
  g_erreurs                 NUMBER := 0;
  g_avertissement           NUMBER := 0;


/*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 21/05/2020
  -- Remarques         :
/*============================================================================*/
PROCEDURE writeout(P_message IN VARCHAR2) IS
  L_procedure VARCHAR2(30) := 'writeout';
  v_etape   VARCHAR2(100);
BEGIN

  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);

EXCEPTION
  WHEN OTHERS THEN
    G_retproc := 1;
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
  -- Auteur            : Asma AMENKOUR
  -- Date              : 03/06/2020
  -- Remarques         :
/*=================================================================================*/
  PROCEDURE SORTIE_TRAITEMENT
  IS
    l_procedure                   VARCHAR2(30) := 'sortie_traitement';
    l_message                     VARCHAR2(2000);
    v_po_number DKA_IPOCDE_HEADERS.po_number%TYPE;
    v_file_name DKA_IPOCDE_HEADERS.file_name%TYPE;

    CURSOR cur_err_mess IS
    SELECT dih.po_number,dih.file_name,dpm.source,dih.line_num,NULL ivalua_line_id,dpm.message_text
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCDE_HEADERS    dih
    WHERE dpm.REQUEST_ID     = g_request_id
    --AND   dih.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCDE_HEADERS'
    AND   dih.record_id  = dpm.table_id
	and dpm.message_type='E'
	and dih.statut = 'REJECTED'
   -- ORDER BY dih.po_number
    UNION
    SELECT dil.po_number,dil.file_name,dpm.source,dil.line_num,dil.ivalua_line_id,dpm.message_text
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCDE_LINES     dil
    WHERE dpm.REQUEST_ID     = g_request_id
   -- AND   dil.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCDE_LINES'
    AND   dil.record_id  = dpm.table_id
	and dpm.message_type='E'
	and dil.statut = 'REJECTED'
   -- ORDER BY dil.ivalua_line_id
    ;
	/*
    CURSOR cur_aver_mess IS
    SELECT dih.po_number,dih.file_name,dpm.source,dih.line_num,NULL ivalua_line_id,dpm.message_text
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCDE_HEADERS    dih
    WHERE dpm.REQUEST_ID     = g_request_id
    --AND   dih.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCDE_HEADERS'
    AND   dih.record_id  = dpm.table_id
	and dpm.message_type='W'
	and dih.statut = 'COMPLETE'
   -- ORDER BY dih.po_number
    UNION
    SELECT dil.po_number,dil.file_name,dpm.source,dil.line_num,dil.ivalua_line_id,dpm.message_text
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCDE_LINES     dil
    WHERE dpm.REQUEST_ID     = g_request_id
   -- AND   dil.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCDE_LINES'
    AND   dil.record_id  = dpm.table_id
	AND  dpm.message_type='W'
	and dil.statut = 'COMPLETE'
   -- ORDER BY dil.ivalua_line_id
    ;
    */
	-- EDB301 - SELO
	CURSOR cur_aver_mess IS
    SELECT dih.po_number,dih.file_name,dpm.source,dih.line_num,NULL ivalua_line_id,dpm.message_text
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCDE_HEADERS    dih
    WHERE dpm.REQUEST_ID     = g_request_id
    --AND   dih.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCDE_HEADERS'
    AND   dih.record_id  = dpm.table_id
	and dpm.message_type='W'
	and dih.statut = 'WARNING'
   -- ORDER BY dih.po_number
    UNION
    SELECT dil.po_number,dil.file_name,dpm.source,dil.line_num,dil.ivalua_line_id,dpm.message_text
    FROM  DKA_PROGRAM_MESSAGES dpm
    ,     DKA_IPOCDE_LINES     dil
    WHERE dpm.REQUEST_ID     = g_request_id
   -- AND   dil.REQUEST_ID = dpm.REQUEST_ID
    AND dpm.table_name = 'DKA_IPOCDE_LINES'
    AND   dil.record_id  = dpm.table_id
	and dpm.message_type='W'
	and dil.statut = 'WARNING'
   -- ORDER BY dil.ivalua_line_id
    ;



    CURSOR C_OI_ERROR IS
    SELECT dih.po_number,dih.file_name,pie.Table_name,pie.column_name,dih.line_num,NULL ivalua_line_id,pie.error_message,dih.record_id ,'DKA_IPOCDE_HEADERS' table_interface
    FROM PO_INTERFACE_ERRORS pie
    ,    PO_HEADERS_INTERFACE phi
    ,    DKA_IPOCDE_HEADERS dih
	  WHERE 1=1
    AND   pie.interface_header_id = phi.interface_header_id
    AND  dih.interface_header_id  = phi.interface_header_id
    AND  pie.Table_name           = 'PO_HEADERS_INTERFACE'
    --AND  dih.request_id= g_request_id
    UNION
    SELECT dil.po_number,dil.file_name,pie.Table_name,pie.column_name,dil.line_num,dil.ivalua_line_id,pie.error_message,dil.record_id,'DKA_IPOCDE_LINES' table_interface
    FROM PO_INTERFACE_ERRORS pie
    ,    PO_LINES_INTERFACE pli
    ,    DKA_IPOCDE_LINES dil
	  WHERE 1=1
    AND   pie.interface_line_id  = pli.interface_line_id
    AND   dil.interface_line_id  = pli.interface_line_id
    AND   pie.Table_name in ('PO_LINES_INTERFACE','PO_LINE_LOCATIONS_INTERFACE','PO_DISTRIBUTIONS_INTERFACE')
    --AND  dih.request_id= g_request_id
   ;

    CURSOR C_CMD_APPROBATION IS
    SELECT pha.segment1
    ,      hou.name
    ,      pha.AUTHORIZATION_STATUS
    FROM   po_headers_all pha
    ,      hr_operating_units hou
    WHERE pha.attribute7            = 'IVALUA'
    AND   pha.AUTHORIZATION_STATUS != 'APPROVED'
    AND   pha.org_id                = hou.organization_id;

  BEGIN
    writeout('                                                                ');
    writeout('                                                                ');
    writeout('BILAN :');
    writeout('-------');
    writeout('                                                                ');
    writeout('NIVEAU ENTËTE :');
    writeout('. Nombre d''enregistrements à traiter (nouveaux et rejets)          : '||g_enreg_a_traite_entete);
    writeout('. Nombre d''enregistrements rejetés (phase validation)              : '||g_enreg_entete_rejete1 );
	writeout('. Nombre d''enregistrements en avertissement (phase validation)     : '||g_enreg_entete_warning );  -- SELO EDB301
    writeout('. Nombre d''enregistrements rejetés (phase création/MAJ/annulation) : '||g_enreg_entete_rejete2  );
    writeout('. Nombre d''enregistrements traités avec succès                     : '||g_enreg_entete_succes  );
    writeout('                                                                          ');
    writeout('                                                                          ');
    writeout('NIVEAU LIGNES :');
    writeout('. Nombre d''enregistrements à traiter (nouveaux et rejets)          : '||g_enreg_a_traite_lineT );
    writeout('. Nombre d''enregistrements rejetés (phase validation)              : '||(g_enreg_ligne_rejet));
	writeout('. Nombre d''enregistrements en avertissement (phase validation)     : '||g_enreg_ligne_warning );  -- SELO EDB301
    writeout('. Nombre d''enregistrements rejetés (phase création/MAJ/annulation) : '||g_enreg_line_rejete2   );
    writeout('. Nombre d''enregistrements traités avec succès                     : '||g_enreg_line_succes    );
    writeout('                                                                          ');
    writeout('                                                                          ');

    FOR rec_oi_err IN C_OI_ERROR LOOP
      DKA_TOOLS_PKG.INS_PROG_MESSAGE( g_request_id,              --request_id
                                      'DKA_IPOCMD_IVALUA', --prog_name
                                      'OI',               --source
                                       rec_oi_err.table_interface, --'DKA_IPOCDE_HEADERS' ,   --table_name
                                       rec_oi_err.RECORD_ID,  --table_id
                                       rec_oi_err.column_name,  --column_name
                                       NULL, -- rec_oi_err.Table_name,--'PO_HEADERS_INTERFACE', --column_value
                                       'E',                       --message_type
                                       rec_oi_err.Table_name||' : '||rec_oi_err.error_message                   --message_text
                                    );
    END LOOP;
    commit;

    FOR rec_erreur IN cur_err_mess LOOP
      g_erreurs := g_erreurs + 1;
      g_tab_erreurs(g_erreurs).po_number       := rec_erreur.po_number;
      g_tab_erreurs(g_erreurs).file_name       := rec_erreur.file_name;
      g_tab_erreurs(g_erreurs).line_num        := rec_erreur.line_num;
      g_tab_erreurs(g_erreurs).source          := rec_erreur.source;
      g_tab_erreurs(g_erreurs).ivalua_line_id  := rec_erreur.ivalua_line_id;
      g_tab_erreurs(g_erreurs).message_text    := rec_erreur.message_text;
    END LOOP;
    writeout( 'LISTE DES ANOMALIES :');
    writeout( '---------------------');
    IF g_tab_erreurs.count > 0 THEN
      writeout( RPAD('Commande',35)||RPAD('ID Ligne Ivalua',25)||RPAD('Fichier',55)||RPAD('Ligne',15)||RPAD('Phase',25)||RPAD('Message',500));
      writeout( RPAD('--------',35)||RPAD('---------------',25)||RPAD('-------',55)||RPAD('-----',15)||RPAD('-----',25)||RPAD('-------',500));
      FOR i IN g_tab_erreurs.first..g_tab_erreurs.last LOOP
        l_message := RPAD(NVL(g_tab_erreurs(i).po_number,' '),35,' ')||RPAD(NVL(g_tab_erreurs(i).ivalua_line_id,' '),25,' ')||RPAD(NVL(g_tab_erreurs(i).file_name,' '),55,' ')||RPAD(NVL(g_tab_erreurs(i).line_num,' '),15,' ')||RPAD(g_tab_erreurs(i).source,25)||RPAD(g_tab_erreurs(i).message_text,500);
        writeout(l_message);
	    END LOOP;
    ELSE
      writeout('Aucune commande en erreur');
    END IF;


    FOR rec_erreur IN cur_aver_mess LOOP
      g_avertissement := g_avertissement + 1;
      g_tab_avertissements(g_avertissement).po_number       := rec_erreur.po_number;
      g_tab_avertissements(g_avertissement).file_name       := rec_erreur.file_name;
      g_tab_avertissements(g_avertissement).line_num        := rec_erreur.line_num;
      g_tab_avertissements(g_avertissement).source          := rec_erreur.source;
      g_tab_avertissements(g_avertissement).ivalua_line_id  := rec_erreur.ivalua_line_id;
      g_tab_avertissements(g_avertissement).message_text    := rec_erreur.message_text;
    END LOOP;
    writeout('                                                                          ');
    writeout('                                                                          ');
    writeout( 'LISTE DES AVERTISSEMENTS :');
    writeout( '---------------------');
    IF g_tab_avertissements.count > 0 THEN
      writeout( RPAD('Commande',35)||RPAD('ID Ligne Ivalua',25)||RPAD('Fichier',55)||RPAD('Ligne',15)||RPAD('Phase',25)||RPAD('Message',500));
      writeout( RPAD('--------',35)||RPAD('---------------',25)||RPAD('-------',55)||RPAD('-----',15)||RPAD('-----',25)||RPAD('-------',500));
      FOR i IN g_tab_avertissements.first..g_tab_avertissements.last LOOP
        l_message := RPAD(NVL(g_tab_avertissements(i).po_number,' '),35,' ')||RPAD(NVL(g_tab_avertissements(i).ivalua_line_id,' '),25,' ')||RPAD(NVL(g_tab_avertissements(i).file_name,' '),55,' ')||RPAD(NVL(g_tab_avertissements(i).line_num,' '),15,' ')||RPAD(g_tab_avertissements(i).source,25)||RPAD(g_tab_avertissements(i).message_text,500);
        writeout(l_message);
	    END LOOP;
    ELSE
      writeout('Aucune commande en erreur');
    END IF;


    FOR rec_cmd_app IN C_CMD_APPROBATION LOOP
      g_approb := g_approb + 1;
      g_tab_approb(g_approb).UO            := rec_cmd_app.name;
      g_tab_approb(g_approb).commande      := rec_cmd_app.segment1;
      g_tab_approb(g_approb).statut        := rec_cmd_app.AUTHORIZATION_STATUS;
    END LOOP;
    writeout('                                                                          ');
    writeout('                                                                          ');
    writeout( 'LISTE DES COMMANDES POUR LESQUELLES L''APPROBATION A ECHOUE :');
    writeout( '-----------------------------------------------------------');
    IF g_tab_approb.count > 0 THEN
      writeout( RPAD('UO',35)||RPAD('Commande',35)||RPAD('Statut Approbation',50));
      writeout( RPAD('--',35)||RPAD('--------',35)||RPAD('------------------',50));

      FOR i IN g_tab_approb.first..g_tab_approb.last LOOP
        l_message := RPAD(NVL(g_tab_approb(i).uo,' '),35,' ')||RPAD(NVL(g_tab_approb(i).commande,' '),35,' ')||RPAD(NVL(g_tab_approb(i).statut,' '),50,' ');
        writeout(l_message);
		  END LOOP;
    ELSE
      writeout('Toutes les commandes IVALUA sont approuvées');
    END IF;
    writeout('                                                                          ');
    writeout('                                                                          ');
  END SORTIE_TRAITEMENT;


   /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie(p_recyclage IN VARCHAR2) IS

  l_procedure                  VARCHAR2(30) := 'entete_de_sortie';
  l_message                    VARCHAR2(2000);

  BEGIN
    writeout('+-------------------------------------------------------------------------+');
    writeout('COMPTE-RENDU DU TRAITEMENT « DKA : Import des commandes depuis iValua »');
    writeout('Traitement n° : '||g_request_id);
    writeout('Programme lancé le : '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('PARAMETRES : ');
    writeout('------------');
    writeout('Recyclage seulement : '||p_recyclage);
    writeout('                                                                           ');
    writeout('                                                                           ');
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
  -- Procedure         : PURGE_TABLE
  -- Description       : Procédure pour purger les tables de tarvail
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 21/05/2020
  -- Remarques         :
/*=================================================================================*/
PROCEDURE PURGE_TABLE (p_request_id IN NUMBER) IS
BEGIN
    DELETE FROM DKA_IPOCDE_HEADERS WHERE LOADER_REQUEST_ID = p_request_id;
    DELETE FROM DKA_IPOCDE_HIST_HEADERS WHERE LOADER_REQUEST_ID = p_request_id;
    DELETE FROM DKA_IPOCDE_REPORTING_HEADERS WHERE LOADER_REQUEST_ID = p_request_id;
    DELETE FROM  DKA_IPOCDE_LINES WHERE LOADER_REQUEST_ID = p_request_id;
    DELETE FROM  DKA_IPOCDE_HIST_LINES WHERE LOADER_REQUEST_ID = p_request_id;
    DELETE FROM  DKA_IPOCDE_REPORTING_LINES WHERE LOADER_REQUEST_ID = p_request_id ;
	COMMIT;
END PURGE_TABLE;
  /*==============================================================================*/
  -- Procedure         : UPDATE_RECORD
  -- Description       : Procédure pour MAJ les tables de tarvail après chargement
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 04/06/2020
  -- Remarques         :
/*=================================================================================*/
PROCEDURE UPDATE_RECORD (pv_errbuf  IN OUT VARCHAR2,
                         pn_retcode OUT NUMBER,
                         p_request_id IN NUMBER )IS

  cursor cur_entete IS (SELECT * FROM DKA_IPOCDE_HEADERS
                        WHERE LOADER_REQUEST_ID = p_request_id);
  cursor cur_ligne  IS (SELECT * FROM DKA_IPOCDE_LINES
                        WHERE LOADER_REQUEST_ID = p_request_id);
  v_record_id DKA_IPOCDE_LINES.record_id%TYPE;
  v_unicite_entete              NUMBER;
  v_unicite_ligne               NUMBER;
  l_message                     VARCHAR2(2000);
  v_unicite_KO                NUMBER := 0;
  BEGIN
		FOR rec_entete in cur_entete LOOP
      DKA_TOOLS_PKG.put_log_message('entree à la boucle pour update record_id TOOLS');

		  UPDATE DKA_IPOCDE_REPORTING_HEADERS
		  SET    record_id = rec_entete.record_id
      ,      request_id = g_request_id
		  WHERE LOADER_REQUEST_ID = p_request_id
		  AND   line_num = rec_entete.line_num   ;

		  UPDATE DKA_IPOCDE_HIST_HEADERS
		  SET    record_id = rec_entete.record_id
      ,      request_id = g_request_id
		  WHERE LOADER_REQUEST_ID = p_request_id
		  AND  line_num = rec_entete.line_num  ;

		  BEGIN
		    SELECT count(*)
        INTO  v_unicite_entete
        FROM 	DKA_IPOCDE_HEADERS
        WHERE LOADER_REQUEST_ID = p_request_id
			  AND   po_number         = rec_entete.po_number       ;
		  END;

		  IF v_unicite_entete > 1 THEN
        g_doublons := g_doublons + 1;
        g_tab_doublons(g_doublons).po_number       := rec_entete.po_number;
        g_tab_doublons(g_doublons).ivalua_line_id := NULL;
        g_tab_doublons(g_doublons).nom_table      := 'DKA_IPOCDE_HEADERS';
        v_unicite_KO := 1;

		  END IF;
      commit;
		END LOOP;

    FOR rec_donne_ligne in cur_ligne LOOP

			UPDATE DKA_IPOCDE_REPORTING_LINES
			SET    record_id = rec_donne_ligne.record_id
      ,      request_id = g_request_id
			WHERE LOADER_REQUEST_ID = p_request_id
			AND   line_num = rec_donne_ligne.line_num ;

			UPDATE DKA_IPOCDE_HIST_LINES
			SET    record_id = rec_donne_ligne.record_id
      ,      request_id = g_request_id
			WHERE  LOADER_REQUEST_ID = p_request_id
			AND   line_num = rec_donne_ligne.line_num ;

			BEGIN
			  SELECT count(*)
        INTO  v_unicite_ligne
        FROM 	DKA_IPOCDE_LINES
        WHERE LOADER_REQUEST_ID = p_request_id
		    AND   po_number  = rec_donne_ligne.po_number
              AND ivalua_line_id = rec_donne_ligne.ivalua_line_id	 ;
			END;

			IF v_unicite_ligne > 1 THEN
        g_doublons := g_doublons + 1;
        g_tab_doublons(g_doublons).po_number       := rec_donne_ligne.po_number;
        g_tab_doublons(g_doublons).ivalua_line_id  := rec_donne_ligne.ivalua_line_id;
        g_tab_doublons(g_doublons).nom_table       := 'DKA_IPOCDE_LINES';
        v_unicite_KO := 1;

			END IF;
		END LOOP;
    --DKA_TOOLS_PKG.put_log_message(v_flag_unicite);
    IF  v_unicite_KO != 0 THEN
      purge_table(p_request_id);
      pn_retcode := 2;
    END IF;
  END UPDATE_RECORD;
  /*==============================================================================*/
  -- Procedure         : init
  --  Description   : Procédure d'initialisation
  --  PARAMETRES :
  --    pv_errbuf   Entrée/Sortie          message d'erreur
  --    VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
/*=================================================================================*/
  PROCEDURE init (pv_errbuf    IN OUT   VARCHAR2,
                  pn_retcode   OUT      NUMBER
                  )
    IS
        rec_param   dka_parameters%ROWTYPE;
        vv_category fnd_document_categories.name%TYPE;

    BEGIN
        dka_tools_pkg.put_debug_message ('(+) Init');
        pv_errbuf     := NULL;
        pn_retcode    := 0;

        -- Variables liées à la création du document joint
        Dka_Tools_Pkg.get_parameter ('SPOBON', 'DESCRIPTION', rec_param, pv_errbuf, pn_retcode);
        gv_description                   := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Paramètre DESCRIPTION : ' || pv_errbuf;
            RETURN;
        ELSIF gv_description IS NULL
        THEN
            pv_errbuf    := 'Paramètre DESCRIPTION : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gv_description : ' || gv_description);

        Dka_Tools_Pkg.get_parameter ('SPOBON', 'CATEGORY', rec_param, pv_errbuf, pn_retcode);
        vv_category                  := rec_param.varchar2_value;

        IF pn_retcode != 0
        THEN
            pv_errbuf    := 'Paramètre CATEGORY : ' || pv_errbuf;
            RETURN;
        ELSIF vv_category IS NULL
        THEN
            pv_errbuf    := 'Paramètre CATEGORY : Aucune donnée trouvée';
            pn_retcode   := 2;
            RETURN;
        END IF;

        -- Récupération de l'id correspondant à la categorie de document
        SELECT category_id
        INTO gn_category_id
        FROM fnd_document_categories
        WHERE name = vv_category;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_category_id : ' || gn_category_id);


        -- Récupération de l'id correspondant à la categorie de document
        SELECT category_id
        INTO   gn_default_value1
        FROM mtl_categories_kfv
       WHERE concatenated_segments ='99.99.99.01';

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_default_value1 : ' || gn_default_value1);


        -- Récupération de l'id correspondant à la categorie de document
        SELECT category_id
        INTO   gn_default_value2
        FROM mtl_categories_kfv
       WHERE concatenated_segments ='99.99.99.02';

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_default_value2 : ' || gn_default_value2);
        -- Récupération de l'id correspondant au type de document
        SELECT distinct datatype_id
        INTO gn_datatype_id
        FROM fnd_document_datatypes
        WHERE name = gv_datatype_name;

        Dka_Tools_Pkg.put_debug_message (CHR (10) || 'gn_datatype_id : ' || gn_datatype_id);

        -- Récupération de l'id du batch
        SELECT DKA_IPOCDE_BATCH_S.NEXTVAL
        INTO gn_batch_id
        FROM DUAL;

        dka_tools_pkg.put_debug_message ('(-) Init');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode   := 2;
            pv_errbuf    := 'INIT : ' ||SQLERRM;
    END init;
  /*==============================================================================*/
  -- Procedure         : LANCE_CHARGEMENT_FICHIER
  -- Description       : Procédure pour lancer le cahrgement des tables de tarvail
  -- Parametres entree : AUCUN
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 18/05/2020
  -- Remarques         :
/*=================================================================================*/
PROCEDURE LANCE_CHARGEMENT_FICHIER  (pv_errbuf  IN OUT VARCHAR2,
                                     pn_retcode OUT NUMBER
                                      ) IS

  l_procedure                   VARCHAR2(30) := 'LANCE_CHARGEMENT_FICHIER';
  l_message                     VARCHAR2(2000);
  l_request_id                  NUMBER;
  l_application_code            VARCHAR2(50) := 'DKA';
  l_conc_program                VARCHAR2(50) := 'DKA_IPOCDEIVALUA_LOADER';
  l_execute_code                BOOLEAN;
  l_req_interval                NUMBER := 30;
  l_req_max_wait                NUMBER := 999999;
  l_req_ret_code                NUMBER;
  l_req_phase                   VARCHAR2(255);
  l_req_status                  VARCHAR2(255);
  l_req_dev_phase               VARCHAR2(255);
  l_req_dev_status              VARCHAR2(255);
  l_status                      VARCHAR2(255);
  l_req_message                 VARCHAR2(255);
  v_unicite_entete              NUMBER;
  v_unicite_ligne               NUMBER;
  v_record_id DKA_IPOCDE_LINES.record_id%TYPE;
  vf_errbuf                     VARCHAR2(500);
  vf_retcode                    NUMBER;
  --- ARAOUF INC0580800 : pb de décimales sur fichiers
    vb_state						 BOOLEAN;
  BEGIN
    l_message := l_procedure || '- 01 - Debut';
    Fnd_File.put_line(Fnd_File.LOG, l_message);

    l_message := l_procedure || '- 02 - Submit Request';
    Fnd_File.put_line(Fnd_File.LOG, l_message);

	--- ARAOUF INC0580800 : pb de décimales sur fichiers
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
    IF g_tab_doublons.count > 0 THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_003');
	  pn_retcode := 2; -- SELO tracker50786 - INC0538812
      writeout(l_message);
      writeout('                                                    ');
      writeout('                                                    ');
      l_message := 'LA LISTES DES DOUBLONS:';
      writeout(l_message);
      writeout('-------------------------');
      writeout( RPAD('N° commande',35)||RPAD('id ligne IVALUA ',35)||RPAD('Table ',50));
      writeout( RPAD('-----------',35)||RPAD('----------------',35)||RPAD('----------------',50));
	    FOR i IN g_tab_doublons.first..g_tab_doublons.last LOOP
        l_message := RPAD(g_tab_doublons(i).po_number,35)||RPAD(NVL(g_tab_doublons(i).ivalua_line_id,' '),35)||RPAD(g_tab_doublons(i).nom_table,50);
        writeout(l_message);
	    END LOOP;
      writeout('                                                    ');
      writeout('                                                    ');
    END IF;
END LANCE_CHARGEMENT_FICHIER;
  /*============================================================================*/
 -- Procedure         : PURGE_DONNEE_TRAITEE
 -- Description       : préparer les donneés de la table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              : 21/05/2020
 -- Remarques         :
/*===============================================================================*/
PROCEDURE PURGE_DONNEE_TRAITEE(pv_errbuf  IN OUT VARCHAR2,
                               pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='PURGE_DONNEE_TRAITEE';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;

  BEGIN
	  DKA_TOOLS_PKG.put_log_message('Purge des enregistrements précédemment traités avec succès par l''interface des tables d''intefaces');

	  DELETE FROM PO_LINES_INTERFACE
	  WHERE interface_header_id IN (select phi.interface_header_id
	  							                from PO_HEADERS_INTERFACE phi,
	  							                	   DKA_IPOCDE_HEADERS dih
	  							                where dih.interface_header_id = phi.interface_header_id
	  							                --and    phi.PROCESS_CODE	 = 'ACCEPTED'
	  							                and    dih.STATUT ='COMPLETE');

	  DELETE FROM  PO_LINE_LOCATIONS_INTERFACE
   	WHERE interface_header_id IN (select phi.interface_header_id
								                  from PO_HEADERS_INTERFACE phi,
								                  	   DKA_IPOCDE_HEADERS dih
								                  where dih.interface_header_id = phi.interface_header_id
								                  --and    phi.PROCESS_CODE	 = 'ACCEPTED'
								                  and    dih.STATUT ='COMPLETE');

	  DELETE FROM PO_DISTRIBUTIONS_INTERFACE
	  WHERE interface_header_id IN (select phi.interface_header_id
	  							                from PO_HEADERS_INTERFACE phi,
	  							                	   DKA_IPOCDE_HEADERS dih
	  							                where dih.interface_header_id = phi.interface_header_id
	  							                --and    phi.PROCESS_CODE	 = 'ACCEPTED'
	  							                and    dih.STATUT ='COMPLETE');

	  DELETE FROM PO_INTERFACE_ERRORS
	  WHERE TABLE_NAME IN ('PO_HEADERS_INTERFACE','PO_LINES_INTERFACE','PO_LINE_LOCATIONS_INTERFACE','PO_DISTRIBUTIONS_INTERFACE')
	  AND   interface_header_id IN (select phi.interface_header_id
	  							                from PO_HEADERS_INTERFACE phi,
	  							                	   DKA_IPOCDE_HEADERS dih
	  							                where dih.interface_header_id = phi.interface_header_id
	  							                --and    phi.PROCESS_CODE	 = 'ACCEPTED'
	  							                and    dih.STATUT ='COMPLETE');

    DELETE FROM PO_HEADERS_INTERFACE
	  WHERE interface_header_id IN (select phi.interface_header_id
								                  from PO_HEADERS_INTERFACE phi,
								                  	   DKA_IPOCDE_HEADERS dih
								                  where dih.interface_header_id = phi.interface_header_id
								                  --and    phi.PROCESS_CODE	 = 'ACCEPTED'
								                  and    dih.STATUT ='COMPLETE');

    DKA_TOOLS_PKG.put_log_message('Purge des enregistrements précédemment traités avec succès par l''interface des tables spécifiques');
	DELETE FROM DKA_IPOCDE_LINES WHERE po_number IN (SELECT po_number
	                                                   FROM DKA_IPOCDE_HEADERS
													                           WHERE STATUT = 'COMPLETE');

    DELETE FROM DKA_IPOCDE_LINES WHERE STATUT = 'COMPLETE';

    DELETE FROM DKA_IPOCDE_HEADERS  WHERE STATUT = 'COMPLETE';


	-- EDB301 SELO
	DELETE FROM DKA_IPOCDE_LINES WHERE STATUT = 'WARNING';
	DELETE FROM DKA_IPOCDE_HEADERS  WHERE STATUT = 'WARNING';

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      v_message := 'ERROR lors de la préparation des données'||SQLERRM ;
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
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
 -- Auteur            : Asma AMENKOUR
 -- Date              : 21/05/2020
 -- Remarques         :
/*===============================================================================*/
PROCEDURE PREPARATION_DONNEE(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='PREPARATION_DONNEE';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;


  CURSOR donnee_a_recycler IS
  SELECT *
  FROM DKA_IPOCDE_HEADERS
  WHERE STATUT NOT IN ('NEW','COMPLETE');
  v_po_a_recycler  DKA_IPOCDE_HEADERS.po_number%type;

  BEGIN
  DKA_TOOLS_PKG.put_log_message('Nettoyage liées aux enregistrements en erreur dans les OI');
    DELETE FROM PO_LINES_INTERFACE
    WHERE interface_header_id IN (select phi.interface_header_id
                                  from PO_HEADERS_INTERFACE phi,
                                       DKA_IPOCDE_HEADERS dih
                                  where dih.interface_header_id = phi.interface_header_id
                                  and    phi.PROCESS_CODE	 = 'REJECTED');

    DELETE FROM  PO_LINE_LOCATIONS_INTERFACE
    WHERE interface_header_id IN (select phi.interface_header_id
                                  from PO_HEADERS_INTERFACE phi,
                                       DKA_IPOCDE_HEADERS dih
                                  where dih.interface_header_id = phi.interface_header_id
                                  and    phi.PROCESS_CODE	 = 'REJECTED');

    DELETE FROM PO_DISTRIBUTIONS_INTERFACE
    WHERE interface_header_id IN (select phi.interface_header_id
                                  from PO_HEADERS_INTERFACE phi,
                                       DKA_IPOCDE_HEADERS dih
                                  where dih.interface_header_id = phi.interface_header_id
                                  and    phi.PROCESS_CODE	 = 'REJECTED');
    DELETE FROM PO_INTERFACE_ERRORS
    WHERE TABLE_NAME IN ('PO_HEADERS_INTERFACE','PO_LINES_INTERFACE','PO_LINE_LOCATIONS_INTERFACE','PO_DISTRIBUTIONS_INTERFACE')
    AND   interface_header_id IN (select phi.interface_header_id
                                  from PO_HEADERS_INTERFACE phi,
                                  	   DKA_IPOCDE_HEADERS dih
                                  where dih.interface_header_id = phi.interface_header_id
                                  and    phi.PROCESS_CODE	 = 'REJECTED');

    DELETE FROM PO_HEADERS_INTERFACE
    WHERE interface_header_id IN (select phi.interface_header_id
                                  from PO_HEADERS_INTERFACE phi,
                                       DKA_IPOCDE_HEADERS dih
                                  where dih.interface_header_id = phi.interface_header_id
                                  and    phi.PROCESS_CODE	 = 'REJECTED');

    DKA_TOOLS_PKG.put_log_message('Recyclage des enregistrements remplacés par une nouvelle version');
    FOR rec_a_recycler IN donnee_a_recycler
    LOOP
      BEGIN
        SELECT po_number
        INTO   v_po_a_recycler
        FROM DKA_IPOCDE_HEADERS
        WHERE po_number = rec_a_recycler.po_number
        AND   STATUT = 'NEW';
      EXCEPTION
        WHEN OTHERS THEN
          v_po_a_recycler:= NULL;
      END;
      IF v_po_a_recycler IS NOT NULL
      THEN

        UPDATE DKA_IPOCDE_REPORTING_HEADERS
        SET STATUT ='DELETED'
        ,   LAST_UPDATE_DATE  = SYSDATE
        ,   LAST_UPDATED_BY    = g_user
        WHERE po_number = rec_a_recycler.po_number
        AND RECORD_ID = rec_a_recycler.RECORD_ID ;

        UPDATE DKA_IPOCDE_REPORTING_LINES
        SET STATUT ='DELETED'
        ,   LAST_UPDATE_DATE  = SYSDATE
        ,   LAST_UPDATED_BY    = g_user
        WHERE po_number = rec_a_recycler.po_number
        AND RECORD_ID IN (SELECT RECORD_ID
                          FROM DKA_IPOCDE_LINES
                          WHERE po_number = rec_a_recycler.po_number
                          AND   STATUT != 'NEW');

        DELETE FROM DKA_IPOCDE_LINES
        WHERE  po_number = rec_a_recycler.po_number
        AND   STATUT != 'NEW'; -- STATUT IN ('REJECTED','PROCESSING_ERROR');

        DELETE FROM DKA_IPOCDE_HEADERS
        WHERE po_number = rec_a_recycler.po_number
        AND   STATUT != 'NEW';-- STATUT IN ('REJECTED','PROCESSING_ERROR');


       END IF;

	  END LOOP;


    DKA_TOOLS_PKG.put_log_message('Nettoyage liées aux enregistrements en erreur');
    DELETE FROM DKA_PROGRAM_MESSAGES
    WHERE PROG_NAME  = 'DKA_IPOCMD_IVALUA'
    AND   request_id != g_request_id;

    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      v_message := 'ERROR lors de la préparation des données'||SQLERRM ;
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCMD_IVALUA'
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
 -- Auteur            : Asma AMENKOUR
 -- Date              :
 -- Remarques         :
/*===============================================================================*/
  PROCEDURE MAJ_DONNEE_ATRAITEE(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='MAJ_DONNEE_ATRAITEE';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;


  BEGIN
    SELECT COUNT(*)
	  INTO   g_enreg_a_traite_entete
	  FROM   DKA_IPOCDE_HEADERS;

    SELECT COUNT(*)
	  INTO   g_enreg_a_traite_lineT
	  FROM   DKA_IPOCDE_LINES;

    UPDATE DKA_IPOCDE_HEADERS
    SET    request_id = g_request_id;

    UPDATE DKA_IPOCDE_LINES
    SET    request_id = g_request_id;


  END MAJ_DONNEE_ATRAITEE;
  /*============================================================================*/
 -- Fonction          : IS_LIGNE_DE_FRAIS
 -- Description       : déterminer si la ligne de commande est ligne article ou
 --                     note de frais
 -- Parametres entree : p_type_ligne_ivalua
 -- Parametres sortie : Y/N
 -- Auteur            : Asma AMENKOUR
 -- Date              : 22/05/2020
 -- Remarques         :
/*===============================================================================*/
FUNCTION IS_LIGNE_DE_FRAIS(p_type_ligne_ivalua IN VARCHAR2) return varchar2 IS
  v_return_value DKA_STRANSCO_LINES.RETURN_VALUE%TYPE;
  v_is_frais     VARCHAR2(2);
  BEGIN
    BEGIN
      SELECT  DSTL.RETURN_VALUE
      INTO    v_return_value
      FROM   DKA_STRANSCO_LINES DSTL
      ,      DKA_STRANSCO_HEADERS DSTH
      WHERE  DSTL.SET_ID = DSTH.SET_ID
      AND  DSTH.SET_NAME ='DKA_IVALUA_TYPE_LIGNE'
      AND  PARAMS_VALUE = (p_type_ligne_ivalua);
    EXCEPTION
      WHEN OTHERS THEN
        v_return_value := NULL;
    END;
      IF  v_return_value = 'FRAIS' THEN
        v_is_frais := 'Y';
      ELSE
        v_is_frais := 'N';
      END IF;

     RETURN v_is_frais;
  END IS_LIGNE_DE_FRAIS;
  /*============================================================================*/
 -- Procedure         : DETERMINATION_ACTION
 -- Description       : déterminer les action à effectuer sur chaque donnee de la
 --                     table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              : 21/05/2020
 -- Remarques         :
/*===============================================================================*/
PROCEDURE DETERMINATION_ACTION(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

 v_procedure            VARCHAR2(30):='DETERMINATION_ACTION';
 v_etape                VARCHAR2(500);
 v_message              VARCHAR2(500) := null;

 v_ITEM_DESCRIPTION      PO_LINES_ALL.ITEM_DESCRIPTION%TYPE;
 v_UNIT_PRICE            PO_LINES_ALL.UNIT_PRICE%TYPE;
 v_PRICE_UNIT            PO_LINES_ALL.UNIT_PRICE%TYPE;
 v_attribute5            PO_LINES_ALL.attribute5%TYPE;
 v_need_by_date          po_line_locations_All.need_by_date%TYPE;
 v_quantity              po_line_locations_All.QUANTITY%TYPE;

 v_IVALUA_LINE_ID         DKA_IPOCDE_LINES.IVALUA_LINE_ID%TYPE;
 v_LINE_DESCRIPTION       DKA_IPOCDE_LINES.LINE_DESCRIPTION%TYPE;
 v_PRICE                  DKA_IPOCDE_LINES.PRICE%TYPE;
 v_PRIX_UNI               DKA_IPOCDE_LINES.PRICE%TYPE;
 v_quantite               DKA_IPOCDE_LINES.QUANTITY%TYPE;
 v_DELIVERY_DATE          DKA_IPOCDE_LINES.DELIVERY_DATE%TYPE;
 v_EXPENSE_TYPE           DKA_IPOCDE_LINES.EXPENSE_TYPE%TYPE;
 v_CATEGORY               DKA_IPOCDE_LINES.CATEGORY%TYPE;
 v_type_depense           po_distributions_all.EXPENDITURE_TYPE%TYPE;
 v_line_existe            PO_LINES_ALL.po_line_id%TYPE;
 v_CLOSED_CODE            po_headers_all.CLOSED_CODE%TYPE;
 v_CANCEL_FLAG            po_headers_all.CANCEL_FLAG%TYPE;
 v_line_to_cancel         NUMBER;
 v_ligne_ignoree        NUMBER;

 CURSOR c_donne_ligne_maj(p_po_number VARCHAR2) IS
 SELECT * FROM DKA_IPOCDE_LINES WHERE po_number = p_po_number
 FOR UPDATE;

  BEGIN
    v_etape := 'Mise à jour entête de la commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);

  --CREATION ENTTETE
    UPDATE DKA_IPOCDE_HEADERS
  	SET HEADER_ACTION = 'CREATE'
  	,   LAST_UPDATE_DATE  = SYSDATE
  	,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
  	WHERE po_number NOT IN (SELECT segment1 FROM po_headers_all)
    AND PO_STATUS = 'val';

  --MISE A JOUR ENTTETE
    UPDATE DKA_IPOCDE_HEADERS
  	SET  HEADER_ACTION = 'UPDATE'
    ,   LAST_UPDATE_DATE  = SYSDATE
  	,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
  	WHERE po_number  IN (SELECT segment1 FROM po_headers_all)
  	AND  AMENDMENT_NUMBER is not null
    AND PO_STATUS = 'val';

  --ANNULATION ENTTETE
    UPDATE DKA_IPOCDE_HEADERS
  	SET HEADER_ACTION = 'CANCEL'
  	,   LAST_UPDATE_DATE  = SYSDATE
  	,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
  	WHERE po_number  IN (SELECT segment1 FROM po_headers_all where  NVL(CANCEL_FLAG,'N') = 'N')
  	--AND  AMENDMENT_NUMBER is not null
    AND PO_STATUS = 'can';

  --DEBUT SHA-EDB310

  --CREATION_ANNULATION
  UPDATE DKA_IPOCDE_HEADERS
  	SET HEADER_ACTION = 'CREATE_CANCEL'
  	,   LAST_UPDATE_DATE  = SYSDATE
  	,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
  	WHERE po_number  NOT IN (SELECT segment1 FROM po_headers_all )
    AND PO_STATUS = 'can';

  --fin SHA-EDB310

  --PAS D'ACTION ENTTETE
  	UPDATE DKA_IPOCDE_HEADERS
  	SET HEADER_ACTION = 'IGNORED'
    ,   STATUT        = 'COMPLETE'
  	,   LAST_UPDATE_DATE  = SYSDATE
  	,   LAST_UPDATED_BY    = g_user
    ,   request_id         = g_request_id
  	WHERE  PO_STATUS = 'can'
  	AND  -- (po_number  NOT IN (SELECT segment1 FROM po_headers_all)
  	   -- OR --SHA-EDB310
	  po_number  IN (SELECT segment1 FROM po_headers_all where CANCEL_FLAG = 'Y') ;
	  --);SHA-EDB310
    COMMIT; --(commit pour les maj des entêtes pour qu'on puisse se baser sur ces modifications pour la maj des lignes)

  	v_etape := 'Mise à jour les lignes de la commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);
  --MISE A JOUR DES LIGNES (SI LE CHAMP HEADER_ACTION = 'IGNORED')
    FOR rec_entete_ignore IN (SELECT * FROM DKA_IPOCDE_HEADERS WHERE HEADER_ACTION = 'IGNORED' AND STATUT = 'COMPLETE') LOOP
      UPDATE DKA_IPOCDE_LINES
      SET STATUT = 'COMPLETE'
      ,   LAST_UPDATE_DATE  = SYSDATE
  	  ,   LAST_UPDATED_BY    = g_user
      ,   request_id         = g_request_id
      WHERE po_number        = rec_entete_ignore.po_number;
    END LOOP;
  --MISE A JOUR DES LIGNES (SI LE CHAMP HEADER_ACTION = 'UPDATE')
    FOR rec_entete_maj IN (SELECT * FROM  DKA_IPOCDE_HEADERS WHERE HEADER_ACTION = 'UPDATE') LOOP
  	  BEGIN
  	    SELECT count(po_line_id)
  	    INTO   v_line_to_cancel
  	    FROM   PO_LINES_ALL pla
        ,      po_headers_all pha
        WHERE pla.attribute8 NOT IN (SELECT ivalua_line_id FROM DKA_IPOCDE_LINES WHERE po_number=rec_entete_maj.po_number)
  	    AND   pla.po_header_id = pha.po_header_id
        AND   pha.segment1    =  rec_entete_maj.po_number
        AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
        AND   pla.CANCEL_FLAG= 'N';
  	  EXCEPTION
  	    WHEN NO_DATA_FOUND THEN
  		  v_line_to_cancel := 0;
  	  END;

  	  IF v_line_to_cancel > 0 THEN
  	    UPDATE DKA_IPOCDE_HEADERS
  		  SET   LINE_TO_CANCEL  ='Y'
        ,   LAST_UPDATE_DATE  = SYSDATE
  	    ,   LAST_UPDATED_BY    = g_user
        ,   request_id         = g_request_id
  		  WHERE po_number=rec_entete_maj.po_number;
  	  END IF ;

  	  FOR  rec_donne_ligne_maj IN c_donne_ligne_maj(rec_entete_maj.po_number)LOOP

        DKA_TOOLS_PKG.put_log_message('cmd :'||rec_entete_maj.po_number);
        DKA_TOOLS_PKG.put_log_message('line_id :'||rec_donne_ligne_maj.ivalua_line_id );

  	    IF IS_LIGNE_DE_FRAIS(rec_donne_ligne_maj.IVALUA_LINE_TYPE) = 'Y' THEN
          v_ligne_ignoree := 0;
  	      BEGIN
  		      SELECT count(po_line_id)
  		      INTO   v_line_existe
  		      FROM   PO_LINES_ALL
  		      WHERE  attribute8 = rec_donne_ligne_maj.ivalua_line_id;
  		    EXCEPTION
            WHEN NO_DATA_FOUND THEN
              v_line_existe := 0;
  		    END ;
          IF v_line_existe = 0 THEN
           --AJOUT LIGNE
              UPDATE DKA_IPOCDE_LINES
              SET LINE_ACTION = 'ADD'
              ,   TYPE_LINE   = 'FRAIS'
              ,   LAST_UPDATE_DATE  = SYSDATE
  	          ,   LAST_UPDATED_BY    = g_user
              WHERE CURRENT OF c_donne_ligne_maj;
              v_ligne_ignoree := 1;
          END IF;


          --MAJ LIGNE
          IF (rec_donne_ligne_maj.UPDATED  = 'Y' and v_line_existe <> 0) -- SELO : artf07455147 INC0536669
		  THEN
            UPDATE DKA_IPOCDE_LINES
            SET LINE_ACTION = 'UPDATE'
            ,   TYPE_LINE   = 'FRAIS'
  			    ,   LAST_UPDATE_DATE  = SYSDATE
  	        ,   LAST_UPDATED_BY    = g_user
            WHERE CURRENT OF c_donne_ligne_maj;
            v_ligne_ignoree := 1;
          ELSE
            BEGIN
  	          SELECT LINE_DESCRIPTION,PRICE,EXPENSE_TYPE,CATEGORY
  		        INTO v_LINE_DESCRIPTION
  		        ,    v_PRICE
  		        ,    v_EXPENSE_TYPE
  		        ,    v_CATEGORY
  		        FROM  DKA_IPOCDE_LINES
  		        WHERE IVALUA_LINE_ID = rec_donne_ligne_maj.ivalua_line_id
  		        ;
  	        EXCEPTION
  	          WHEN OTHERS THEN
  		          v_LINE_DESCRIPTION     :=NULL;
  		          v_PRICE                :=NULL;
  		          v_EXPENSE_TYPE         :=NULL;
  		          v_CATEGORY 		         :=NULL;
  	        END;
  	        BEGIN
              SELECT pla.ITEM_DESCRIPTION
              ,      pla.UNIT_PRICE
              ,      pla.attribute5
              ,      pda.EXPENDITURE_TYPE
              INTO   v_ITEM_DESCRIPTION
              ,      v_UNIT_PRICE
              ,      v_attribute5
              ,      v_type_depense
              FROM  PO_LINES_ALL pla
              ,     po_line_locations_All plla
              ,     PO_DISTRIBUTIONS_ALL pda
              WHERE 1=1
              AND pla.po_line_id        = plla.po_line_id
              AND plla.line_location_id = pda.line_location_id
  		        AND pla.attribute8        = rec_donne_ligne_maj.ivalua_line_id;
            EXCEPTION
  	          WHEN OTHERS THEN
  		          v_ITEM_DESCRIPTION   := NULL;
                v_UNIT_PRICE        := NULL;
                v_attribute5         := NULL;
                v_type_depense       := NULL;
  	        END;

  	        IF   ((v_ITEM_DESCRIPTION   != v_LINE_DESCRIPTION)
                 OR (v_UNIT_PRICE       != v_PRICE)
                 OR (v_attribute5       != v_CATEGORY)
                 OR (v_type_depense     != v_EXPENSE_TYPE)) THEN
              DKA_TOOLS_PKG.put_log_message('difference des champs');
  	          UPDATE DKA_IPOCDE_LINES
              SET LINE_ACTION = 'UPDATE'
              ,   TYPE_LINE   = 'FRAIS'
  			      ,   LAST_UPDATE_DATE  = SYSDATE
  	          ,   LAST_UPDATED_BY    = g_user
              WHERE CURRENT OF c_donne_ligne_maj;
              v_ligne_ignoree := 1;

  	        END IF ;
  		    END IF ;

          IF v_ligne_ignoree = 0 THEN
            UPDATE DKA_IPOCDE_LINES
            SET LINE_ACTION = 'IGNORED'
            ,   TYPE_LINE   = 'FRAIS'--'ARTICLE'
            ,   STATUT = 'PROCESSING_SUCCESS'
  		      ,   LAST_UPDATE_DATE  = SYSDATE
  	        ,   LAST_UPDATED_BY    = g_user
            ,   request_id         = g_request_id
            WHERE CURRENT OF c_donne_ligne_maj;
          END IF;

  		  ELSE -- s'il s'agit d'une ligne d'article
          DKA_TOOLS_PKG.put_log_message('LIGNE article');
		  -- SHA CR76
		  BEGIN
  	          SELECT QUANTITY,PRICE
  		        INTO v_QUANTITE
  		        ,    v_PRIX_UNI
  		        FROM  DKA_IPOCDE_LINES
  		        WHERE IVALUA_LINE_ID = rec_donne_ligne_maj.ivalua_line_id
  		        ;
  	        EXCEPTION
  	          WHEN OTHERS THEN
  		          v_QUANTITE     :=NULL;
  		          v_PRIX_UNI        :=NULL;
  	        END;
		   BEGIN
              SELECT pla.QUANTITY
              ,      pla.UNIT_PRICE
              INTO   v_quantity
              ,      v_PRICE_UNIT
              FROM  PO_LINES_ALL pla
              WHERE 1=1
              AND pla.attribute8        = rec_donne_ligne_maj.ivalua_line_id;
            EXCEPTION
  	          WHEN OTHERS THEN
  		        v_quantity          := NULL;
                v_PRICE_UNIT        := NULL;

  	        END;
		    IF   ((v_quantity           != v_QUANTITE)
                 OR (v_PRICE_UNIT       != v_PRIX_UNI)
                 ) THEN
              DKA_TOOLS_PKG.put_log_message('difference des champs');
  	          UPDATE DKA_IPOCDE_LINES
              SET LINE_ACTION = 'UPDATE'
              ,   TYPE_LINE   = 'ARTICLE'
  			  ,   LAST_UPDATE_DATE  = SYSDATE
  	          ,   LAST_UPDATED_BY    = g_user
              WHERE CURRENT OF c_donne_ligne_maj;
              v_ligne_ignoree := 1;
		    END IF ;
			--Fin SHA CR76
		IF v_ligne_ignoree = 0 THEN
          UPDATE DKA_IPOCDE_LINES
          SET LINE_ACTION = 'IGNORED'
          ,   TYPE_LINE   = 'ARTICLE'
          ,   STATUT = 'PROCESSING_SUCCESS'
  		    ,   LAST_UPDATE_DATE  = SYSDATE
  	      ,   LAST_UPDATED_BY    = g_user
          ,   request_id         = g_request_id
          WHERE CURRENT OF c_donne_ligne_maj;
		  END IF;
  	    END IF ;

      END LOOP;-- end loop rec_donne_ligne_maj
    END LOOP; -- end loop rec_entete_maj
    COMMIT;
    --
    BEGIN
      SELECT count(*)
      INTO g_enreg_ignore
      FROM  DKA_IPOCDE_LINES
      WHERE LINE_ACTION = 'IGNORED'
      AND   STATUT = 'PROCESSING_SUCCESS';
    END;
    BEGIN
      SELECT count(*)
      INTO  g_entete_ignore
      FROM  DKA_IPOCDE_HEADERS
      WHERE HEADER_ACTION = 'IGNORED'
      AND   STATUT        = 'COMPLETE';
    END;
     BEGIN
      SELECT count(*)
      INTO  g_line_complete
      FROM  DKA_IPOCDE_LINES
      WHERE 1=1 --LINE_ACTION IS NULL
      AND   STATUT = 'COMPELTE';
    END;

  END DETERMINATION_ACTION;
  /*============================================================================*/
 -- Procedure         : VALIDATION_DONNEES
 -- Description       : valider les données de la table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              : 22/05/2020
 -- Remarques         :
/*===============================================================================*/
PROCEDURE VALIDATION_DONNEES(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

  CURSOR C_DONNEE_ENTETE IS
  SELECT * FROM DKA_IPOCDE_HEADERS WHERE STATUT IN ('NEW','REJECTED','PROCESSING_ERROR','PROCESSING_ERROR_CAN')--SHA-EDB310
  FOR UPDATE;

  CURSOR C_DONNEE_LIGNE(p_cmd VARCHAR2) IS
  SELECT * FROM DKA_IPOCDE_LINES
  WHERE STATUT IN('NEW','REJECTED')
  AND   po_number = p_cmd
  FOR UPDATE;

  CURSOR C_LIGNE_ORPHELINE IS
  SELECT *
  FROM   DKA_IPOCDE_LINES dil
  WHERE   not exists (select 1 from DKA_IPOCDE_HEADERS where po_number = dil.po_number)
   -- AND    request_id = :g_request_id
  AND   STATUT IN ('NEW','REJECTED')
  FOR UPDATE;


  v_procedure             VARCHAR2(30):='VALIDATION_DONNEES';
  v_etape                 VARCHAR2(500);
  v_message               VARCHAR2(500) := null;
  l_message               VARCHAR2(2000);
  v_id_cmd                PO_LINES_ALL.po_header_id%TYPE;
  v_exist_ligne           NUMBER;
  v_exist_entete          NUMBER;
  v_uo_exist              NUMBER;
  v_num_cmd               po_headers_all.segment1%TYPE;
  v_end_date_active       AP_SUPPLIERS.END_DATE_ACTIVE%TYPE;
  v_supp_exist            NUMBER;
  v_vendor_site_id        AP_SUPPLIER_SITES_ALL.vendor_site_id%TYPE;
  v_inactive_date         AP_SUPPLIER_SITES_ALL.inactive_date%TYPE;
  v_purchasing_site_flag  AP_SUPPLIER_SITES_ALL.purchasing_site_flag%TYPE;
  v_CURRENCY_CODE         gl_ledgers.currency_code%TYPE;
  v_entite_comptable      gl_ledgers.name%TYPE;
  v_person_id             per_people_f.person_id%TYPE;
  v_effective_end_date    per_people_f.effective_end_date%TYPE;
  v_effective_start_date  per_people_f.effective_start_date%TYPE;
  v_acheteur              po_agents.agent_id%TYPE:= NULL;
  v_start_date_agent      po_agents.start_date_active%TYPE;
  v_end_date_agent        po_agents.end_date_active%TYPE;
  v_UOM_CODE		          po_units_of_measure_val_v.UOM_CODE%TYPE;
  v_task_id               pa_tasks.task_id%TYPE;
  v_t_start_date          pa_tasks.start_date%TYPE;
  v_t_completion_date     pa_tasks.completion_date%TYPE;
  v_expenditure_item_id   pa_expenditure_items_all.expenditure_item_id%TYPE;
  v_flag_erreur_entete    BOOLEAN;
  v_flag_warning_entete   BOOLEAN;
  v_flag_erreur_lines     BOOLEAN;
  v_flag_erreur_entete_cancel BOOLEAN;
  l_buyer_rowid           VARCHAR2 (100);
  v_emp_actif             NUMBER;
  v_type_existe           NUMBER;
  v_expenditure_existe    NUMBER;
  v_end_date_expend       PA_EXPENDITURE_TYPES.end_date_active%TYPE;
  v_start_date_expend     PA_EXPENDITURE_TYPES.start_date_active%TYPE;
  v_autorise_po           PA_EXPENDITURE_TYPES.attribute3%TYPE;
  v_depense_pr_task       NUMBER;
  v_uo                    hr_operating_units.name%TYPE;
  v_frns                  ap_suppliers.segment1%TYPE;
  v_vendor_id             ap_suppliers.vendor_id%TYPE;
  v_site_frns             ap_supplier_sites_all.vendor_site_code%TYPE;
  v_devise			      po_headers_all.CURRENCY_CODE%TYPE;
  v_CLOSED_CODE           po_headers_all.CLOSED_CODE%TYPE;
  v_CANCEL_FLAG           po_headers_all.CANCEL_FLAG%TYPE;
  v_AUTHORIZATION_STATUS  po_headers_all.AUTHORIZATION_STATUS%TYPE;
  v_QUANTITY_BILLED       po_line_locations_All.QUANTITY_BILLED%TYPE;
  v_code_projet           pa_projects_all.name%TYPE := NULL;
  v_qt_recptionnee        po_line_locations_All.QUANTITY_RECEIVED%TYPE;
  v_QUANTITY_RECEIVED     po_line_locations_All.QUANTITY_RECEIVED%TYPE;
  v_qt_facturee           po_line_locations_All.QUANTITY_BILLED%TYPE;
  v_statut_cmd            po_headers_all.AUTHORIZATION_STATUS%TYPE;


BEGIN
    FOR rec_donnee_entete IN C_DONNEE_ENTETE  LOOP
     -- g_enreg_a_traite_entete := g_enreg_a_traite_entete + 1;
	    v_flag_erreur_entete := FALSE;
      v_etape:= 'contrôle Unité opérationnelle';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      DKA_TOOLS_PKG.put_log_message('debut boucle cmd n°:'||rec_donnee_entete.po_number);

	  IF rec_donnee_entete.UO IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_VT01');
		  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'UO' --pv_column_name
		                                 ,rec_donnee_entete.UO --pv_column_value
		                                 ,'E'
		                                 ,l_message
				                            );
		  DKA_TOOLS_PKG.put_log_message(l_message);
		  v_flag_erreur_entete := TRUE;
	  ELSE
      BEGIN
		    SELECT count(*)
        INTO v_uo_exist
        FROM per_security_organizations_v pso
        ,    hr_organization_units hou
        WHERE pso.security_profile_id = fnd_profile.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
        AND   pso.organization_id     = hou.organization_id
        AND   hou.name                = rec_donnee_entete.UO;
      END ;
      IF v_uo_exist = 0 THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT02','UO',rec_donnee_entete.UO);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'UO' --pv_column_name
		                                 ,rec_donnee_entete.UO --pv_column_value
		                                 ,'E'
		                                 ,l_message
				                     );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
      END IF;
    END IF ;

	  v_etape:= 'Contrôle Numéro de commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);

	  IF rec_donnee_entete.po_number IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT03');
		  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'po_number' --pv_column_name
		                                 ,rec_donnee_entete.po_number --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		  DKA_TOOLS_PKG.put_log_message(l_message);
		  v_flag_erreur_entete := TRUE;
	  END IF;

	  v_etape:= 'Contrôle Statut de la commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);

	  IF rec_donnee_entete.PO_STATUS  IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT04');
		  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'PO_STATUS' --pv_column_name
		                                 ,rec_donnee_entete.PO_STATUS --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		  DKA_TOOLS_PKG.put_log_message(l_message);
		  v_flag_erreur_entete := TRUE;
	  ELSIF rec_donnee_entete.PO_STATUS NOT IN ('val','can') THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT05','STATUT',rec_donnee_entete.PO_STATUS);
		  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'PO_STATUS' --pv_column_name
		                                 ,rec_donnee_entete.PO_STATUS --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                          );
		  DKA_TOOLS_PKG.put_log_message(l_message);
		  v_flag_erreur_entete := TRUE;
	  END IF;

	  v_etape:= 'Contrôle Lien vers l''image du bon de commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);

	  IF rec_donnee_entete.URL_BDC   IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT06');
		  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'URL_BDC' --pv_column_name
		                                 ,rec_donnee_entete.URL_BDC --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                          );
		  DKA_TOOLS_PKG.put_log_message(l_message);
		  v_flag_erreur_entete := TRUE;
	  END IF ;

	  v_etape:= 'Contrôle de l''existence de lignes de commande';
    DKA_TOOLS_PKG.put_log_message(v_etape);
	  BEGIN
	    SELECT count(*)
		  INTO   v_exist_ligne
		  FROM   DKA_IPOCDE_LINES
		  WHERE  po_number = rec_donnee_entete.po_number
		  AND    loader_request_id = rec_donnee_entete.loader_request_id;
	  END ;
    IF v_exist_ligne = 0 THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT13');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'po_number' --pv_column_name
		                                 ,rec_donnee_entete.po_number --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                            );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
    END IF ;

	  v_etape:= 'Contrôle de la détermination de l''action à effectuer';
    DKA_TOOLS_PKG.put_log_message(v_etape);


	  IF rec_donnee_entete.HEADER_ACTION IS NULL THEN
      l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT14');
		  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'HEADER_ACTION' --pv_column_name
		                                 ,rec_donnee_entete.HEADER_ACTION --pv_column_value
		                                 ,'W'
		                                 ,l_message
		  		                          );
		  DKA_TOOLS_PKG.put_log_message(l_message);
		--  v_flag_erreur_entete := TRUE; -- SELO EDB301
		  v_flag_warning_entete := TRUE;  -- SELO EDB301
    END IF;
    IF rec_donnee_entete.HEADER_ACTION in  ('CREATE','CREATE_CANCEL') THEN -- SHA-EDB310
	    v_etape:= 'contrôle Numéro du fournisseur';
      DKA_TOOLS_PKG.put_log_message(v_etape);

	    IF rec_donnee_entete.SUPPLIER_NUMBER  IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC01');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'SUPPLIER_NUMBER' --pv_column_name
		                                 ,rec_donnee_entete.SUPPLIER_NUMBER --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
	    ELSE
	      BEGIN
		      SELECT count(*)
		      ,      END_DATE_ACTIVE
          ,      vendor_id
		      INTO v_supp_exist
		      ,    v_end_date_active
          ,    v_vendor_id
		      FROM AP_SUPPLIERS
		      WHERE segment1 = rec_donnee_entete.SUPPLIER_NUMBER
          GROUP BY END_DATE_ACTIVE
          ,        vendor_id;
		    EXCEPTION
		      WHEN NO_DATA_FOUND THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC02','FRNS',rec_donnee_entete.SUPPLIER_NUMBER);
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_HEADERS'
		                                   , rec_donnee_entete.record_id
		                                   ,'SUPPLIER_NUMBER' --pv_column_name
		                                   ,rec_donnee_entete.SUPPLIER_NUMBER --pv_column_value
		                                   ,'E'
		                                   ,l_message
				                           );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_entete := TRUE;
		    END ;

		    IF nvl(v_end_date_active,SYSDATE) < SYSDATE-1 THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC03','FRNS',rec_donnee_entete.SUPPLIER_NUMBER);
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_HEADERS'
		                                   , rec_donnee_entete.record_id
		                                   ,'SUPPLIER_NUMBER' --pv_column_name
		                                   ,rec_donnee_entete.SUPPLIER_NUMBER --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                            );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_entete := TRUE;
		    END IF ;
	    END IF;

		  v_etape:= 'contrôle Site fournisseur';
      DKA_TOOLS_PKG.put_log_message(v_etape);
		  IF rec_donnee_entete.SITE_SUPPLIER_NAME IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC04');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'SITE_SUPPLIER_NAME' --pv_column_name
		                                 ,rec_donnee_entete.SITE_SUPPLIER_NAME --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
		  ELSE
        BEGIN
		      SELECT vendor_site_id
		  	  ,      inactive_date
		  	  ,      purchasing_site_flag
          INTO   v_vendor_site_id
		  	  ,      v_inactive_date
		  	  ,      v_purchasing_site_flag
		  	  FROM AP_SUPPLIER_SITES_ALL ass
          ,    hr_operating_units hou
		  	  WHERE vendor_site_code = rec_donnee_entete.SITE_SUPPLIER_NAME
          AND   ass.org_id = hou.organization_id
          AND   ass.vendor_id = v_vendor_id
          AND	  hou.name = rec_donnee_entete.UO;
        EXCEPTION
		      WHEN NO_DATA_FOUND THEN
          DKA_TOOLS_PKG.put_log_message('extraction vendor site via id site ivalua');
		  	  BEGIN
		  	    SELECT vendor_site_id
		  		  ,      NVL(inactive_date,sysdate)
		  		  ,      purchasing_site_flag
            INTO   v_vendor_site_id
		  		  ,      v_inactive_date
		  		  ,      v_purchasing_site_flag
		  		  FROM AP_SUPPLIER_SITES_ALL ass
                  ,    hr_operating_units hou
		  	    WHERE ass.attribute4 = rec_donnee_entete.IVALUA_SITE_SUPPLIER_ID
            AND   ass.org_id = hou.organization_id
            AND   ass.vendor_id = v_vendor_id
            AND	  hou.name = rec_donnee_entete.UO;
		  	  EXCEPTION
		  	    WHEN NO_DATA_FOUND THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC06','SITE_FRNS',rec_donnee_entete.SITE_SUPPLIER_NAME,'UO',rec_donnee_entete.UO,'FRNS',rec_donnee_entete.SUPPLIER_NUMBER);
		          DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                               ,'DKA_IPOCMD_IVALUA'
		                               ,'VALIDATION'
		                               ,'DKA_IPOCDE_HEADERS'
		                               , rec_donnee_entete.record_id
		                               ,'SITE_SUPPLIER_NAME' --pv_column_name
		                               ,rec_donnee_entete.SITE_SUPPLIER_NAME --pv_column_value
		                               ,'E'
		                               ,l_message
		  		                     );
		  		    DKA_TOOLS_PKG.put_log_message(l_message);
		  		    v_flag_erreur_entete := TRUE;
		  		  WHEN OTHERS THEN
		  		    v_vendor_site_id := NULL;
		  		    v_inactive_date  := NULL;
		  		    v_purchasing_site_flag := NULL;
		  	  END;
		  	WHEN OTHERS THEN
		  	  v_vendor_site_id := NULL;
		  	  v_inactive_date  := NULL;
		  	  v_purchasing_site_flag := NULL;
        END;
		  END IF ;
       DKA_TOOLS_PKG.put_log_message('rec_donnee_entete.SITE_SUPPLIER_NAME :'||rec_donnee_entete.SITE_SUPPLIER_NAME);
       DKA_TOOLS_PKG.put_log_message('v_vendor_id :'||v_vendor_id);
       DKA_TOOLS_PKG.put_log_message('v_vendor_site_id :'||v_vendor_site_id);
       DKA_TOOLS_PKG.put_log_message('po_number :'||rec_donnee_entete.po_number);

		  IF v_vendor_site_id IS NOT NULL THEN
		    IF v_inactive_date < SYSDATE-1  OR v_purchasing_site_flag !='Y' THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC07','SITE_FRNS',rec_donnee_entete.SITE_SUPPLIER_NAME,'UO',rec_donnee_entete.UO,'FRNS',rec_donnee_entete.SUPPLIER_NUMBER);
		      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'SITE_SUPPLIER_NAME' --pv_column_name
		                                 ,rec_donnee_entete.SITE_SUPPLIER_NAME --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		  	  DKA_TOOLS_PKG.put_log_message(l_message);
		  	  v_flag_erreur_entete := TRUE;
		    END IF;
		  END IF;

		  IF rec_donnee_entete.IVALUA_SITE_SUPPLIER_ID  IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC05');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'IVALUA_SITE_SUPPLIER_ID' --pv_column_name
		                                 ,rec_donnee_entete.IVALUA_SITE_SUPPLIER_ID --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
		  END IF;

		  v_etape:= 'contrôle Devise';
      DKA_TOOLS_PKG.put_log_message(v_etape);
		  IF rec_donnee_entete.CURRENCY IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC08');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'CURRENCY' --pv_column_name
		                                 ,rec_donnee_entete.CURRENCY --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
		  ELSE
        BEGIN
		      SELECT gl.currency_code
		  	  ,      gl.name
          INTO   v_CURRENCY_CODE
		  	  ,      v_entite_comptable
          FROM   gl_ledgers gl ,hr_operating_units hou
          WHERE  gl.ledger_id = hou.SET_OF_BOOKS_ID
		  	  AND    hou.name     = rec_donnee_entete.UO;
        EXCEPTION
		      WHEN OTHERS THEN
		  	    v_CURRENCY_CODE := NULL;
		  	    v_entite_comptable := NULL;
        END;
        IF  v_CURRENCY_CODE != rec_donnee_entete.CURRENCY THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC09','DEVISE',rec_donnee_entete.CURRENCY,'CODE_ENTITE',v_entite_comptable);
		  	  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_HEADERS'
		                                   , rec_donnee_entete.record_id
		                                   ,'CURRENCY' --pv_column_name
		                                   ,rec_donnee_entete.CURRENCY --pv_column_value
		                                   ,'E'
		                                   ,l_message
		  	  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
		  	  v_flag_erreur_entete := TRUE;
        END IF ;
		  END IF;

		  v_etape:= 'contrôle acheteur';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      DKA_TOOLS_PKG.put_log_message('rec_donnee_entete.AGENT_NUMBER :'||rec_donnee_entete.AGENT_NUMBER);
		  IF rec_donnee_entete.AGENT_NUMBER  IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC10');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'AGENT_NUMBER' --pv_column_name
		                                 ,rec_donnee_entete.AGENT_NUMBER --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
		  ELSE
		    BEGIN
		      SELECT distinct person_id
		  	  INTO v_person_id
		      FROM per_people_f
          WHERE  employee_number = rec_donnee_entete.AGENT_NUMBER;
        EXCEPTION
		      WHEN NO_DATA_FOUND THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC11','AGENT',rec_donnee_entete.AGENT_NUMBER);
		  	  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'AGENT_NUMBER' --pv_column_name
		                                 ,rec_donnee_entete.AGENT_NUMBER --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
		  	    v_flag_erreur_entete := TRUE;
		    END;
        DKA_TOOLS_PKG.put_log_message('v_person_id  :'||v_person_id);
        IF v_person_id IS NOT NULL THEN
          BEGIN
		        SELECT 1
            INTO v_emp_actif
            FROM per_people_f ppf
            ,    per_all_assignments_f paaf
            WHERE  ppf.person_id = v_person_id
            AND paaf.person_id = ppf.person_id
            AND ppf.current_employee_flag = 'Y'
            AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
            AND sysdate BETWEEN NVL(paaf.effective_start_date,sysdate) AND NVL(paaf.effective_end_date,sysdate)
            ;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC12','AGENT',rec_donnee_entete.AGENT_NUMBER);
		  	      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_HEADERS'
		                                     , rec_donnee_entete.record_id
		                                     ,'AGENT_NUMBER' --pv_column_name
		                                     ,rec_donnee_entete.AGENT_NUMBER --pv_column_value
		                                     ,'E'
		                                     ,l_message
		  		                           );
		          DKA_TOOLS_PKG.put_log_message(l_message);
		  	      v_flag_erreur_entete := TRUE;
		  	  END;

          DKA_TOOLS_PKG.put_log_message('v_emp_actif :'||v_emp_actif);
		  	  IF v_emp_actif IS NOT NULL THEN
		  	    BEGIN
		  	      SELECT pa.agent_id
		  	      ,      pa.start_date_active
		  	      ,      pa.end_date_active
              INTO   v_acheteur
		  		    ,      v_start_date_agent
		  		    ,      v_end_date_agent
              FROM  po_agents pa
              WHERE pa.agent_id = v_person_id;
		  	    EXCEPTION
              WHEN NO_DATA_FOUND THEN
              --création automatique de l'acheteur
		  	        apps.po_agents_pkg.insert_row (x_rowid                    => l_buyer_rowid,
                                                      x_agent_id                 => v_person_id, --v_acheteur,
                                                      x_last_update_date         => SYSDATE,
                                                      x_last_updated_by          => 0,
                                                      x_last_update_login        => 0,
                                                      x_creation_date            => SYSDATE,
                                                      x_created_by               => 0,
                                                      x_location_id              => NULL,
                                                      x_category_id              => NULL,
                                                      x_authorization_limit      => NULL,
                                                      x_start_date_active        => SYSDATE,
                                                      x_end_date_active          => NULL,
                                                      x_attribute_category       => NULL,
                                                      x_attribute1               => NULL,
                                                      x_attribute2               => NULL,
                                                      x_attribute3               => NULL,
                                                      x_attribute4               => NULL,
                                                      x_attribute5               => NULL,
                                                      x_attribute6               => NULL,
                                                      x_attribute7               => NULL,
                                                      x_attribute8               => NULL,
                                                      x_attribute9               => NULL,
                                                      x_attribute10              => NULL,
                                                      x_attribute11              => NULL,
                                                      x_attribute12              => NULL,
                                                      x_attribute13              => NULL,
                                                      x_attribute14              => NULL,
                                                      x_attribute15              => NULL
                                                      )                ;
                       -- COMMIT;
                v_acheteur :=  v_person_id;
              WHEN OTHERS THEN
 		  	        DKA_TOOLS_PKG.put_log_message('Exceprion lors de l''extraction de l''acheteur : agent_id');
		  	    END ;
            DKA_TOOLS_PKG.put_log_message('v_acheteur obligatoire pour creation :'||v_acheteur);
		  	    IF v_acheteur IS NOT NULL AND sysdate NOT BETWEEN NVL(v_start_date_agent,sysdate) AND NVL(v_end_date_agent,sysdate) THEN
              DKA_TOOLS_PKG.put_log_message('activer l''acheteur');
		  	      --activer l'acheteur
		  		    UPDATE po_agents
		  		    SET    end_date_active = NULL
		  		    ,      last_update_date = sysdate
		  		    ,      LAST_UPDATED_BY  = g_user
		  		    WHERE  agent_id = v_acheteur;

		  	    END IF;
          END IF ; --v_emp_actif IS NOT NULL

        END IF; --v_person_id is not null
      END IF;

		  v_etape:= 'Date de création dans iValua';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      IF rec_donnee_entete.PO_CREATION_DATE  IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC13');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'PO_CREATION_DATE' --pv_column_name
		                                 ,rec_donnee_entete.PO_CREATION_DATE --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_entete := TRUE;
		  END IF;

      v_etape:= 'Paiement direct';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      IF rec_donnee_entete.DIRECT_PAYMENT   IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC14');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'DIRECT_PAYMENT' --pv_column_name
		                                 ,rec_donnee_entete.DIRECT_PAYMENT --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
      ELSIF rec_donnee_entete.DIRECT_PAYMENT NOT IN ('OUI','NON') THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC15','PAIMENT',rec_donnee_entete.DIRECT_PAYMENT);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'DIRECT_PAYMENT' --pv_column_name
		                                 ,rec_donnee_entete.DIRECT_PAYMENT --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;

		  END IF;

    ELSIF  rec_donnee_entete.HEADER_ACTION = 'UPDATE' THEN
	    v_etape:= 'Vérification de la conformité de la commande à mettre à jour';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      DKA_TOOLS_PKG.put_log_message('rec_donnee_entete.po_number1 :'||rec_donnee_entete.po_number);
		  BEGIN
		    SELECT hou.name
        ,      ass.segment1
        ,      ass.vendor_id
        ,      assa.vendor_site_code
        ,      assa.vendor_site_id
			  ,      pha.CURRENCY_CODE
			  ,      pha.CLOSED_CODE
			  ,      pha.CANCEL_FLAG
			  ,      pha.AUTHORIZATION_STATUS
			  INTO   v_uo

			  ,      v_frns
        ,      v_vendor_id
			  ,      v_site_frns
        ,      v_vendor_site_id
        ,      v_devise
        ,      v_CLOSED_CODE
			  ,      v_CANCEL_FLAG
			  ,      v_AUTHORIZATION_STATUS
			  FROM  po_headers_all pha
        ,     ap_suppliers ass
        ,     ap_supplier_sites_all assa
        ,     hr_operating_units hou
			  WHERE pha.vendor_id = ass.vendor_id
			  AND   ass.vendor_id = assa.vendor_id
        AND   assa.vendor_site_id = pha.vendor_site_id
        AND   pha.org_id    = hou.organization_id
			  AND   pha.segment1  = rec_donnee_entete.po_number;
		  EXCEPTION
		    WHEN NO_DATA_FOUND THEN
			    DKA_TOOLS_PKG.put_log_message('ERROR lors de la Vérification de la conformité de la commande à mettre à jour');
		  END ;
		  IF  v_uo != rec_donnee_entete.uo THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM01','UO_ORACLE',v_uo,'UO_IVALUA',rec_donnee_entete.UO);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                               ,'DKA_IPOCMD_IVALUA'
		                               ,'VALIDATION'
		                               ,'DKA_IPOCDE_HEADERS'
		                               , rec_donnee_entete.record_id
		                               ,'UO' --pv_column_name
		                               ,rec_donnee_entete.uo --pv_column_value
		                               ,'E'
		                               ,l_message
				                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;
		  IF  v_frns != rec_donnee_entete.supplier_number THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM02','FRNS_ORACLE',v_frns,'FRNS_IVALUA',rec_donnee_entete.supplier_number);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'SUPPLIER_NUMBER' --pv_column_name
		                                 ,rec_donnee_entete.supplier_number --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;
		  IF  v_site_frns != rec_donnee_entete.site_supplier_name THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM03','SFRNS_ORACLE',v_site_frns,'SFRNS_IVALUA',rec_donnee_entete.site_supplier_name);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'SUPPLIER_SITE_NAME' --pv_column_name
		                                 ,rec_donnee_entete.site_supplier_name --pv_column_value
		                                 ,'E'
		                                 ,l_message
		  		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;
		  IF  v_devise != rec_donnee_entete.currency THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM04','CURR_ORACLE',v_devise,'CURR_IVALUA',rec_donnee_entete.currency);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'CURRENCY' --pv_column_name
		                                 ,rec_donnee_entete.currency --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;

      v_etape:= 'Vérification de l''état de la commande à mettre à jour';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      IF v_CLOSED_CODE = 'FINALLY CLOSED' THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM05','STATUT','DEFINITIVEMENT FERME');
        DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'STATUT_CMD_ORACLE' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;

      ELSIF v_CANCEL_FLAG = 'Y' THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM05','STATUT','ANNULE');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'STATUT_CMD_ORACLE' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;

      ELSIF v_AUTHORIZATION_STATUS != 'APPROVED' THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM05','STATUT',v_AUTHORIZATION_STATUS);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'STATUT_CMD_ORACLE' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;


    ELSIF  rec_donnee_entete.HEADER_ACTION = 'CANCEL' THEN
	    BEGIN
        SELECT SUM(plla.QUANTITY_RECEIVED)
        INTO   v_qt_recptionnee
        FROM  PO_LINES_ALL pla
        ,     po_line_locations_All plla
        ,     po_headers_all pha
		,     MTL_CATEGORIES_B_KFV mcbk
        WHERE 1=1
        AND pla.po_line_id        = plla.po_line_id
        AND pla.po_header_id      = pha.po_header_id
		AND mcbk.category_id      = pla.category_id
		AND mcbk.concatenated_segments = '99.99.99.01'
        AND pha.segment1          = rec_donnee_entete.po_number;
      EXCEPTION
        WHEN OTHERS THEN
          v_qt_recptionnee := 0;
      END ;



      v_etape:= 'Contrôle des quantités réceptionnées';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      IF v_qt_recptionnee != 0 THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VA03');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'quantite_receptionnee' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;

       BEGIN
        SELECT SUM(plla.QUANTITY_BILLED)
        ,      pha.AUTHORIZATION_STATUS
        INTO   v_qt_facturee
        ,      v_statut_cmd
        FROM  PO_LINES_ALL pla
        ,     po_line_locations_All plla
        ,     po_headers_all pha
        WHERE 1=1
        AND pla.po_line_id        = plla.po_line_id
        AND pla.po_header_id      = pha.po_header_id
        AND pha.segment1          = rec_donnee_entete.po_number
        group by pha.AUTHORIZATION_STATUS;
      EXCEPTION
        WHEN OTHERS THEN
          v_qt_facturee    := 0;
      END ;

      v_etape:= 'Contrôle des quantités facturées';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      IF v_qt_facturee    != 0 THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VA04');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'quantite_facturee' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF;


      v_etape:= 'Statut de la commande';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      IF v_statut_cmd != 'APPROVED' THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VA05');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'statut_cmd' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_entete := TRUE;
      END IF ;
	  END IF;


	  --DEBUT CONTROLE LIGNE
	  FOR  rec_donne_ligne IN C_DONNEE_LIGNE(rec_donnee_entete.po_number) LOOP
	    v_code_projet := Null; -- SELO : artf07455137 INC0536680
        v_person_id   := Null; -- SELO : artf07455137 INC0536680

      g_enreg_a_traite_line := g_enreg_a_traite_line + 1;
	    v_flag_erreur_lines := FALSE;
      IF IS_LIGNE_DE_FRAIS(rec_donne_ligne.IVALUA_LINE_TYPE) = 'Y' THEN
        UPDATE DKA_IPOCDE_LINES
        SET type_line = 'FRAIS'
        ,   LAST_UPDATE_DATE  = SYSDATE
		    ,   LAST_UPDATED_BY    = g_user
		    WHERE CURRENT OF C_DONNEE_LIGNE;
      END IF;
	    v_etape:= 'Contrôle ID de la ligne de commande iValua';
      DKA_TOOLS_PKG.put_log_message(v_etape);
      v_id_cmd := null;
	    IF rec_donne_ligne.IVALUA_LINE_ID    IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT07');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'IVALUA_LINE_ID' --pv_column_name
		                                   ,rec_donne_ligne.IVALUA_LINE_ID --pv_column_value
		                                   ,'E'
		                                   ,l_message
		    		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_lines := TRUE;
	    ELSE
        BEGIN
		      SELECT distinct po_header_id
		      INTO   v_id_cmd
		      FROM PO_LINES_ALL pa
		      WHERE attribute8 = rec_donne_ligne.IVALUA_LINE_ID;
		    EXCEPTION
		      WHEN NO_DATA_FOUND THEN
		        v_id_cmd := null;
		    END;
        DKA_TOOLS_PKG.put_log_message('v_id_cmd :'||v_id_cmd);
        IF v_id_cmd IS NOT NULL THEN
		      SELECT segment1
			    INTO   v_num_cmd
			    FROM   po_headers_all
          WHERE  po_header_id = v_id_cmd	;

		      IF  v_num_cmd != rec_donne_ligne.po_number THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT08','NUMCMD',v_num_cmd);
		        DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'IVALUA_LINE_ID' --pv_column_name
		                                     ,v_num_cmd --pv_column_value
		                                     ,'E'
		                                     ,l_message
		      		                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
		        v_flag_erreur_lines := TRUE;
		      END IF;
        END IF;
	    END IF ;

	    v_etape:= 'Contrôle type de ligne';
      DKA_TOOLS_PKG.put_log_message(v_etape);

	    IF rec_donne_ligne.IVALUA_LINE_TYPE     IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT09');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'IVALUA_LINE_TYPE' --pv_column_name
		                                   ,rec_donne_ligne.IVALUA_LINE_TYPE  --pv_column_value
		                                   ,'E'
		                                   ,l_message
		    		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_lines := TRUE;
	    ELSE
        BEGIN
          SELECT  count(*)
          INTO    v_type_existe
          FROM    DKA_STRANSCO_LINES DSTL
          ,       DKA_STRANSCO_HEADERS DSTH
          WHERE   DSTL.SET_ID = DSTH.SET_ID
           AND DSTH.SET_NAME ='DKA_IVALUA_TYPE_LIGNE'
           AND DSTL.PARAMS_VALUE = rec_donne_ligne.IVALUA_LINE_TYPE;
        END;
        IF v_type_existe = 0 THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT10','IVALUA_LINE',rec_donne_ligne.IVALUA_LINE_TYPE);
		      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'IVALUA_LINE_TYPE' --pv_column_name
		                                     ,rec_donne_ligne.IVALUA_LINE_TYPE  --pv_column_value
		                                     ,'E'
		                                     ,l_message
		      		                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
		      v_flag_erreur_lines := TRUE;
        END IF;
      END IF;

	    v_etape:= 'Contrôle Mis à jour (O/N)';
      DKA_TOOLS_PKG.put_log_message(v_etape);

	    IF rec_donne_ligne.UPDATED    IS NULL THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT11');
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'UPDATED' --pv_column_name
		                                   ,rec_donne_ligne.UPDATED  --pv_column_value
		                                   ,'E'
		                                   ,l_message
		    		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    v_flag_erreur_lines := TRUE;
	    ELSIF	rec_donne_ligne.UPDATED NOT IN ('Y','N') THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT12','UPDATED',rec_donne_ligne.UPDATED);
		    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'UPDATED' --pv_column_name
		                                   ,rec_donne_ligne.UPDATED  --pv_column_value
		                                   ,'E'
		                                   ,l_message
		    		                       );
		    DKA_TOOLS_PKG.put_log_message(l_message);
        v_flag_erreur_lines := TRUE;
	    END IF ;

	    v_etape:= ' Contrôle de l''existence d''entête de commande';
      DKA_TOOLS_PKG.put_log_message(v_etape);
	    BEGIN
	      SELECT count(*)
		    INTO  v_exist_entete
		    FROM  DKA_IPOCDE_HEADERS
		    WHERE po_number = rec_donne_ligne.po_number;
	    END;
      IF v_exist_entete = 0 THEN
        l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT15');
		      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'po_number' --pv_column_name
		                                   ,rec_donne_ligne.po_number  --pv_column_value
		                                   ,'E'
		                                   ,l_message
		  	  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
          v_flag_erreur_lines := TRUE;
      END IF;
	    IF rec_donnee_entete.HEADER_ACTION IN ('CREATE','CREATE_CANCEL'  )OR (rec_donnee_entete.HEADER_ACTION = 'UPDATE' AND rec_donne_ligne.LINE_ACTION ='ADD') THEN --SHA-EDB310
	      v_etape:= 'Description de la ligne';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.LINE_DESCRIPTION IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC16');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'LINE_DESCRIPTION' --pv_column_name
		                                 ,rec_donne_ligne.LINE_DESCRIPTION --pv_column_value
		                                 ,'E'
		                                 ,l_message
				                         );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  END IF;

			  v_etape:= 'Unité de mesure';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.UOM IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC17');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'UOM' --pv_column_name
		                                 ,rec_donne_ligne.UOM --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  ELSE
			    BEGIN
            SELECT 1
			      INTO  v_UOM_CODE
			      FROM   po_units_of_measure_val_v
            WHERE  UOM_CODE = rec_donne_ligne.UOM ;
          EXCEPTION
            WHEN OTHERS THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC18','UOM',rec_donne_ligne.UOM);
			  	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'UOM' --pv_column_name
		                                   ,rec_donne_ligne.UOM --pv_column_value
		                                   ,'E'
		                                   ,l_message
			  	                         );
		          DKA_TOOLS_PKG.put_log_message(l_message);
			  	    v_flag_erreur_lines := TRUE;
			    END ;
			  END IF;

			  v_etape:= 'Quantité commandée';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.QUANTITY  IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC19');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'QUANTITY' --pv_column_name
		                                 ,rec_donne_ligne.QUANTITY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;

			  ELSIF rec_donne_ligne.QUANTITY <= 0 THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC20');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'QUANTITY' --pv_column_name
		                                 ,rec_donne_ligne.QUANTITY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;


        ELSIF rec_donne_ligne.QUANTITY != ROUND(rec_donne_ligne.QUANTITY,5) THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC21');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'QUANTITY' --pv_column_name
		                                 ,rec_donne_ligne.QUANTITY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;

        END IF;

			  v_etape:= 'Prix unitaire';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.PRICE   IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC22');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'PRICE' --pv_column_name
		                                 ,rec_donne_ligne.PRICE --pv_column_value
		                                 ,'E'
		                                 ,l_message
				                         );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;

			  ELSIF rec_donne_ligne.PRICE < 0  THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC23');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'PRICE' --pv_column_name
		                                 ,rec_donne_ligne.PRICE --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;

			  END IF;

			  v_etape:= 'Lieu de livraison';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.DELIVERY_ADDRESS_NAME    IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC24');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'DELIVERY_ADDRESS_NAME' --pv_column_name
		                                 ,rec_donne_ligne.DELIVERY_ADDRESS_NAME --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  END IF;

        v_etape:= ' Clé catégorie';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.CATEGORY     IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC25');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'CATEGORY' --pv_column_name
		                                 ,rec_donne_ligne.CATEGORY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  END IF;

        v_etape:= 'Commande catalogue (O/N)';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.CATALOG_PURCHASE      IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC26');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'CATALOG_PURCHASE' --pv_column_name
		                                 ,rec_donne_ligne.CATALOG_PURCHASE --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  ELSIF  rec_donne_ligne.CATALOG_PURCHASE NOT IN ('Y','N') THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC27','CMD_CATA',rec_donne_ligne.CATALOG_PURCHASE);
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'CATALOG_PURCHASE' --pv_column_name
		                                 ,rec_donne_ligne.CATALOG_PURCHASE --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  END IF;

        v_etape:= 'Tâche finance';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.FINANCIAL_TASK       IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC28');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'FINANCIAL_TASK' --pv_column_name
		                                 ,rec_donne_ligne.FINANCIAL_TASK --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  ELSE
			    BEGIN
			      SELECT task_id
			  	  ,      pt.start_date
			  	  ,      pt.completion_date
            ,      ppa.name
            INTO   v_task_id
			  	  ,      v_t_start_date
			  	  ,      v_t_completion_date
            ,      v_code_projet
            FROM   pa_tasks pt
            ,      pa_projects_all ppa
            WHERE  ppa.project_id          = pt.project_id
            AND    pt.task_number          = rec_donne_ligne.FINANCIAL_TASK  ;
			    EXCEPTION
			      WHEN OTHERS THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC29','TASK',rec_donne_ligne.FINANCIAL_TASK );
			  	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'FINANCIAL_TASK' --pv_column_name
		                                   ,rec_donne_ligne.FINANCIAL_TASK --pv_column_value
		                                   ,'E'
		                                   ,l_message
			  	                         );
		          DKA_TOOLS_PKG.put_log_message(l_message);
			  	    v_flag_erreur_lines := TRUE;
              v_code_projet := NULL;
			    END ;
			    IF sysdate NOT BETWEEN NVL(v_t_start_date,sysdate) AND NVL(v_t_completion_date,sysdate)  THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC30','TASK',rec_donne_ligne.FINANCIAL_TASK );
			  	  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'FINANCIAL_TASK' --pv_column_name
		                                 ,rec_donne_ligne.FINANCIAL_TASK --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			  	  v_flag_erreur_lines := TRUE;
          END IF;

			  END IF;

			  v_etape:= 'Type de dépense';
        DKA_TOOLS_PKG.put_log_message(v_etape);
			  IF rec_donne_ligne.EXPENSE_TYPE  IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC31');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'EXPENSE_TYPE' --pv_column_name
		                                 ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;
			  ELSE

			    BEGIN
			      SELECT 1
            ,     end_date_active
            ,     start_date_active
            ,     nvl(attribute3,'N')
			  	  INTO   v_expenditure_existe
            ,      v_end_date_expend
            ,      v_start_date_expend
            ,      v_autorise_po
			  	  FROM   PA_EXPENDITURE_TYPES
			  	  WHERE  expenditure_type = rec_donne_ligne.EXPENSE_TYPE;
			    EXCEPTION
			      WHEN NO_DATA_FOUND THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC32','DEPENSE',rec_donne_ligne.EXPENSE_TYPE);
			  	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'EXPENSE_TYPE' --pv_column_name
		                                   ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			  	                         );
		          DKA_TOOLS_PKG.put_log_message(l_message);
              v_flag_erreur_lines := TRUE;
          END;

          IF v_expenditure_existe IS NOT NULL THEN
            IF  sysdate NOT BETWEEN NVL(v_start_date_expend,sysdate) AND NVL(v_end_date_expend,sysdate) THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC33','DEPENSE',rec_donne_ligne.EXPENSE_TYPE);
			  	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'EXPENSE_TYPE' --pv_column_name
		                                   ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			  	                         );
		           DKA_TOOLS_PKG.put_log_message(l_message);
			  	    v_flag_erreur_lines := TRUE;
            END IF;


            DKA_TOOLS_PKG.put_log_message('v_autorise_po :'|| v_autorise_po);
            IF v_autorise_po != 'Y' THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC35','DEPENSE',rec_donne_ligne.EXPENSE_TYPE);
			  	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'EXPENSE_TYPE' --pv_column_name
		                                   ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			  	                         );
		          DKA_TOOLS_PKG.put_log_message(l_message);
			  	    v_flag_erreur_lines := TRUE;
            END IF ;

            BEGIN
            SELECT  count(*)
            INTO    v_depense_pr_task
            FROM    pa_projects_all ppa
            ,       pa_transaction_controls ptc
            ,       pa_tasks pt
            WHERE  1=1
            AND ppa.project_id          = ptc.project_id
            AND ppa.project_id          = pt.project_id
            AND pt.task_number          = rec_donne_ligne.FINANCIAL_TASK
            AND ptc.expenditure_type    = rec_donne_ligne.EXPENSE_TYPE
            AND ptc.task_id             = pt.task_id ;
            EXCEPTION
              WHEN OTHERS THEN
                v_depense_pr_task := 0;
            END ;
            IF v_depense_pr_task = 0 THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC34','DEPENSE',rec_donne_ligne.EXPENSE_TYPE,'TASK',rec_donne_ligne.FINANCIAL_TASK);
			  	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'EXPENSE_TYPE' --pv_column_name
		                                   ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			  	                          );
		          DKA_TOOLS_PKG.put_log_message(l_message);
			  	    v_flag_erreur_lines := TRUE;
            END IF ;  -- FIN IF v_depense_pr_task = 0
          END IF ;     -- fin v_expenditure_existe is not null
        END IF ;  --rec_donne_ligne.EXPENSE_TYPE

			  v_etape:= 'Demandeur DA';
        DKA_TOOLS_PKG.put_log_message(v_etape);
        IF rec_donne_ligne.REQUESTER IS NOT NULL THEN
		      BEGIN
		        SELECT distinct person_id
		  	    INTO v_person_id
		        FROM per_people_f
            WHERE  employee_number = rec_donne_ligne.REQUESTER;
          EXCEPTION
		        WHEN NO_DATA_FOUND THEN
              l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC36','DA',rec_donne_ligne.REQUESTER);
			    	  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'REQUESTER' --pv_column_name
		                                     ,rec_donne_ligne.REQUESTER --pv_column_value
		                                     ,'E'
		                                     ,l_message
			    	                         );
		          DKA_TOOLS_PKG.put_log_message(l_message);
			    	  v_flag_erreur_lines := TRUE;
		      END;
          DKA_TOOLS_PKG.put_log_message('v_person_id  :'||v_person_id);
          IF v_person_id IS NOT NULL THEN
            BEGIN
		          SELECT 1
              INTO v_emp_actif
              FROM per_people_f ppf
              ,    per_all_assignments_f paaf
              WHERE  ppf.person_id = v_person_id
              AND paaf.person_id = ppf.person_id
              AND ppf.current_employee_flag = 'Y'
              AND sysdate BETWEEN NVL(ppf.effective_start_date,sysdate) AND NVL(ppf.effective_end_date,sysdate)
              AND sysdate BETWEEN NVL(paaf.effective_start_date,sysdate) AND NVL(paaf.effective_end_date,sysdate)
              ;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC37','DA',rec_donne_ligne.REQUESTER);
			    	  DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'REQUESTER' --pv_column_name
		                                     ,rec_donne_ligne.REQUESTER --pv_column_value
		                                     ,'E'
		                                     ,l_message
			    	                         );
		          DKA_TOOLS_PKG.put_log_message(l_message);
			    	  v_flag_erreur_lines := TRUE;
		  	    END;

          END IF; --v_person_id is not null
        END IF;

	    ELSIF rec_donnee_entete.HEADER_ACTION = 'UPDATE'	THEN
	      IF  rec_donne_ligne.LINE_ACTION = 'UPDATE' THEN
		      v_etape:= 'Description de la ligne';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    IF rec_donne_ligne.LINE_DESCRIPTION IS NULL THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC16');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'LINE_DESCRIPTION' --pv_column_name
		                                   ,rec_donne_ligne.LINE_DESCRIPTION --pv_column_value
		                                   ,'E'
		                                   ,l_message
				                           );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;
			    END IF;
			    v_etape:= 'Prix unitaire';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    IF rec_donne_ligne.PRICE   IS NULL THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC22');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'PRICE' --pv_column_name
		                                   ,rec_donne_ligne.PRICE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;

			    ELSIF rec_donne_ligne.PRICE < 0  THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC23');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'PRICE' --pv_column_name
		                                   ,rec_donne_ligne.PRICE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;

			    END IF;

			    v_etape:= ' Clé catégorie';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    IF rec_donne_ligne.CATEGORY     IS NULL THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC25');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'CATEGORY' --pv_column_name
		                                   ,rec_donne_ligne.CATEGORY --pv_column_value
		                                   ,'E'
		                                   ,l_message
				                           );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;
			    END IF;

			    v_etape:= 'Type de dépense';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    IF rec_donne_ligne.EXPENSE_TYPE  IS NULL THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC31');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'EXPENSE_TYPE' --pv_column_name
		                                   ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;
			    ELSE

			      BEGIN
			        SELECT 1
              ,     end_date_active
              ,     start_date_active
              ,     nvl(attribute3,'N')
			    	  INTO   v_expenditure_existe
              ,      v_end_date_expend
              ,      v_start_date_expend
              ,      v_autorise_po
			    	  FROM   PA_EXPENDITURE_TYPES
			    	  WHERE  expenditure_type = rec_donne_ligne.EXPENSE_TYPE;
			      EXCEPTION
			        WHEN NO_DATA_FOUND THEN
                l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC32','DEPENSE',rec_donne_ligne.EXPENSE_TYPE);
			    	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'EXPENSE_TYPE' --pv_column_name
		                                     ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                     ,'E'
		                                     ,l_message
			    	                         );
		              DKA_TOOLS_PKG.put_log_message(l_message);
                  v_flag_erreur_lines   := TRUE;
                  v_expenditure_existe  := NULL;
            END;

            IF v_expenditure_existe IS NOT NULL THEN
              IF  sysdate NOT BETWEEN NVL(v_start_date_expend,sysdate) AND NVL(v_end_date_expend,sysdate) THEN
                l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC33','DEPENSE',rec_donne_ligne.EXPENSE_TYPE);
			    	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'EXPENSE_TYPE' --pv_column_name
		                                     ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                     ,'E'
		                                     ,l_message
			    	                         );
		            DKA_TOOLS_PKG.put_log_message(l_message);
			    	    v_flag_erreur_lines := TRUE;
              END IF;

              DKA_TOOLS_PKG.put_log_message('v_autorise_po :'|| v_autorise_po);
              IF v_autorise_po != 'Y' THEN
                l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC35','DEPENSE',rec_donne_ligne.EXPENSE_TYPE);
			    	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'EXPENSE_TYPE' --pv_column_name
		                                     ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                     ,'E'
		                                     ,l_message
			    	                         );
		            DKA_TOOLS_PKG.put_log_message(l_message);
			    	    v_flag_erreur_lines := TRUE;
              END IF ;

              BEGIN
                SELECT  count(*)
                INTO    v_depense_pr_task
                FROM    pa_projects_all ppa
                ,       pa_transaction_controls ptc
                ,       pa_tasks pt
                WHERE  1=1
                AND ppa.project_id          = ptc.project_id
                AND ppa.project_id          = pt.project_id
                AND pt.task_number          = rec_donne_ligne.FINANCIAL_TASK
                AND ptc.expenditure_type    = rec_donne_ligne.EXPENSE_TYPE
                AND ptc.task_id             = pt.task_id ;
              EXCEPTION
                WHEN OTHERS THEN
                  v_depense_pr_task := 0;
              END ;

              IF v_depense_pr_task = 0 THEN
                l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC34','DEPENSE',rec_donne_ligne.EXPENSE_TYPE,'TASK',rec_donne_ligne.FINANCIAL_TASK);
			    	    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                     ,'DKA_IPOCMD_IVALUA'
		                                     ,'VALIDATION'
		                                     ,'DKA_IPOCDE_LINES'
		                                     , rec_donne_ligne.record_id
		                                     ,'EXPENSE_TYPE' --pv_column_name
		                                     ,rec_donne_ligne.EXPENSE_TYPE --pv_column_value
		                                     ,'E'
		                                     ,l_message
			    	                         );
		            DKA_TOOLS_PKG.put_log_message(l_message);
			    	    v_flag_erreur_lines := TRUE;
              END IF ;    --fin v_depense_pr_task =0
            END IF ;   -- FIN v_expenditure_existe IS NOT NULL
          END IF ; -- fin rec_donne_ligne.EXPENSE_TYPE
        --   SHA CR76 Début
		--   Ajout contrôle pour la mise à jour de ligne d’article sur une commande existante
		  v_etape:= 'Quantité';
          DKA_TOOLS_PKG.put_log_message(v_etape);
		 IF rec_donne_ligne.QUANTITY  IS NULL THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC19');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'QUANTITY' --pv_column_name
		                                 ,rec_donne_ligne.QUANTITY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;

			  ELSIF rec_donne_ligne.QUANTITY <= 0 THEN
          l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC20');
			    DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'QUANTITY' --pv_column_name
		                                 ,rec_donne_ligne.QUANTITY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
			    v_flag_erreur_lines := TRUE;


        ELSIF rec_donne_ligne.QUANTITY != ROUND(rec_donne_ligne.QUANTITY,5) THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC21');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_LINES'
		                                 , rec_donne_ligne.record_id
		                                 ,'QUANTITY' --pv_column_name
		                                 ,rec_donne_ligne.QUANTITY --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;

        END IF;
         v_etape:= 'Prix unitaire';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    IF rec_donne_ligne.PRICE   IS NULL THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC22');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'PRICE' --pv_column_name
		                                   ,rec_donne_ligne.PRICE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;

			    ELSIF rec_donne_ligne.PRICE < 0  THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VC23');
			      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'PRICE' --pv_column_name
		                                   ,rec_donne_ligne.PRICE --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			      v_flag_erreur_lines := TRUE;

			    END IF;

		--   SHA CR76 Fin
		  v_etape:= 'Vérification de l''état de la ligne à mettre à jour';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    BEGIN
			      SELECT CLOSED_CODE
			      ,      CANCEL_FLAG
			      INTO   v_CLOSED_CODE
			      ,      v_CANCEL_FLAG
			      FROM   po_lines_all
			      WHERE  attribute8 = rec_donne_ligne.ivalua_line_id;
			    EXCEPTION
			      WHEN NO_DATA_FOUND THEN
			        v_CLOSED_CODE := NULL;
			        v_CANCEL_FLAG := NULL;
			    END ;

			    IF v_CLOSED_CODE like 'FINALLY CLOSED%' OR nvl(v_CANCEL_FLAG, 'N') != 'N' THEN
             l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM06');
			    	DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'etat de ligne' --pv_column_name
		                                   ,NULL --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			    	v_flag_erreur_lines := TRUE;
			    END IF;

			    v_etape:= 'Vérification que la ligne de frais à mettre à jour n''est pas facturée';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    BEGIN
			      SELECT QUANTITY_BILLED
			      INTO   v_QUANTITY_BILLED
			      FROM  PO_LINES_ALL pla
            ,     po_line_locations_All plla
            where 1=1
            and   pla.po_line_id = plla.po_line_id
		        and   pla.attribute8 = rec_donne_ligne.ivalua_line_id;
			    EXCEPTION
			      WHEN OTHERS THEN
			        DKA_TOOLS_PKG.put_log_message('erreur lors de la détermination de la quantité facturée');
			    END ;

			    IF v_QUANTITY_BILLED != 0 THEN

            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM07');
			    	DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'quantité facturée' --pv_column_name
		                                   ,NULL --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			    	v_flag_erreur_lines := TRUE;
			    END IF;
			--   SHA CR76 Début
          v_etape:= 'Vérification que la ligne d’article à mettre à jour n’est pas réceptionnée';
          DKA_TOOLS_PKG.put_log_message(v_etape);
			    BEGIN
			      SELECT QUANTITY_RECEIVED
			      INTO   v_QUANTITY_RECEIVED
			      FROM  PO_LINES_ALL pla
            ,     po_line_locations_All plla
            where 1=1
            and   pla.po_line_id = plla.po_line_id
		        and   pla.attribute8 = rec_donne_ligne.ivalua_line_id;
			    EXCEPTION
			      WHEN OTHERS THEN
			        DKA_TOOLS_PKG.put_log_message('erreur lors de la détermination de la quantité réceptionnée');
			    END ;

			    IF v_QUANTITY_RECEIVED != 0 THEN

            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VM08');
			    	DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'VALIDATION'
		                                   ,'DKA_IPOCDE_LINES'
		                                   , rec_donne_ligne.record_id
		                                   ,'quantité réceptionnée' --pv_column_name
		                                   ,NULL --pv_column_value
		                                   ,'E'
		                                   ,l_message
			    	                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
			    	v_flag_erreur_lines := TRUE;
			    END IF;
            --   SHA CR76 Fin
		    ELSIF rec_donne_ligne.LINE_ACTION = 'CANCEL' THEN
          NULL;
		    END IF;

	    END IF ;

      IF v_flag_erreur_lines THEN
        DKA_TOOLS_PKG.put_log_message('ERREUR niveau ligne');
        g_enreg_line_rejete1 := g_enreg_line_rejete1 + 1;
        UPDATE DKA_IPOCDE_LINES
		    SET STATUT ='REJECTED'
        ,   request_id = g_request_id
		    ,   LAST_UPDATE_DATE  = SYSDATE
		    ,   LAST_UPDATED_BY    = g_user
		    WHERE CURRENT OF C_DONNEE_LIGNE ;
	      v_flag_erreur_entete := TRUE;
	ELSE
         --enregistrement validé
       UPDATE DKA_IPOCDE_LINES
       SET STATUT = 'VALIDATED'
      ,   person_id   = v_person_id --REQUESTER
      ,   code_projet = v_code_projet
      ,   request_id = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
           ,   LAST_UPDATED_BY    = g_user
       WHERE CURRENT OF C_DONNEE_LIGNE ;

	    END IF;
      --COMMIT;
    END LOOP;  --end loop C_DONNEE_LIGNE


    IF rec_donnee_entete.LINE_TO_CANCEL = 'Y' THEN
      FOR rec_line_to_cancel IN(SELECT pla.line_num
                                ,      pla.attribute8
                                ,      plla.QUANTITY_RECEIVED
  	      FROM   PO_LINES_ALL pla
          ,      po_headers_all pha
          ,      po_line_locations_All plla
		  ,      MTL_CATEGORIES_B_KFV mcbk
          WHERE pla.attribute8 NOT IN (SELECT ivalua_line_id FROM DKA_IPOCDE_LINES WHERE po_number=rec_donnee_entete.po_number)
  	      AND   pla.po_header_id = pha.po_header_id
          AND   pha.segment1     =  rec_donnee_entete.po_number
		  and   mcbk.category_id = pla.category_id
		  and   mcbk.concatenated_segments = '99.99.99.01'-- sha - Il devra seulement être effectué sur les lignes d’article
          AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
          AND   pla.CANCEL_FLAG= 'N'
          AND   pla.po_line_id        = plla.po_line_id)LOOP


          v_flag_erreur_entete_cancel := FALSE;
          IF rec_line_to_cancel.QUANTITY_RECEIVED != 0 THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VA01','NUM_LINE_CDE',rec_line_to_cancel.line_num,'ID_LINE_IVALUA',rec_line_to_cancel.attribute8);
		        DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'ligne' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		       DKA_TOOLS_PKG.put_log_message(l_message);
           v_flag_erreur_entete_cancel := TRUE;
          END IF;
        END LOOP;
         FOR rec_line_to_cancel_billed IN(SELECT pla.line_num
                                ,      pla.attribute8
                                ,      plla.QUANTITY_BILLED
  	      FROM   PO_LINES_ALL pla
          ,      po_headers_all pha
          ,      po_line_locations_All plla
          WHERE pla.attribute8 NOT IN (SELECT ivalua_line_id FROM DKA_IPOCDE_LINES WHERE po_number=rec_donnee_entete.po_number)
  	      AND   pla.po_header_id = pha.po_header_id
          AND   pha.segment1    =  rec_donnee_entete.po_number
          AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
          AND   pla.CANCEL_FLAG= 'N'
          AND   pla.po_line_id        = plla.po_line_id)LOOP


          IF rec_line_to_cancel_billed.QUANTITY_BILLED != 0 THEN
            l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VA02','NUM_LINE_CDE',rec_line_to_cancel_billed.line_num,'ID_LINE_IVALUA',rec_line_to_cancel_billed.attribute8);
		        DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'VALIDATION'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_donnee_entete.record_id
		                                 ,'ligne' --pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,l_message
			  	                       );
		       DKA_TOOLS_PKG.put_log_message(l_message);
           v_flag_erreur_entete_cancel := TRUE;
          END IF;
          IF v_flag_erreur_entete_cancel THEN
             v_flag_erreur_entete := TRUE;
             UPDATE DKA_IPOCDE_HEADERS
             SET STATUT_CANCEL_LINE  = 'REJECTED'
             ,   request_id = g_request_id
             ,   LAST_UPDATE_DATE  = SYSDATE
	           ,   LAST_UPDATED_BY    = g_user
             WHERE po_number = rec_donnee_entete.po_number;
          END IF;
       END LOOP;
    END IF;

    --Mise à jour des tables après validation
    IF NOT v_flag_erreur_entete THEN
      --MAJ de la table entete et ligne
      UPDATE 	DKA_IPOCDE_HEADERS
      SET STATUT = 'VALIDATED'
      ,   vendor_site_id = v_vendor_site_id
      ,   vendor_id      = v_vendor_id
      ,   agent_id       = v_acheteur
      ,   request_id     = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
      --WHERE po_number = rec_donnee_entete.po_number;
      WHERE CURRENT OF c_donnee_entete;

    ELSE
      DKA_TOOLS_PKG.put_log_message('ERREUR niveau entête');
      --g_enreg_entete_rejete1 := g_enreg_entete_rejete1 + 1;
      --MAJ de la table entete
      UPDATE DKA_IPOCDE_HEADERS
		  SET STATUT ='REJECTED'
      ,   request_id = g_request_id
		  ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
		  WHERE CURRENT OF C_DONNEE_ENTETE;

      UPDATE DKA_IPOCDE_LINES
		  SET STATUT = 'REJECTED'
      ,   request_id = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
		  WHERE po_number = rec_donnee_entete.po_number;
      pn_retcode := 1;
	END IF;
    --COMMIT;
	-- SELO EDB301 BEGIN
    IF v_flag_warning_entete THEN
      --MAJ de la table entete et ligne
    /*  UPDATE 	DKA_IPOCDE_HEADERS
      SET STATUT = 'COMPLETE'
      ,   vendor_site_id = v_vendor_site_id
      ,   vendor_id      = v_vendor_id
      ,   agent_id       = v_acheteur
      ,   request_id     = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
      --WHERE po_number = rec_donnee_entete.po_number;
      WHERE CURRENT OF c_donnee_entete;

      UPDATE DKA_IPOCDE_LINES
		  SET STATUT = 'COMPLETE'
      ,   request_id = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
		  WHERE po_number = rec_donnee_entete.po_number;
      pn_retcode := 1;
	  */
	    UPDATE 	DKA_IPOCDE_HEADERS
      SET STATUT = 'WARNING'
      ,   vendor_site_id = v_vendor_site_id
      ,   vendor_id      = v_vendor_id
      ,   agent_id       = v_acheteur
      ,   request_id     = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
    -- WHERE po_number = rec_donnee_entete.po_number;
     WHERE CURRENT OF c_donnee_entete;

      UPDATE DKA_IPOCDE_LINES
		  SET STATUT = 'WARNING'
      ,   request_id = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
		  WHERE po_number = rec_donnee_entete.po_number;
      pn_retcode := 1;
	  v_flag_warning_entete := false;
	END IF;

	-- SELO EDB301 FIN


	END LOOP; -- end loop C_DONNEE_ENTETE

  FOR REC_LIGNE_ORPHELINE IN C_LIGNE_ORPHELINE LOOP
    g_enreg_a_traite_orph := g_enreg_a_traite_orph +1;
    l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_VT15');
    DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                     ,'DKA_IPOCMD_IVALUA'
                                     ,'VALIDATION'
                                     ,'DKA_IPOCDE_LINES'
                                     , REC_LIGNE_ORPHELINE.record_id
                                     ,'ivalua_line_id' --pv_column_name
                                     ,REC_LIGNE_ORPHELINE.po_number  --pv_column_value
                                     ,'E'
                                     ,l_message
    	  	                       );
    DKA_TOOLS_PKG.put_log_message(l_message);
    UPDATE DKA_IPOCDE_LINES
    SET STATUT = 'REJECTED'
      ,   request_id       = g_request_id
      ,   LAST_UPDATE_DATE  = SYSDATE
	    ,   LAST_UPDATED_BY    = g_user
    WHERE CURRENT OF C_LIGNE_ORPHELINE;
   -- WHERE po_number = REC_LIGNE_ORPHELINE.po_number;
    g_enreg_line_rejete1 := g_enreg_line_rejete1 + 1;
  END LOOP;
    --g_enreg_a_traite_lineT  := g_enreg_a_traite_line + g_enreg_a_traite_orph + g_enreg_ignore + g_line_complete ;
    --g_enreg_a_traite_entete := g_enreg_a_traite_entete + g_entete_ignore;
  COMMIT;

END VALIDATION_DONNEES;
/*======================================================================================================*/
  --  Nom           : INIT_SEQUENCE
  --  Description   : Procédure pour initialiser la sequence
  --  DATE          : 18/06/2020
/*=========================================================================================================*/
PROCEDURE INIT_SEQUENCE IS
BEGIN
    execute immediate'drop sequence DKA.DKA_IPOCDE_LINENUM_S';
    execute immediate'CREATE SEQUENCE DKA.DKA_IPOCDE_LINENUM_S INCREMENT BY 1';
    execute immediate'drop SYNONYM DKA_IPOCDE_LINENUM_S';
    execute immediate'CREATE SYNONYM DKA_IPOCDE_LINENUM_S FOR DKA.DKA_IPOCDE_LINENUM_S';
END;
/*======================================================================================================*/
  --  Nom           : IMPORT_DONNEES
  --  Description   : Procédure d'import des données dans les tables d'interface
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 09/06/2020
/*=========================================================================================================*/
  PROCEDURE IMPORT_DONNEES(pv_errbuf        OUT VARCHAR2,
                           pn_retcode       OUT NUMBER
                          )
  IS


  CURSOR C_CMD_ACREER IS
  SELECT DIH.*
  ,      hou.organization_id
  ,      hou.set_of_books_id
  ,      fspa.ship_to_location_id
  ,      fspa.bill_to_location_id
  FROM DKA_IPOCDE_HEADERS DIH
		,    financials_system_params_all fspa
		,    hr_operating_units hou
  WHERE dih.uo = hou.name
  AND   hou.organization_id= fspa.org_id
  AND   dih.HEADER_ACTION in ( 'CREATE','CREATE_CANCEL' ) --SHA-EDB310
  AND   dih.statut IN ('VALIDATED','PROCESSING_ERROR','PROCESSING_ERROR_CAN','COMPLETE_CREATE')
  -- AND   dih.po_number ='POC0003'
  order by po_number ;
  --FOR UPDATE;
  
--dil.ivalua_line_id ; BNZ: KDFI-1374 
  CURSOR C_LIGNE_ACREER (P_CMD VARCHAR2) IS
    SELECT DECODE(dil.TYPE_LINE,'FRAIS',gn_default_value2,gn_default_value1) category_id,
	to_number(replace ( req_line,'-','' )) REC_line1 ,
	nvl( substr( req_line,1,instr(req_line,'-')-1),0) REC_line2 , dil.*
	FROM   DKA_IPOCDE_LINES dil
	WHERE  dil.po_number = P_CMD
	order by 3,2 ;
 
  --po_number ='POC0003'
 -- FOR UPDATE;

  CURSOR C_CMD_AMAJ IS
  SELECT DIH.*
  ,      hou.organization_id
  ,      hou.set_of_books_id
  ,      fspa.ship_to_location_id
  ,      fspa.bill_to_location_id

  FROM DKA_IPOCDE_HEADERS DIH
	,    financials_system_params_all fspa
	,    hr_operating_units hou
	,    DKA_IPOCDE_LINES dil
  WHERE dih.uo = hou.name
	AND   hou.organization_id= fspa.org_id
	AND   dih.HEADER_ACTION = 'UPDATE'
	AND   dih.statut IN ('VALIDATED','PROCESSING_ERROR')
	AND   dih.po_number     = dil.po_number
	AND   dil.line_action   = 'ADD'
  FOR UPDATE;
--ivalua_line_id BNZ: KDFI-1374
  CURSOR C_LIGNE_AMAJ (P_CMD VARCHAR2) IS
  SELECT to_number(replace ( req_line,'-','' )) rec_line1 ,nvl( substr( req_line,1,instr(req_line,'-')-1),0) REC_line2 ,DKA_IPOCDE_LINES.* FROM   DKA_IPOCDE_LINES
  WHERE  po_number = P_CMD
  AND LINE_ACTION = 'ADD'
  AND STATUT IN ('VALIDATED','PROCESSING_ERROR')
  order by 2,1
  FOR UPDATE;

  V_PO_HEADERS_INTERFACE_ID NUMBER;
  V_PO_LINES_INTERFACE_ID   NUMBER;
  v_procedure              VARCHAR2(30):='IMPORT_DONNEES';
  v_etape                  VARCHAR2(500);
  v_org_depense            HR_ORGANIZATION_UNITS.name%TYPE;
  v_line_num               PO_LINES_ALL.line_num%TYPE;
  cpt_line_add              NUMBER := 0 ;
  BEGIN
    v_etape := 'Insertion dans la table PO_HEADERS_INTERFACE';
    DKA_TOOLS_PKG.put_log_message(v_etape);
    FOR REC_CMD_ACREER IN C_CMD_ACREER	LOOP
      DKA_TOOLS_PKG.put_log_message('Initialiser la séquence utilisé pour le champ numéro de la ligne');
      INIT_SEQUENCE;
      DKA_TOOLS_PKG.put_log_message('cmd à importer: '||REC_CMD_ACREER.po_number);
	    SELECT PO_HEADERS_INTERFACE_S.NEXTVAL
	    INTO   V_PO_HEADERS_INTERFACE_ID
	    FROM DUAL;
	    DKA_TOOLS_PKG.put_log_message('V_PO_HEADERS_INTERFACE_ID: '||V_PO_HEADERS_INTERFACE_ID);
      INSERT INTO PO_HEADERS_INTERFACE
        (   INTERFACE_HEADER_ID
        ,   BATCH_ID
        ,   PROCESS_CODE
        ,   ACTION
        ,   ORG_ID
        ,   DOCUMENT_TYPE_CODE
        ,   DOCUMENT_NUM
        ,   CURRENCY_CODE
        ,   AGENT_ID
        ,   VENDOR_ID
        ,   VENDOR_SITE_ID
        ,   SHIP_TO_LOCATION_ID
        ,   BILL_TO_LOCATION_ID
        ,   APPROVAL_STATUS
        ,   APPROVED_DATE
        ,   COMMENTS
        ,   CLOSED_CODE
        ,   ATTRIBUTE6
        ,   ATTRIBUTE7
        ,   ATTRIBUTE8
        ,   ATTRIBUTE10
        ,   ATTRIBUTE11
        ,   ATTRIBUTE13
        ,   CREATION_DATE
        ,   CREATED_BY
        )
        VALUES
		   (    V_PO_HEADERS_INTERFACE_ID
		    ,   gn_batch_id
        ,   'PENDING'
        ,   'ORIGINAL'
        ,   REC_CMD_ACREER.ORGANIZATION_ID
        ,   'STANDARD'
        ,   REC_CMD_ACREER.po_number
        ,   REC_CMD_ACREER.currency
        ,   REC_CMD_ACREER.agent_id
        ,   REC_CMD_ACREER.vendor_id
        ,   REC_CMD_ACREER.vendor_site_id
        ,   REC_CMD_ACREER.SHIP_TO_LOCATION_ID --(definir)
	     	,   REC_CMD_ACREER.BILL_TO_LOCATION_ID --(definir)
        ,   'APPROVED'
        ,   SYSDATE
        ,   REC_CMD_ACREER.DESCRIPTION
        ,   'OPEN'
        ,   'NON'
        ,   'IVALUA'
        ,   'OUI'
        ,   REC_CMD_ACREER.AMENDMENT_NUMBER
        ,   to_char(REC_CMD_ACREER.PO_CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')
        ,   REC_CMD_ACREER.DIRECT_PAYMENT
        ,   SYSDATE
        ,   g_user
        );

		  FOR REC_LIGNE_ACREER IN C_LIGNE_ACREER(REC_CMD_ACREER.po_number) LOOP
	        v_etape := 'Insertion dans la table PO_LINES_INTERFACE';
          DKA_TOOLS_PKG.put_log_message(v_etape);
          DKA_TOOLS_PKG.put_log_message('Ligne à imporeter : '||REC_LIGNE_ACREER.ivalua_line_id);
	        SELECT PO_LINES_INTERFACE_S.NEXTVAL
          INTO   V_PO_LINES_INTERFACE_ID
          FROM DUAL;
          -- identification de l''Organisation de dépense
          BEGIN
            SELECT org.name
            INTO v_org_depense
            FROM PA_PROJECTS_ALL ppa
            ,    HR_ORGANIZATION_UNITS org
            WHERE ppa.name = REC_LIGNE_ACREER.code_projet
            AND   ppa.CARRYING_OUT_ORGANIZATION_ID = ORG.ORGANIZATION_ID
            AND   sysdate BETWEEN NVL(org.date_from,sysdate) AND NVL(org.date_to ,sysdate);
          EXCEPTION
            WHEN OTHERS THEN
              v_org_depense := NULL;
              pn_retcode   := 2;
              DKA_TOOLS_PKG.put_log_message('ERROR lors de l''identification de l''Organisation de dépense');
          END;
            INSERT INTO PO_LINES_INTERFACE
              (   INTERFACE_HEADER_ID
              ,   INTERFACE_LINE_ID
              ,   ACTION
              ,   LINE_NUM
              ,   SHIPMENT_NUM
              ,   SHIPMENT_TYPE
              ,   LINE_TYPE
              ,   CATEGORY_iD
              ,   ITEM_DESCRIPTION
              ,   VENDOR_PRODUCT_NUM
              ,   UOM_CODE
              ,   QUANTITY
              ,   UNIT_PRICE
              ,   CLOSED_CODE
              ,   SHIP_TO_ORGANIZATION_ID
              ,   SHIP_TO_LOCATION
              ,   NEED_BY_DATE
              ,   LINE_ATTRIBUTE3
              ,   LINE_ATTRIBUTE4
              ,   LINE_ATTRIBUTE5
              ,   LINE_ATTRIBUTE6
              ,   LINE_ATTRIBUTE7
              ,   LINE_ATTRIBUTE8
              ,   CREATION_DATE
              ,   CREATED_BY
              ,   ORGANIZATION_ID
              ,   PROCESS_CODE
              ,   LINE_LOC_POPULATED_FLAG

            )
              VALUES
		  	    (     V_PO_HEADERS_INTERFACE_ID
              ,   V_PO_LINES_INTERFACE_ID
              ,   'ORIGINAL'
              ,   DKA_IPOCDE_LINENUM_S.NEXTVAL
              ,   1
              ,   'STANDARD'
              ,   'MATERIEL'
              ,   REC_LIGNE_ACREER.category_id--DECODE(REC_LIGNE_ACREER.TYPE_LINE,'FRAIS',gn_default_value2,gn_default_value1)
              ,   REC_LIGNE_ACREER.LINE_DESCRIPTION
              ,   REC_LIGNE_ACREER.SUPPLIER_ITEM_REFERENCE
              ,   REC_LIGNE_ACREER.UOM
              ,   REC_LIGNE_ACREER.QUANTITY
              ,   REC_LIGNE_ACREER.PRICE
              ,   'OPEN'
              ,   REC_CMD_ACREER.ORGANIZATION_ID
              ,   'Adresse temporaire' --RV-V03
              ,   REC_LIGNE_ACREER.DELIVERY_DATE
              ,   REC_LIGNE_ACREER.SITE_DK_CODE
              ,   REC_LIGNE_ACREER.PRODUCT_CODE
              ,   REC_LIGNE_ACREER.CATEGORY
              ,   REC_LIGNE_ACREER.CATALOG_PURCHASE
              ,   REC_LIGNE_ACREER.DELIVERY_ADDRESS_NAME
              ,   REC_LIGNE_ACREER.IVALUA_LINE_ID
              ,   SYSDATE

              ,   g_user
              ,   REC_CMD_ACREER.ORGANIZATION_ID
              ,   'PENDING'
              ,   'N'
		  	    );
		      DKA_TOOLS_PKG.put_log_message('afeter insert in lines tablese');
		      v_etape := 'Insertion dans la table PO_DISTRIBUTIONS_INTERFACE';
          DKA_TOOLS_PKG.put_log_message(v_etape);

            INSERT INTO PO_DISTRIBUTIONS_INTERFACE
              (   INTERFACE_HEADER_ID
              ,   INTERFACE_LINE_ID
              ,   INTERFACE_DISTRIBUTION_iD
              ,   DISTRIBUTION_NUM
              ,   ORG_ID
              ,   QUANTITY_ORDERED
              ,   DELIVER_TO_LOCATION
              ,   DELIVER_TO_PERSON_ID
              ,   DESTINATION_TYPE_CODE
              ,   DESTINATION_ORGANIZATION_ID
              ,   SET_OF_BOOKS_ID
              ,   PROJECT
              ,   TASK
              ,   EXPENDITURE_TYPE
              ,   PROJECT_ACCOUNTING_CONTEXT
              ,   EXPENDITURE_ORGANIZATION
              ,   PROJECT_RELEATED_FLAG
              ,   EXPENDITURE_ITEM_DATE
              ,   ATTRIBUTE1
              ,   ATTRIBUTE2
              ,   CREATION_DATE
              ,   CREATED_BY

              )
              VALUES
              (   V_PO_HEADERS_INTERFACE_ID
              ,   V_PO_LINES_INTERFACE_ID
              ,   PO_DISTRIBUTIONS_INTERFACE_S.NEXTVAL
              ,   1
              ,   REC_CMD_ACREER.organization_id
              ,   REC_LIGNE_ACREER.QUANTITY
              ,   'Adresse temporaire' --A REVOIR
              ,   REC_LIGNE_ACREER.person_id
              ,   'EXPENSE'
              ,   REC_CMD_ACREER.organization_id
              ,   REC_CMD_ACREER.set_of_books_id -- AREVOIR
              ,   REC_LIGNE_ACREER.code_projet --'FA0019909Z-DRW0028 PF RESEAU E'-
              ,   REC_LIGNE_ACREER.FINANCIAL_TASK
              ,   REC_LIGNE_ACREER.EXPENSE_TYPE
              ,   'Y'
              ,   v_org_depense  --'B00001301D' -- A IMPLEMENTER
              ,   'Y'
              ,   SYSDATE
		          ,   REC_LIGNE_ACREER.REQ_LINE
		          ,   REC_LIGNE_ACREER.REQ_DESCRIPTION
              ,   SYSDATE
              ,   g_user
              )
              ;
          DKA_TOOLS_PKG.put_log_message('afeter insert in destribution tablese');
          UPDATE DKA_IPOCDE_LINES
          SET    INTERFACE_LINE_ID = V_PO_LINES_INTERFACE_ID
          ,      STATUT   = 'INSERTED_OI'
          where ivalua_line_id = REC_LIGNE_ACREER.ivalua_line_id;
	       -- WHERE CURRENT OF C_LIGNE_ACREER ;

	      END LOOP;
	    begin
        DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_IPOCDE_HEADER');
	      UPDATE DKA_IPOCDE_HEADERS
        SET STATUT   = 'INSERTED_OI'
        ,   INTERFACE_HEADER_ID  = V_PO_HEADERS_INTERFACE_ID
	      WHERE po_number= rec_CMD_ACREER.po_number;

      exception when others then
          DKA_TOOLS_PKG.put_log_message('update statut de la table DKA_IPOCDE_HEADERS a échoué');
      end;

    END LOOP; --FIN LOOP C_CMD_ACREER

 	FOR REC_CMD_AMAJ IN C_CMD_AMAJ	LOOP
    DKA_TOOLS_PKG.put_log_message('Initialiser la séquence utilisé pour le champ numéro de la ligne');
   -- INIT_SEQUENCE;
    DKA_TOOLS_PKG.put_log_message('cmd à importer: '||REC_CMD_AMAJ.po_number);
	  SELECT PO_HEADERS_INTERFACE_S.NEXTVAL
	  INTO   V_PO_HEADERS_INTERFACE_ID
	  FROM DUAL;
	  DKA_TOOLS_PKG.put_log_message('V_PO_HEADERS_INTERFACE_ID: '||V_PO_HEADERS_INTERFACE_ID);
      INSERT INTO PO_HEADERS_INTERFACE
        (   INTERFACE_HEADER_ID
        ,   BATCH_ID
        ,   PROCESS_CODE
        ,   ACTION
        ,   ORG_ID
        ,   DOCUMENT_TYPE_CODE
        ,   DOCUMENT_NUM
        ,   CURRENCY_CODE
        ,   AGENT_ID
        ,   VENDOR_ID
        ,   VENDOR_SITE_ID
        ,   SHIP_TO_LOCATION_ID
        ,   BILL_TO_LOCATION_ID
        ,   APPROVAL_STATUS
        ,   APPROVED_DATE
        ,   COMMENTS
        ,   CLOSED_CODE
        ,   ATTRIBUTE6
        ,   ATTRIBUTE7
        ,   ATTRIBUTE8
        ,   ATTRIBUTE10
        ,   ATTRIBUTE11
        ,   ATTRIBUTE13
        ,   CREATION_DATE
        ,   CREATED_BY
        )
        VALUES
		   (    V_PO_HEADERS_INTERFACE_ID
		    ,   gn_batch_id
        ,   'PENDING'
        ,   'UPDATE'
        ,   REC_CMD_AMAJ.ORGANIZATION_ID
        ,   'STANDARD'
        ,   REC_CMD_AMAJ.po_number
        ,   REC_CMD_AMAJ.currency
        ,   REC_CMD_AMAJ.agent_id
        ,   REC_CMD_AMAJ.vendor_id
        ,   REC_CMD_AMAJ.vendor_site_id
        ,   REC_CMD_AMAJ.SHIP_TO_LOCATION_ID --(definir)
		    ,   REC_CMD_AMAJ.BILL_TO_LOCATION_ID --(definir)
        ,   'APPROVED'
        ,   SYSDATE
        ,   REC_CMD_AMAJ.DESCRIPTION
        ,   'OPEN'
        ,   'NON'
        ,   'IVALUA'
        ,   'OUI'
        ,   REC_CMD_AMAJ.AMENDMENT_NUMBER
        ,   to_char(REC_CMD_AMAJ.PO_CREATION_DATE,'DD/MM/YYYY HH24:MI:SS')
        ,   REC_CMD_AMAJ.DIRECT_PAYMENT
        ,   SYSDATE
        ,   g_user
        );
       cpt_line_add := 0 ;
    BEGIN
           SELECT max(line_num)
           INTO   v_line_num
           FROM PO_HEADERS_ALL pha
		       ,    PO_LINES_ALL pla
           WHERE pla.PO_HEADER_ID = pha.PO_HEADER_ID
           AND  pha.segment1 =REC_CMD_AMAJ.po_number;
    END;
		FOR REC_LIGNE_AMAJ IN C_LIGNE_AMAJ(REC_CMD_AMAJ.po_number) LOOP
      --cpt_line_add := cpt_line_add + 1 ;
	      v_etape := 'Insertion dans la table PO_LINES_INTERFACE';
        DKA_TOOLS_PKG.put_log_message(v_etape);
        DKA_TOOLS_PKG.put_log_message('Ligne à imporeter : '||REC_LIGNE_AMAJ.ivalua_line_id);
	      SELECT PO_LINES_INTERFACE_S.NEXTVAL
        INTO   V_PO_LINES_INTERFACE_ID
        FROM DUAL;
         /*BEGIN
           SELECT max(line_num)
           INTO   v_line_num
           FROM PO_HEADERS_ALL pha
		       ,    PO_LINES_ALL pla
           WHERE pla.PO_HEADER_ID = pha.PO_HEADER_ID
           AND  pha.segment1 =REC_CMD_AMAJ.po_number;
         END;  */

        v_line_num := v_line_num + 1 ;

         -- identification de l''Organisation de dépense
          BEGIN
            SELECT org.name
            INTO v_org_depense
            FROM PA_PROJECTS_ALL ppa
            ,    HR_ORGANIZATION_UNITS org
            WHERE ppa.name = REC_LIGNE_AMAJ.code_projet
            AND   ppa.CARRYING_OUT_ORGANIZATION_ID = ORG.ORGANIZATION_ID
            AND   sysdate BETWEEN NVL(org.date_from,sysdate) AND NVL(org.date_to ,sysdate);
          EXCEPTION
            WHEN OTHERS THEN
              v_org_depense := NULL;
              pn_retcode   := 2;
              DKA_TOOLS_PKG.put_log_message('ERROR lors de l''identification de l''Organisation de dépense');
          END;
          INSERT INTO PO_LINES_INTERFACE
            (   INTERFACE_HEADER_ID
            ,   INTERFACE_LINE_ID
            ,   ACTION
            ,   LINE_NUM
            ,   SHIPMENT_NUM
            ,   SHIPMENT_TYPE
            ,   LINE_TYPE
            ,   CATEGORY_iD
            ,   ITEM_DESCRIPTION
            ,   VENDOR_PRODUCT_NUM
            ,   UOM_CODE
            ,   QUANTITY
            ,   UNIT_PRICE
            ,   CLOSED_CODE
            ,   SHIP_TO_ORGANIZATION_ID
            ,   SHIP_TO_LOCATION
            ,   NEED_BY_DATE
            ,   LINE_ATTRIBUTE3
            ,   LINE_ATTRIBUTE4
            ,   LINE_ATTRIBUTE5
            ,   LINE_ATTRIBUTE6
            ,   LINE_ATTRIBUTE7
            ,   LINE_ATTRIBUTE8
            ,   CREATION_DATE
            ,   CREATED_BY
            ,   ORGANIZATION_ID
            ,   PROCESS_CODE
            ,   LINE_LOC_POPULATED_FLAG

            )
            VALUES
			     (    V_PO_HEADERS_INTERFACE_ID
            ,   V_PO_LINES_INTERFACE_ID
            ,   'ORIGINAL'
            ,   v_line_num --DKA_IPOCDE_LINENUM_S.NEXTVAL
            ,   1
            ,   'STANDARD'
            ,   'MATERIEL'
            ,   DECODE(REC_LIGNE_AMAJ.TYPE_LINE,'FRAIS',gn_default_value2,gn_default_value1)
            ,   REC_LIGNE_AMAJ.LINE_DESCRIPTION
            ,   REC_LIGNE_AMAJ.SUPPLIER_ITEM_REFERENCE
            ,   REC_LIGNE_AMAJ.UOM
            ,   REC_LIGNE_AMAJ.QUANTITY
            ,   REC_LIGNE_AMAJ.PRICE
            ,   'OPEN'
            ,   REC_CMD_AMAJ.ORGANIZATION_ID
            ,   'Adresse temporaire' --RV-V03
            ,   REC_LIGNE_AMAJ.DELIVERY_DATE
            ,   REC_LIGNE_AMAJ.SITE_DK_CODE
            ,   REC_LIGNE_AMAJ.PRODUCT_CODE
            ,   REC_LIGNE_AMAJ.CATEGORY
            ,   REC_LIGNE_AMAJ.CATALOG_PURCHASE
            ,   REC_LIGNE_AMAJ.DELIVERY_ADDRESS_NAME
            ,   REC_LIGNE_AMAJ.IVALUA_LINE_ID
            ,   SYSDATE

            ,   g_user
            ,   REC_CMD_AMAJ.ORGANIZATION_ID
            ,   'PENDING'
            ,   'N'
			    );
		    DKA_TOOLS_PKG.put_log_message('afeter insert in lines tablese');
		    v_etape := 'Insertion dans la table PO_DISTRIBUTIONS_INTERFACE';
        DKA_TOOLS_PKG.put_log_message(v_etape);

          INSERT INTO PO_DISTRIBUTIONS_INTERFACE
            (   INTERFACE_HEADER_ID
            ,   INTERFACE_LINE_ID
            ,   INTERFACE_DISTRIBUTION_iD
            ,   DISTRIBUTION_NUM
            ,   ORG_ID
            ,   QUANTITY_ORDERED
            ,   DELIVER_TO_LOCATION
            ,   DELIVER_TO_PERSON_ID
            ,   DESTINATION_TYPE_CODE
            ,   DESTINATION_ORGANIZATION_ID
            ,   SET_OF_BOOKS_ID
            ,   PROJECT
            ,   TASK
            ,   EXPENDITURE_TYPE
            ,   PROJECT_ACCOUNTING_CONTEXT
            ,   EXPENDITURE_ORGANIZATION
            ,   PROJECT_RELEATED_FLAG
            ,   EXPENDITURE_ITEM_DATE
            ,   ATTRIBUTE1
            ,   ATTRIBUTE2
            ,   CREATION_DATE
            ,   CREATED_BY
            )
            VALUES
            (   V_PO_HEADERS_INTERFACE_ID
            ,   V_PO_LINES_INTERFACE_ID
            ,   PO_DISTRIBUTIONS_INTERFACE_S.NEXTVAL
            ,   1
            ,   REC_CMD_AMAJ.organization_id
            ,   REC_LIGNE_AMAJ.QUANTITY
            ,   'Adresse temporaire' --A REVOIR
            ,   REC_LIGNE_AMAJ.person_id
            ,   'EXPENSE'
            ,   REC_CMD_AMAJ.organization_id
            ,   REC_CMD_AMAJ.set_of_books_id -- AREVOIR
            ,   REC_LIGNE_AMAJ.code_projet
            ,   REC_LIGNE_AMAJ.FINANCIAL_TASK
            ,   REC_LIGNE_AMAJ.EXPENSE_TYPE
            ,   'Y'
            ,   v_org_depense --'B00001301D' -- A IMPLEMENTER
            ,   'Y'
            ,   SYSDATE
		        ,   REC_LIGNE_AMAJ.REQ_LINE
		        ,   REC_LIGNE_AMAJ.REQ_DESCRIPTION
            ,   SYSDATE
            ,   g_user
            )
            ;
        DKA_TOOLS_PKG.put_log_message('afeter insert in destribution tablese');
        UPDATE DKA_IPOCDE_LINES
        SET    INTERFACE_LINE_ID = V_PO_LINES_INTERFACE_ID
		    ,      STATUT            = 'INSERTED_OI'
	      WHERE CURRENT OF C_LIGNE_AMAJ ;

	  END LOOP;
      UPDATE DKA_IPOCDE_HEADERS
        SET --STATUT   = 'INSERTED_OI',
           INTERFACE_HEADER_ID  = V_PO_HEADERS_INTERFACE_ID
	      WHERE po_number= rec_CMD_AMAJ.po_number;

  END LOOP; -- fIN LOOP C_CMD_AMAJ

  COMMIT;

  EXCEPTION
    WHEN OTHERS THEN
	    pn_retcode   := 2;
      pv_errbuf    := 'IMPORT_DONNEES : ' ||SQLERRM;
      DKA_TOOLS_PKG.put_log_message(pv_errbuf);
	    DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure IMPORT_DONNEES : EXCEPTION OTHERS ');

  END IMPORT_DONNEES;
/*======================================================================================================*/
  --  Nom           : get_ccid
  --  Description   : Procédure de calcul de la ccid
  --  PARAMETRES    :
/*=========================================================================================================*/

  PROCEDURE get_ccid(
                     pn_project_id                 IN NUMBER,
                     pn_task_id                    IN NUMBER,
                     pn_vendor_id                  IN NUMBER,
                     pn_agent_id                   IN NUMBER,
                     pn_line_type_id               IN NUMBER,
                     pn_set_of_books_id            IN NUMBER,
                     pn_destination_org_id         IN NUMBER,
                     pn_expenditure_type           IN VARCHAR2,
                     pn_charge_ccid                OUT NUMBER,
                     pn_retcode                    OUT NUMBER,
                     pv_err_msg                    OUT VARCHAR2) IS
    result BOOLEAN;

    l_charge_success              BOOLEAN;
    l_budget_success              BOOLEAN;
    l_accrual_success             BOOLEAN;
    l_variance_success            BOOLEAN;
    l_code_combination_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_budget_account_id           gl_code_combinations_kfv.code_combination_id%TYPE;
    l_accrual_account_id          gl_code_combinations_kfv.code_combination_id%TYPE;
    l_variance_account_id         gl_code_combinations_kfv.code_combination_id%TYPE;
    l_charge_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_budget_account_flex         gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_accrual_account_flex        gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_variance_account_flex       gl_code_combinations_kfv.concatenated_segments%TYPE;
    l_charge_account_desc         gl_code_combinations_kfv.description%TYPE;
    l_budget_account_desc         gl_code_combinations_kfv.description%TYPE;
    l_accrual_account_desc        gl_code_combinations_kfv.description%TYPE;
    l_variance_account_desc       gl_code_combinations_kfv.description%TYPE;
    l_coa_id                      NUMBER;
    l_bom_resource_id             NUMBER;
    l_bom_cost_element_id         NUMBER;
    l_category_id                 NUMBER;
    l_destination_type_code       VARCHAR2(100);
    l_deliver_to_location_id      NUMBER;
    l_destination_organization_id NUMBER;
    l_destination_subinventory    VARCHAR2(100);
    l_expenditure_type            VARCHAR2(100);
    l_expenditure_organization_id NUMBER;
    l_expenditure_item_date       DATE;
    l_item_id                     NUMBER;
    l_line_type_id                NUMBER;
    l_result_billable_flag        VARCHAR2(100);
    l_agent_id                    NUMBER;
    l_project_id                  NUMBER;
    l_from_type_lookup_code       VARCHAR2(100);
    l_from_header_id              NUMBER;
    l_from_line_id                NUMBER;
    l_task_id                     NUMBER;
    l_deliver_to_person_id        NUMBER;
    l_type_lookup_code            VARCHAR2(100);
    l_vendor_id                   NUMBER;
    l_wip_entity_id               NUMBER;
    l_wip_entity_type             VARCHAR2(100);
    l_wip_line_id                 NUMBER;
    l_wip_repetitive_schedule_id  NUMBER;
    l_wip_operation_seq_num       NUMBER;
    l_wip_resource_seq_num        NUMBER;
    l_po_encumberance_flag        VARCHAR2(100);
    l_gl_encumbered_date          DATE;
    l_wf_itemkey                  VARCHAR2(100);
    l_new_combination             BOOLEAN;
    l_header_att1                 VARCHAR2(240);
    l_header_att2                 VARCHAR2(240);
    l_header_att3                 VARCHAR2(240);
    l_header_att4                 VARCHAR2(240);
    l_header_att5                 VARCHAR2(240);
    l_header_att6                 VARCHAR2(240);
    l_header_att7                 VARCHAR2(240);
    l_header_att8                 VARCHAR2(240);
    l_header_att9                 VARCHAR2(240);
    l_header_att10                VARCHAR2(240);
    l_header_att11                VARCHAR2(240);
    l_header_att12                VARCHAR2(240);
    l_header_att13                VARCHAR2(240);
    l_header_att14                VARCHAR2(240);
    l_header_att15                VARCHAR2(240);
    l_line_att1                   VARCHAR2(240);
    l_line_att2                   VARCHAR2(240);
    l_line_att3                   VARCHAR2(240);
    l_line_att4                   VARCHAR2(240);
    l_line_att5                   VARCHAR2(240);
    l_line_att6                   VARCHAR2(240);
    l_line_att7                   VARCHAR2(240);
    l_line_att8                   VARCHAR2(240);
    l_line_att9                   VARCHAR2(240);
    l_line_att10                  VARCHAR2(240);
    l_line_att11                  VARCHAR2(240);
    l_line_att12                  VARCHAR2(240);
    l_line_att13                  VARCHAR2(240);
    l_line_att14                  VARCHAR2(240);
    l_line_att15                  VARCHAR2(240);
    l_shipment_att1               VARCHAR2(240);
    l_shipment_att2               VARCHAR2(240);
    l_shipment_att3               VARCHAR2(240);
    l_shipment_att4               VARCHAR2(240);
    l_shipment_att5               VARCHAR2(240);
    l_shipment_att6               VARCHAR2(240);
    l_shipment_att7               VARCHAR2(240);
    l_shipment_att8               VARCHAR2(240);
    l_shipment_att9               VARCHAR2(240);
    l_shipment_att10              VARCHAR2(240);
    l_shipment_att11              VARCHAR2(240);
    l_shipment_att12              VARCHAR2(240);
    l_shipment_att13              VARCHAR2(240);
    l_shipment_att14              VARCHAR2(240);
    l_shipment_att15              VARCHAR2(240);
    l_distribution_att1           VARCHAR2(240);
    l_distribution_att2           VARCHAR2(240);
    l_distribution_att3           VARCHAR2(240);
    l_distribution_att4           VARCHAR2(240);
    l_distribution_att5           VARCHAR2(240);
    l_distribution_att6           VARCHAR2(240);
    l_distribution_att7           VARCHAR2(240);
    l_distribution_att8           VARCHAR2(240);
    l_distribution_att9           VARCHAR2(240);
    l_distribution_att10          VARCHAR2(240);
    l_distribution_att11          VARCHAR2(240);
    l_distribution_att12          VARCHAR2(240);
    l_distribution_att13          VARCHAR2(240);
    l_distribution_att14          VARCHAR2(240);
    l_distribution_att15          VARCHAR2(240);
    l_fb_error_msg                VARCHAR2(1000);
    l_etape                       VARCHAR2(100);
    l_message                     VARCHAR2(1000);

    l_transaction_flow_header_id  NUMBER;
    l_dest_charge_success         BOOLEAN;
    l_dest_variance_success       BOOLEAN;
    l_dest_charge_account_id      NUMBER;
    l_dest_variance_account_id    NUMBER;
    l_dest_charge_account_desc    VARCHAR2(240);
    l_dest_variance_account_desc  VARCHAR2(240);
    l_dest_charge_account_flex    VARCHAR2(240);
    l_dest_variance_account_flex  VARCHAR2(240);

    e_error                       EXCEPTION;


  BEGIN
    l_etape := 'Début :';

    l_bom_cost_element_id   := NULL;
    l_from_type_lookup_code := NULL;
    l_from_header_id        := NULL;
    l_from_line_id          := NULL;
    l_wip_entity_type       := NULL;

    l_etape := 'Récuperation coa_id :';

      BEGIN
        SELECT chart_of_accounts_id
        INTO l_coa_id
        FROM gl_sets_of_books
        WHERE set_of_books_id = pn_set_of_books_id ; --rec_maj_entete.set_of_books_id;
      EXCEPTION
        WHEN OTHERS THEN
          l_message  := 'MAJ CCID : Impossible de récupérer le chart_of_accounts_id';
          pn_retcode := 1;
          raise e_error;
      END;

/*    l_etape := 'Récuperation project_id et task_id :';
      BEGIN
        SELECT pt.task_id,
               ppa.project_id,
               ppa.carrying_out_organization_id
        INTO   l_task_id,
               l_project_id,
               l_expenditure_organization_id
        FROM pa_tasks pt,
             pa_projects_all ppa
        WHERE pt.project_id = ppa.project_id
        AND   pt.task_number = pn_task_number--rec_maj_ligne.FINANCIAL_TASK
        AND   ppa.name       = pn_project_name ;--rec_maj_ligne.code_projet;




      EXCEPTION
        WHEN OTHERS THEN
	        l_message:='Impossible de récupérer les information tache_id,project_id' ;
			    pn_retcode := 1;
		      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'MAJ_CMD'
		                                   ,'DKA_IPOCDE_HEADERS'
		                                   , null
		                                   ,null
		                                   ,null
		                                   ,'E'
		                                   ,l_message
		    		                            );
      END;
*/



    l_etape := 'Appel po_wf_build_account_init.start_workflow :';
    IF l_message IS NULL  THEN
               result := po_wf_build_account_init.start_workflow(  x_purchasing_ou_id            => pn_destination_org_id,
                                                                   x_transaction_flow_header_id  => NULL,
                                                                   x_dest_charge_success         => l_dest_charge_success,
                                                                   x_dest_variance_success       => l_dest_variance_success,
                                                                   x_dest_charge_account_id      => l_dest_charge_account_id,
                                                                   x_dest_variance_account_id    => l_dest_variance_account_id,
                                                                   x_dest_charge_account_desc    => l_dest_charge_account_desc,
                                                                   x_dest_variance_account_desc  => l_dest_variance_account_desc,
                                                                   x_dest_charge_account_flex    => l_dest_charge_account_flex,
                                                                   x_dest_variance_account_flex  => l_dest_variance_account_flex,
                                                                   x_charge_success              => l_charge_success,
                                                                   x_budget_success              => l_budget_success,
                                                                   x_accrual_success             => l_accrual_success,
                                                                   x_variance_success            => l_variance_success,
                                                                   x_code_combination_id         => l_code_combination_id,
                                                                   x_budget_account_id           => l_budget_account_id,
                                                                   x_accrual_account_id          => l_accrual_account_id,
                                                                   x_variance_account_id         => l_variance_account_id,
                                                                   x_charge_account_flex         => l_charge_account_flex,
                                                                   x_budget_account_flex         => l_budget_account_flex,
                                                                   x_accrual_account_flex        => l_accrual_account_flex,
                                                                   x_variance_account_flex       => l_variance_account_flex,
                                                                   x_charge_account_desc         => l_charge_account_desc,
                                                                   x_budget_account_desc         => l_budget_account_desc,
                                                                   x_accrual_account_desc        => l_accrual_account_desc,
                                                                   x_variance_account_desc       => l_variance_account_desc,
                                                                   x_coa_id                      => l_coa_id,
                                                                   x_bom_resource_id             => l_bom_resource_id,
                                                                   x_bom_cost_element_id         => l_bom_cost_element_id,
                                                                   x_category_id                 => l_category_id,
                                                                   x_destination_type_code       => 'EXPENSE',     --
                                                                   x_deliver_to_location_id      => l_deliver_to_location_id,
                                                                   x_destination_organization_id => pn_destination_org_id,   --
                                                                   x_destination_subinventory    => l_destination_subinventory,
                                                                   x_expenditure_type            => pn_expenditure_type,                --
                                                                   x_expenditure_organization_id => l_expenditure_organization_id,     --
                                                                   x_expenditure_item_DATE       => SYSDATE,
                                                                   x_item_id                     => l_item_id,
                                                                   x_line_type_id                => pn_line_type_id,          --
                                                                   x_result_billable_flag        => 'N',
                                                                   x_agent_id                    => pn_agent_id,
                                                                   x_project_id                  => pn_project_id,          --
                                                                   x_from_type_lookup_code       => l_from_type_lookup_code,
                                                                   x_from_header_id              => l_from_header_id,
                                                                   x_from_line_id                => l_from_line_id,
                                                                   x_task_id                     => pn_task_id,          --
                                                                   x_deliver_to_person_id        => l_deliver_to_person_id,
                                                                   x_type_lookup_code            => 'STANDARD',
                                                                   x_vendor_id                   => l_vendor_id,       --
                                                                   x_wip_entity_id               => l_wip_entity_id,
                                                                   x_wip_entity_type             => l_wip_entity_type,
                                                                   x_wip_line_id                 => l_wip_line_id,
                                                                   x_wip_repetitive_schedule_id  => l_wip_repetitive_schedule_id,
                                                                   x_wip_operation_seq_num       => l_wip_operation_seq_num,
                                                                   x_wip_resource_seq_num        => l_wip_resource_seq_num,
                                                                   x_po_encumberance_flag        => 'N',
                                                                   x_gl_encumbered_DATE          => l_gl_encumbered_DATE,
                                                                   wf_itemkey                    => l_wf_itemkey,
                                                                   x_new_combination             => l_new_combination,
                                                                   header_att1                   => l_header_att1,
                                                                   header_att2                   => l_header_att2,
                                                                   header_att3                   => l_header_att3,
                                                                   header_att4                   => l_header_att4,
                                                                   header_att5                   => l_header_att5,
                                                                   header_att6                   => l_header_att6,
                                                                   header_att7                   => l_header_att7,
                                                                   header_att8                   => l_header_att8,
                                                                   header_att9                   => l_header_att9,
                                                                   header_att10                  => l_header_att10,
                                                                   header_att11                  => l_header_att11,
                                                                   header_att12                  => l_header_att12,
                                                                   header_att13                  => l_header_att13,
                                                                   header_att14                  => l_header_att14,
                                                                   header_att15                  => l_header_att15,
                                                                   line_att1                     => l_line_att1,
                                                                   line_att2                     => l_line_att2,
                                                                   line_att3                     => l_line_att3,
                                                                   line_att4                     => l_line_att4,
                                                                   line_att5                     => l_line_att5,
                                                                   line_att6                     => l_line_att6,
                                                                   line_att7                     => l_line_att7,
                                                                   line_att8                     => l_line_att8,
                                                                   line_att9                     => l_line_att9,
                                                                   line_att10                    => l_line_att10,
                                                                   line_att11                    => l_line_att11,
                                                                   line_att12                    => l_line_att12,
                                                                   line_att13                    => l_line_att13,
                                                                   line_att14                    => l_line_att14,
                                                                   line_att15                    => l_line_att15,
                                                                   shipment_att1                 => l_shipment_att1,
                                                                   shipment_att2                 => l_shipment_att2,
                                                                   shipment_att3                 => l_shipment_att3,
                                                                   shipment_att4                 => l_shipment_att4,
                                                                   shipment_att5                 => l_shipment_att5,
                                                                   shipment_att6                 => l_shipment_att6,
                                                                   shipment_att7                 => l_shipment_att7,
                                                                   shipment_att8                 => l_shipment_att8,
                                                                   shipment_att9                 => l_shipment_att9,
                                                                   shipment_att10                => l_shipment_att10,
                                                                   shipment_att11                => l_shipment_att11,
                                                                   shipment_att12                => l_shipment_att12,
                                                                   shipment_att13                => l_shipment_att13,
                                                                   shipment_att14                => l_shipment_att14,
                                                                   shipment_att15                => l_shipment_att15,
                                                                   distribution_att1             => l_distribution_att1,
                                                                   distribution_att2             => l_distribution_att2,
                                                                   distribution_att3             => l_distribution_att3,
                                                                   distribution_att4             => l_distribution_att4,
                                                                   distribution_att5             => l_distribution_att5,
                                                                   distribution_att6             => l_distribution_att6,
                                                                   distribution_att7             => l_distribution_att7,
                                                                   distribution_att8             => l_distribution_att8,
                                                                   distribution_att9             => l_distribution_att9,
                                                                   distribution_att10            => l_distribution_att10,
                                                                   distribution_att11            => l_distribution_att11,
                                                                   distribution_att12            => l_distribution_att12,
                                                                   distribution_att13            => l_distribution_att13,
                                                                   distribution_att14            => l_distribution_att14,
                                                                   distribution_att15            => l_distribution_att15,
                                                                   fb_error_msg                  => l_fb_error_msg);


    l_etape := 'Fin po_wf_build_account_init.start_workflow :';
      IF NOT l_charge_success
      THEN
        pv_err_msg  := 'ERREUR Workflow : '||l_fb_error_msg;
        pn_retcode := 1;
      ELSE
        pn_charge_ccid    := l_code_combination_id;
      END IF;
    END IF;
  EXCEPTION
    WHEN e_error THEN
      pn_retcode := 1;
      pv_err_msg := l_message;
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_err_msg  := 'GET_CCID =>' || l_etape || SQLERRM;
  END get_ccid;
/*======================================================================================================*/
  --  Nom           : MAJ_ENTETE_CMD
  --  Description   :
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          :

/*=========================================================================================================*/
  PROCEDURE MAJ_ENTETE_CMD(pv_errbuf        OUT VARCHAR2,
                           pn_retcode       OUT NUMBER
                          ) IS


  l_message VARCHAR2(1000);
  v_document_id         fnd_documents.document_id%TYPE;
  vn_retcode            NUMBER     ;
  vv_err_update         VARCHAR2(1000);
  vv_err_select         VARCHAR2(1000);
  vv_err_wf             VARCHAR2(1000);
  vv_err                VARCHAR2(1000);
  v_destination_org_id  NUMBER;
  v_line_type_id        NUMBER;
  v_type_line           VARCHAR2(50);
  v_ccid                NUMBER;
  v_project_id          NUMBER;
  v_task_id             NUMBER;
  v_expenditure_type    po_distributions_all.expenditure_type%TYPE;
  v_charge_ccid         NUMBER;


  CURSOR C_MAJ_ENTETE IS
  SELECT dih.*
  ,      pha.po_header_id
  ,      hou.set_of_books_id
  ,      hou.organization_id
  FROM DKA_IPOCDE_HEADERS dih
  --,    DKA_IPOCDE_LINES dil
  ,    PO_HEADERS_ALL pha
  ,    HR_OPERATING_UNITS hou
  WHERE	dih.HEADER_ACTION = 'UPDATE'
  AND  dih.STATUT IN ('VALIDATED','PROCESSING_ERROR')
  AND ((dih.STATUT_UPDATE_HEADER  IS NULL OR dih.STATUT_UPDATE_HEADER ='ERROR')
        OR exists (SELECT 'x' FROM DKA_IPOCDE_LINES dil
                 WHERE dil.po_number = dih.po_number
                 AND LINE_ACTION = 'UPDATE'
                 AND STATUT IN ('VALIDATED','PROCESSING_ERROR')))
 -- AND  dil.po_number = dih.po_number
  AND  dih.po_number = pha.segment1
  AND  dih.UO        = hou.name
  AND  pha.org_id    = hou.organization_id
  --AND  dil.line_action = 'UPDATE'
  FOR UPDATE;

  CURSOR C_MAJ_LIGNE(P_CMD VARCHAR2) IS
  SELECT * FROM DKA_IPOCDE_LINES
  WHERE PO_NUMBER = P_CMD
  AND LINE_ACTION = 'UPDATE'
  AND STATUT IN ('VALIDATED','PROCESSING_ERROR')
  FOR UPDATE;

  v_maj_error       NUMBER ;
  v_maj_error_ligne NUMBER;
BEGIN

  FOR rec_maj_entete IN C_MAJ_ENTETE
  LOOP
      v_maj_error := 0;
      v_document_id := 0;
      -- Récupération de l'Id du bon de commande
      BEGIN
        SELECT fd.document_id
        INTO   v_document_id
        FROM fnd_documents fd
        ,    fnd_attached_documents fad
        WHERE fd.document_id = fad.document_id
        AND   fad.pk1_value = rec_maj_entete.po_header_id
        AND   fad.entity_name = gv_entity_name -- 'PO_HEADERS'
        ;
      EXCEPTION
        WHEN OTHERS THEN
          pn_retcode := 1;
          l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I02','MESSAGE_ERREUR','Impossible de récupérer l''Id du document joint du Bon de commande');
          DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                         ,'DKA_IPOCMD_IVALUA'
                                         ,'IMPORT'
                                         ,'DKA_IPOCDE_HEADERS'
                                         , rec_maj_entete.record_id
                                         ,null
                                         ,null
                                         ,'E'
                                         ,l_message
                                         );
         v_maj_error := 1;
      END;

      IF v_document_id != 0
      THEN
         BEGIN

            UPDATE PO_HEADERS_ALL
            SET ATTRIBUTE10 = rec_maj_entete.AMENDMENT_NUMBER
            ,   COMMENTS = rec_maj_entete.DESCRIPTION
            ,   LAST_UPDATED_BY  = g_user
            ,   LAST_UPDATE_DATE = SYSDATE
            WHERE po_header_id = rec_maj_entete.po_header_id
            ;

            UPDATE fnd_documents
            SET   URL =rec_maj_entete.URL_BDC
                 ,LAST_UPDATED_BY  = g_user
                 ,LAST_UPDATE_DATE = SYSDATE
            WHERE document_id = v_document_id;
        EXCEPTION
        WHEN OTHERS THEN
           l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I02','MESSAGE_ERREUR',SQLERRM);
           DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                          ,'DKA_IPOCMD_IVALUA'
                                          ,'IMPORT'
                                          ,'DKA_IPOCDE_HEADERS'
                                          ,rec_maj_entete.record_id
                                          ,null
                                          ,null
                                          ,'E'
                                          ,l_message
                                         );
            DKA_TOOLS_PKG.put_log_message(l_message);
            pn_retcode := 1;
            v_maj_error := 1;
        END;
      END IF;

      IF v_maj_error != 0
      THEN
           --g_enreg_entete_rejete2 := g_enreg_entete_rejete2 + 1;
           UPDATE DKA_IPOCDE_HEADERS
           SET STATUT_UPDATE_HEADER = 'ERROR'
           WHERE record_id = rec_maj_entete.record_id;
      ELSE
           UPDATE DKA_IPOCDE_HEADERS
           SET STATUT_UPDATE_HEADER = 'SUCCESS'
           WHERE record_id = rec_maj_entete.record_id;
      END IF;


      FOR rec_maj_ligne IN C_MAJ_LIGNE(rec_maj_entete.po_number)
      LOOP
        v_maj_error_ligne  := 0;
        v_line_type_id     := 0;
        v_project_id       := 0;
        v_task_id          := 0;
        v_expenditure_type := NULL;

        BEGIN
          SELECT pla.line_type_id
                ,pda.project_id
                ,pda.task_id
                ,pda.expenditure_type
          INTO  v_line_type_id
               ,v_project_id
               ,v_task_id
               ,v_expenditure_type
          FROM   PO_LINES_ALL pla,
                 PO_DISTRIBUTIONS_ALL pda
          WHERE  pda.po_line_id = pla.po_line_id
          AND    pla.attribute8 = rec_maj_ligne.ivalua_line_id;
        EXCEPTION
        WHEN OTHERS THEN
          vv_err_select := 'ERROR lors de la récupération des line_type_id, project_id et task_id';
          l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I03','MESSAGE_ERREUR',vv_err_select);
          DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                       ,'DKA_IPOCMD_IVALUA'
                                       ,'IMPORT'
                                       ,'DKA_IPOCDE_LINES'
                                       , rec_maj_ligne.record_id
                                       ,'type ligne - projet - tâche' --pv_column_name
                                       ,NULL --pv_column_value
                                       ,'E'
                                      ,l_message
                                     );
          v_maj_error_ligne := 1;
        END;

        IF v_maj_error_ligne = 0
        THEN
           BEGIN
              UPDATE PO_LINES_ALL
              SET ITEM_DESCRIPTION = rec_maj_ligne.LINE_DESCRIPTION
                 ,UNIT_PRICE       = rec_maj_ligne.PRICE
                 ,ATTRIBUTE5       = rec_maj_ligne.CATEGORY
                 ,LAST_UPDATED_BY  = g_user
                 ,LAST_UPDATE_DATE = SYSDATE
              WHERE attribute8     = rec_maj_ligne.ivalua_line_id;
			  --DEBUT SHA
              UPDATE PO_LINE_LOCATIONS_ALL
			  SET PRICE_OVERRIDE   = rec_maj_ligne.PRICE
			     ,LAST_UPDATED_BY  = g_user
				 ,LAST_UPDATE_DATE = SYSDATE
			  where po_line_id     = (select po_line_id
                         			  from PO_LINES_ALL
									  where attribute8 = rec_maj_ligne.ivalua_line_id);
			  --FIN SHA
              IF v_expenditure_type != rec_maj_ligne.expense_type
              THEN

                 get_ccid(v_project_id
                         ,v_task_id
                         ,rec_maj_entete.vendor_id
                         ,rec_maj_entete.agent_id
                         ,v_line_type_id
                         ,rec_maj_entete.set_of_books_id
                         ,rec_maj_entete.organization_id
                         ,rec_maj_ligne.EXPENSE_TYPE
                         ,v_charge_ccid
                         ,vn_retcode
                         ,vv_err_wf
                         );

                  IF vn_retcode != 0
                  THEN
                      l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I03','MESSAGE_ERREUR',vv_err_wf);
                      DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                                     ,'DKA_IPOCMD_IVALUA'
                                                     ,'IMPORT'
                                                     ,'DKA_IPOCDE_LINES'
                                                     , rec_maj_ligne.record_id
                                                     ,'CCID' --pv_column_name
                                                     ,NULL --pv_column_value
                                                     ,'E'
                                                     ,l_message
                                                     );
                       v_maj_error_ligne := 1;
                  ELSE
                      UPDATE PO_DISTRIBUTIONS_ALL
                      SET    EXPENDITURE_TYPE = rec_maj_ligne.EXPENSE_TYPE
					        ,CODE_COMBINATION_ID = v_charge_ccid
                            ,ACCRUAL_ACCOUNT_ID =  ACCRUAL_ACCOUNT_ID -- Pas de modification du compte de charge car modif type de dépense n'a pas d'impact sur cette clé
                            ,VARIANCE_ACCOUNT_ID  = v_charge_ccid
                            ,LAST_UPDATED_BY = g_user
                            ,LAST_UPDATE_DATE = SYSDATE
                      WHERE  line_location_id = ( SELECT plla.line_location_id
                                                  FROM  PO_LINES_ALL pla
                                                  ,     po_line_locations_All plla
                                                  WHERE pla.po_line_id        = plla.po_line_id
                                                  AND   pla.attribute8        = rec_maj_ligne.ivalua_line_id);
                   END IF;
               END IF;

           EXCEPTION
           WHEN OTHERS THEN
               vv_err    := SQLERRM;
               l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I03','MESSAGE_ERREUR',vv_err);
               DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                              ,'DKA_IPOCMD_IVALUA'
                                              ,'IMPORT'
                                              ,'DKA_IPOCDE_LINES'
                                              , rec_maj_ligne.record_id
                                              ,null
                                              ,null
                                              ,'E'
                                              ,l_message
                                              );
               v_maj_error_ligne := 1;
           END;

		   END IF;

     -- Début SHA CR76

           BEGIN
              UPDATE PO_LINES_ALL
              SET
                 UNIT_PRICE       = rec_maj_ligne.PRICE
				 ,QUANTITY         = rec_maj_ligne.QUANTITY
                 ,LAST_UPDATED_BY  = g_user
                 ,LAST_UPDATE_DATE = SYSDATE
              WHERE attribute8     = rec_maj_ligne.ivalua_line_id;

              UPDATE PO_LINE_LOCATIONS_ALL
			  SET PRICE_OVERRIDE   = rec_maj_ligne.PRICE
			     ,QUANTITY         = rec_maj_ligne.QUANTITY
			     ,LAST_UPDATED_BY  = g_user
				 ,LAST_UPDATE_DATE = SYSDATE
			  where po_line_id     = (select po_line_id
                         			  from PO_LINES_ALL
									  where attribute8 = rec_maj_ligne.ivalua_line_id);
    		  UPDATE PO_DISTRIBUTIONS_ALL
			  SET   quantity_ordered = rec_maj_ligne.QUANTITY
					,LAST_UPDATED_BY = g_user
					,LAST_UPDATE_DATE = SYSDATE
			  WHERE  line_location_id = ( SELECT plla.line_location_id
										  FROM  PO_LINES_ALL pla
										  ,     po_line_locations_All plla
										  WHERE pla.po_line_id        = plla.po_line_id
										  AND   pla.attribute8        = rec_maj_ligne.ivalua_line_id);

            EXCEPTION
           WHEN OTHERS THEN
               vv_err    := SQLERRM;
               l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I03','MESSAGE_ERREUR',vv_err);
               DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                              ,'DKA_IPOCMD_IVALUA'
                                              ,'IMPORT'
                                              ,'DKA_IPOCDE_LINES'
                                              , rec_maj_ligne.record_id
                                              ,null
                                              ,null
                                              ,'E'
                                              ,l_message
                                              );
               v_maj_error_ligne := 1;
            END;
		-- Fin SHA CR76

        IF v_maj_error_ligne = 0
        THEN
           UPDATE DKA_IPOCDE_LINES
           SET STATUT ='PROCESSING_SUCCESS'
           WHERE CURRENT OF C_MAJ_LIGNE;
        ELSE
           UPDATE DKA_IPOCDE_LINES
           SET STATUT ='PROCESSING_ERROR'
           WHERE CURRENT OF C_MAJ_LIGNE;
          -- g_enreg_line_rejete2 := g_enreg_line_rejete2 + 1;
           pn_retcode := 1;
        END IF;
     END LOOP; -- END LOOP C_MAJ_LIGNE
  END LOOP; -- EN LOOP C_MAJ_ENTETE
  COMMIT;
END MAJ_ENTETE_CMD;
/*======================================================================================================*/
  --  Nom           : ANNUL_ENTETE_CMD
  --  Description   :
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          :

/*=========================================================================================================*/
  PROCEDURE ANNUL_ENTETE_CMD(pv_errbuf        OUT VARCHAR2,
                             pn_retcode       OUT NUMBER
                            ) IS
  CURSOR C_ANNUL_ENTETE IS
  SELECT dih.po_number
  ,      dih.record_id
  ,      hou.organization_id
  ,      pha.po_header_id
  ,      pha.org_id
  ,      SUM(plla.QUANTITY_RECEIVED) QUANTITY_RECEIVED -- SHA EBD262
  FROM DKA_IPOCDE_HEADERS dih
  ,    PO_HEADERS_ALL pha
  ,    PO_LINES_ALL pla
  ,    po_line_locations_All plla
  ,    hr_operating_units hou
  WHERE	dih.HEADER_ACTION in ( 'CANCEL' ,'CREATE_CANCEL') -- SHA-EDB310
  AND  pla.po_header_id = pha.po_header_id
  AND  plla.po_line_id  = pla.po_line_id
  AND  dih.STATUT IN ('VALIDATED','PROCESSING_ERROR_CAN','COMPLETE_CREATE') -- SHA-EDB310 modification suite à la RG4343-01
  AND  dih.po_number = pha.segment1
  AND  hou.organization_id = pha.org_id
  AND  hou.name = dih.uo
  GROUP BY pha.po_header_id ,
  hou.organization_id,
  dih.po_number ,
  dih.record_id,
  pha.org_id;

  v_return_status   VARCHAR2 (10);
  v_msg_data        VARCHAR2(1000);
  l_message         VARCHAR2(1000);
  v_doc_subtype     VARCHAR2(10)  := 'STANDARD';
  v_doc_type        VARCHAR2(10)  := 'PO';
  v_action          VARCHAR2(10)  := 'CANCEL';
  v_action_date     DATE          := SYSDATE;
  v_employe         per_all_people_f.person_id%TYPE;
  cpt_annul_succes  NUMBER := 0;
  cpt_a_annulee     NUMBER := 0;
  v_erreur_annul    NUMBER :=0;
  vv_erreur         NUMBER :=0;
  BEGIN
    FOR REC_ANNUL_ENTETE IN C_ANNUL_ENTETE LOOP
	  IF (REC_ANNUL_ENTETE.QUANTITY_RECEIVED)= 0 THEN

	    po_document_control_pub.control_document(p_api_version => 1.0, -- p_api_version
                                                 p_init_msg_list => fnd_api.g_true, -- p_init_msg_list
                                                 p_commit => fnd_api.g_true, -- p_commit
                                                 x_return_status => v_return_status, -- x_return_status
                                                 p_doc_type => 'PO', -- p_doc_type
                                                 p_doc_subtype => 'STANDARD', -- p_doc_subtype
                                                 p_doc_id => REC_ANNUL_ENTETE.po_header_id, -- p_doc_id
                                                 p_doc_num => NULL, -- p_doc_num
                                                 p_release_id => NULL, -- p_release_id
                                                 p_release_num => NULL, -- p_release_num
                                                 p_doc_line_id => NULL, -- p_doc_line_id
                                                 p_doc_line_num => NULL, -- p_doc_line_num
                                                 p_doc_line_loc_id => NULL, -- p_doc_line_loc_id
                                                 p_doc_shipment_num => NULL, -- p_doc_shipment_num
                                                 p_action => 'CANCEL', -- p_action
                                                 p_action_date => SYSDATE, -- p_action_date
                                                 p_cancel_reason => NULL, -- p_cancel_reason
                                                 p_cancel_reqs_flag => 'N', -- p_cancel_reqs_flag
                                                 p_print_flag => NULL, -- p_print_flag
                                                 p_note_to_vendor => NULL, -- p_note_to_vendor
                                                 p_use_gldate =>NULL ,
                                                 p_org_id => REC_ANNUL_ENTETE.org_id
                                                 );
      COMMIT;
      IF v_return_status = fnd_api.g_ret_sts_success THEN
        COMMIT;

        l_message := 'Annulation de la commande '||REC_ANNUL_ENTETE.po_number ||' a été bien passée';
		    DKA_TOOLS_PKG.put_log_message(l_message);
		    UPDATE DKA_IPOCDE_HEADERS
		    SET STATUT = 'COMPLETE'
		    WHERE po_number = REC_ANNUL_ENTETE.po_number;

        UPDATE DKA_IPOCDE_LINES
		    SET STATUT = 'COMPLETE'
		    WHERE po_number = REC_ANNUL_ENTETE.po_number;

      ELSE
        FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
          v_msg_data := FND_MSG_PUB.GET( p_msg_index => i, p_encoded => 'F');
			    l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I05','MESSAGE_API',v_msg_data);
		      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'IMPORT'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 ,REC_ANNUL_ENTETE.record_id
		                                 ,null
		                                 ,null
		                                 ,'E'
		                                 ,l_message
		  		                       );
		      DKA_TOOLS_PKG.put_log_message(l_message);
          --g_enreg_entete_rejete2 := g_enreg_entete_rejete2 + 1;
			    UPDATE DKA_IPOCDE_HEADERS
		      SET STATUT = 'PROCESSING_ERROR_CAN'-- SHA-EDB310
		      WHERE po_number = REC_ANNUL_ENTETE.po_number;
          pn_retcode :=1;
        END LOOP;
      END IF;

	ELSE
	-- SHA EBD262
	 FOR rec_annul IN (SELECT pla.*
                        FROM PO_LINES_ALL pla
                        ,    PO_HEADERS_ALL pha
						,    po_line_locations_All plla
	                      WHERE  pla.po_header_id = pha.po_header_id
						  and    plla.po_line_id  = pla.po_line_id
						  and    plla.QUANTITY_RECEIVED = 0
                          AND    pha.po_header_id  = REC_ANNUL_ENTETE.po_header_id
	                      AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
                        AND   pla.CANCEL_FLAG= 'N')LOOP
        cpt_a_annulee :=  cpt_a_annulee + 1 ;
        DKA_TOOLS_PKG.put_log_message('Lancement de l''api d''annulation');
	      PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT( p_api_version      => 1.0,
                                                    p_init_msg_list    => fnd_api.g_true,
                                                    p_commit           => fnd_api.g_false,
                                                    x_return_status    => v_return_status,
                                                    p_doc_type         => v_doc_type,
                                                    p_doc_subtype      => v_doc_subtype,
                                                    p_doc_id           => REC_ANNUL_ENTETE.po_header_id,
                                                    p_doc_num          => REC_ANNUL_ENTETE.po_number,
                                                    p_release_id       => NULL,
                                                    p_release_num      => NULL,
                                                    p_doc_line_id      => NULL,
                                                    p_doc_line_num     => rec_annul.line_num, ---A REVOIR
                                                    p_doc_line_loc_id  => NULL,
                                                    p_doc_shipment_num => NULL,
                                                    p_action           => v_action,
                                                    p_action_date      => v_action_date,
                                                    p_cancel_reason    => NULL,
                                                    p_cancel_reqs_flag => 'N',
                                                    p_print_flag       => NULL,
                                                    p_note_to_vendor   => NULL,
                                                    p_use_gldate       =>NULL ,
                                                    p_org_id           => rec_annul.org_id
                                                   );

        --COMMIT;

        IF v_return_status = fnd_api.g_ret_sts_success THEN
          --COMMIT;
          l_message :='Annulation de la ligne '|| rec_annul.line_num||' de la commande '||REC_ANNUL_ENTETE.po_number ||' a été bien passée';
		      DKA_TOOLS_PKG.put_log_message(l_message);
          cpt_annul_succes := cpt_annul_succes + 1;

		    ELSE
          FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
            v_msg_data := FND_MSG_PUB.GET( p_msg_index => i, p_encoded => 'F');
			      l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I04','NUM_LINE_CDE',rec_annul.line_num,'ID_LINE_IVALUA' ,rec_annul.attribute8,'MESSAGE_API',v_msg_data);
		        DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'IMPORT'
		                                   ,'DKA_IPOCDE_HEADERS'
		                                   ,REC_ANNUL_ENTETE.record_id
		                                   ,null
		                                   ,null
		                                   ,'E'
		                                   ,l_message
		    		                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
            --g_enreg_line_rejete2 := g_enreg_line_rejete2 + 1;

          END LOOP;
        END IF;
      END LOOP;
        -- BEGIN
	        -- SELECT person_id
			-- into   v_employe
			-- FROM per_all_people_f  papf ,
      			 -- fnd_user fu11
            -- where papf.person_id=fu11.employee_id
            -- and   fu11.user_id = g_user;
        -- END;
	   FOR rec_annul_frais IN (SELECT pla.*
                        FROM PO_LINES_ALL pla
                        ,    PO_HEADERS_ALL pha
						,    po_line_locations_All plla
						,    MTL_CATEGORIES_B_KFV  mcbk
	                      WHERE  pla.po_header_id = pha.po_header_id
						  and    plla.po_line_id  = pla.po_line_id
						  and    pla.category_id  = mcbk.category_id
						  and    plla.QUANTITY_RECEIVED != 0
						  and    mcbk.concatenated_segments ='99.99.99.02'
                          AND    pha.po_header_id  = REC_ANNUL_ENTETE.po_header_id
	                      AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
                          AND   pla.CANCEL_FLAG= 'N')LOOP

		 cpt_a_annulee :=  cpt_a_annulee + 1 ;
		BEGIN
        UPDATE  PO_LINES_ALL
        SET     CLOSED_CODE = 'FINALLY CLOSED'	,
                CLOSED_DATE = sysdate ,
                CLOSED_BY   = (select fu.employee_id from fnd_user fu where fu.user_id = g_user),
                ClOSED_REASON ='ANNULATION DE LA LIGNE DANS IVALUA'
        where 	po_line_id =	rec_annul_frais.po_line_id	;

        EXCEPTION
        WHEN OTHERS THEN
	        l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I06','NUM_LINE_CDE',rec_annul_frais.line_num,'ID_LINE_IVALUA' ,rec_annul_frais.attribute8,'MESSAGE_ORACLE',SQLERRM);
	        v_erreur_annul := v_erreur_annul + 1;
            DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                           ,'DKA_IPOCMD_IVALUA'
                                           ,'ANNULATION_DONNEE'
                                           , NULL
                                           , NULL
                                           , NULL
                                           , NULL
                                           ,'E'
                                           ,l_message
                                          );
		END ;
		BEGIN
		UPDATE  po_line_locations_All
        SET     CLOSED_CODE = 'FINALLY CLOSED'	,
                CLOSED_DATE = sysdate ,
                CLOSED_BY   = (select fu.employee_id from fnd_user fu where fu.user_id = g_user),
                ClOSED_REASON ='ANNULATION DE LA LIGNE DANS IVALUA',
				SHIPMENT_CLOSED_DATE = sysdate -- BNZ KDFI-1979
        where 	po_line_id =	rec_annul_FRAIS.po_line_id	;
		EXCEPTION
        WHEN OTHERS THEN
	        l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I06','NUM_LINE_CDE',rec_annul_frais.line_num,'ID_LINE_IVALUA' ,rec_annul_frais.attribute8,'MESSAGE_ORACLE',SQLERRM);

            v_erreur_annul := v_erreur_annul + 1;
            DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                           ,'DKA_IPOCMD_IVALUA'
                                           ,'ANNULATION_DONNEE'
                                           , NULL
                                           , NULL
                                           , NULL
                                           , NULL
                                           ,'E'
                                           ,l_message
                                          );
	    END;
		if v_erreur_annul = 0 then
		cpt_annul_succes := cpt_annul_succes + 1;
		END IF ;
	    END LOOP;


	IF cpt_annul_succes = cpt_a_annulee THEN
	    BEGIN
	    UPDATE  PO_HEADERS_ALL
		SET     CLOSED_CODE = 'FINALLY CLOSED'	,
                CLOSED_DATE = sysdate ,
                COMMENTS ='COMMANDE IVALUA ANNULEE - '||COMMENTS
	    where    po_header_id = REC_ANNUL_ENTETE.po_header_id;
	    EXCEPTION
        WHEN OTHERS THEN
	        l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I07','MESSAGE_ORACLE',SQLERRM);
	        vv_erreur := vv_erreur + 1;
            DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                           ,'DKA_IPOCMD_IVALUA'
                                           ,'ANNULATION_DONNEE'
                                           , NULL
                                           , NULL
                                           , NULL
                                           , NULL
                                           ,'E'
                                           ,l_message
                                          );
		END;
		BEGIN

		INSERT INTO po_action_history
                   (object_id,
                    object_type_code,
                    object_sub_type_code,
					last_update_date,
                    last_updated_by,
                    sequence_num,
                    creation_date,
                    created_by,
                    action_code,
                    action_date,
                    employee_id,
                    object_revision_num,
					note
                    )
        VALUES(
                   REC_ANNUL_ENTETE.po_header_id,
				   'PO',
                   'STANDARD',
				   SYSDATE,
                    g_user,
                    (select decode(MAX(SEQUENCE_NUM),NULL,0,MAX(SEQUENCE_NUM))+1 from po_action_history pah where pah.object_id = REC_ANNUL_ENTETE.po_header_id),
                    SYSDATE,
                    g_user,
                    'FINALLY CLOSE',
                    SYSDATE,
                    (select fu.employee_id from fnd_user fu where fu.user_id = g_user),
                    (select revision_num  from PO_HEADERS_ALL where po_header_id = REC_ANNUL_ENTETE.po_header_id),
					'Annulation de la commande dans IVALUA '
                   );
         commit;
        EXCEPTION
        WHEN OTHERS THEN
	        l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I07','MESSAGE_ORACLE',SQLERRM);
	        vv_erreur := vv_erreur + 1;
            DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                           ,'DKA_IPOCMD_IVALUA'
                                           ,'ANNULATION_DONNEE'
                                           , NULL
                                           , NULL
                                           , NULL
                                           , NULL
                                           ,'E'
                                           ,l_message
                                          );
		END;

	   if  vv_erreur = 0 then
	      UPDATE DKA_IPOCDE_HEADERS
	      SET STATUT  = 'COMPLETE'
	      WHERE po_number = REC_ANNUL_ENTETE.po_number;
		  UPDATE DKA_IPOCDE_LINES
		  SET STATUT = 'COMPLETE'
		  WHERE po_number = REC_ANNUL_ENTETE.po_number;

	    ELSE

        UPDATE DKA_IPOCDE_HEADERS
	      SET STATUT  = 'PROCESSING_ERROR_CAN'--SHA-EDB310
	      WHERE po_number = REC_ANNUL_ENTETE.po_number;
        pn_retcode :=1;
      END IF;
    END IF ;
END IF ;
    END LOOP;
    COMMIT;
  END;

/*======================================================================================================*/
  --  Nom           : ANNUL_LIGNE_CMD
  --  Description   :
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          :

/*=========================================================================================================*/
  PROCEDURE ANNUL_LIGNE_CMD(pv_errbuf        OUT VARCHAR2,
                           pn_retcode       OUT NUMBER
                          ) IS
  CURSOR C_ANNUL_LIGNE IS
  SELECT dih.*
  ,      hou.organization_id
  ,      pha.po_header_id
  FROM DKA_IPOCDE_HEADERS dih
  ,    PO_HEADERS_ALL pha
  ,    hr_operating_units hou
  WHERE	1=1
  AND dih.HEADER_ACTION = 'UPDATE'
  AND dih.LINE_TO_CANCEL = 'Y'
  --AND dih.STATUT_CANCEL_LINE IS NULL OR dih.STATUT_CANCEL_LINE ='ERROR'
  AND nvl(dih.STATUT_CANCEL_LINE,'xx') NOT IN ('REJECTED','SUCCESS')
  AND  dih.STATUT IN ('VALIDATED','PROCESSING_ERROR')
  AND  dih.po_number = pha.segment1
  AND  hou.organization_id = pha.org_id
  AND  hou.name = dih.uo;
  v_employe         per_all_people_f.person_id%TYPE;
  v_return_status   VARCHAR2 (10);
  v_msg_data        VARCHAR2(1000);
  l_message         VARCHAR2(1000);
  v_doc_subtype     VARCHAR2(10)  := 'STANDARD';
  v_doc_type        VARCHAR2(10)  := 'PO';
  v_action          VARCHAR2(10)  := 'CANCEL';
  v_action_date     DATE          := SYSDATE;
  cpt_annul_succes  NUMBER := 0;
  cpt_a_annulee     NUMBER := 0;
  vv_erreur         NUMBER := 0;
  BEGIN
    FOR REC_ANNUL_LIGNE IN C_ANNUL_LIGNE LOOP
    DKA_TOOLS_PKG.put_log_message('Entree à la boucle FOR');
      cpt_annul_succes  := 0;
      cpt_a_annulee     := 0;
	    FOR rec_annul IN (SELECT pla.*
                        FROM PO_LINES_ALL pla
                        ,    PO_HEADERS_ALL pha
						,    po_line_locations_All plla
	                      WHERE  pla.po_header_id = pha.po_header_id
						  and    plla.po_line_id  = pla.po_line_id
						  and    plla.QUANTITY_RECEIVED = 0
                        --AND    pha.segment1     = REC_ANNUL_LIGNE.po_number
                          AND    pha.po_header_id  = REC_ANNUL_LIGNE.po_header_id
	                      AND    pla.attribute8 NOT IN (SELECT ivalua_line_id FROM DKA_IPOCDE_LINES
                                                  WHERE po_number = REC_ANNUL_LIGNE.po_number)
	                      AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
                        AND   pla.CANCEL_FLAG= 'N')LOOP
        cpt_a_annulee :=  cpt_a_annulee + 1 ;
        DKA_TOOLS_PKG.put_log_message('Lancement de l''api d''annulation');
	      PO_DOCUMENT_CONTROL_PUB.CONTROL_DOCUMENT( p_api_version      => 1.0,
                                                    p_init_msg_list    => fnd_api.g_true,
                                                    p_commit           => fnd_api.g_false,
                                                    x_return_status    => v_return_status,
                                                    p_doc_type         => v_doc_type,
                                                    p_doc_subtype      => v_doc_subtype,
                                                    p_doc_id           => REC_ANNUL_LIGNE.po_header_id,
                                                    p_doc_num          => REC_ANNUL_LIGNE.po_number,
                                                    p_release_id       => NULL,
                                                    p_release_num      => NULL,
                                                    p_doc_line_id      => NULL,
                                                    p_doc_line_num     => rec_annul.line_num, ---A REVOIR
                                                    p_doc_line_loc_id  => NULL,
                                                    p_doc_shipment_num => NULL,
                                                    p_action           => v_action,
                                                    p_action_date      => v_action_date,
                                                    p_cancel_reason    => NULL,
                                                    p_cancel_reqs_flag => 'N',
                                                    p_print_flag       => NULL,
                                                    p_note_to_vendor   => NULL,
                                                    p_use_gldate       =>NULL ,
                                                    p_org_id           => rec_annul.org_id
                                                   );

        --COMMIT;

        IF v_return_status = fnd_api.g_ret_sts_success THEN
          --COMMIT;
          l_message :='Annulation de la ligne '|| rec_annul.line_num||' de la commande '||REC_ANNUL_LIGNE.po_number ||' a été bien passée';
		      DKA_TOOLS_PKG.put_log_message(l_message);
          cpt_annul_succes := cpt_annul_succes + 1;

		    ELSE
          FOR i IN 1 .. FND_MSG_PUB.COUNT_MSG LOOP
            v_msg_data := FND_MSG_PUB.GET( p_msg_index => i, p_encoded => 'F');
			      l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I04','NUM_LINE_CDE',rec_annul.line_num,'ID_LINE_IVALUA' ,rec_annul.attribute8,'MESSAGE_API',v_msg_data);
		        DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                   ,'DKA_IPOCMD_IVALUA'
		                                   ,'IMPORT'
		                                   ,'DKA_IPOCDE_HEADERS'
		                                   ,REC_ANNUL_LIGNE.record_id
		                                   ,null
		                                   ,null
		                                   ,'E'
		                                   ,l_message
		    		                       );
		        DKA_TOOLS_PKG.put_log_message(l_message);
            --g_enreg_line_rejete2 := g_enreg_line_rejete2 + 1;

          END LOOP;
        END IF;
      END LOOP;
	   BEGIN
	        SELECT person_id
			into   v_employe
			FROM per_all_people_f  papf ,
      			 fnd_user fu11
            where papf.person_id=fu11.employee_id
            and   fu11.user_id = g_user;
        END;
	   FOR rec_annul_frais IN (SELECT pla.*
                        FROM PO_LINES_ALL pla
                        ,    PO_HEADERS_ALL pha
						,    po_line_locations_All plla
						,    MTL_CATEGORIES_B_KFV  mcbk
	                      WHERE  pla.po_header_id = pha.po_header_id
						  and    plla.po_line_id  = pla.po_line_id
						  and    pla.category_id  = mcbk.category_id
						  and    plla.QUANTITY_RECEIVED != 0
						  and    mcbk.concatenated_segments ='99.99.99.02'
                        --AND    pha.segment1     = REC_ANNUL_LIGNE.po_number
                          AND    pha.po_header_id  = REC_ANNUL_LIGNE.po_header_id
	                      AND    pla.attribute8 NOT IN (SELECT ivalua_line_id FROM DKA_IPOCDE_LINES
                                                  WHERE po_number = REC_ANNUL_LIGNE.po_number)
	                      AND   nvl(pla.CLOSED_CODE,'xx')  != 'FINALLY CLOSED'
                          AND   pla.CANCEL_FLAG= 'N')LOOP

		 cpt_a_annulee :=  cpt_a_annulee + 1 ;
		BEGIN
        UPDATE  PO_LINES_ALL
        SET     CLOSED_CODE = 'FINALLY CLOSED'	,
                CLOSED_DATE = sysdate ,
                CLOSED_BY   = v_employe,
                ClOSED_REASON ='ANNULATION DE LA LIGNE DANS IVALUA'
        where 	po_line_id =	rec_annul_frais.po_line_id	;

        EXCEPTION
        WHEN OTHERS THEN
	        l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I06','NUM_LINE_CDE',rec_annul_frais.line_num,'ID_LINE_IVALUA' ,rec_annul_frais.attribute8,'MESSAGE_ORACLE',SQLERRM);
	        vv_erreur := vv_erreur + 1;
            DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                           ,'DKA_IPOCMD_IVALUA'
                                           ,'ANNULATION_DONNEE'
                                           , NULL
                                           , NULL
                                           , NULL
                                           , NULL
                                           ,'E'
                                           ,l_message
                                          );
		END ;
		BEGIN
		UPDATE  po_line_locations_All
        SET     CLOSED_CODE = 'FINALLY CLOSED'	,
                CLOSED_DATE = sysdate ,
                CLOSED_BY   = v_employe,
                ClOSED_REASON = 'ANNULATION DE LA LIGNE DANS IVALUA',
				SHIPMENT_CLOSED_DATE= sysdate -- BNZ KDFI-1979
        where 	po_line_id =	rec_annul_FRAIS.po_line_id	;
		EXCEPTION
        WHEN OTHERS THEN
	        l_message := DKA_TOOLS_PKG.get_message('DKA','DKA_IPOCDE_I06','NUM_LINE_CDE',rec_annul_frais.line_num,'ID_LINE_IVALUA' ,rec_annul_frais.attribute8,'MESSAGE_ORACLE',SQLERRM);

            vv_erreur := vv_erreur + 1;
            DKA_TOOLS_PKG.ins_prog_message( g_request_id
                                           ,'DKA_IPOCMD_IVALUA'
                                           ,'ANNULATION_DONNEE'
                                           , NULL
                                           , NULL
                                           , NULL
                                           , NULL
                                           ,'E'
                                           ,l_message
                                          );
	    END;
		if vv_erreur = 0 then
		cpt_annul_succes := cpt_annul_succes + 1;
		END IF ;
	    END LOOP;
	   --DKA_TOOLS_PKG.put_log_message('cpt_annul_succes sortie de la boucle:'||cpt_annul_succes);
     --DKA_TOOLS_PKG.put_log_message('cpt_a_annulee sortie de la boucle:'||cpt_a_annulee);
      IF cpt_annul_succes = cpt_a_annulee THEN
	      UPDATE DKA_IPOCDE_HEADERS
	      SET STATUT_CANCEL_LINE  = 'SUCCESS'
	      WHERE po_number = REC_ANNUL_LIGNE.po_number;

	    ELSE

        UPDATE DKA_IPOCDE_HEADERS
	      SET STATUT_CANCEL_LINE  = 'ERROR'
	      WHERE po_number = REC_ANNUL_LIGNE.po_number;
        pn_retcode :=1;
      END IF;
    END LOOP;
    COMMIT;
 END;
   /*============================================================================*/
 -- Procedure         : MAJ_STATUT_CMD
 -- Description       : mise à jour du statut de la commande (UPDATE)
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              :
 -- Remarques         :
/*===============================================================================*/
  PROCEDURE MAJ_STATUT_CMD(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='MAJ_STATUT_CMD';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;
  v_ligne_cancel_ok      NUMBER := 0;
  v_ligne_maj_ok         NUMBER := 0;
  CURSOR C_CMD_UPDATE IS
  SELECT *
  FROM DKA_IPOCDE_HEADERS dih
  WHERE  1 = 1
  AND    header_action = 'UPDATE'
  AND    dih.STATUT_UPDATE_HEADER = 'SUCCESS'
  FOR UPDATE;

  BEGIN
    FOR REC_CMD_UPDATE IN C_CMD_UPDATE
    LOOP
       v_ligne_maj_ok := 0;
       v_ligne_cancel_ok := 0;
       IF REC_CMD_UPDATE.LINE_TO_CANCEL ='Y'
       THEN
          IF REC_CMD_UPDATE.STATUT_CANCEL_LINE  = 'SUCCESS'
          THEN
              v_ligne_cancel_ok := 0;
          ELSE
              v_ligne_cancel_ok := 1;
          END IF;
      END IF;

      FOR rec_ligne IN (SELECT * FROM DKA_IPOCDE_LINES where po_number = REC_CMD_UPDATE.po_number  )
      LOOP
         IF rec_ligne.STATUT != 'PROCESSING_SUCCESS'
         THEN
            v_ligne_maj_ok := 1;
         END IF;
      END LOOP;

      IF v_ligne_maj_ok = 0 AND v_ligne_cancel_ok = 0
      THEN
         UPDATE DKA_IPOCDE_HEADERS
         SET    STATUT ='COMPLETE'
         WHERE CURRENT OF C_CMD_UPDATE;

         UPDATE DKA_IPOCDE_LINES
         SET    STATUT ='COMPLETE'
         WHERE  STATUT = 'PROCESSING_SUCCESS'
         AND    PO_NUMBER = REC_CMD_UPDATE.PO_NUMBER;
      ELSE
        UPDATE DKA_IPOCDE_HEADERS
        SET    STATUT ='PROCESSING_ERROR'
        WHERE CURRENT OF C_CMD_UPDATE;

      END IF ;

   END LOOP;
   COMMIT;
  END;
/*======================================================================================================*/
  --  Nom           : LANCE_OI_CMD
  --  Description   : Procédure de lancement du programme standard de l'interface des commandes
  --  PARAMETRES    : p_ou                Entrée           unité opérationnelle
  --                  pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 09/06/2020
/*=========================================================================================================*/
  PROCEDURE LANCE_OI_CMD(p_errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER
                         )

  IS
    v_phase                  VARCHAR2 (100);
    v_status                 VARCHAR2 (100);
    v_dev_phase              VARCHAR2 (100);
    v_dev_status             VARCHAR2 (100);
    v_message                VARCHAR2 (100);
    b_result                 BOOLEAN;

    v_resp_id                NUMBER;
    v_resp_appl_id           NUMBER;
    l_request_id             NUMBER;
    l_req_interval           NUMBER := 30;
    l_req_max_wait           NUMBER := 999999;
    l_trt_std                NUMBER := 0;

    TYPE num_traitement IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
    num_trait_list num_traitement;
    v_cpt INTEGER := 0;

    CURSOR cur_uo IS
    SELECT DISTINCT org_id
    FROM PO_HEADERS_INTERFACE
    WHERE document_type_code = 'STANDARD'
    AND process_code <> 'ACCEPTED'
	  AND  org_id in (SELECT HOU.organization_id
                    FROM HR_ORGANIZATION_UNITS HOU
                    ,     DKA_IPOCDE_HEADERS DIH
                    WHERE 1=1
                    AND HOU.NAME = DIH.UO
                    --AND DIH.STATUT  = 'INSERTED_OI'
			             )
	  AND interface_header_id IN (SELECT dih.interface_header_id
                               FROM   DKA_IPOCDE_HEADERS DIH
			                  )

    ;

  BEGIN

    DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début LANCE_OI_CMD');

    DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                                     'Lancement de l''interface des commandes : ');
    writeout('LANCEMENT DES INTERFACES STANDARDS DES COMMANDES :');
    writeout('---------------------------------------------------');

    FOR rec IN cur_uo LOOP
      DKA_TOOLS_PKG.put_log_message('Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);
     -- writeout( 'Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);


      BEGIN
        SELECT responsibility_id, application_id
        INTO v_resp_id, v_resp_appl_id
        FROM fnd_responsibility fr, hr_operating_units hou
        WHERE hou.organization_id = rec.org_id
        AND fr.responsibility_key = hou.name || '_PO_ADMINISTRATEUR';

        APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => g_user,
                                        RESP_ID      => v_resp_id,
                                        RESP_APPL_ID => v_resp_appl_id
                                        );

        mo_global.set_policy_context('S',rec.org_id);

        Fnd_Request.set_org_id(org_id => rec.org_id);

      EXCEPTION
        WHEN OTHERS THEN
          p_retcode   := 2;
          v_resp_id   := NULL;
          v_resp_appl_id := NULL;
        --  writeout( '. Problème de recupération de la responsabilité ');
          DKA_TOOLS_PKG.put_log_message('. Problème de recupération de la responsabilité ');
      END;

      IF v_resp_id IS NOT NULL THEN
      ---------------------------------------------------
      -- Lancement du traitement de l'interface des commandes --
      ---------------------------------------------------
      l_request_id          := Fnd_Request.submit_request (
                                           'PO'
                                          ,'POXPOPDOI'
                                          ,NULL
                                          ,NULL
                                          ,FALSE
                                          ,NULL
                                          ,'STANDARD'
                                          ,NULL
                                          ,'N'
                                          ,NULL
                                          ,'APPROVED'
                                          ,NULL
                                          ,gn_batch_id
                                          ,rec.org_id
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,NULL
                                          ,'N'
                                          ,'N'
                                          ,5000
                                          ,'N'
                                          );

        IF l_request_id = 0
        THEN
            p_retcode    := 2;
           writeout('====> ERREUR : Le traitement de l''interface des commandes a échoué');
        ELSE
            COMMIT;
            v_cpt := v_cpt + 1;
            num_trait_list(v_cpt) := l_request_id;
        END IF;

      END IF;
      l_trt_std := 1;
    END LOOP; --end loop cur_uo
    -- Attente de la fin des traitements
    FOR var IN 1 .. v_cpt LOOP
      IF NOT (Fnd_Concurrent.wait_for_request(num_trait_list(var),
                                              l_req_interval,
                                              l_req_max_wait,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
        p_errbuf := v_Message;
        DKA_TOOLS_PKG.put_log_message(
                          'ERREUR : Attente de la fin du programme de l''interface des commandes : Fin du traitement' ||
                          CHR(10) || 'MESSAGE : ' || v_Message || CHR(10));
      END IF;

      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
        DKA_TOOLS_PKG.put_log_message(
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
        DKA_TOOLS_PKG.put_log_message('Fin du traitement de l''interface des commandes en warning ' ||l_request_id);
        p_retcode := 1;

      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        p_retcode := 1;
        p_errbuf  := 'ERREUR : Fin anormale du traitement de l''interface des commandes : ' ||v_Message;
        DKA_TOOLS_PKG.put_log_message('ERREUR : Fin anormale du traitement de l''interface des commandes ' ||
                          l_request_id || CHR(10) || 'Phase/Statut : ' ||
                          v_dev_phase || '/' || v_dev_status || CHR(10) ||
                          'MESSAGE : ' || v_message || CHR(10));
      END IF;
       writeout('. Numéro du traitement de l''interface des commandes : '||num_trait_list(var));
       writeout('. Statut de fin : '||v_dev_status);
    END LOOP;
    IF l_trt_std = 0 THEN
      writeout('Aucun traitement standard n''a été lancé.');
    END IF;
    DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin LANCE_OI_CMD');


  EXCEPTION
    WHEN OTHERS
    THEN
        p_retcode   := 2;
        p_errbuf    := 'LANCE_OI_CMD : ' ||SQLERRM;
        DKA_TOOLS_PKG.put_log_message(p_errbuf);
        DKA_TOOLS_PKG.put_log_message(TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure LANCE_OI_CMD : EXCEPTION OTHERS ');
  END LANCE_OI_CMD;

  /*============================================================================*/
 -- Procedure         : CONTROLE_IMPORT_CMD
 -- Description       : contoler l'import effectif de la comande
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              :
 -- Remarques         :
/*===============================================================================*/
  PROCEDURE CONTROLE_IMPORT_CMD(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='CONTROLE_IMPORT_CMD';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;
  CURSOR C_CMD_IMPORTEE IS
  SELECT * FROM DKA_IPOCDE_HEADERS
  WHERE STATUT = 'INSERTED_OI'
  FOR UPDATE;

  CURSOR C_LIGNE_IMPORTEE IS
  SELECT * FROM DKA_IPOCDE_LINES
  WHERE STATUT = 'INSERTED_OI'
  FOR UPDATE;
  v_id_cmd   PO_HEADERS_INTERFACE.PO_HEADER_ID%TYPE;
  v_exist    NUMBER;
  v_id_ligne  PO_LINES_INTERFACE.po_line_id%TYPE;
  BEGIN
    FOR rec_cmd_importee IN C_CMD_IMPORTEE LOOP
      BEGIN
        SELECT PO_HEADER_ID
        INTO   v_id_cmd
        FROM  PO_HEADERS_INTERFACE
        WHERE interface_header_id = rec_cmd_importee.interface_header_id
        AND   PROCESS_CODE = 'ACCEPTED';
      EXCEPTION
        WHEN OTHERS THEN
          v_id_cmd := 0;
          UPDATE DKA_IPOCDE_HEADERS
          SET    STATUT = 'PROCESSING_ERROR'
          WHERE CURRENT OF C_CMD_IMPORTEE;
      END;
      IF v_id_cmd != 0  THEN
        BEGIN
          SELECT 1
          INTO   v_exist
          FROM PO_HEADERS_ALL
          WHERE PO_HEADER_ID = v_id_cmd;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            UPDATE DKA_IPOCDE_HEADERS
            SET    STATUT = 'PROCESSING_ERROR'
            WHERE CURRENT OF C_CMD_IMPORTEE;
        END;

        IF v_exist IS NOT NULL THEN
          UPDATE DKA_IPOCDE_HEADERS
          SET    STATUT = 'PROCESSING_SUCCESS'
          WHERE CURRENT OF C_CMD_IMPORTEE;
        END IF;
      END IF ;
   END LOOP;

    FOR rec_ligne_importee IN C_LIGNE_IMPORTEE LOOP
      BEGIN
        SELECT po_line_id,PO_HEADER_ID
        INTO   v_id_ligne, v_id_cmd
        FROM  PO_LINES_INTERFACE
        WHERE interface_line_id = rec_ligne_importee.interface_line_id
        AND   PROCESS_CODE = 'ACCEPTED';
      EXCEPTION
        WHEN OTHERS THEN
		      v_id_ligne := 0;
          v_id_cmd := 0;
          UPDATE DKA_IPOCDE_LINES
          SET    STATUT = 'PROCESSING_ERROR'
          WHERE CURRENT OF C_LIGNE_IMPORTEE;
      END;
      IF v_id_ligne != 0 THEN
        BEGIN
          SELECT 1
          INTO   v_exist
          FROM PO_HEADERS_ALL pha
		      ,    PO_LINES_ALL pla
          WHERE pla.PO_HEADER_ID = pha.PO_HEADER_ID
          AND   pha.PO_HEADER_ID = v_id_cmd
		      AND   pla.po_line_id = v_id_ligne;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            UPDATE DKA_IPOCDE_LINES
            SET    STATUT = 'PROCESSING_ERROR'
            WHERE CURRENT OF C_LIGNE_IMPORTEE;
        END;

        IF v_exist IS NOT NULL THEN
          UPDATE DKA_IPOCDE_LINES
          SET    STATUT = 'PROCESSING_SUCCESS'
          WHERE CURRENT OF C_LIGNE_IMPORTEE;
        END IF;
      END IF ;


   END LOOP;
      /*WHEN OTHERS THEN
      v_message := 'ERROR lors de la vérification de l''imporation proc CONTROLE_IMPORT_CMD '||SQLERRM
      pn_retcode := 1;
      DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'CONTROLE_IMPORT_CMD'
		                                 , NULL
		                                 , NULL
		                                 , NULL
		                                 , NULL
		                                 ,'E'
		                                 ,v_message
				                            );  */

  END;

  /*======================================================================================================*/
  --  Nom           : create_attached_document_bdc
  --  Description   :  procédure qui crée le document attaché
  --  PARAMETRES :
  --   pv_errbuf   Entrée/Sortie          message d'erreur
  --   VALEUR RETOURNEE :  pn_retcode
  --  Valeurs possibles : 0=normal, 1=warning, 2=erreur
/*=========================================================================================================*/
  PROCEDURE create_attached_document_bdc
                (pn_po_header_id IN NUMBER,
                 pn_url          IN VARCHAR2,
                 pv_errbuf       OUT VARCHAR2,
                 pn_retcode      IN OUT NUMBER)
  IS

    l_document_id NUMBER;
    l_attached_document_id NUMBER;
    l_num_seq NUMBER;

  BEGIN

    dka_tools_pkg.put_debug_message ('(+) create_attached_document_bdc');
    pn_retcode := 0;

    -- Recupération du dernier numéro de séquence
    BEGIN
    -- SELECT seq_num + 10
    SELECT NVL(MAX(seq_num), 0) + 10
    INTO   l_num_seq
    FROM   fnd_attached_documents
    WHERE  entity_name   = gv_entity_name
    AND pk1_value = pn_po_header_id;

    EXCEPTION
    WHEN NO_DATA_FOUND
    THEN
        l_num_seq := 10;
    END;


    SELECT fnd_documents_s.nextval
    INTO l_document_id
    FROM DUAL;

    INSERT INTO fnd_documents_tl
                (document_id,
                file_name,
                media_id,
                description,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                language,
                source_lang)
           VALUES(l_document_id,
                  NULL,
                  NULL,
                  gv_description,
                  sysdate,
                  g_user,
                  sysdate,
                  g_user,
                  userenv('LANG'),
                  userenv('LANG'));

    INSERT INTO fnd_documents
                (document_id,
                category_id,
                datatype_id,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                security_type,
                security_id,
                publish_flag,
                URL,
                usage_type)
           VALUES(l_document_id,
                  gn_category_id,
                  gn_datatype_id,
                  sysdate,
                  g_user,
                  sysdate,
                  g_user,
                  1,
                  gn_org_id,
                  'Y',
                  pn_url,
                  'O');

    SELECT fnd_attached_documents_s.nextval
    INTO l_attached_document_id
    FROM DUAL;

    INSERT INTO fnd_attached_documents
                (attached_document_id,
                document_id,
                seq_num,
                entity_name,
                pk1_value,
				        category_id,
                creation_date,
                created_by,
                last_update_date,
                last_updated_by,
                AUTOMATICALLY_ADDED_FLAG)
           VALUES(l_attached_document_id,
                  l_document_id,
                  l_num_seq,
                  gv_entity_name,
                  pn_po_header_id,
				          gn_category_id,
                  sysdate,
                  g_user,
                  sysdate,
                  g_user,
                  'N');

    --dka_Tools_Pkg.put_outdebug_message ('==>  Création du document_id : '|| l_document_id);
   -- dka_tools_pkg.put_debug_message ('(-) create_attached_document_bdc');

  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message(SQLCODE || '=' ||
                                      substr(SQLERRM, 1, 400));
      dka_tools_pkg.put_debug_message('create_attached_document_bdc - ' || SQLERRM);
      --pv_errbuf  := 'create_attached_document_bdc - ' || SQLERRM;
      pv_errbuf := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_I01','MESSAGE_ERREUR',SQLERRM);

      pn_retcode := 2;
      ROLLBACK;
  END create_attached_document_bdc;
    /*============================================================================*/
 -- Procedure         : ENREGISTREMENT_COMPTEUR
 -- Description       :
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              :
 -- Remarques         :
/*===============================================================================*/
  PROCEDURE ENREGISTREMENT_COMPTEUR(pv_errbuf  IN OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

  v_procedure            VARCHAR2(30):='ENREGISTREMENT_COMPTEUR';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;


  BEGIN
    SELECT COUNT(*)
	  INTO   g_enreg_entete_succes
	  FROM   DKA_IPOCDE_HEADERS
	  WHERE  STATUT = 'COMPLETE'
	  AND    request_id = g_request_id;

    SELECT COUNT(*)
    INTO   g_enreg_entete_rejete2
    FROM   DKA_IPOCDE_HEADERS
	  WHERE  STATUT IN ('VALIDATED','INSERTED_OI','PROCESSING_ERROR','PROCESSING_SUCCESS')
    AND    request_id = g_request_id;

    SELECT COUNT(*)
	  INTO   g_enreg_entete_rejete1
	  FROM   DKA_IPOCDE_HEADERS
	  WHERE  STATUT = 'REJECTED'
	  AND    request_id = g_request_id;


	-- SELO EDB301 BEGIN
	/*select count(distinct dii.record_id) INTO g_enreg_entete_warning
	  from dka_program_messages dpm,
		   DKA_IPOCDE_HEADERS dii
	 where prog_name ='DKA_IPOCMD_IVALUA'
	   and table_id=dii.record_id
	   and dii.request_id=g_request_id
	   and dpm.request_id=g_request_id
	   and dpm.message_type='W'
	   and dii.statut = 'COMPLETE' ;*/
	select count(distinct dii.record_id) INTO g_enreg_entete_warning
	  from dka_program_messages dpm,
		   DKA_IPOCDE_HEADERS dii
	 where prog_name ='DKA_IPOCMD_IVALUA'
	   and table_id=dii.record_id
	   and dii.request_id=g_request_id
	   and dpm.request_id=g_request_id
	   and dpm.message_type='W'
	   and dii.statut = 'WARNING' ;
	 --  group by  dii.po_number, TABLE_ID	  ;

    --g_enreg_entete_succes := g_enreg_entete_succes - g_enreg_entete_warning;


	/*select count(distinct dii.po_number) INTO g_enreg_ligne_warning
	  from dka_program_messages dpm,
		   DKA_IPOCDE_HEADERS dii,
		   DKA_IPOCDE_LINES DIL
	 where prog_name ='DKA_IPOCMD_IVALUA'
	   and table_id=dii.record_id
	   and dii.request_id=g_request_id
	   and dpm.request_id=g_request_id
	   and dpm.message_type='W'
	   and dii.statut = 'COMPLETE'
	   and DIL.po_number = dii.po_number
	 --  group by  dii.po_number, DIL.IVALUA_LINE_ID, TABLE_ID
	   ; */
	   select  count(distinct dii.po_number||DIL.line_num) INTO g_enreg_ligne_warning
	  from dka_program_messages dpm,
		   DKA_IPOCDE_HEADERS dii,
		   DKA_IPOCDE_LINES DIL
	 where prog_name ='DKA_IPOCMD_IVALUA'
	   and table_id=dii.record_id
	   and dii.request_id=g_request_id
	   and dpm.request_id=g_request_id
	   and dpm.message_type='W'
	   and dii.statut = 'WARNING'
	   and DIL.po_number = dii.po_number;
	 --  group by  dii.po_number, DIL.IVALUA_LINE_ID, TABLE_ID


	-- SELO EDB301 FIN

	  SELECT COUNT(*)
	  INTO   g_enreg_line_succes
	  FROM   DKA_IPOCDE_LINES
	  WHERE  STATUT = 'COMPLETE'
	  AND    request_id = g_request_id;

	--g_enreg_line_succes := g_enreg_line_succes - g_enreg_ligne_warning;



    SELECT COUNT(*)
    INTO   g_enreg_line_rejete2
    FROM   DKA_IPOCDE_LINES
	  WHERE  STATUT IN ('VALIDATED','INSERTED_OI','PROCESSING_ERROR','PROCESSING_SUCCESS')
    AND    request_id = g_request_id;

    SELECT COUNT(*)
	  INTO   g_enreg_ligne_rejet
	  FROM   DKA_IPOCDE_LINES
	  WHERE  STATUT = 'REJECTED'
	  AND    request_id = g_request_id;
  END;
   /*==============================================================================*/
  -- Procedure         : UPDATE_RECORD2
  -- Description       : Procédure pour MAJ les tables de tarvail à la fin de traitement
  -- Parametres entree : p_request_id
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 27/07/2020
  -- Remarques         :
/*=================================================================================*/
  PROCEDURE UPDATE_RECORD2 (pv_errbuf  IN OUT VARCHAR2,
                           pn_retcode OUT NUMBER,
                           p_request_id IN NUMBER )IS
  cursor cur_entete IS (SELECT * FROM DKA_IPOCDE_HEADERS
                       -- WHERE LOADER_REQUEST_ID = p_request_id
                       );
  cursor cur_ligne  IS (SELECT * FROM DKA_IPOCDE_LINES
                       -- WHERE LOADER_REQUEST_ID = p_request_id
                       );
  BEGIN
  FOR rec_entete in cur_entete LOOP
    update DKA_IPOCDE_REPORTING_HEADERS
    set
    HEADER_ACTION         = rec_entete.HEADER_ACTION          ,
    LINE_TO_CANCEL        = rec_entete.LINE_TO_CANCEL         ,
    STATUT                = rec_entete.STATUT                 ,
    STATUT_UPDATE_HEADER  = rec_entete.STATUT_UPDATE_HEADER   ,
    STATUT_CANCEL_LINE    = rec_entete.STATUT_CANCEL_LINE     ,
    INTERFACE_HEADER_ID   = rec_entete.INTERFACE_HEADER_ID    ,
    VENDOR_SITE_ID        = rec_entete.VENDOR_SITE_ID         ,
    VENDOR_ID             = rec_entete.VENDOR_ID              ,
    AGENT_ID              = rec_entete.AGENT_ID               ,
    request_id            = rec_entete.request_id             ,
    last_update_date      = SYSDATE                ,
    LAST_UPDATED_BY       = g_user
    WHERE record_id       = rec_entete.record_id ;

  END LOOP;

  FOR rec_donne_ligne in cur_ligne LOOP
    update DKA_IPOCDE_REPORTING_LINES
    set
    LINE_ACTION           = rec_donne_ligne.LINE_ACTION            ,
    STATUT                = rec_donne_ligne.STATUT                 ,
    INTERFACE_LINE_ID     = rec_donne_ligne.INTERFACE_LINE_ID      ,
    PERSON_ID             = rec_donne_ligne.PERSON_ID              ,
    TYPE_LINE             = rec_donne_ligne.TYPE_LINE              ,
    CODE_PROJET           = rec_donne_ligne.CODE_PROJET            ,
    request_id            = rec_donne_ligne.request_id             ,
    last_update_date      = SYSDATE                ,
    LAST_UPDATED_BY       = g_user
    WHERE record_id       = rec_donne_ligne.record_id  ;

  END LOOP;
  END UPDATE_RECORD2;
  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 26/05/2020
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
  entete_de_sortie(p_recyclage);
  PURGE_DONNEE_TRAITEE(vf_errbuf ,
                      vf_retcode );
  IF  vf_retcode = 1  THEN
       pn_retcode := 1;
  END IF ;

  v_phase := 'PHASE  INITIALISATION DES VARIABLES';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  init (vf_errbuf, vf_retcode);
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


 /* IF vf_retcode != 0 THEN
    Dka_Tools_Pkg.put_outdebug_message( CHR(10)||vf_errbuf);
    vf_retcode :=1;
  END IF      ; */

  v_phase := 'PHASE  LANCEMENT DE TRAITEMENT STANDARD';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  LANCE_OI_CMD(vf_errbuf ,
                vf_retcode) ;
  IF vf_retcode != 0 and pn_retcode < 2 THEN
    Dka_Tools_Pkg.put_outdebug_message( CHR(10)||vf_errbuf);
    pn_retcode :=1;
  ELSE
    CONTROLE_IMPORT_CMD(vf_errbuf, vf_retcode);
  END IF  ;

  v_phase := 'PHASE  ATTACHEMENT URL';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  FOR rec_po_attach IN (SELECT pha.po_header_id
                        ,      dih.url_bdc
                        ,      dih.po_number
                        ,      dih.record_id
                        FROM   po_headers_all pha
                        ,      DKA_IPOCDE_HEADERS dih
                        WHERE  dih.po_number = pha.segment1
                        AND    dih.statut = 'PROCESSING_SUCCESS') LOOP
            create_attached_document_bdc
                (pn_po_header_id => rec_po_attach.po_header_id,
                 pn_url          => rec_po_attach.url_bdc,
                 pv_errbuf       => vf_errbuf,
                 pn_retcode      => vf_retcode);
             DKA_TOOLS_PKG.put_log_message('retcode de rattachement :'||vf_retcode);
             IF vf_retcode != 0
             THEN
                -- l_message := DKA_TOOLS_PKG.get_message ('DKA','DKA_IPOCDE_I01','MESSAGE_ERREUR',vf_errbuf);
                 --Dka_Tools_Pkg.put_outdebug_message( CHR(10)||vf_errbuf);
                 --DKA_TOOLS_PKG.put_log_message('ebbufr de rattachement :'||vf_errbuf);
                 DKA_TOOLS_PKG.ins_prog_message( g_request_id
		                                 ,'DKA_IPOCMD_IVALUA'
		                                 ,'IMPORT'
		                                 ,'DKA_IPOCDE_HEADERS'
		                                 , rec_po_attach.record_id
		                                 , NULL--pv_column_name
		                                 , NULL --pv_column_value
		                                 ,'E'
		                                 ,vf_errbuf
			  	                       );
                 RETURN;
             ELSE

              UPDATE DKA_IPOCDE_HEADERS
              SET STATUT ='COMPLETE'
              WHERE po_number= rec_po_attach.po_number
			  and HEADER_ACTION = 'CREATE'; -- SHA-EDB310

			  UPDATE DKA_IPOCDE_LINES
              SET STATUT ='COMPLETE'
              WHERE po_number= rec_po_attach.po_number;

              --Debut SHA-EDB310

			  UPDATE DKA_IPOCDE_HEADERS
              SET STATUT ='COMPLETE_CREATE'
              WHERE po_number= rec_po_attach.po_number
			  and HEADER_ACTION = 'CREATE_CANCEL';

			  --FIN SHA-EDB310



             END IF;

  END LOOP;
  --Positionnement du programme sur la responsabilité TOUT_PO_ADMINISTRATEUR
		BEGIN
		   SELECT responsibility_id,application_id
		   INTO v_responsibility_id,v_application_id
		   FROM fnd_responsibility_vl
		   WHERE responsibility_key = 'TOUT_PO_ADMINISTRATEUR';
		EXCEPTION
		WHEN OTHERS THEN
		   vf_errbuf  := 'ERREUR : Impossible de se positionner sur la responsabilité TOUT_PO_ADMINISTRATEUR';

		END;


	 fnd_global.apps_initialize(user_id => g_user, resp_id => v_responsibility_id, resp_appl_id => v_application_id);
	 COMMIT;
  v_phase := 'PHASE  MISE A JOUR ENTETE COMMANDE';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  MAJ_ENTETE_CMD (vf_errbuf, vf_retcode);
  IF  vf_retcode = 1 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;

  v_phase := 'PHASE  ANNULATION ENTETE DE COMMANDE';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  ANNUL_ENTETE_CMD (vf_errbuf, vf_retcode);
  IF  vf_retcode = 1 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;


  v_phase := 'PHASE  ANNULATION LIGNES DE COMMANDE';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  ANNUL_LIGNE_CMD (vf_errbuf, vf_retcode);
  IF  vf_retcode = 1 and pn_retcode < 2 THEN
       pn_retcode := 1;
  END IF ;

  v_phase := 'PHASE  Mise à jour statut commande';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  MAJ_STATUT_CMD(vf_errbuf, vf_retcode);

  ENREGISTREMENT_COMPTEUR(vf_errbuf, vf_retcode);

  v_phase := 'PHASE  Mise à jour des tables reporting/historique';
  DKA_TOOLS_PKG.put_log_message(v_phase);
  UPDATE_RECORD2(vf_errbuf,vf_retcode ,g_request_loader);

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

END  MAIN;

END DKA_IPOCDE_IVALUA_PKG;
/
SHOW ERRORS;
EXIT