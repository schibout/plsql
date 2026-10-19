create or replace PACKAGE BODY DKA_SAPFRSDUPLI_INIT_PKG IS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPFRSDUPLI_INIT_PKG.pkb  $
-- Capgemini
-- Projet           :
-- Nom              : DKA_SAPFRSDUPLI_INIT_PKG.pks
-- Description      : Corps du package DKA_SAPFRSDUPLI_INIT_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 14/01/2020
-- Commentaires     :
-- Historique
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------
-- 20/11/2020 ARA Correctif SPE006 sur party_site_id
--------------------------------------------------------------------------------
 -- g_UO_REF   VARCHAR2(7) := 'REF9999';
  g_package                 VARCHAR2(30)  := 'DKA_SAPFRSDUPLI_INIT_PKG';
  --g_nom_traitement          VARCHAR2(200) := 'DKA : Initialisation de la base de référence fournisseur ';
  g_sqlerrm                 VARCHAR2(500) := NULL;
  g_retproc                 NUMBER        := 0;
  g_site_a_creer            NUMBER := 0;
  g_site_a_attach           NUMBER := 0;
  g_site_a_maj              NUMBER := 0;
  g_adr_a_desactivee        NUMBER := 0;
  g_tab_sites_creer         t_sites_creer;
  g_tab_sites_attach        t_sites_attach;
  g_tab_sites_maj           t_sites_maj;
  g_tab_sites_valide        t_sites_valide;
  g_site_creer_ok           NUMBER := 0;
  g_site_creer_ko           NUMBER := 0;
  g_site_maj_ok             NUMBER := 0;
  g_site_maj_ko             NUMBER := 0;
  g_site_attach_ok          NUMBER := 0;
  g_site_attach_ko          NUMBER := 0;
  g_site_orph_ok            NUMBER := 0;
  g_site_a_valide           NUMBER := 0;
  g_nom_traitement          FND_CONCURRENT_PROGRAMS_VL.USER_CONCURRENT_PROGRAM_NAME%TYPE;
  g_code_traitement         FND_CONCURRENT_PROGRAMS_VL.CONCURRENT_PROGRAM_NAME%TYPE;
  g_request_id              NUMBER :=fnd_global.CONC_REQUEST_ID;
  g_user                    NUMBER        := fnd_profile.value('USER_ID');

  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 14/01/2020
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
    /*============================================================================*/
  /* Procedure         : writelog                                               */
  /* Description       : Ecriture dans fichier *.LOG                            */
  /* Parametres entree : P_message IN VARCHAR2 : message a ecrire               */
  /*                   : P_av      IN NUMBER   : Nb de saut de ligne avant      */
  /*                   : P_ap      IN NUMBER   : Nb de saut de ligne apres      */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE writelog(p_message IN VARCHAR2, p_av IN NUMBER, p_ap IN NUMBER)
  IS

  i                             NUMBER       := 0;
  l_procedure                   VARCHAR2(30) := 'writelog';
  v_etape                     VARCHAR2(2000);

  BEGIN
      v_etape := 'appel a FND_FILE.PUT_LINE';

      FOR i IN 1 .. p_av
      LOOP
          fnd_file.put_line(fnd_file.LOG, ' ');
      END LOOP;

      fnd_file.put_line(fnd_file.LOG, p_message);

      FOR i IN 1 .. p_ap
      LOOP
          fnd_file.put_line(fnd_file.LOG, ' ');
      END LOOP;
  EXCEPTION
      WHEN OTHERS THEN
          g_retproc := 1;
          g_sqlerrm := substr(sqlerrm, 1, 500);
          writelog('-------------------- ERREUR --------------------', 1, 0);
          writelog('Package   : ' || g_package, 0, 0);
          writelog('Procedure : ' || l_procedure, 0, 0);
          writelog('Exception : OTHERS', 0, 0);
          writelog('Message   : ' || v_etape, 0, 0);
          writelog('Cause     : ' || g_sqlerrm, 0, 0);
          writelog('------------------------------------------------', 0, 0);
  END writelog;
  /*============================================================================*/
  /* Fonction          : sortie_traitement                                      */
  /* Description       : affiche les statistiques dans la sortie de traitement  */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE sortie_traitement IS

    l_procedure                   VARCHAR2(30) := 'sortie_traitement';
    l_message                     VARCHAR2(2000);


  BEGIN

    ---------------
    -- Statistiques
    ---------------

    writeout('BILAN :');
    writeout('-------');
    writeout('');
    l_message := '     . Nombre de sites fournisseurs créés sur la référence avec succès : ' ||g_site_creer_ok;
    writeout(l_message);
    l_message := '     . Nombre de sites fournisseurs qui n''ont pas pu être créés sur la référence : ' ||g_site_creer_ko;
    writeout(l_message);
    l_message := '     . Nombre de sites fournisseurs qui ont changé d''adresse : ' ||g_site_attach_ok;
    writeout(l_message);
    l_message := '     . Nombre de sites fournisseurs pour lesquels le changement d''adresse a échoué : ' ||g_site_attach_ko;
    writeout(l_message);
	l_message := '     . Nombre de sites fournisseurs mis à jour à partir de la référence : ' ||g_site_maj_ok;
    writeout(l_message);
	l_message := '     . Nombre de sites fournisseurs pour lesquels la mise à jour à partir de la référence a échoué : ' ||g_site_maj_ko;
    writeout(l_message);
	l_message := '     . Nombre d''adresses orphelines qui ont été désactivées : ' ||g_adr_a_desactivee;
    writeout(l_message);

    writeout('');
    writeout('');

	IF g_tab_sites_valide.count > 0 THEN
      l_message := 'SITES POUR LESQUELS LA VALIDATION A ECHOUE :';
      writeout(l_message);
      writeout('---------------------------------------------');
      writeout( RPAD('N° de la ligne du fichier',35)||RPAD('Nom du fournisseur',35)||RPAD('Code site',25)||RPAD('UO du site',25)||RPAD('Code de l''adresse',25)||RPAD('Message erreur',500));
      writeout( RPAD('-------------------------',35)||RPAD('------------------',35)||RPAD('---------',25)||RPAD('----------',25)||RPAD('------------------',25)||RPAD('--------------',500));
      ---writeout('ATTENTION : Il y a des cas de rejet ou avertissement.');
	  FOR i IN g_tab_sites_valide.first..g_tab_sites_valide.last LOOP
        l_message := RPAD(g_tab_sites_valide(i).NUM_LIGNE,35)||RPAD(g_tab_sites_valide(i).NOM_FOURNISSEUR,35)||RPAD(g_tab_sites_valide(i).CODE_SITE,25)||RPAD(g_tab_sites_valide(i).UO_SITE,25)||RPAD(g_tab_sites_valide(i).CODE_ADRESSE,25)||RPAD(g_tab_sites_valide(i).LISTE_MSG,500);
        writeout(l_message);
	  END LOOP;
    END IF;

	writeout('');
    writeout('');

	IF g_tab_sites_creer.count > 0 THEN
      l_message := 'SITES EN ERREUR DE CREATION SUR LA REFERENCE';
      writeout(l_message);
      writeout('---------------------------------------------');
      writeout( RPAD('N° de la ligne du fichier',35)||RPAD('Nom du fournisseur',35)||RPAD('Code site',25)||RPAD('UO du site',25)||RPAD('Code de l''adresse',25)||RPAD('Message erreur',500));
      writeout( RPAD('-------------------------',35)||RPAD('------------------',35)||RPAD('---------',25)||RPAD('----------',25)||RPAD('------------------',25)||RPAD('--------------',500));

	  FOR i IN g_tab_sites_creer.first..g_tab_sites_creer.last LOOP
        l_message := RPAD(g_tab_sites_creer(i).NUM_LIGNE,35)||RPAD(g_tab_sites_creer(i).NOM_FOURNISSEUR,35)||RPAD(g_tab_sites_creer(i).CODE_SITE,25)||RPAD(g_tab_sites_creer(i).UO_SITE,25)||RPAD(g_tab_sites_creer(i).CODE_ADRESSE,25)||RPAD(g_tab_sites_creer(i).LISTE_MSG,500);
        writeout(l_message);
	  END LOOP;
	END IF ;

	writeout('');
    writeout('');

	IF g_tab_sites_attach.count > 0 THEN
      l_message := 'SITES POUR LESQUELS LE CHANGEMENT D''ADRESSE A ECHOUE';
	  writeout(l_message);
      writeout('-----------------------------------------------------');
      writeout( RPAD('N° de la ligne du fichier',35)||RPAD('Nom du fournisseur',35)||RPAD('Code site',25)||RPAD('UO du site',25)||RPAD('Code de l''adresse',25)||RPAD('Message erreur',500));
      writeout( RPAD('-------------------------',35)||RPAD('------------------',35)||RPAD('---------',25)||RPAD('----------',25)||RPAD('------------------',25)||RPAD('--------------',500));

	  FOR i IN g_tab_sites_attach.first..g_tab_sites_attach.last LOOP
        l_message := RPAD(g_tab_sites_attach(i).NUM_LIGNE,35)||RPAD(g_tab_sites_attach(i).NOM_FOURNISSEUR,35)||RPAD(g_tab_sites_attach(i).CODE_SITE,25)||RPAD(g_tab_sites_attach(i).UO_SITE,25)||RPAD(g_tab_sites_attach(i).CODE_ADRESSE,25)||RPAD(g_tab_sites_attach(i).LISTE_MSG,500);
        writeout(l_message);
	  END LOOP;
	END IF ;

	writeout('');
    writeout('');

	IF g_tab_sites_maj.count > 0 THEN
      l_message := 'SITES POUR LESQUELS LA MISE A JOUR A ECHOUE';
	  writeout(l_message);
      writeout('---------------------------------------------');
      writeout( RPAD('Nom du fournisseur',35)||RPAD('Code de l''adresse',25)||RPAD('Code site',25)||RPAD('UO du site',25)||RPAD('Message erreur',500));
      writeout( RPAD('------------------',35)||RPAD('------------------',25)||RPAD('---------',25)||RPAD('----------',25)||RPAD('--------------',500));

	  FOR i IN g_tab_sites_maj.first..g_tab_sites_maj.last LOOP
        l_message := RPAD(g_tab_sites_maj(i).NOM_FOURNISSEUR,35)||RPAD(g_tab_sites_maj(i).CODE_ADRESSE,25)||RPAD(g_tab_sites_maj(i).CODE_SITE,25)||RPAD(g_tab_sites_maj(i).UO_SITE,25)||RPAD(g_tab_sites_maj(i).LISTE_MSG,500);
        writeout(l_message);
	  END LOOP;
	END IF ;

END sortie_traitement;
  /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie(p_nom_fichier IN VARCHAR2) IS

  l_procedure                   VARCHAR2(30) := 'entete_de_sortie';
  l_message                    VARCHAR2(2000);

  BEGIN
    l_message := 'Information du traitement principale';
    BEGIN
    SELECT fcp.USER_CONCURRENT_PROGRAM_NAME
    ,      fcp.CONCURRENT_PROGRAM_NAME
    INTO   g_nom_traitement
    ,      g_code_traitement
    FROM   FND_CONCURRENT_PROGRAMS_VL fcp
    ,      FND_CONCURRENT_REQUESTS    fcr
    WHERE  1 = 1
    AND    fcr.PROGRAM_APPLICATION_ID = fcp.APPLICATION_ID
    AND    fcp.CONCURRENT_PROGRAM_ID = fcr.CONCURRENT_PROGRAM_ID
    AND    fcr.REQUEST_ID            = g_request_id;
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
    g_nom_traitement := '???????????????????';
    g_code_traitement := '?????';
    END;

    writeout('+-------------------------------------------------------------------------+');
    writeout('                                                                           ');
    writeout('Nom du traitement  : '||g_nom_traitement);
    writeout('Code du traitement : '||g_code_traitement);
    writeout('Programme lancé le : '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
    writeout('                                                                           ');
    writeout('+-------------------------------------------------------------------------+');

    writeout('PARAMETRES : ');
    writeout('------------');
    writeout('Nom du fichier à traiter : '||p_nom_fichier);
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
  -- Procedure         : LANCE_CHARGEMENT_FICHIER
  -- Description       : Procédure pour lancer le cahrgement de la table de tarvail
  -- Parametres entree : p_fichier IN VARCHAR2 : chemin complet de fichier à charger
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
  -- Date              : 14/01/2020
  -- Remarques         :
/*=================================================================================*/
PROCEDURE LANCE_CHARGEMENT_FICHIER  (pv_errbuf  IN OUT VARCHAR2,
                                     pn_retcode OUT NUMBER,
                                     p_fichier IN VARCHAR2
                                      ) IS

  l_procedure VARCHAR2(30) := 'LANCE_CHARGEMENT_FICHIER';
  l_message   VARCHAR2(2000);
  l_request_id       NUMBER;
  l_application_code VARCHAR2(50) := 'DKA';
  l_conc_program     VARCHAR2(50) := 'DKA_SAPFRSDUPLI_LOADER';
  l_execute_code                BOOLEAN;
  l_req_interval                NUMBER := 30;
  l_req_max_wait                NUMBER := 999999;
  l_req_ret_code                NUMBER;
  l_req_phase                   VARCHAR2(255);
  l_req_status                  VARCHAR2(255);
  l_req_dev_phase               VARCHAR2(255);
  l_req_dev_status              VARCHAR2(255);
  l_req_message                 VARCHAR2(255);
  BEGIN
    l_message := l_procedure || '- 01 - Debut';
    Fnd_File.put_line(Fnd_File.LOG, l_message);

    l_message := l_procedure || '- 02 - Submit Request';
    Fnd_File.put_line(Fnd_File.LOG, l_message);
    l_request_id := FND_REQUEST.submit_request(l_application_code,
                                                l_conc_program,
                                                '',
                                                SYSDATE,
                                                FALSE,
                                                p_fichier
                                                );


COMMIT;
    IF l_request_id != 0 THEN
        l_message := l_procedure||' - 03 - Attente fin traitement';
        writelog(l_message,0,0);
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
            l_message := l_procedure||' - 04a - Traitement terminé en avertissement';
            writelog(l_message,0,0);
            pn_retcode := 1;
        ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'ERROR' THEN
            l_message := l_procedure||' - 04b - Traitement terminé en erreur';
            writelog(l_message,0,0);
            pn_retcode := 2;
        ELSIF l_req_dev_phase = 'COMPLETE' AND l_req_dev_status = 'NORMAL' THEN
            l_message := l_procedure||' - 04b - Traitement terminé normal';
            writelog(l_message,0,0);
            pn_retcode := 0;
        END IF;
    ELSE
        l_message := l_procedure||' - 03 - Erreur lors du lancement du traitement';
        writelog(l_message,0,0);
        pn_retcode := 2;

    END IF;

    writeout('CHARGEMENT DU FICHIER :');
    writeout('-----------------------');
    writeout('. Numéro du traitement de chargement du fichier : '||l_request_id);
    writeout('. Statut de fin : Terminé/'||l_req_dev_status);
    writeout('                                                                           ');
    writeout('                                                                           ');

END LANCE_CHARGEMENT_FICHIER;
  /*============================================================================*/
 -- Procedure         : VALIDATION_DONNEES
 -- Description       : valider les donner de la table de tarvail
 -- Parametres entree :
 -- Parametres sortie : AUCUN
 -- Auteur            : Asma AMENKOUR
 -- Date              : 14/01/2020
 -- Remarques         :
/*===============================================================================*/
PROCEDURE VALIDATION_DONNEES(pv_errbuf  IN OUT VARCHAR2,
                             pn_retcode OUT NUMBER) IS

  CURSOR C_DONNEE IS
  SELECT * FROM DKA_SAPFRSDUPLI_INIT_TMP WHERE STATUT ='NEW';

  v_procedure            VARCHAR2(30):='VALIDATION_DONNEES';
  v_etape                VARCHAR2(500);
  v_message              VARCHAR2(500) := null;
  V_COUNTRY_CODE         ap_supplier_sites_all.COUNTRY%TYPE;
  V_ZIP                  ap_supplier_sites_all.ZIP%TYPE;
  V_VENDOR_SITE_ID_REF   ap_supplier_sites_all.VENDOR_SITE_ID%TYPE;
  V_CODE_PAYS            FND_TERRITORIES.ISO_TERRITORY_CODE%TYPE;
  V_CODE_POSTAL_LG       NUMBER;
  V_CODE_SUP             FND_FLEX_VALUES_VL.FLEX_VALUE%TYPE;
  v_nbr_site_ref         NUMBER;
  v_uo_ref               DKA_SAPFRSDUPLI_INIT_TMP.UO_SITE_REF%TYPE;
  v_site_ref             DKA_SAPFRSDUPLI_INIT_TMP.VENDOR_SITE_CODE_REF%TYPE;
  v_exit_ref             NUMBER;
  V_CODE_POSTAL          NUMBER;
  v_id_site_cree        ap_supplier_sites_all.vendor_site_id%TYPE;
  v_ADDRESS_CODE_REF    DKA_SAPFRSDUPLI_INIT_TMP.address_code%TYPE;


  BEGIN
    FOR rec_donnee IN C_DONNEE LOOP
       --g_site_a_valide := g_site_a_valide + 1;
       DBMS_OUTPUT.PUT_LINE('DEBUT VALIDATION');
       writelog('Début Validation ligne '||rec_donnee.ligne_num,0,0);
       DBMS_OUTPUT.PUT_LINE('rec_donnee.ADDRESS_CODE: '||rec_donnee.ADDRESS_CODE);
       DBMS_OUTPUT.PUT_LINE('rec_donnee.VENDOR_SITE_CODE_REF: '||rec_donnee.VENDOR_SITE_CODE_REF);
       DBMS_OUTPUT.PUT_LINE('rec_donnee.UO_SITE_REF: '||rec_donnee.UO_SITE_REF);

       pn_retcode:=0;
      v_etape := 'RG-INIT3 : Homogénéisation des codes sites lors de l''initialisation de la référence' ;
      --writelog(v_procedure ||':'||v_etape,0,0);
      DBMS_OUTPUT.PUT_LINE(v_procedure ||':'||v_etape);
      BEGIN
        SELECT COUNTRY
		    ,      ZIP
		    ,      VENDOR_SITE_ID
        ,      PARTY_SITE_NAME
		    INTO   V_COUNTRY_CODE
		    ,      V_ZIP
		    ,      V_VENDOR_SITE_ID_REF
        ,      v_ADDRESS_CODE_REF
		    FROM   ap_supplier_sites_all ass
		    ,      HR_OPERATING_UNITS hou
        ,      ap_suppliers asa
        ,      hz_party_sites hps
		    WHERE  ass.vendor_site_code = rec_donnee.VENDOR_SITE_CODE_REF
		    AND    ass.org_id       = hou.organization_id
        AND    hou.name         = rec_donnee.UO_SITE_REF
        AND    ass.vendor_id    =  asa.vendor_id
        AND    asa.vendor_name  =  rec_donnee.vendor_name
        AND    hps.location_id  = ass.location_id
        AND    hps.party_site_id = ass.party_site_id
       ;


      EXCEPTION
	      WHEN NO_DATA_FOUND THEN
            UPDATE DKA_SAPFRSDUPLI_INIT_TMP
            SET STATUT = 'REJECTED',
			          LAST_UPDATED_BY = g_user,
                LAST_UPDATE_DATE = SYSDATE
            WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
              AND UO_SITE_REF          = rec_donnee.UO_SITE_REF
              AND VENDOR_NAME          = rec_donnee.VENDOR_NAME;
            pn_retcode := 1;
            v_message := 'la requête des informations d''adresse ne ramène aucune donnée';
		    DBMS_OUTPUT.PUT_LINE(v_message);
	  END;    

    IF (rec_donnee.VENDOR_SITE_CODE = rec_donnee.VENDOR_SITE_CODE_REF)   AND (rec_donnee.UO = rec_donnee.UO_SITE_REF)
    THEN  --Seules les adresses liées aux sites à prendre pour référence sont à contrôler
	  IF LENGTH(v_ADDRESS_CODE_REF) > 15 THEN
	    v_message := 'Le code adresse ne doit pas dépasser 15 caractères';
        DBMS_OUTPUT.PUT_LINE(v_message);
        writelog(v_message,0,0);
	      	UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	      	SET STATUT = 'REJECTED',
		          LAST_UPDATED_BY = g_user,
			        LAST_UPDATE_DATE = SYSDATE
          WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
            AND UO_SITE_REF          = rec_donnee.UO_SITE_REF
            AND VENDOR_NAME          = rec_donnee.VENDOR_NAME;
        pn_retcode := 1;
	  ELSE
      v_etape := 'RG-INIT4 : Vérification des règles de nommage';
      --writelog(v_procedure ||':'||v_etape,0,0);
      DBMS_OUTPUT.PUT_LINE(v_procedure ||':'||v_etape);
      DBMS_OUTPUT.PUT_LINE('rec_donnee.VENDOR_SITE_CODE_REF :'||rec_donnee.VENDOR_SITE_CODE_REF);
      DBMS_OUTPUT.PUT_LINE('rec_donnee.vendor_name :'||rec_donnee.vendor_name);
      DBMS_OUTPUT.PUT_LINE('rec_donnee.UO_SITE_REF :'||rec_donnee.UO_SITE_REF);

       BEGIN
	      SELECT ISO_TERRITORY_CODE
        INTO   V_CODE_PAYS
        FROM   FND_TERRITORIES
        WHERE  TERRITORY_CODE = V_COUNTRY_CODE ;
	  EXCEPTION
	    WHEN NO_DATA_FOUND THEN
		  V_CODE_PAYS := 'FRA';
	  END;
	  BEGIN
	      SELECT return_value
        INTO   V_CODE_POSTAL_LG
        FROM   DKA_STRANSCO_LINES      DSTL,
	      	     DKA_STRANSCO_HEADERS    DSTH
        WHERE  DSTL.SET_ID 					 = DSTH.SET_ID
        AND    DSTH.SET_NAME LIKE 'DKA_PAYS_LONGUEUR_CODE_POSTAL'
        AND    DSTL.ENABLE					 = 'Y'
        and    params_value = V_CODE_PAYS --V_COUNTRY_CODE
        AND    NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE);
	  EXCEPTION
	    WHEN NO_DATA_FOUND THEN
	      V_CODE_POSTAL_LG := 0;
	  END;

      DBMS_OUTPUT.PUT_LINE('V_VENDOR_SITE_ID_REF :'||V_VENDOR_SITE_ID_REF);
	    IF SUBSTR(v_ADDRESS_CODE_REF,1,3) != V_CODE_PAYS THEN
	      v_message := 'Le code de l''adresse à prendre pour référence ne respecte pas les règles de nommage : Le code pays est une zone obligatoire et il faut qu''il soit sur 3 caractères';
        DBMS_OUTPUT.PUT_LINE(v_message);
        writelog(v_message,0,0);
	      	UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	      	SET STATUT = 'REJECTED',
	      	    LAST_UPDATED_BY = g_user,
	        		LAST_UPDATE_DATE = SYSDATE
          WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
            AND UO_SITE_REF          = rec_donnee.UO_SITE_REF
            AND VENDOR_NAME          = rec_donnee.VENDOR_NAME;
        pn_retcode := 1;

	  ELSIF (V_CODE_POSTAL_LG = 0  AND SUBSTR(v_ADDRESS_CODE_REF,4,V_CODE_POSTAL_LG) != V_ZIP) THEN
        v_message := 'Le code de l''adresse à prendre pour référence ne respecte pas les règles de nommage : Le code postal est une zone obligatoire et il faut qu''il soit entre 5 et 7 caractères selon le pays ';
        DBMS_OUTPUT.PUT_LINE(v_message);
        writelog(v_message,0,0);
	      	UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	      	SET STATUT = 'REJECTED',
	      	    LAST_UPDATED_BY = g_user,
	        		LAST_UPDATE_DATE = SYSDATE
          WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
            AND UO_SITE_REF          = rec_donnee.UO_SITE_REF
            AND VENDOR_NAME          = rec_donnee.VENDOR_NAME;
        pn_retcode := 1;
	  ELSIF(SUBSTR(v_ADDRESS_CODE_REF,V_CODE_POSTAL_LG +4) IS NOT NULL)THEN
					BEGIN
					   SELECT FLEX_VALUE
              INTO   V_CODE_SUP
							FROM
							FND_FLEX_VALUE_SETS  	FFVS ,
							FND_FLEX_VALUES_VL   	FFVV
							WHERE  FFVS.FLEX_VALUE_SET_ID 	     = FFVV.FLEX_VALUE_SET_ID
							AND    FFVS.FLEX_VALUE_SET_NAME      = 'DKA_SITE_FRS_COMPLEMENT'
							and FLEX_VALUE = SUBSTR(rec_donnee.ADDRESS_CODE,V_CODE_POSTAL_LG +4);

					EXCEPTION
					WHEN NO_DATA_FOUND THEN
					  v_message := 'Le code de l''adresse à prendre pour référence ne respecte pas les règles de nommage :Le CODE COMPLEMENTAIRE s''il existe il faut qu''il soit entre 6 et 8 caractères ';
		              --p_retcode := 1;
					  DBMS_OUTPUT.PUT_LINE(v_message);
                      writelog(v_message,0,0);
                      UPDATE DKA_SAPFRSDUPLI_INIT_TMP
                      SET STATUT = 'REJECTED',
                          LAST_UPDATED_BY = g_user,
                          LAST_UPDATE_DATE = SYSDATE
                      WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
                        AND UO_SITE_REF          = rec_donnee.UO_SITE_REF
                        AND VENDOR_NAME          = rec_donnee.VENDOR_NAME;
                      pn_retcode := 1;
                    END;
      END IF;

   END IF;
    END IF;
      v_etape := 'RG-INIT5 : Cas où 2 sites fournisseurs rattachés à la même adresse ont été désignés comme référence';
      DBMS_OUTPUT.PUT_LINE(v_procedure ||':'||v_etape);
      --writelog(v_procedure ||':'||v_etape,0,0);
		BEGIN
          SELECT count(*)
          ,      UO_SITE_REF
          ,      VENDOR_SITE_CODE_REF          
		      INTO  v_nbr_site_ref
		      ,     v_uo_ref
		      ,     v_site_ref
          FROM  DKA_SAPFRSDUPLI_INIT_TMP dsip
              , AP_SUPPLIER_SITES_ALL ass
              , AP_SUPPLIERS asp
              , HR_OPERATING_UNITS hou
          WHERE dsip.VENDOR_NAME = rec_donnee.VENDOR_NAME
          AND ass.VENDOR_SITE_CODE = dsip.VENDOR_SITE_CODE_REF
          AND hou.NAME = dsip.UO_SITE_REF
          AND ass.ORG_ID = hou.ORGANIZATION_ID
          AND ass.VENDOR_ID = asp.VENDOR_ID
          AND asp.VENDOR_NAME = dsip.VENDOR_NAME 
          AND ass.LOCATION_ID = (SELECT ass1.LOCATION_ID 
                                    FROM AP_SUPPLIER_SITES_ALL ass1
                                       , HR_OPERATING_UNITS hou1
                                     WHERE ass1.VENDOR_ID = asp.VENDOR_ID   
                                       AND ass1.VENDOR_SITE_CODE = rec_donnee.VENDOR_SITE_CODE_REF
                                       AND ass1.ORG_ID = hou.ORGANIZATION_ID
                                       AND hou1.NAME = rec_donnee.UO_SITE_REF)
          GROUP BY UO_SITE_REF
          ,        VENDOR_SITE_CODE_REF;                              

		EXCEPTION
		  WHEN TOO_MANY_ROWS THEN
	        v_message := 'Le site '||rec_donnee.VENDOR_SITE_CODE_REF||' de l''UO '|| rec_donnee.UO_SITE_REF|| ' n''a pas pu être recopié sur UO de référence. Un seul site peut être désigné comme référence pour une même adresse fournisseur';
		  DBMS_OUTPUT.PUT_LINE(v_message);
          writelog(v_message,0,0);
          UPDATE DKA_SAPFRSDUPLI_INIT_TMP
		      SET STATUT = 'REJECTED',
		          LAST_UPDATED_BY = g_user,
			        LAST_UPDATE_DATE = SYSDATE
          WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
                AND UO_SITE_REF      = rec_donnee.UO_SITE_REF
                AND VENDOR_NAME      = rec_donnee.VENDOR_NAME;
          pn_retcode := 1;
          WHEN OTHERS THEN
          UPDATE DKA_SAPFRSDUPLI_INIT_TMP
		      SET STATUT = 'REJECTED',
		          LAST_UPDATED_BY = g_user,
			        LAST_UPDATE_DATE = SYSDATE
         WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
                AND UO_SITE_REF      = rec_donnee.UO_SITE_REF
                AND VENDOR_NAME      = rec_donnee.VENDOR_NAME;
		END;

      v_etape := 'RG-INIT6 : Cas où il existe déjà un site rattaché à l''adresse sur la base de référence';
      DBMS_OUTPUT.PUT_LINE(v_procedure ||':'||v_etape);

      --writelog(v_procedure ||':'||v_etape,0,0);
        BEGIN
	      SELECT  count(*)
	      INTO   v_exit_ref
          FROM
          ap_supplier_sites_all assa,
          ap_suppliers asp,
          hz_party_sites hps,
          hr_organization_units hou
          WHERE asp.vendor_id = assa.vendor_id
          AND assa.location_id = hps.location_id
          AND assa.party_site_id = hps.party_site_id
          AND hps.status = 'A'
          AND hou.organization_id = assa.org_id
          AND hou.name = 'REF9999'
	        AND hps.party_site_name = v_ADDRESS_CODE_REF
          AND asp.vendor_name = rec_donnee.VENDOR_NAME;
		EXCEPTION
		    WHEN OTHERS THEN
			  v_exit_ref := 1;
        END;


        IF 	v_exit_ref >= 1	THEN

            v_message := 'Un site fournisseur correspondant à l''adresse '||v_ADDRESS_CODE_REF||' est déjà crée sur la base de référence';
            DBMS_OUTPUT.PUT_LINE(v_message);
            writelog(v_message,0,0);
            --Extraction du id du site cree sur la reference:
            BEGIN
                SELECT  vendor_site_id
                INTO    v_id_site_cree
                FROM    ap_supplier_sites_all assa, 
                        ap_suppliers asp,
                        hr_operating_units hou                
                WHERE vendor_site_code= v_ADDRESS_CODE_REF
                AND   hou.organization_id = assa.org_id
                AND   asp.vendor_id = assa.vendor_id
                AND   asp.vendor_name = rec_donnee.VENDOR_NAME
                AND   hou.name = 'REF9999';
            EXCEPTION  
              WHEN NO_DATA_FOUND THEN
                pn_retcode := 1;
                v_message := 'la requête ne ramène pas  l''identifiant du site fournisseur créé sur la référence pour l''adresse '||v_ADDRESS_CODE_REF;
            END ;
            UPDATE DKA_SAPFRSDUPLI_INIT_TMP
		           SET STATUT = 'CREATEOK',
			             VENDOR_SITE_ID_REF      = V_VENDOR_SITE_ID_REF,
		          	   ADDRESS_CODE_REF        = v_ADDRESS_CODE_REF,
                   ID_SITE_CREE            = v_id_site_cree,
			           	 LAST_UPDATED_BY = g_user,
			            	LAST_UPDATE_DATE = SYSDATE
		         WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
		         AND   UO_SITE_REF          = rec_donnee.UO_SITE_REF
             AND   VENDOR_NAME          = rec_donnee.VENDOR_NAME
            --AND ADDRESS_CODE           = rec_donnee.ADDRESS_CODE
			;


            pn_retcode := 1;
		END IF;
        DBMS_OUTPUT.PUT_LINE('pn_retcode ='||pn_retcode);

        IF pn_retcode = 0 THEN
        DBMS_OUTPUT.PUT_LINE('ENTREE à la req d''update');
	      	UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	      	SET   VENDOR_SITE_ID_REF = V_VENDOR_SITE_ID_REF,
		            ADDRESS_CODE_REF   = v_ADDRESS_CODE_REF,
                STATUT ='VALIDATED',
			          LAST_UPDATED_BY = g_user,
			          LAST_UPDATE_DATE = SYSDATE
		      WHERE VENDOR_SITE_CODE_REF = rec_donnee.VENDOR_SITE_CODE_REF
		      AND   UO_SITE_REF          = rec_donnee.UO_SITE_REF
          AND   VENDOR_NAME          = rec_donnee.VENDOR_NAME
		  AND   STATUT          != 'REJECTED';
        ELSE
          g_site_a_valide := g_site_a_valide + 1;
          g_tab_sites_valide(g_site_a_valide).NUM_LIGNE       := rec_donnee.ligne_num;
          g_tab_sites_valide(g_site_a_valide).NOM_FOURNISSEUR := rec_donnee.VENDOR_NAME;
          g_tab_sites_valide(g_site_a_valide).CODE_SITE       := rec_donnee.VENDOR_SITE_CODE;
          g_tab_sites_valide(g_site_a_valide).UO_SITE         := rec_donnee.UO;
          g_tab_sites_valide(g_site_a_valide).CODE_ADRESSE    := rec_donnee.ADDRESS_CODE;
          g_tab_sites_valide(g_site_a_valide).LISTE_MSG       := v_message;
          --pn_retcode := 1;
        END IF;
	COMMIT;



    END LOOP;
END VALIDATION_DONNEES;
  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 14/01/2020
/*=========================================================================================================*/
PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
               pn_retcode OUT NUMBER,
			   p_nom_fichier IN VARCHAR2) IS

CURSOR C_SITE_ACREER IS
  SELECT  count(1)
  ,       VENDOR_NAME
  ,       ADDRESS_CODE_REF
  ,       UO_SITE_REF
  ,       VENDOR_SITE_ID_REF
  ,       VENDOR_SITE_CODE_REF
  FROM DKA_SAPFRSDUPLI_INIT_TMP WHERE STATUT = 'VALIDATED'
  GROUP BY VENDOR_NAME
  ,        ADDRESS_CODE_REF
  ,        UO_SITE_REF
  ,        VENDOR_SITE_ID_REF
  ,        VENDOR_SITE_CODE_REF;

CURSOR C_SITE_AMAJ IS
    SELECT  distinct 
            VENDOR_NAME
    ,       UO_SITE_REF
	,       ADDRESS_CODE_REF
    ,       VENDOR_SITE_ID_REF
    ,       VENDOR_SITE_CODE_REF
    ,       id_site_cree
    FROM DKA_SAPFRSDUPLI_INIT_TMP WHERE STATUT IN ('CREATEOK', 'ATTACHOK')
    AND id_site_cree IS NOT NULL;

  v_retcode              NUMBER;
  v_nombre_succes        NUMBER;
  v_nombre_echoues       NUMBER;
  v_nombre_ignores       NUMBER;
  v_resultat_duplication VARCHAR2(2);
  v_id_liste_erreur      NUMBER;
  v_id_site_cree         NUMBER;
  v_result_maj           VARCHAR2(2);
  v_nombre_existe        NUMBER;
  v_nbr_maj_succes       NUMBER;
  v_nbr_maj_echec        NUMBER;
  v_maj_code_echec       NUMBER;
  v_modif_attach         NUMBER;
  v_site_exist           NUMBER;
  v_phase                VARCHAR2(500);
  v_etape                VARCHAR2(500);
  v_location_id_ref      ap_supplier_sites_all.location_id%TYPE;
  v_party_site_id_ref    ap_supplier_sites_all.party_site_id%TYPE;
  vv_errbuf              VARCHAR2(500);
  vn_retcode             NUMBER;
  vf_errbuf              VARCHAR2(500);
  vf_retcode             NUMBER;
  vf_statut              VARCHAR2(30);
  vf_request_id          NUMBER;
  v_message              VARCHAR2(500);
  tv_perimetre           DKA_SAPFRSDUPLI_PKG.tabtype;
  v_line_num             DKA_SAPFRSDUPLI_INIT_TMP.LIGNE_NUM%type;
  l_path_c               VARCHAR2(240) := 'DKA_IN_DIR';
  v_chemin_fichier       VARCHAR2(500);
  --v_new_address         HZ_PARTY_SITES.PARTY_SITE_NAME%TYPE;
  v_user_id              NUMBER;
  v_resp_id              NUMBER;
  v_resp_appl_id         NUMBER;
  proc_warning           EXCEPTION;
  l_procedure            VARCHAR2(30) := 'MAIN';
  --v_adresse_code       DKA_SAPFRSDUPLI_INIT_TMP.ADDRESS_CODE%TYPE;
  v_id_site_ref          DKA_SAPFRSDUPLI_INIT_TMP.ID_SITE_CREE%TYPE;
  v_VENDOR_SITE_CODE_DUP ap_supplier_sites_all.vendor_site_code%type;
  v_UO_SITE_DUP          hr_operating_units.name%type;

BEGIN

  v_phase := 'PHASE Préliminaire';
  writelog(v_phase,0,0);
  entete_de_sortie(p_nom_fichier);

  IF p_nom_fichier IS NOT NULL THEN
    --Purger la table de travail

    DELETE FROM DKA_SAPFRSDUPLI_INIT_TMP;

    execute immediate'drop sequence DKA.DKA_LINE_NUMBER_S';
    execute immediate'CREATE SEQUENCE DKA.DKA_LINE_NUMBER_S INCREMENT BY 1';
    execute immediate'drop SYNONYM DKA_LINE_NUMBER_S';
    execute immediate'CREATE SYNONYM DKA_LINE_NUMBER_S FOR DKA.DKA_LINE_NUMBER_S';


    v_phase := 'PHASE 1 : Phase de chargement';
    BEGIN
      SELECT DIRECTORY_PATH
      INTO   v_chemin_fichier
      FROM   ALL_DIRECTORIES
      WHERE  OWNER = 'SYS'
      AND    DIRECTORY_NAME = l_path_c --'DKA_IN_DIR'--
     ;
     EXCEPTION
      WHEN OTHERS THEN
        writelog('Problème pour trouver le chemin absolu',0,0);
     END;

    LANCE_CHARGEMENT_FICHIER (vf_errbuf ,
                              vf_retcode,
                              v_chemin_fichier||'/'||p_nom_fichier);

     IF  vf_retcode = 2  THEN
       pn_retcode := 1;
      -- RAISE proc_WARNING;
     END IF ;

  ELSE

    v_etape := 'RG-INIT14 : Retraitement des rejets';
    UPDATE DKA_SAPFRSDUPLI_INIT_TMP
    SET STATUT = 'NEW',
        LAST_UPDATED_BY = g_user,
        LAST_UPDATE_DATE = SYSDATE
    WHERE STATUT IN ('REJECTED' ,'CREATEKO');

    UPDATE DKA_SAPFRSDUPLI_INIT_TMP
    SET STATUT = 'CREATEOK',
        LAST_UPDATED_BY = g_user,
        LAST_UPDATE_DATE = SYSDATE
    WHERE STATUT IN ('ATTACHKO');


  END IF;
  COMMIT;



  v_phase := 'PHASE 2 : Phase de validation des sites à prendre pour référence';
  writelog(v_phase,0,0);
  DBMS_OUTPUT.PUT_LINE(v_phase);
  VALIDATION_DONNEES (vv_errbuf ,vn_retcode);
  IF vn_retcode != 0 Then
    pn_retcode := vn_retcode;
  END IF;
  --En mode recyclage il se peut que des lignes de fichier ont le statut valide par contre le fournisseur de reference correspondant est deja cree 

  FOR rec_created IN (SELECT * FROM DKA_SAPFRSDUPLI_INIT_TMP 
                       WHERE STATUT = 'VALIDATED'
					               AND VENDOR_SITE_ID_REF IN (SELECT VENDOR_SITE_ID_REF 
					                                          FROM DKA_SAPFRSDUPLI_INIT_TMP 
												                            WHERE STATUT = 'CREATEOK'))LOOP
   /* BEGIN
      SELECT ID_SITE_CREE
      INTO   v_id_site_ref
      FROM DKA_SAPFRSDUPLI_INIT_TMP  
      WHERE VENDOR_SITE_ID_REF =rec_created.VENDOR_SITE_ID_REF
      AND ROWNUM =1;
    EXCEPTION
      WHEN OTHERS THEN
        v_id_site_ref := null ;
    END;*/


    UPDATE DKA_SAPFRSDUPLI_INIT_TMP
    SET STATUT = 'CREATEOK',
       -- ID_SITE_CREE = v_id_site_ref,
	      LAST_UPDATED_BY = g_user,
	    	LAST_UPDATE_DATE = SYSDATE
    WHERE ADDRESS_CODE = rec_created.ADDRESS_CODE
    AND   UO_SITE_REF  = rec_created.UO_SITE_REF
    AND   VENDOR_SITE_ID_REF = rec_created.VENDOR_SITE_ID_REF
    AND   VENDOR_SITE_CODE_REF = rec_created.VENDOR_SITE_CODE_REF;
    COMMIT;

  END LOOP;


  v_phase := 'PHASE 3 : Phase de création des sites de référence';
  writelog(v_phase,0,0);
  DBMS_OUTPUT.PUT_LINE(v_phase);
  FOR rec_site_acreer IN C_SITE_ACREER LOOP
    --g_site_a_creer := g_site_a_creer + 1;

    --Identification de la ligne niveau création :
    SELECT LIGNE_NUM
    INTO   v_line_num
    FROM DKA_SAPFRSDUPLI_INIT_TMP
    WHERE 1=1
    AND   VENDOR_NAME = rec_site_acreer.VENDOR_NAME
   -- AND   ADDRESS_CODE = rec_site_acreer.ADDRESS_CODE
    AND   UO_SITE_REF  = rec_site_acreer.UO_SITE_REF
    AND   VENDOR_SITE_ID_REF = rec_site_acreer.VENDOR_SITE_ID_REF
    AND   VENDOR_SITE_CODE_REF = rec_site_acreer.VENDOR_SITE_CODE_REF
    AND   ROWNUM = 1;


	v_etape := 'RG-INIT7 : Création des sites de référence';
      SELECT hou.name
      BULK COLLECT INTO tv_perimetre
      FROM hr_operating_units hou
      WHERE name IN ('REF9999');
      DBMS_OUTPUT.PUT_LINE('rec_site_acreer.VENDOR_SITE_ID_REF :'||rec_site_acreer.VENDOR_SITE_ID_REF);
   --   DBMS_OUTPUT.PUT_LINE('rec_site_acreer.ADDRESS_CODE :'||rec_site_acreer.ADDRESS_CODE);
	  DKA_SAPFRSDUPLI_PKG.DUPLICATION_SITE_FOURNISSEUR ( v_retcode                             ,
                                                       tv_perimetre                          ,
                                                       rec_site_acreer.VENDOR_SITE_ID_REF    ,
                                                       v_nombre_succes                       ,
                                                       v_nombre_echoues                      ,
                                                       v_nombre_ignores                      ,
                                                       v_resultat_duplication                ,
                                                       v_nombre_existe                       ,
                                                       v_id_liste_erreur                     ,
                                                       v_id_site_cree
                                         );
      DBMS_OUTPUT.PUT_LINE('v_resultat_duplication :'|| v_resultat_duplication);
      DBMS_OUTPUT.PUT_LINE('v_nombre_existe :'|| v_nombre_existe);
      DBMS_OUTPUT.PUT_LINE('v_id_liste_erreur :'|| v_id_liste_erreur);
      DBMS_OUTPUT.PUT_LINE('v_nombre_echoues :'|| v_nombre_echoues);

    /* SELECT ADDRESS_CODE
     INTO   v_adresse_code   
     FROM   DKA_SAPFRSDUPLI_INIT_TMP 
     WHERE  VENDOR_SITE_ID_REF   = rec_site_acreer.VENDOR_SITE_ID_REF
     AND    VENDOR_SITE_CODE     = rec_site_acreer.VENDOR_SITE_CODE_REF
     AND    ROWNUM =1;*/

	  IF v_resultat_duplication = 'OK' THEN
	    v_message := 'La création du fournisseur'||rec_site_acreer.VENDOR_SITE_CODE_REF||' sur la base de référence a été bine passé';
        g_site_creer_ok := g_site_creer_ok + 1;
         DBMS_OUTPUT.PUT_LINE(v_message);
	       UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	       SET STATUT = 'CREATEOK',
		         LAST_UPDATED_BY = g_user,
			       LAST_UPDATE_DATE = SYSDATE,
             id_site_cree = v_id_site_cree
	      	WHERE VENDOR_SITE_ID_REF = rec_site_acreer.VENDOR_SITE_ID_REF
     --   AND   ADDRESS_CODE       = rec_site_acreer.ADDRESS_CODE
     --          UO_SITE_REF           = rec_site_acreer.UO_SITE_REF
     --     AND    VENDOR_SITE_CODE_REF  = rec_site_acreer.VENDOR_SITE_CODE_REF
     ;

     WRITELOG('v_id_site_cree : '||v_id_site_cree,0,0);


		UPDATE AP_SUPPLIER_SITES_ALL
		SET    VENDOR_SITE_CODE = rec_site_acreer.ADDRESS_CODE_REF 
		WHERE  VENDOR_SITE_ID = v_id_site_cree;



	  ELSE

        g_site_creer_ko := g_site_creer_ko + 1;
        DBMS_OUTPUT.PUT_LINE('g_site_creer_ko :'||g_site_creer_ko);
	      UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	      SET STATUT = 'CREATEKO',
		        LAST_UPDATED_BY = g_user,
			      LAST_UPDATE_DATE = SYSDATE
	  	  WHERE VENDOR_SITE_ID_REF = rec_site_acreer.VENDOR_SITE_ID_REF
        --AND   ADDRESS_CODE       = rec_site_acreer.ADDRESS_CODE_REF
        ;
        --Initialisation du tableau
		g_site_a_creer := g_site_a_creer + 1;
		
        g_tab_sites_creer(g_site_a_creer).NUM_LIGNE        := v_line_num;
	      g_tab_sites_creer(g_site_a_creer).NOM_FOURNISSEUR := rec_site_acreer.VENDOR_NAME;
        g_tab_sites_creer(g_site_a_creer).CODE_SITE       := rec_site_acreer.VENDOR_SITE_CODE_REF;
        g_tab_sites_creer(g_site_a_creer).UO_SITE         := rec_site_acreer.UO_SITE_REF;
        g_tab_sites_creer(g_site_a_creer).CODE_ADRESSE    := rec_site_acreer.ADDRESS_CODE_REF;

		FOR rec_erreur_creer IN (SELECT * FROM DKA_SAPFRSDUPLI_ERROR_TMP
		                         WHERE  ACTION_ID = v_id_liste_erreur) LOOP
		  g_tab_sites_creer(g_site_a_creer).LISTE_MSG   := rec_erreur_creer.error_message;
        END LOOP;
        pn_retcode := 1;
      END IF;

    COMMIT;
  END LOOP;

  v_phase := 'PHASE 4 : Modification des rattachements'  ;
  DBMS_OUTPUT.PUT_LINE(v_phase);
  writelog(v_phase,0,0);
    v_etape := 'RG-INIT9 : Déplacement des sites d''une adresse à une autre';
    FOR rec_donnee IN (SELECT *
	                     FROM DKA_SAPFRSDUPLI_INIT_TMP
                       WHERE STATUT = 'CREATEOK'
					             AND   ADDRESS_CODE != ADDRESS_CODE_REF) LOOP
      --g_site_a_attach := g_site_a_attach + 1;

    --  BEGIN
       /* SELECT 1
        INTO   v_modif_attach
        FROM   DKA_SAPFRSDUPLI_INIT_TMP
        WHERE  1=1
        AND    rec_donnee.VENDOR_SITE_CODE_REF IN (SELECT  VENDOR_SITE_CODE FROM DKA_SAPFRSDUPLI_INIT_TMP TMP1
                                                   WHERE   TMP1.ADDRESS_CODE = rec_donnee.ADDRESS_CODE)
        AND   ADDRESS_CODE = rec_donnee.ADDRESS_CODE                                           ;*/

       /* SELECT 1
        INTO v_modif_attach
        FROM DKA_SAPFRSDUPLI_INIT_TMP
        WHERE VENDOR_SITE_CODE= rec_donnee.VENDOR_SITE_CODE_REF
        AND  ADDRESS_CODE = rec_donnee.ADDRESS_CODE
        AND rownum<2;

      EXCEPTION
        WHEN TOO_MANY_ROWS THEN
          v_modif_attach:= 1;
        WHEN NO_DATA_FOUND THEN
          v_modif_attach :=  0;
      END ;
      DBMS_OUTPUT.PUT_LINE('v_modif_attach :'||v_modif_attach);*/

	  --IF v_modif_attach = 0 THEN
        BEGIN

	        SELECT
		       location_id
		     , party_site_id
	  	    INTO
		       v_location_id_ref
		     , v_party_site_id_ref
		      FROM   ap_supplier_sites_all
		      WHERE  vendor_site_id = rec_donnee.VENDOR_SITE_ID_REF;
	    EXCEPTION
	      WHEN TOO_MANY_ROWS THEN
          NULL;
	    END;


        BEGIN
          SELECT  count(*)
	        INTO   v_site_exist
          FROM
            ap_supplier_sites_all assa,
            ap_suppliers asp,
            hz_party_sites hps,
            hr_organization_units hou
          WHERE asp.vendor_id = assa.vendor_id
          AND assa.party_site_id = hps.party_site_id
          AND hou.organization_id = assa.org_id
          AND hou.name = rec_donnee.UO
	        AND hps.party_site_name = rec_donnee.ADDRESS_CODE_REF
          AND asp.vendor_name    =  rec_donnee.vendor_name;


        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            v_site_exist := 0;
        END;

        IF v_site_exist =0 THEN
	      BEGIN
          -- ARA Correctif INC0484215 - SPE006 Programme d'initialisation de la référence
          UPDATE  AP_INVOICES_ALL
             SET      party_site_id       = v_party_site_id_ref,
		              LAST_UPDATED_BY = g_user,
			            LAST_UPDATE_DATE = SYSDATE                  
           WHERE	vendor_site_id   = (SELECT vendor_site_id FROM ap_supplier_sites_all aps_all, ap_suppliers aps , HR_OPERATING_UNITS hr
                                        WHERE aps_all.vendor_id = aps.vendor_id 
                                        AND vendor_site_code = rec_donnee.VENDOR_SITE_CODE                                       
                                        AND aps.VENDOR_NAME = rec_donnee.VENDOR_NAME
                                        AND hr.organization_id = aps_all.org_id
                                        AND hr.name = rec_donnee.UO);
         
           
	        UPDATE  ap_supplier_sites_all
             SET  location_id         = v_location_id_ref,
                  party_site_id       = v_party_site_id_ref,
		              LAST_UPDATED_BY = g_user,
			            LAST_UPDATE_DATE = SYSDATE                  
           WHERE	vendor_site_code   = rec_donnee.VENDOR_SITE_CODE
           AND    org_id             = (SELECT organization_id from HR_OPERATING_UNITS where name= rec_donnee.UO)
           AND    vendor_id          = (SELECT vendor_id FROM ap_suppliers WHERE vendor_name = rec_donnee.VENDOR_NAME);

          UPDATE IBY_EXTERNAL_PAYEES_ALL
	        SET  party_site_id     = v_party_site_id_ref,
		           LAST_UPDATED_BY = g_user,
			         LAST_UPDATE_DATE = SYSDATE
	        WHERE supplier_site_id = (SELECT vendor_site_id 
                                    FROM ap_supplier_sites_all 
                                    WHERE vendor_site_code   = rec_donnee.VENDOR_SITE_CODE
                                    AND   org_id    = (SELECT organization_id from HR_OPERATING_UNITS where name= rec_donnee.UO)
                                    AND   vendor_id  = (SELECT vendor_id FROM ap_suppliers WHERE vendor_name = rec_donnee.VENDOR_NAME) );
									
			
			
			
			
          COMMIT;
          g_site_attach_ok := g_site_attach_ok + 1;

          DBMS_OUTPUT.PUT_LINE('ATTACHOK');
	    	  UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	        SET STATUT = 'ATTACHOK',
		          LAST_UPDATED_BY = g_user,
			        LAST_UPDATE_DATE = SYSDATE
	        WHERE VENDOR_SITE_ID_REF = rec_donnee.VENDOR_SITE_ID_REF
          AND   ADDRESS_CODE       = rec_donnee.ADDRESS_CODE
          AND   VENDOR_SITE_CODE   = rec_donnee.VENDOR_SITE_CODE
          AND   UO                 = rec_donnee.UO
          AND   VENDOR_NAME        = rec_donnee.VENDOR_NAME;

        EXCEPTION
	      WHEN OTHERS THEN
		    g_site_attach_ko := g_site_attach_ko + 1;
             --Initialisation du tableau
			g_site_a_attach := g_site_a_attach + 1; 
            g_tab_sites_attach(g_site_a_attach).NUM_LIGNE       := rec_donnee.LIGNE_NUM;
	          g_tab_sites_attach(g_site_a_attach).NOM_FOURNISSEUR := rec_donnee.VENDOR_NAME;
            g_tab_sites_attach(g_site_a_attach).CODE_SITE       := rec_donnee.VENDOR_SITE_CODE_REF;
            g_tab_sites_attach(g_site_a_attach).UO_SITE         := rec_donnee.UO_SITE_REF;
            g_tab_sites_attach(g_site_a_attach).CODE_ADRESSE    := rec_donnee.ADDRESS_CODE;

            DBMS_OUTPUT.PUT_LINE('ATTACHKO');
	  	      UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	            SET STATUT = 'ATTACHKO',
			        LAST_UPDATED_BY = g_user,
		       		LAST_UPDATE_DATE = SYSDATE
	          WHERE VENDOR_SITE_ID_REF = rec_donnee.VENDOR_SITE_ID_REF
            AND   ADDRESS_CODE       = rec_donnee.ADDRESS_CODE
            AND   VENDOR_SITE_CODE   = rec_donnee.VENDOR_SITE_CODE
            AND   UO                 = rec_donnee.UO
            AND   VENDOR_NAME        = rec_donnee.VENDOR_NAME;
            g_tab_sites_attach(g_site_a_attach).LISTE_MSG   := SUBSTR(SQLERRM,1,500);
            pn_retcode := 1;
	    END;
        ELSE
           v_message := 'Le site '|| rec_donnee.vendor_site_code ||' de l''UO '|| rec_donnee.uo || ' n''a pas pu être déplacé sur l''adresse '||rec_donnee.ADDRESS_CODE_REF;
           g_site_attach_ko := g_site_attach_ko + 1;
             --Initialisation du tableau
			 g_site_a_attach := g_site_a_attach + 1;
			 
            g_tab_sites_attach(g_site_a_attach).NUM_LIGNE       := rec_donnee.LIGNE_NUM;
	          g_tab_sites_attach(g_site_a_attach).NOM_FOURNISSEUR := rec_donnee.VENDOR_NAME;
            g_tab_sites_attach(g_site_a_attach).CODE_SITE       := rec_donnee.VENDOR_SITE_CODE_REF;
            g_tab_sites_attach(g_site_a_attach).UO_SITE         := rec_donnee.UO_SITE_REF;
            g_tab_sites_attach(g_site_a_attach).CODE_ADRESSE    := rec_donnee.ADDRESS_CODE;

            DBMS_OUTPUT.PUT_LINE('ATTACHKO');
	  	      UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	           SET STATUT = 'ATTACHKO',
     	       		 LAST_UPDATED_BY = g_user,
			         	 LAST_UPDATE_DATE = SYSDATE
	          WHERE VENDOR_SITE_ID_REF = rec_donnee.VENDOR_SITE_ID_REF
            AND   ADDRESS_CODE       = rec_donnee.ADDRESS_CODE
            AND   VENDOR_SITE_CODE   = rec_donnee.VENDOR_SITE_CODE
            AND   UO                 = rec_donnee.UO
            AND   VENDOR_NAME        = rec_donnee.VENDOR_NAME;
            g_tab_sites_attach(g_site_a_attach).LISTE_MSG   := v_message;
            pn_retcode := 1;
        END IF;

	/*	v_etape := 'RG-INIT12 : Désactivation des adresses orphelines';
        DBMS_OUTPUT.PUT_LINE(v_etape);
		--désactivation de rec_donnee.ADDRESS_CODE
		UPDATE hz_party_sites
		SET END_DATE_ACTIVE = SYSDATE
		WHERE party_site_id = (SELECT hps.party_site_id
                                FROM
                                ap_supplier_sites_all assa,
                                hz_party_sites hps
                                WHERE  assa.party_site_id = hps.party_site_id
                                AND    hps.party_site_name = rec_donnee.ADDRESS_CODE);*/
	 -- END IF;
      COMMIT;
    END LOOP;
    v_etape := 'Initialisation d''environnement ';
    writelog(v_etape,0,0);
    BEGIN
            SELECT responsibility_id, application_id
            INTO v_resp_id, v_resp_appl_id
            FROM fnd_responsibility fr
            WHERE  fr.responsibility_key = 'TOUT_AP_ADMINISTRATEUR';

           v_user_id      := FND_PROFILE.VALUE('USER_ID');

              APPS.FND_GLOBAL.APPS_INITIALIZE(USER_ID      => v_user_id,
                                              RESP_ID      => v_resp_id,
                                              RESP_APPL_ID => v_resp_appl_id
                                              );

   EXCEPTION
            WHEN OTHERS THEN
                pn_retcode   := 2;
                v_resp_id   := NULL;
                v_resp_appl_id := NULL;
                --fnd_file.put_line(fnd_file.OUTPUT, 'Lancement de l''interface des commandes pour l''org_id : '||rec.org_id);
                writeout('. Problème de recupération de la responsabilité ');
                writelog('. Problème de recupération de la responsabilité ',0,0);
                pv_errbuf := '. Problème de recupération de la responsabilité';
            END;

    v_phase := 'PHASE 5 : Mise à jour globale des sites fournisseurs'  ;
    v_etape := 'Mise à jour globale des sites fournisseurs';
    DBMS_OUTPUT.PUT_LINE(v_phase);
    writelog(v_phase,0,0);
    FOR rec_site_maj IN C_SITE_AMAJ LOOP
	 -- g_site_a_maj := g_site_a_maj + 1;


      --Identification de la ligne niveau MAJ :
    /*SELECT LIGNE_NUM
    INTO   v_line_num
    FROM DKA_SAPFRSDUPLI_INIT_TMP
    WHERE 1=1
    AND   VENDOR_NAME  = rec_site_maj.VENDOR_NAME
    AND   ADDRESS_CODE = rec_site_maj.ADDRESS_CODE_REF
    AND   UO_SITE_REF  = rec_site_maj.UO_SITE_REF
    AND   VENDOR_SITE_ID_REF   = rec_site_maj.VENDOR_SITE_ID_REF
    AND   VENDOR_SITE_CODE_REF = rec_site_maj.VENDOR_SITE_CODE_REF
    AND   ROWNUM = 1;*/

    writelog('juste avant MAJ a partir site ref id '||rec_site_maj.id_site_cree,0,0);
    DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR ( rec_site_maj.id_site_cree, --rec_site_maj.VENDOR_SITE_ID_REF    ,
                			                         v_result_maj                         ,
                			                         v_nbr_maj_succes                     ,
                			                         v_nbr_maj_echec                      ,
                                               v_maj_code_echec                     ,
                			                         v_id_liste_erreur
                                                 );

writelog('v_maj_code_echec : '||v_maj_code_echec,0,0);
writelog('v_nbr_maj_succes : '||v_nbr_maj_succes,0,0);

        IF v_nbr_maj_echec = 0 THEN
	    	  UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	          SET STATUT = 'COMPLETE',
		            LAST_UPDATED_BY = g_user,
			          LAST_UPDATE_DATE = SYSDATE
	      WHERE id_site_cree   = rec_site_maj.id_site_cree
		  AND STATUT IN ('ATTACHOK', 'CREATEOK') ;
		ELSE
		  UPDATE DKA_SAPFRSDUPLI_INIT_TMP
	      SET STATUT = 'UPDATEKO',
		        LAST_UPDATED_BY = g_user,
            LAST_UPDATE_DATE = SYSDATE
	      WHERE id_site_cree   = rec_site_maj.id_site_cree;
          --Initialisation du tableau
		  FOR rec_erreur_maj IN (SELECT * FROM DKA_SAPFRSDUPLI_ERROR_TMP
		                         WHERE  ACTION_ID = v_id_liste_erreur) LOOP
             g_site_a_maj := g_site_a_maj + 1;                    
        --  g_tab_sites_maj(g_site_a_maj).NUM_LIGNE       := v_line_num;
	      g_tab_sites_maj(g_site_a_maj).NOM_FOURNISSEUR := rec_site_maj.VENDOR_NAME;
          g_tab_sites_maj(g_site_a_maj).CODE_ADRESSE    := rec_site_maj.ADDRESS_CODE_REF;
		  BEGIN
		    SELECT ass.vendor_site_code,hou.name
			INTO    v_VENDOR_SITE_CODE_DUP,v_UO_SITE_DUP  
            FROM   ap_supplier_sites_all ass              
                   ,hr_operating_units hou 
            WHERE vendor_site_id= rec_erreur_maj.VENDOR_SITE_ID_REF
            AND hou.organization_id = ass.org_id; 
		  EXCEPTION WHEN OTHERS THEN
		    v_VENDOR_SITE_CODE_DUP:= null;
			v_UO_SITE_DUP := null;	
		  END ;
          g_tab_sites_maj(g_site_a_maj).CODE_SITE       := v_VENDOR_SITE_CODE_DUP;
          g_tab_sites_maj(g_site_a_maj).UO_SITE         := v_UO_SITE_DUP;		  
		  g_tab_sites_maj(g_site_a_maj).LISTE_MSG       := rec_erreur_maj.error_message;

          END LOOP;
          pn_retcode := 1;
		END IF;

        IF v_maj_code_echec != 0 THEN
                  --Initialisation du tableau
		  FOR rec_erreur_maj IN (SELECT * FROM DKA_SAPFRSDUPLI_ERROR_TMP
		                         WHERE  ACTION_ID = v_id_liste_erreur) LOOP	
            g_site_a_maj := g_site_a_maj + 1;                     
          --g_tab_sites_maj(g_site_a_maj).NUM_LIGNE       := v_line_num;
	      g_tab_sites_maj(g_site_a_maj).NOM_FOURNISSEUR := rec_site_maj.VENDOR_NAME;
          g_tab_sites_maj(g_site_a_maj).CODE_ADRESSE    := rec_site_maj.ADDRESS_CODE_REF;
		  BEGIN
		    SELECT ass.vendor_site_code,hou.name
			INTO    v_VENDOR_SITE_CODE_DUP,v_UO_SITE_DUP  
            FROM   ap_supplier_sites_all ass              
                   ,hr_operating_units hou 
            WHERE vendor_site_id= rec_erreur_maj.VENDOR_SITE_ID_REF
            AND hou.organization_id = ass.org_id; 
		  EXCEPTION WHEN OTHERS THEN
		    v_VENDOR_SITE_CODE_DUP:= null;
			v_UO_SITE_DUP := null;
		  END ;
          g_tab_sites_maj(g_site_a_maj).CODE_SITE       := v_VENDOR_SITE_CODE_DUP;
          g_tab_sites_maj(g_site_a_maj).UO_SITE         := v_UO_SITE_DUP;		  
		  g_tab_sites_maj(g_site_a_maj).LISTE_MSG       := rec_erreur_maj.error_message;

          END LOOP;
          pn_retcode := 1;

        END IF;

        g_site_maj_ok := g_site_maj_ok + v_nbr_maj_succes;
        g_site_maj_ko := g_site_maj_ko + v_nbr_maj_echec;
        writelog('g_site_maj_ok : '||g_site_maj_ok,0,0);

	END LOOP;
	v_phase := 'PHASE 6 : Désactivation des adresses orphelines'  ;
    v_etape := 'Désactivation des adresses orphelines';
    writelog(v_phase,0,0);

    FOR rec_adresse_orphelines IN ( select * from hz_party_sites hz
                                    where application_id = 200
                                    and not exists (select 'x' from ap_supplier_sites_all ap
                                                    where ap.party_site_id = hz.party_site_id
                                                    and ap.location_id = hz.location_id)
                                    and status = 'A') LOOP
                                                    
		g_adr_a_desactivee := g_adr_a_desactivee + 1;
        
	    UPDATE hz_party_sites
        SET	status = 'I',
            LAST_UPDATED_BY = g_user,
            LAST_UPDATE_DATE = SYSDATE         
  		WHERE party_site_id = rec_adresse_orphelines.party_site_id;
	END LOOP;


    sortie_traitement;

    writelog('pn_retcode :'||pn_retcode,0,0);
  	IF pn_retcode = 2
		THEN
         pv_errbuf := 'ATTENTION : Erreur bloquante : '||pv_errbuf;
	  ELSIF  (pn_retcode = 1 OR g_tab_sites_valide.count > 0 OR g_tab_sites_creer.count > 0 OR g_tab_sites_attach.count > 0 OR g_tab_sites_maj.count > 0)
		THEN
         pv_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         pn_retcode := 1;
  	ELSE
         pv_errbuf := 'Fin normale du traitement - Aucun rejet.';
         pn_retcode := 0;
	  END IF;

    writeout(pv_errbuf);
    fin_de_sortie;


  END MAIN;

END DKA_SAPFRSDUPLI_INIT_PKG;

/
SHOW ERRORS
EXIT