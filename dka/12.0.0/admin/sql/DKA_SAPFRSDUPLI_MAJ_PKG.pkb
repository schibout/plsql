create or replace PACKAGE BODY DKA_SAPFRSDUPLI_MAJ_PKG IS
--------------------------------------------------------------------------------
-- $Id: DKA_SAPFRSDUPLI_MAJ_PKG.pkb  $
-- Capgemini
-- Projet           :
-- Nom              : DKA_SAPFRSDUPLI_MAJ_PKG.pks
-- Description      : Corps du package DKA_SAPFRSDUPLI_MAJ_PKG
-- Auteur           : Asma AMENKOUR
-- Date de création : 08/07/2020
-- Commentaires     :
---- modification 
---- SHA :INC0617119 / Correctif : Mise à jour d'une règle de gestion sysdate dans le programme "DKA : Mise à jour quotidienne des sites fournisseurs dupliqués"
---- IBA KDFI-652 Désynchronisation référentiel fournisseur
--------------------------------------------------------------------------------
  g_package                 VARCHAR2(30)  := 'DKA_SAPFRSDUPLI_MAJ_PKG';
  --g_nom_traitement          VARCHAR2(200) := 'DKA : Mise à jour quotidienne des sites fournisseurs dupliqués';
  g_sqlerrm                 VARCHAR2(500) := NULL;
  g_retproc                 NUMBER        := 0;
  g_nom_traitement          FND_CONCURRENT_PROGRAMS_VL.USER_CONCURRENT_PROGRAM_NAME%TYPE;
  g_code_traitement         FND_CONCURRENT_PROGRAMS_VL.CONCURRENT_PROGRAM_NAME%TYPE;
  g_request_id              NUMBER := fnd_global.CONC_REQUEST_ID;
  g_user                    NUMBER        := fnd_profile.value('USER_ID');
  g_nbr_site                NUMBER := 0;
  g_site_maj_ok             NUMBER := 0;
  g_site_maj_ko             NUMBER := 0;
  g_site_a_maj              NUMBER := 0;
  g_tab_sites_maj           t_sites_maj;

  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Asma AMENKOUR
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
    l_message := '. Nombre de sites de la référence sélectionnés pour la mise à jour : ' ||g_nbr_site;
    writeout(l_message);             
	  l_message := '. Nombre de sites dupliqués mis à jour avec succès : ' ||g_site_maj_ok;
    writeout(l_message);
	  l_message := '. Nombre de sites dupliqués pour lesquels la mise à jour a échoué : ' ||g_site_maj_ko;
    writeout(l_message);
	  

    writeout('');
    writeout('');

	IF g_tab_sites_maj.count > 0 THEN
      l_message := 'LISTE DES ERREURS EN MISE A JOUR :';
      writeout(l_message);
      writeout('---------------------------------------------');
      writeout(RPAD('Nom du fournisseur',35)||RPAD('Code site',25)||RPAD('UO Maj',25)||RPAD('Message erreur',500));
      writeout(RPAD('------------------',35)||RPAD('---------',25)||RPAD('------',25)||RPAD('--------------',500));

	  FOR i IN g_tab_sites_maj.first..g_tab_sites_maj.last LOOP
        l_message := RPAD(g_tab_sites_maj(i).NOM_FOURNISSEUR,35)||RPAD(g_tab_sites_maj(i).CODE_SITE,25)||RPAD(g_tab_sites_maj(i).UO_SITE,25)||RPAD(g_tab_sites_maj(i).LISTE_MSG,500);
        writeout(l_message);
	  END LOOP;
    END IF;

	writeout('');
  writeout('');

null;

END sortie_traitement;
   /*============================================================================*/
  /* Fonction          : entete_de_sortie                                      */
  /* Description       : entete de la sortie                 */
  /*                                                                            */
  /* Parametres entree : nom de fichier                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE entete_de_sortie IS

  l_procedure                  VARCHAR2(30) := 'entete_de_sortie';
  l_message                    VARCHAR2(2000);

  BEGIN
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout('COMPTE-RENDU DU TRAITEMENT « DKA : Mise à jour quotidienne des sites fournisseurs dupliqués »');
    writeout('Traitement n° : '||g_request_id);
    writeout('Programme lancé le : '||to_char(sysdate,'DD/MM/YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
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

  /*============================================================================*/
  /* Fonction          : MAJ_DATE_LANCEMENT                                      */
  /* Description       : Mise à jour de la date dans DKA_PARAMETERS                */
  /*                                                                            */
  /* Parametres entree : AUCUN                                                  */
  /* Parametres sortie : AUCUN                                                  */
  /*============================================================================*/
  PROCEDURE MAJ_DATE_LANCEMENT IS

  l_procedure                   VARCHAR2(30) := 'MAJ_DATE_LANCEMENT';
  l_message                    VARCHAR2(2000);

  BEGIN
    UPDATE DKA_PARAMETERS
	SET    date_value = --SYSDATE
	(select requested_start_date from fnd_concurrent_requests  where request_id   = g_request_id )-- SHA -INC0617119
    WHERE  program_code  = 'DKA_SAPFRSDUPLI_MAJ'
    AND   parameter_name = 'DATE_DERNIERE_MAJ';    
  END;
  /*======================================================================================================*/
  --  Nom           : main
  --  Description   : procédure principale du traitement qui enchaînera l'ensemble
  --                  des autres procèdures.
  --  PARAMETRES    : pv_errbuf           Entrée/Sortie    message d'erreur
  --                  pn_retcode          Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
  --  DATE          : 08/07/2020
/*=========================================================================================================*/
PROCEDURE MAIN(pv_errbuf  IN OUT VARCHAR2,
               pn_retcode OUT NUMBER) IS


CURSOR SITE_A_MAJ (p_date_maj DATE)  IS 
  SELECT  DISTINCT assa.vendor_site_id
  ,       assa.vendor_site_code
  ,       ass.vendor_name
/*  ,       assa.last_update_date
  ,       ieb.ext_bank_account_id
  ,       ieb.iban
  ,       IEB.BANK_ACCOUNT_NAME
  ,       IPI.end_date --end_date_relle
  ,       IPI.ORDER_OF_PREFERENCE
  ,       ipi.LAST_UPDATE_DATE*/
  FROM    ap_supplier_sites_all assa 
  ,       ap_suppliers ass
  ,       hr_operating_units hou 
  ,       iby_ext_bank_accounts ieb
  ,       iby_pmt_instr_uses_all ipi
  ,       iby_external_payees_all iep
  ,       iby_ext_party_pmt_mthds   ieppm  ---IBA KDFI-652
  WHERE   assa.vendor_id = ass.vendor_id
  AND     hou.organization_id = assa.org_id
  AND     hou.name = 'REF9999' 
  AND     iep.ext_payee_id = ieppm.ext_pmt_party_id ---IBA KDFI-652
  AND     iep.supplier_site_id(+) = assa.vendor_site_id
  AND     iep.ext_payee_id = ipi.ext_pmt_party_id(+)
  AND     ipi.instrument_id = ieb.ext_bank_account_id(+)
  AND     ipi.payment_function(+) = 'PAYABLES_DISB'
  AND    ( ieppm.last_update_date > p_date_maj or ---IBA KDFI-652
  assa.last_update_date > p_date_maj OR ipi.LAST_UPDATE_DATE > p_date_maj OR iep.LAST_UPDATE_DATE > p_date_maj);

  v_etape               VARCHAR2(100);
  l_message             VARCHAR2(500);
  v_result_maj           VARCHAR2(2);
  v_id_liste_erreur      NUMBER;
  v_nbr_maj_succes       NUMBER;
  v_nbr_maj_echec        NUMBER;
  v_maj_code_echec       NUMBER;
  v_date_maj             DATE;
  V_UO_SITE_DUP         hr_operating_units.name%TYPE; 
  v_user_id              NUMBER;
  v_resp_id              NUMBER;
  v_resp_appl_id         NUMBER;
  
BEGIN
  entete_de_sortie;
  v_etape  := 'Determination de paramètre date de dernière mise à jour';
  BEGIN
    SELECT date_value
    INTO   v_date_maj
    FROM   DKA_PARAMETERS
    WHERE  program_code = 'DKA_SAPFRSDUPLI_MAJ'
    AND   parameter_name = 'DATE_DERNIERE_MAJ';
  EXCEPTION
    WHEN OTHERS THEN
      l_message := 'erreur lors de la récupération de paramètre de dernière mise à jour';
      pn_retcode := 2;
    
  END;
  v_etape := 'Initialisation d''environnement ';
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
     -- writeout('. Problème de recupération de la responsabilité ');
      pv_errbuf := '. Problème de recupération de la responsabilité';
  END;
  ----
  FOR rec_site_a_maj IN SITE_A_MAJ (v_date_maj) LOOP
    g_nbr_site := g_nbr_site + 1;
    DKA_SAPFRSDUPLI_PKG.MAJ_SITE_FOURNISSEUR ( rec_site_a_maj.vendor_site_id        ,
                			                         v_result_maj                         ,
                			                         v_nbr_maj_succes                     ,
                			                         v_nbr_maj_echec                      ,
                                               v_maj_code_echec                     ,
                			                         v_id_liste_erreur
                                                 );
    IF v_nbr_maj_echec != 0 THEN
      FOR rec_erreur_maj IN (SELECT * FROM DKA_SAPFRSDUPLI_ERROR_TMP
	  	                         WHERE  ACTION_ID = v_id_liste_erreur) LOOP
      g_site_a_maj := g_site_a_maj + 1;                    
      g_tab_sites_maj(g_site_a_maj).NOM_FOURNISSEUR := rec_site_a_maj.VENDOR_NAME;
      g_tab_sites_maj(g_site_a_maj).CODE_SITE       := rec_site_a_maj.vendor_site_code;
      BEGIN
        SELECT hou.name
	  		INTO   V_UO_SITE_DUP  
        FROM   ap_supplier_sites_all ass              
        ,      hr_operating_units hou 
        WHERE vendor_site_id      = rec_erreur_maj.VENDOR_SITE_ID_REF
        AND   hou.organization_id = ass.org_id; 
      EXCEPTION WHEN OTHERS THEN
	  		V_UO_SITE_DUP := null;	
      END ;
      g_tab_sites_maj(g_site_a_maj).UO_SITE         := V_UO_SITE_DUP;
      g_tab_sites_maj(g_site_a_maj).LISTE_MSG       := rec_erreur_maj.error_message;
    
      END LOOP;
    END IF;
    g_site_maj_ok := g_site_maj_ok + v_nbr_maj_succes;
    g_site_maj_ko := g_site_maj_ko + v_nbr_maj_echec;
   
  END LOOP;
    MAJ_DATE_LANCEMENT;
    sortie_traitement;

  	IF pn_retcode = 2
		THEN
         pv_errbuf := 'ATTENTION : Erreur bloquante : '||pv_errbuf;
	  ELSIF  (pn_retcode = 1 OR  g_tab_sites_maj.count > 0)
		THEN
         pv_errbuf := 'ATTENTION : Il y a des cas de rejet ou avertissement.';
         pn_retcode := 1;
  	ELSE
         pv_errbuf := 'Fin normale du traitement - Aucun rejet.';
         pn_retcode := 0;
	  END IF;

    writeout(pv_errbuf);
    fin_de_sortie;
END ;

END DKA_SAPFRSDUPLI_MAJ_PKG;



/
SHOW ERRORS
EXIT