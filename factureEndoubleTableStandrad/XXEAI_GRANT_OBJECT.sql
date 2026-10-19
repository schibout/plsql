CREATE OR REPLACE PACKAGE BODY APPS.Dka_Sapautorgt_Pkg AS
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- $Id: DKA_SAPAUTORGT_PKG.pkb 2080 2009-08-20 09:26:56Z CORP\mslama $
-- PROJET            : DALKIA Oracle Applications
-- NOM         : DKA_SAPAUTORGT_PKG.pkb
-- DESCRIPTION       : Automatisation de lancement du jeu de lots de règlements
--             multi organisations
--             par type de réglements (chèque , billet à ordre , virement)
---
--- AUTEUR       : Evelyne SIMON (CGEY)
--- DATE DE CREATION : 12/07/2002
--- DOC. ASSOCIEE    : N/A
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 09/09/2002 EVS Ajout de l'org_name dans la table DKA_SAPAUTORGT_2_TMP, table qui collecte les lots lancés
---                avec leur no de boucle de traitement.
---                Dans l'exception OTHERS, réduction à l'org_id pour découvrir si le titre de paiement existe
--- 12/09/2002 EVS Refonte de la requête de sélection de jeux de lots
---                Utilisation de la table ap_payment_schedules_all pour récupérer le mode de règlement au lieu
---                de la facture.
---                Elimination des paiements par virement sur compte fournisseur non renseigné
--- 13/09/2002 EVS Ajout d'une EXCEPTION OTHERS dans le SELECT 1 into vn_dummy,
---                Ajout de vn_not_requested_batches en fin de traitement
--- 27/03/2003 EMA Ajout de la recherche de l'imprimante du centre de gestion pour impression de l'état
---                'Registre des règlements effectués' sur cette imprimante.
--- 08/04/2003 EMA Ajout de la réédition des états sur l'imprimante PARIS.
---                Recherche de l'imprimante dans la table de transco, puis dans l'option de profile
--- 13/05/2003 EMA Ajout de la valeur Vn_Days_Between à Sysdate pour le calcul de vd_pay_thru_date.
--- 09/10/2003 ADR MAIN-INSERT_SUBMIT_RECORDS-VALIDATE : Modifications des procédures pour lancer le traitement
---                standard d'annulation des jeux de lots de réglements dont le montant et le type de titre
---                négotiable est à zéro. Ajout de TRUNC devant la variable p_payment_date dans certaines clause where.
--- 29/10/2003 ADR Suppression du bloquage des lots après annulation.
--- 19/12/2003 ADR MAIN : Modification du calcul de Vn_Days_Between. Paramétrage de le valeur en fonction du type de
---                de campagne dans la table dka_parameters (TIERS-GROUPE-EMPLOYE).
--- 21/04/2004 ADR MAIN : Suppression des réimpressions des registres en fin de traitement.
--- 27/07/2004 SFE Migration projet PHENIX 2004 - Impacts sur main
--- 11/10/2006 SRO Prise en compte les lignes d'échéance partiellement réglées lors de la constitution des lots de réglements
--- 17/04/2006 SRO Prise en compte les lignes d'échéance uniquement de type acompte lors de la constitution des lots de réglements
--- 29/10/2007 ADR ETANCHEITE DALKIA 2007
--- 02/07/2008 JJA Ajout de la gestion de la campagne de reglement express
--- 14/11/2008 TBO Gestion de la date de compensation (artf431339)
--- 11/06/2009 GV  truncate des tables de travail
--- 28/04/2009 MSL Modification de la gestion des responsabilités et des imprimantes
--- 11/06/2009 PCA Modification des responsabilités lancées et ajout de la gestion de l'ORG_ID
--- 31/07/2009 MSL Artf495135 : Campagne de règlements VT
--- 19/08/2009 MSL Artf508452 : Campagne de règlements -> Anomalie lors de recette client
--- 19/08/2009 EMA Modification suivant EID20090221
---                Ajout de la sauvegarde des tables de travail.
---                Dans le cas des campagnes Express
---                => Si le traitement passe entre J 19h00 et 00h00, la date de compensation est égale à J+1
---                => Si le traitement passe après 00h00, la date de compensation est égale à J
---                => Après détermination de cette date de compensation, si le jour n'est pas un jour ouvré,
---                   il faut rechercher le jour ouvré suivant.
---                Suppression des tables de sauvegarde de plus de 30 jours.
--- 04/11/2009 EMA EARS00008874735 : Les états ne sortent pas sur la bonne imprimante
---                Anomalie dûe au fait que la variable vv_region n'est pas renseignée au bon endroit
--- 29/03/2010 GV  main : la date de compensation est augmentée d'un jour pour les paiements Express---
--  24/06/2010 FMI EIS20100069 : Les etats concernés par la campagne de reglement TIERS EXPR sont mis a disposition sur l'imprimante
--                de la tresorerie s'il n'ont pas déja été imprimés sur cette imprimante.
--  28/03/2012 JJA ajout restriction sur IMPRIMANTE_CSP_REGISTRE (enable=Y)
--  19/07/2012 JJA Ajout du fichier APIMPORT (archivage des tables) et modification du calcul de date de compensation
--  29/11/2012 JJA Correction du calcul de date de compensation
--  08/10/2013 JJA INC000000459477 - Correction entre 0h et 19h
--  01/09/2016 RBE Migration R12
--  02/02/2017 RBE artf2090995
--  13/02/2017 EFL -> artf2097897: La campagne de reglement soumet un nombre de traitements qui peut varier suivant la configuration
--                 de celle-ci. En outre, les traitements qui soumettent des traitements enfants n'attendent pas forcement
--                 la fin des process fils soumis. L'api standard Fnd_Concurrent.wait_for_request ne peut pas etre utilisee.
--                 Solution: procedure wait_program_end
--                 1) Ctr par requete que l'ensemble des traitements soumis par le PPR sont termines + boucle
--                 2) Balayer les traitements soumis pour ctrle de l'etat de sortie (Ok, warning, erreur) des traitements soumis
--                 en utilisaant l'api standard Fnd_Concurrent.wait_for_request
--                 -> Optimisation: Soumission des traitements en parallele sans attendre la fin des traitements soumis
--                        -- Variables g_request_id_Tab,....
--                        -- Modification des programmes launch_program_payment et launch_program_recalculate (suppression du wait_for_request)
--                        -- Nouvelle procedure wait_program_end
--                        -- Modification de main et recalculate
--                -> Modification de la requete permettant de selectionner les organisations pour lequelles le traitement doit etre lance (curseur cur_jeu_lot)
--                -> Optimisation: Ne pas lancer des traitement de selection pour les orgs pour lesquelles pas de facture en rapport avec le modele de PPR 
--                   Pour cela:  
--                   - 1) Recherche suivant les criteres du curseur cur_jeu_lot
--                        Pour chaque organsaition, on recherche le modele associe. Erreur si pas trouve  
--                   - 2) Ajout des criteres (classe de reglement, priorite) sur modele de PPR a la requete du 1) 
--                   Modification du curseur cur_jeu_lot en sql dynamique pour ajouter les conditions du 1) au 2)
--                   Dans procedure main: Variables v_sql_1,....l_cursor et sql dynamique. 
--  02/02/2017 RBE artf2118984 : INT004_SPE069 : Campagne Paiement AP - Détermination de la date de paiement KO
--  23/06/2017 NBO artf2178593 : BeB - Campagne de Règlements Fournisseurs EMPLOYES - Créer des Règlements en Erreur Defect #794
--  15/12/2017 RBE artf2293446 : INT004 - Mouvements non sélectionnés par Campagnes Reglements
--  22/02/2018 NBO artf2394328 :  INC0193769 : Campagne de paiement AP
--  11/06/2018 NBO artf2691955 : INC0220863 : ALERTE Paiements AP Échéances Fin Mai 2018 TIERS
--  01/08/2018 OBE artf2812973 : INC0221917 - Campagne paiement AP
--  26/11/2020 NBO artf07423406 : INC0486886 - INT004 - Correctif sur campagne de règlement AP : Il s¿agit de modifier le spécifique pour qu¿il attende la fin des traitements standards pour se terminer.
--                 artf07423425 - INC0486848 - INT004 - Correctif sur campagne de règlement - Modèle AP : L'objectif du correctif est de vérifier si le modèle de paiement est actif à la date d¿exécution avant de le lancer.
--  30/04/2021 NBO artf07423405 : INC0486886 - INT004 - Correctif sur campagne de réglement AP
--  25/12/2023 ARA EDB295 Lot3 - Ajout d¿une nouvelle campagne de règlement / Remboursements client
--  04/12/2024 ARA EDB295 Lot1A
---------------------------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
                   gn_father_request_id         NUMBER;     /*ADR le 09/10/2003*/
                   g_tempo                      NUMBER  := 20;
                   TYPE g_request_id_Tab_type   IS TABLE OF Fnd_Concurrent_requests.request_id%TYPE INDEX BY BINARY_INTEGER;
                   g_request_id_Tab             g_request_id_Tab_type;
                   TYPE g_Org_Id_Tab_type       IS TABLE OF hr_all_organization_units.organization_id%TYPE INDEX BY BINARY_INTEGER;
                   g_Org_Id_Tab                 g_Org_Id_Tab_type;
                   TYPE g_Org_Name_Tab_type     IS TABLE OF hr_all_organization_units.name%TYPE INDEX BY BINARY_INTEGER;
                   g_Org_Name_Tab               g_Org_Name_Tab_type;

                   g_nbre_Requests              BINARY_INTEGER := 0;
                   
                   gn_default_delai             CONSTANT NUMBER := 3; --RBE artf2118984

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

/*=========================================================================*/
/* PROCEDURE NAME :   wait_program_end
/*
/* DESCRIPTION  Attente de la fin du traitement . MAJ du lot de reglement
/*              si le parametre p_update_table est TRUE.
/*
/*
/* PARAMETERS
/* ==========
/* NAME               DESCRIPTION
/* -----------------  ------------------------------------------------------
/*
/*
 /*=========================================================================*/
PROCEDURE wait_program_end
                        (p_errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER,
                         p_request_id        IN  NUMBER,
                         p_checkrun_id       OUT NUMBER,
                         p_checkrun_name     OUT VARCHAR2,
                         p_update_table      IN BOOLEAN DEFAULT FALSE )
    IS

        v_phase                  VARCHAR2 (100);
        v_status                 VARCHAR2 (100);
        v_dev_phase              VARCHAR2 (100);
        v_dev_status             VARCHAR2 (100);
        v_message                VARCHAR2 (100);

        -- Boolean. Ctrle qu'un traitement soumis est en cours d'exécution
        v_end boolean := FALSE;
        v_trash VARCHAR2(1);

        -- Liste des programmes soumis par le PPR
        CURSOR Cur_Request IS
        select Fcr.request_id, fcp.USER_CONCURRENT_PROGRAM_NAME
        from fnd_concurrent_requests Fcr, Fnd_Concurrent_Programs_Vl Fcp
        where Fcr.CONCURRENT_PROGRAM_ID = Fcp.CONCURRENT_PROGRAM_ID
        start with Fcr.request_id = p_request_id
        connect by prior Fcr.request_id = Fcr.PARENT_REQUEST_ID
        ORDER BY Fcr.request_id desc;

        v_errbuf varchar2(32000);
        v_retcode NUMBER;

    BEGIN
            -- Tant qu'il existe un traitement en cours dans le PPR
            WHILE ( NOT v_end )
            LOOP

               BEGIN
                  -- Recherche si un traitement soumis par le PPR est en cours
                  select 'x'
                  into v_trash
                  from fnd_concurrent_requests fcr
                  where fcr.request_id in ( select fcr.request_id
                           from fnd_concurrent_requests fcr
                           start with fcr.request_id = p_request_id
                           connect by prior fcr.request_id = fcr.PARENT_REQUEST_ID )
                  and fcr.phase_code <> 'C'
                  and rownum = 1;
                  -- Au moins un traitement est en cours. On attend avant la prochaine boucle
                  dbms_lock.sleep (g_tempo);
               EXCEPTION
               WHEN NO_DATA_FOUND THEN
                  -- Tous les traitements soumis par le PPR sont termines.
                  -- On peut sortir de la boucle et controler l'etat de sortie des traitements soumis.
                  v_end := TRUE;
               END;

            END LOOP; /* ( NOT v_end ) */

            -- Ctrle de l'etat de sortie des traitements soumis par le PPR.
            FOR Rec_Request IN Cur_Request
            LOOP

               IF NOT (Fnd_Concurrent.wait_for_request (Rec_Request.request_id, g_tempo, 0, v_phase, v_status, v_dev_phase, v_dev_status, v_message)) THEN
                    v_errbuf  := v_message;
                    v_retcode    := 2;
                    Fnd_File.put_line (Fnd_File.output, 'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' || CHR(10) ||
                                                        'MESSAGE : ' || v_message || CHR(10) );
               END IF;

               IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN

                   Fnd_File.put_line (Fnd_File.output, 'Request '||Rec_Request.request_id ||': COMPLETION= ' || v_dev_phase || '/' || v_dev_status);
                   Dka_Tools_Pkg.put_log_message( 'Request '||Rec_Request.request_id ||': Statut de fin : ' || v_phase || '/' || v_status);


               ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN

                  Fnd_File.put_line (Fnd_File.output, 'Traitement '||Rec_Request.request_id||'- Programme '||Rec_Request.USER_CONCURRENT_PROGRAM_NAME ||' en warning ');

                  IF NVL(p_retcode,0) < 1 -- Pas d'erreur plus grave que le niveau 1
                  THEN
                     v_errbuf  := 'Request '||Rec_Request.request_id||': Fin du traitement en warning ';
                     v_retcode    := 1;
                  END IF;

               ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN

                  IF NVL(p_retcode,0) < 2 -- Pas d'erreur plus grave de niveau 2
                  THEN
                      v_retcode := 2;
                      v_errbuf  := 'Request '||Rec_Request.request_id||': Fin du traitement en erreur ';
                   END IF;

                   Fnd_File.put_line (Fnd_File.output, 'Traitement '||Rec_Request.request_id||'- Programme '||Rec_Request.USER_CONCURRENT_PROGRAM_NAME ||' en erreur ');

                   Fnd_File.put_line (Fnd_File.output, 'ERREUR : Fin anormale du traitement '|| Rec_Request.request_id  || CHR(10) ||
                                              'Phase/Statut : ' || v_dev_phase || '/' || v_dev_status || CHR(10) ||
                                              'MESSAGE : ' || v_message || CHR(10) );
                   Dka_Tools_Pkg.put_log_message( '===> ERREUR : Fin anormale du traitement '||Rec_Request.request_id);
               END IF;

            END LOOP; /* Rec_Request IN Cur_Request */

            p_retcode := v_retcode;
            p_errbuf := v_errbuf;

            IF p_update_table
            THEN

               BEGIN
                  SELECT checkrun_id,checkrun_name
                  INTO   p_checkrun_id,p_checkrun_name
                  FROM AP_INV_SELECTION_CRITERIA_ALL
                  WHERE ( request_id = p_request_id
                      OR request_id IN (select request_id from FND_CONC_REQ_SUMMARY_V where parent_request_id = p_request_id)
                    )
                  AND ROWNUM = 1;

               EXCEPTION
               WHEN OTHERS THEN
                  p_checkrun_id   := NULL;
                 p_checkrun_name := NULL;
               END;

            END IF;


EXCEPTION
WHEN OTHERS THEN
  p_errbuf  := SQLCODE || ' -' || SQLERRM || ' ';
  p_retcode := 2;
  Dka_Tools_Pkg.put_log_message('launch_program_payment - Erreur... : '|| p_errbuf);

END wait_program_end;

/*=========================================================================*/
/* PROCEDURE NAME :   launch_program_payment
/*
/* DESCRIPTION  Lancement du Le Programme de demande de traitement des règlements
/*
/*
/* PARAMETERS
/* ==========
/* NAME               DESCRIPTION
/* -----------------  ------------------------------------------------------
/*
/*
 /*=========================================================================*/

PROCEDURE launch_program_payment(p_errbuf       OUT VARCHAR2,
                                 p_retcode      OUT NUMBER,
                                 p_template_id  IN NUMBER,
                                 p_org_id       IN hr_all_organization_units.organization_id%TYPE,
                                 p_org_name     IN hr_all_organization_units.NAME%TYPE,
                                 p_payment_date IN DATE) --RBE artf2118984
 IS

  v_request_id fnd_concurrent_requests.request_id%TYPE;
  vv_printer   fnd_printer.printer_name%TYPE;
  
  v_checkrun_id NUMBER;
  v_checkrun_name VARCHAR2(50);

  v_phase      VARCHAR2(100);
  v_status     VARCHAR2(100);
  v_dev_phase  VARCHAR2(100);
  v_dev_status VARCHAR2(100);
  v_message    VARCHAR2(100);
  l_pay_thru_days NUMBER;

BEGIN
  
  -- Choix de l'imprimante
  vv_printer   := Dka_Stransco_Pkg.etl_get_value_f('IMPRIMANTE_TRESORERIE', SYSDATE,substr(p_org_name,1,3), NULL, NULL);

  -- Choix de la langue
  EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';
  
  IF NOT fnd_request.set_print_options (printer => vv_printer, copies  => 1) THEN
   dka_tools_pkg.put_log_message('L''imprimante '||vv_printer||' n''a pas été trouvée pour la responsabilité : ' || fnd_profile.value ('RESP_NAME'));
  ELSE
   dka_tools_pkg.put_log_message('L''imprimante '||vv_printer||' a été défini sur le traitement');
  END IF;  
  
  BEGIN
    select addl_pay_thru_days into l_pay_thru_days from ap_payment_templates where template_id = p_template_id;
  EXCEPTION
    WHEN OTHERS THEN
      l_pay_thru_days := 0;
  END;
  
  v_request_id := fnd_request.submit_request(application => 'SQLAP',
                                             program     => 'APXPBASL',
                                             description => NULL,
                                             start_time  => NULL,
                                             sub_request => FALSE,
                                             argument1   => NULL,
                                             argument2   => p_template_id,
                                             argument3   => to_char(trunc(p_payment_date),
                                                                    'YYYY/MM/DD HH24:MI:SS') --2016/06/22 00:00:00--fnd_date.canonical_to_date(sysdate) --RBE artf2118984
                                            ,
                                            --  22/02/2018 NBO artf2394328 :  INC0193769 : Campagne de paiement AP
                                            -- argument4   => to_char(trunc(p_payment_date),
                                            --                        'YYYY/MM/DD HH24:MI:SS') --fnd_date.canonical_to_date(sysdate+30)                   --rBE artf2118984
                                            argument4 => to_char(trunc(sysdate)+l_pay_thru_days, 'YYYY/MM/DD HH24:MI:SS')
                                            ,
                                             argument5   => NULL);
    
  IF v_request_id = 0 THEN
  
    p_retcode := 2;
    fnd_file.put_line(fnd_file.output,
                      'ERREUR : Le Programme de demande de traitement des règlements' ||
                      chr(10) ||
                      'PROGRAMME  : Le Programme de demande de traitement des règlements');
    dka_tools_pkg.put_log_message('====> ERREUR : Le Programme de demande de traitement des règlements ');
    p_errbuf := ' ERREUR : Le Programme de demande de traitement des règlements ';
  ELSE
    /* g_request_id = 0 */
  
    COMMIT;
  
    fnd_file.put_line(fnd_file.output,
                      'Numéro du Programme de demande de traitement des règlements: ' ||
                      v_request_id);
    dka_tools_pkg.put_log_message('Numéro du Programme de demande de traitement des règlements: ' ||
                                  v_request_id);
    g_nbre_requests := g_nbre_requests + 1;
    g_request_id_tab(g_nbre_requests) := v_request_id;
    g_org_id_tab(g_nbre_requests) := p_org_id;
    g_org_name_tab(g_nbre_requests) := p_org_name;

    --  23/06/2017 NBO artf2178593 : BeB - Campagne de Règlements Fournisseurs EMPLOYES - Créer des Règlements en Erreur Defect #794
    --********************************************
    -- Wait for the concurrent program to complete
    --********************************************
    IF NOT (fnd_concurrent.wait_for_request(v_request_id,
                                            g_tempo,
                                            0,
                                            v_phase,
                                            v_status,
                                            v_dev_phase,
                                            v_dev_status,
                                            v_message)) THEN
    
      p_errbuf  := v_message;
      p_retcode := 2;
      fnd_file.put_line(fnd_file.output,
                        'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                        chr(10) || 'MESSAGE : ' || v_message || chr(10));
    END IF;
  
    IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
    
      fnd_file.put_line(fnd_file.output,
                        'COMPLETION= ' || v_dev_phase || '/' ||
                        v_dev_status);
      fnd_file.put_line(fnd_file.log,
                        'Statut de fin : ' || v_phase || '/' || v_status);
    
    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
    
      fnd_file.put_line(fnd_file.output,
                        'Programme de demande de traitement des règlements en warning ' ||
                        v_request_id);
      v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
      p_retcode := 1;
    
    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
    
      p_retcode := 2;
      v_message := 'ERREUR : Programme de demande de traitement des règlements : ' ||
                   v_message;
    
      fnd_file.put_line(fnd_file.output,
                        'ERREUR : Fin anormale du traitement ' ||
                        v_request_id || chr(10) || 'Phase/Statut : ' ||
                        v_dev_phase || '/' || v_dev_status || chr(10) ||
                        'MESSAGE : ' || v_message || chr(10));
      fnd_file.put_line(fnd_file.log,
                        '===> ERREUR : Fin anormale du traitement ' ||
                        v_request_id);
    END IF;
    p_errbuf := v_message;
  
    BEGIN
      SELECT checkrun_id, checkrun_name
        INTO v_checkrun_id, v_checkrun_name
        FROM ap_inv_selection_criteria_all
       WHERE (request_id = v_request_id OR
             request_id IN
             (SELECT request_id
                 FROM fnd_conc_req_summary_v
                WHERE parent_request_id = v_request_id))
         AND rownum = 1;
    
    EXCEPTION
      WHEN OTHERS THEN
        v_checkrun_id   := NULL;
        v_checkrun_name := NULL;
    END;
  
    --Inserer la demande de reglement cree.
    IF v_checkrun_id IS NOT NULL THEN
      BEGIN
        INSERT INTO dka_sapautorgt_tmp
          (org_id, org_name, checkrun_id, checkrun_name, status_flag)
        VALUES
          (p_org_id,
           p_org_name,
           v_checkrun_id,
           v_checkrun_name,
           'P');
      EXCEPTION
        WHEN OTHERS THEN
          --Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP '|| v_checkrun_name);
          fnd_file.put_line(fnd_file.output,
                            '==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP ' ||
                            v_checkrun_name);
          dka_tools_pkg.put_log_message('==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP ' ||
                                        v_checkrun_name);
          p_retcode := 2;
      END;
    END IF;
  
  END IF; /*  g_request_id = 0 */
  
EXCEPTION
  WHEN OTHERS THEN
    p_errbuf  := SQLCODE || ' -' || SQLERRM || ' ';
    p_retcode := 2;
    dka_tools_pkg.put_log_message('launch_program_payment - Erreur... : ' ||
                                  p_errbuf);
  
END launch_program_payment;

/*=========================================================================*/
/* PROCEDURE NAME :   launch_program_recalculate
/*
/* DESCRIPTION  Lancement du programme Demande de traitement pour recalculer les règlements
/*
/*
/* PARAMETERS
/* ==========
/* NAME               DESCRIPTION
/* -----------------  ------------------------------------------------------
/*
/*
 /*=========================================================================*/

PROCEDURE launch_program_recalculate
                        (p_errbuf            OUT VARCHAR2,
                         p_retcode           OUT NUMBER,
                         p_checkrun_id       IN  VARCHAR2,
                         p_region            IN  VARCHAR2
                         )
    IS

        v_request_id Fnd_Concurrent_Requests.request_Id%TYPE;
        
        v_phase      VARCHAR2(100);
        v_status     VARCHAR2(100);
        v_dev_phase  VARCHAR2(100);
        v_dev_status VARCHAR2(100);
        v_message    VARCHAR2(100);
        
        vv_printer   fnd_printer.printer_name%TYPE;
        
        CURSOR cur_request(p_request_id NUMBER) IS
--  11/06/2018 NBO artf2691955 : INC0220863 : ALERTE Paiements AP Échéances Fin Mai 2018 TIERS
--            select request_id from fnd_concurrent_requests    fcr where fcr.parent_request_id = p_request_id order by request_id;
              SELECT request_id
                FROM fnd_concurrent_requests fcr
               WHERE fcr.parent_request_id = p_request_id
              UNION
              SELECT fcr2.request_id
                FROM fnd_concurrent_requests fcr, fnd_concurrent_requests fcr2
               WHERE fcr.parent_request_id = p_request_id
               AND fcr.request_id = fcr2.parent_request_id
               ORDER BY request_id;             
    BEGIN
        -- Choix de l'imprimante
        vv_printer   := Dka_Stransco_Pkg.etl_get_value_f('IMPRIMANTE_TRESORERIE', SYSDATE,p_region, NULL, NULL);
      
        -- Choix de la langue
        EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''FRENCH''';
        
        IF NOT fnd_request.set_print_options (printer => vv_printer, copies  => 1) THEN
         dka_tools_pkg.put_log_message('L''imprimante '||vv_printer||' n''a pas été trouvée pour la responsabilité : ' || fnd_profile.value ('RESP_NAME'));
        ELSE
         dka_tools_pkg.put_log_message('L''imprimante '||vv_printer||' a été défini sur le traitement');
        END IF;  
    
        v_request_id:= FND_REQUEST.SUBMIT_REQUEST
                               (Application => 'SQLAP'
                               ,Program     => 'APXRECLC'
                               ,Description => NULL
                               ,Start_time  => NULL
                               ,Sub_Request => FALSE
                               ,Argument1   => p_checkrun_id
                               ,Argument2   => 'Y'
                               );


        IF v_request_id = 0 THEN

            p_retcode    := 2;
            Fnd_File.put_line (Fnd_File.output, 'ERREUR : Le Programme de Demande de traitement pour recalculer les règlements' || CHR(10) ||
                                            'PROGRAMME  : Le Programme de Demande de traitement pour recalculer les règlements');
            Dka_Tools_Pkg.put_log_message( '====> ERREUR : Le Programme de Demande de traitement pour recalculer les règlements ');
            p_errbuf :=' ERREUR : Le Programme de Demande de traitement pour recalculer les règlements ';
        ELSE
            COMMIT;
            Fnd_File.put_line (Fnd_File.output, 'Numéro du Programme de Demande de traitement pour recalculer les règlements: ' || v_request_id);
            Dka_Tools_Pkg.put_log_message( 'Numéro du Programme de Demande de traitement pour recalculer les règlements: ' || v_request_id);

            g_nbre_Requests := g_nbre_Requests + 1;
            g_request_id_Tab (g_nbre_Requests) := v_request_id;

        END IF;
        
    --  23/06/2017 NBO artf2178593 : BeB - Campagne de Règlements Fournisseurs EMPLOYES - Créer des Règlements en Erreur Defect #794
    --********************************************
    -- Wait for the concurrent program to complete
    --********************************************
    IF NOT (fnd_concurrent.wait_for_request(v_request_id,
                                            g_tempo,
                                            0,
                                            v_phase,
                                            v_status,
                                            v_dev_phase,
                                            v_dev_status,
                                            v_message)) THEN
    
      p_errbuf  := v_message;
      p_retcode := 2;
      fnd_file.put_line(fnd_file.output,
                        'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                        chr(10) || 'MESSAGE : ' || v_message || chr(10));
    END IF;
          

  
    IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
    
      fnd_file.put_line(fnd_file.output,
                        'COMPLETION= ' || v_dev_phase || '/' ||
                        v_dev_status);
      fnd_file.put_line(fnd_file.log,
                        'Statut de fin : ' || v_phase || '/' || v_status);
    
    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
    
      fnd_file.put_line(fnd_file.output,
                        'Programme de demande de traitement des règlements en warning ' ||
                        v_request_id);
      v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
      p_retcode := 1;
    
    ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
    
      p_retcode := 2;
      v_message := 'ERREUR : Programme de demande de traitement des règlements : ' ||
                   v_message;
    
      fnd_file.put_line(fnd_file.output,
                        'ERREUR : Fin anormale du traitement ' ||
                        v_request_id || chr(10) || 'Phase/Statut : ' ||
                        v_dev_phase || '/' || v_dev_status || chr(10) ||
                        'MESSAGE : ' || v_message || chr(10));
      fnd_file.put_line(fnd_file.log,
                        '===> ERREUR : Fin anormale du traitement ' ||
                        v_request_id);
    END IF;
    
    FOR rec_request IN cur_request(v_request_id) LOOP
        IF NOT (fnd_concurrent.wait_for_request(rec_request.request_id,
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
      
        p_errbuf  := v_message;
        p_retcode := 2;
        fnd_file.put_line(fnd_file.output,
                          'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                          chr(10) || 'MESSAGE : ' || v_message || chr(10));
      END IF;
            

    
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
      
        fnd_file.put_line(fnd_file.output,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        fnd_file.put_line(fnd_file.log,
                          'Statut de fin : ' || v_phase || '/' || v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
      
        fnd_file.put_line(fnd_file.output,
                          'Programme de demande de traitement des règlements en warning ' ||
                          v_request_id);
        v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
        p_retcode := 1;
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
      
        p_retcode := 2;
        v_message := 'ERREUR : Programme de demande de traitement des règlements : ' ||
                     v_message;
      
        fnd_file.put_line(fnd_file.output,
                          'ERREUR : Fin anormale du traitement ' ||
                          v_request_id || chr(10) || 'Phase/Statut : ' ||
                          v_dev_phase || '/' || v_dev_status || chr(10) ||
                          'MESSAGE : ' || v_message || chr(10));
        fnd_file.put_line(fnd_file.log,
                          '===> ERREUR : Fin anormale du traitement ' ||
                          v_request_id);
      END IF;
    
    END LOOP;
  
    p_errbuf := v_message;

EXCEPTION
  WHEN OTHERS THEN
    p_errbuf  := SQLCODE || ' -' || SQLERRM || ' ';
    p_retcode := 2;
    dka_tools_pkg.put_log_message('launch_program_recalculate - Erreur... : ' ||
                                  p_errbuf);
 
END launch_program_recalculate;
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE main(pv_errbuf           IN  OUT     VARCHAR2,
               pn_retcode          OUT         NUMBER,
               pv_vendor_pay_group IN        VARCHAR2)

IS

  --Declaration de curseur sur les lots de règlements
  -- les factures pas bloquées et non soldées --

  vn_montant_mini                  NUMBER;
  v_inactive_date                  DATE;
  
  --EDB295
  v_sql_cond   VARCHAR2(32000);

  v_sql_1   VARCHAR2(32000) := 'SELECT DISTINCT hou.organization_id, hou.NAME ';
  v_sql_2   VARCHAR2(32000) := 'SELECT ''x'' ';

  v_from_1  VARCHAR2(32000) := 'FROM ap_invoices_all ai, hr_all_organization_units hou, ap_payment_schedules_all aps '; --RBE artf2293446
  v_from_2  VARCHAR2(32000) := v_from_1||', ap_payment_templates apt ';
                                -- 1) il existe des factures dans un statut permettant le paiement

            
  v_where_1 VARCHAR2(32000) := --'WHERE ai.org_id = NVL(:1,ai.org_id) AND ai.invoice_type_lookup_code IN (''STANDARD'',''EXPENSE REPORT'',''PREPAYMENT'') '|| --EDB295
                 'WHERE ai.org_id = NVL(:1,ai.org_id)  ' || --EDB295
                               'AND ai.org_id = hou.organization_id AND ai.invoice_id = aps.invoice_id ' ||
                               'AND Ap_Invoices_utility_pkg.get_payment_status(ai.invoice_id) <> ''Y'' '||
                               'and Ap_Invoices_utility_pkg.get_approval_status (ai.invoice_id,ai.INVOICE_AMOUNT,Ap_Invoices_utility_pkg.get_payment_status(ai.invoice_id),ai.invoice_type_lookup_code) IN (''APPROVED'',''UNPAID'') '||
                               'and ai.WFAPPROVAL_STATUS IN (''WFAPPROVED'',''NOT REQUIRED'') AND NVL(aps.external_bank_account_id, 0) > DECODE(aps.payment_method_lookup_code, ''EFT'', 0,-1) ';
                               -- 1) + correspondant au parametrage du modele 
  v_where_2 VARCHAR2(32000) := v_where_1||'and apt.template_id = :2 and ROWNUM = 1 and aps.payment_status_flag = ''N'' '||
                               'and ( apt.HI_PAYMENT_PRIORITY IS NULL OR aps.Payment_Priority >= apt.HI_PAYMENT_PRIORITY ) '||
                               'and ( apt.LOW_PAYMENT_PRIORITY IS NULL OR aps.Payment_Priority <= apt.LOW_PAYMENT_PRIORITY ) '||
                               'AND ( ( Apt.Pay_Group_Option = ''ALL'' ) OR '||
                               '( Apt.Pay_Group_Option = ''SPECIFY'' AND EXISTS ( SELECT ''X'' '||
                               'FROM Ap_Pay_Group Apg '||
                               'WHERE Apg.TEMPLATE_ID =  apt.template_id and apg.VENDOR_PAY_GROUP = ai.PAY_GROUP_LOOKUP_CODE ) ) ) '|| 
                               'AND ( ( apt.OU_GROUP_OPTION = ''ALL'' ) OR '||
                               '( Apt.OU_GROUP_OPTION = ''SPECIFY'' AND EXISTS ( SELECT ''X'' '||
                               'FROM Ap_OU_Group Aog '||
                               'WHERE Aog.TEMPLATE_ID = apt.template_id and aog.org_id = ai.org_id ) ) ) '; 
  v_order_1 VARCHAR2(32000) := 'ORDER BY hou.organization_id ';
  
  CURSOR c_org_ville(cn_org_id hr_all_organization_units.organization_id%TYPE) is
    SELECT v.* 
    FROM (
    SELECT DISTINCT hou.organization_id,
                    hou.NAME organization_name,
                    dsl.return_value csp_ville,
                    fr.responsibility_id, 
                    fr.responsibility_key,
                    fr.application_id
      FROM hr_all_organization_units hou,
           dka_stransco_lines        dsl,
           dka_stransco_headers      dsh,
           fnd_responsibility        fr
     WHERE dsh.set_id = dsl.set_id
       AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
       AND SYSDATE BETWEEN nvl(dsl.start_date,SYSDATE) AND nvl(dsl.end_date,SYSDATE)
       AND dsl.inactive_date IS NULL
       AND dsl.param2_value = substr(hou.NAME,1,3)
       AND fr.responsibility_key = dsl.return_value ||'_REGLEMENTS'
       AND EXISTS ( SELECT NULL
                      FROM ap_invoices_all ai,
                           ap_payment_schedules_all  aps
                     WHERE ai.invoice_type_lookup_code IN ('STANDARD', 'EXPENSE REPORT', 'PREPAYMENT')
                       AND ai.org_id = nvl(cn_org_id,ai.org_id) 
                       AND ap_invoices_utility_pkg.get_payment_status(ai.invoice_id) <> 'Y'
                       AND ap_invoices_utility_pkg.get_approval_status(ai.invoice_id,
                                                                       ai.invoice_amount,
                                                                       ap_invoices_utility_pkg.get_payment_status(ai.invoice_id),
                                                                       ai.invoice_type_lookup_code) IN ('APPROVED','UNPAID') -- SNK 06/05/2019 INC0303618 
                       AND ai.wfapproval_status IN ('WFAPPROVED', 'NOT REQUIRED')
                       AND nvl(aps.external_bank_account_id,0) > decode(aps.payment_method_lookup_code,'EFT',0,-1)
                       AND ai.org_id = hou.organization_id
                       AND ai.invoice_id = aps.invoice_id)) v
         ORDER BY v.organization_name;
     
  --ARA EDB295LOT1A
  CURSOR cur_avoirs_reglee IS
   SELECT customer_trx_id 
   FROM ra_customer_trx_all
   where customer_trx_id in
                 (SELECT substr(ai.description,
                        -instr(reverse(ai.description), '_') + 1)-- , c.check_id
                  from AP_INVOICES_ALL         ai,
                     AP_INVOICE_PAYMENTS_ALL p,
                     ap_checks_all           c
                 where p.invoice_id = ai.invoice_id
                   and c.check_id = p.check_id
                   and c.check_id in (select check_id from ap_checks_all where checkrun_name like '%RBTCLIENT%'));
  
  TYPE V_org_ville_Type IS TABLE OF c_org_ville%ROWTYPE INDEX BY BINARY_INTEGER;          
  V_org_ville V_org_ville_Type;      
  
  TYPE V_Tab_record_2_Type IS TABLE OF VARCHAR2(1) INDEX BY BINARY_INTEGER;          
  V_Tab_record_2 V_Tab_record_2_Type;      
                      
  l_cursor  SYS_REFCURSOR;

  vn_user_id           fnd_user.user_id%TYPE;
  vn_responsibility_id fnd_responsibility_vl.responsibility_id%TYPE;
  vn_application_id    fnd_application.application_id%TYPE;
  
  vr_dka_param                     dka_parameters%ROWTYPE;

  vn_org_id                        NUMBER;
  vv_organization_name             VARCHAR2(200);
  e_not_to_request                 EXCEPTION;

  vv_date_heure                    VARCHAR2(25);
  vv_sqlstmt                       VARCHAR2(500);


  /*Gestion des reglements express*/
  e_duplicate_batch_set            EXCEPTION;

  --RBE MigR12
  V_Template_Name               Varchar2(200);
  v_template_id                 NUMBER;
  vv_type_campagne              Varchar2(200);
  vn_delai                      NUMBER;

  v_checkrun_id                 NUMBER;
  v_checkrun_name               VARCHAR2(150);

  v_retcode                     NUMBER;
  v_errbuf                      VARCHAR2(32000);
  v_retcode_Global              NUMBER := 0;
  v_errbuf_Global               VARCHAR2(32000);

  v_ok                          BOOLEAN;
  
  vd_start_date                    DATE := SYSDATE;
  vd_payment_date                  DATE;
  
  vd_date_debut DATE;
  vd_date_fin   DATE;

  -------------------------------------------------------
  -- Procédure de suppression des tables de sauvegarde --
  -------------------------------------------------------
  PROCEDURE delete_save_tables ( pv_table_name VARCHAR2 ) IS

    CURSOR cur_tables(pv_table_name VARCHAR2) IS
      SELECT owner,
             table_name
      FROM   all_tables
      WHERE  table_name LIKE pv_table_name || '%';

    rec_tables                     cur_tables%ROWTYPE;
    vn_longueur_prefixe            NUMBER;
    vn_longueur_table              NUMBER;
    vv_date_table                  VARCHAR2(30);
    vd_date_table                  DATE;
    vv_sqlstmt                     VARCHAR2(250);

    --------------------------------------------------------------
    -- Fonction qui vérifie qu'une chaine de caractère est bien --
    -- une date au format YYYYMMDDHHMISS                        --
    --------------------------------------------------------------
    FUNCTION is_date ( pv_date VARCHAR2 ) RETURN BOOLEAN IS

      vd_date                      DATE;
      vb_is_date                   BOOLEAN;

    BEGIN

      BEGIN
        vb_is_date := TRUE;

        SELECT TO_DATE(pv_date, 'YYYYMMDDHH24MISS')
        INTO   vd_date
        FROM   dual;

      EXCEPTION
        WHEN OTHERS THEN
          vb_is_date := FALSE;
      END;

      RETURN vb_is_date;

    END is_date;

  BEGIN

    OPEN cur_tables (pv_table_name);
    LOOP
      FETCH cur_tables INTO rec_tables;
      EXIT WHEN cur_tables%NOTFOUND;

      vn_longueur_prefixe := LENGTH(pv_table_name);
      vn_longueur_table   := LENGTH(rec_tables.table_name);

      -------------------------------------------------------------------------------
      -- Le nom de la table doit respester le format 'pv_table_nameYYYYMMDDHHMISS' --
      -- La longueur du nom de la table doit donc être égale à la longueur du      --
      -- préfixe + 14                                                              --
      -------------------------------------------------------------------------------
      IF vn_longueur_table = vn_longueur_prefixe + 14 THEN
        vv_date_table := SUBSTR(rec_tables.table_name, vn_longueur_prefixe + 1, 14);

        -------------------------------------------------------------
        -- On vérifie que les 14 derniers caractères sont une date --
        -------------------------------------------------------------
        IF is_date(vv_date_table) THEN
          vd_date_table := TO_DATE(vv_date_table, 'YYYYMMDDHH24MISS');

          -----------------------------------------------
          -- On supprime les table de plus de 30 jours --
          -----------------------------------------------
          IF TRUNC(SYSDATE) - TRUNC(vd_date_table) > 30 THEN
            vv_sqlstmt := 'DROP TABLE ' || rec_tables.owner || '.' || rec_tables.table_name;
            EXECUTE IMMEDIATE vv_sqlstmt;
            Dka_Tools_Pkg.put_log_message('table ' || rec_tables.owner || '.' || rec_tables.table_name || ' supprimée');
          END IF;
        END IF;
      END IF;

    END LOOP;
    CLOSE cur_tables;

  END delete_save_tables;

BEGIN

  -----  Initialisations des variables -----
  pv_errbuf := NULL;
  pn_retcode := 0;
  gn_father_request_id := Fnd_Global.conc_request_id;  /*ADR le 09/10/2003*/

  -- Début Modif PCA
  --org_id_dka_sqpqutorgt := fnd_profile.value('ORG_ID'); --RBE : ne sert plus à rien je pense
  -- Fin Modif PCA

  --ARA EDB295
  IF pv_vendor_pay_group = 'RBTCLIENT' THEN
   ----v_sql_cond := 'AND ai.invoice_type_lookup_code = ''PAYMENT REQUEST'' ';
   v_sql_cond := 'AND ai.PAY_GROUP_LOOKUP_CODE = ''RBTCLIENT'' AND ai.PAYMENT_METHOD_CODE = ''EFT'' ';
  ELSE
   v_sql_cond := 'AND ai.invoice_type_lookup_code IN (''STANDARD'',''EXPENSE REPORT'',''PREPAYMENT'')';
  END IF;
  
  v_where_1 := v_where_1 || v_sql_cond;
  
  --END EDB295
  
  --ARA EDB295LOT1A
  BEGIN
  
  UPDATE dka_parameters
  SET VARCHAR2_VALUE = 'Y'
  WHERE PROGRAM_CODE = 'DKA_SAPAUTORGT'
  AND PARAMETER_NAME = 'FLAG_CAMPAGNE';
  
  DELETE FROM DKA_AR_REMB_AVOIR_LIST;
  
  INSERT INTO DKA_AR_REMB_AVOIR_LIST
  SELECT * FROM dka_ar_remboursement_avoirs;
  
  COMMIT;
  
  END;

  --RBE Migration R12
  -- Récuperation du code du type fournisseur pour modele de payement
  BEGIN
   Dka_Tools_Pkg.put_log_message('Récuperation du delai et du code du type fournisseur pour modele de payement');
   select
    ffvv.ATTRIBUTE3,to_number(nvl(ffvv.attribute2,gn_default_delai))
   into
    vv_type_campagne,vn_delai
   from
    fnd_flex_value_sets ffvs,
    fnd_flex_values_vl ffvv
   where
    ffvs.flex_value_set_id = ffvv.flex_value_set_id
    and ffvs.flex_value_set_name = 'DKA_VENDOR_PAY_GROUP'
    and ffvv.flex_value = pv_vendor_pay_group
    and enabled_flag = 'Y'
    and sysdate between nvl(ffvv.start_date_active,sysdate)
                    and nvl(ffvv.end_date_active,sysdate);
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := 'Erreur de récupération du delai et du code de la compagne de réglement pour le Type de fournisseur ''' || pv_vendor_pay_group;
      pn_retcode := 2;
      RETURN;

  END;

    --RBE artf2118984
    Dka_Tools_Pkg.put_log_message('date de compensation : START_DATE');
    IF Dka_Tools_Pkg.IS_BANK_HOLIDAY(vd_start_date) = 1
       OR TRIM(TO_CHAR(vd_start_date, 'DAY')) IN ('SAMEDI', 'DIMANCHE') /*JJA 29/11/2012*/ 
       THEN
     vd_payment_date := vd_start_date;
     Dka_Tools_Pkg.Get_Next_Working_Day(vd_payment_date);
    ELSE
     vd_payment_date := vd_start_date;     
    END IF;

    Dka_Tools_Pkg.put_log_message('date de compensation : Vérification de l''heure de lancement : '||TO_CHAR(vd_start_date,'hh24mi') );
    IF TO_NUMBER(TO_CHAR(vd_start_date,'hh24mi')) BETWEEN 0 AND 1900 --JJA - 08/10/2013
       AND vn_delai > 1 THEN
      
      vn_delai := vn_delai - 1;

    END IF;

    Dka_Tools_Pkg.put_log_message('date de compensation : Calcul');
    FOR i  in 1..vn_delai LOOP

      vd_payment_date := vd_payment_date + 1;      
      Dka_Tools_Pkg.Get_Next_Working_Day(vd_payment_date);
      
    END LOOP;

    Dka_Tools_Pkg.put_log_message('date de compensation : '||to_char(vd_payment_date,'dd/mm/yyyy') );

  /* ETANCHEITE DALKIA 2007 */

  /*Ajout de la creation des jeux de lot de reglements express*/
  --RBE MigR12 pas de jeux de lots

  ----- Initialisation des variables du traitement ----- /* ADR le 19/12/2003*/

  Dka_Tools_Pkg.get_parameter('SAPAUTORGT','MONTANT_MINI_VIR_EXPR',vr_dka_param,pn_retcode,pv_errbuf);

  IF pn_retcode != 0
  THEN
      pn_retcode := 2;
      Dka_Tools_Pkg.put_log_message(pv_errbuf);
      RETURN;
  END IF;
  vn_montant_mini := vr_dka_param.number_value;
  Dka_Tools_Pkg.put_log_message('Montant mini : ' || vn_montant_mini);

  COMMIT;

  -- Début modif EMA du 18/08/2009

  -- Suppression des tables de sauvegarde de plus de 30 jours --

  -- Suppression des tables de sauvegarde de la table DKA_IEOAPSAT01_APIMP_LINE ----JJA 19/07/2012
  -------------------------------------------------------------------------
  Dka_Tools_Pkg.put_log_message('Suppression des tables de sauvegarde de la table DKA_IEOAPSAT01_APIMP_LINE');
  delete_save_tables ('DKA_SAT01_APIML_');

  -- Suppression des tables de sauvegarde de la table DKA_IEOAPSAT01_APIMP_HDR ----JJA 19/07/2012
  -------------------------------------------------------------------------
  Dka_Tools_Pkg.put_log_message('Suppression des tables de sauvegarde de la table DKA_IEOAPSAT01_APIMP_HDR');
  delete_save_tables ('DKA_SAT01_APIMH_');

  -- Suppression des tables de sauvegarde de la table DKA_SAPAUTORGT_TMP ----RBE 10/10/2016

  Dka_Tools_Pkg.put_log_message('Suppression des tables de sauvegarde de la table DKA_SAPAUTORGT_TMP');
  delete_save_tables ('DKA_SAPAUTORGT_');

  -- Sauvegarde du contenu des tables de travail --
  -------------------------------------------------
  vv_date_heure := TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS');



  -- Sauvegarde de la table DKA_IEOAPSAT01_APIMP_LINE ----JJA 19/07/2012
  -----------------------------------------------
  Dka_Tools_Pkg.put_log_message('Création de la table DKA.DKA_SAT01_APIML_' || vv_date_heure);
  vv_sqlstmt := 'CREATE TABLE DKA.DKA_SAT01_APIML_' || vv_date_heure || ' AS SELECT * FROM DKA.DKA_IEOAPSAT01_APIMP_LINE';
  EXECUTE IMMEDIATE vv_sqlstmt;

  -- Sauvegarde de la table DKA_IEOAPSAT01_APIMP_HDR ----JJA 19/07/2012
  -----------------------------------------------
  Dka_Tools_Pkg.put_log_message('Création de la table DKA.DKA_SAT01_APIMH_' || vv_date_heure);
  vv_sqlstmt := 'CREATE TABLE DKA.DKA_SAT01_APIMH_' || vv_date_heure || ' AS SELECT * FROM DKA.DKA_IEOAPSAT01_APIMP_HDR';
  EXECUTE IMMEDIATE vv_sqlstmt;

  -- Sauvegarde de la table DKA_SAPAUTORGT_TMP ---- RBE 10/10/2016
  -----------------------------------------------
  Dka_Tools_Pkg.put_log_message('Création de la table DKA.DKA_SAPAUTORGT_' || vv_date_heure);
  vv_sqlstmt := 'CREATE TABLE DKA.DKA_SAPAUTORGT_' || vv_date_heure || ' AS SELECT * FROM DKA.DKA_SAPAUTORGT_TMP';
  EXECUTE IMMEDIATE vv_sqlstmt;

  -- Fin modif EMA du 18/08/2009

  COMMIT;

  EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_IEOAPSAT01_APIMP_LINE';  --JJA 19/07/2012
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_IEOAPSAT01_APIMP_HDR';   --JJA 19/07/2012
  EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_SAPAUTORGT_TMP';

  -- Fin modif GV20090611

  -- recherche des org pour lesquelles une facture est dans un statut permettant d etre payee
  OPEN c_org_ville(gn_org_id);
  FETCH c_org_ville BULK COLLECT INTO V_org_ville;
  CLOSE c_org_ville;  
  
  --Sauvegarde de la responsabilité courante
  vn_user_id           := fnd_profile.value('USER_ID');
  vn_responsibility_id := fnd_profile.value('RESPONSIBILITY_ID');
  vn_application_id    := fnd_profile.value('APPLICATION_ID'); 
   
  
  FOR I IN 1..V_org_ville.COUNT
  LOOP
  
     --RBE artf2293446
     --Pour chaque traitement, on se place sur la réponsabilité CSP_ZZZ_REGLEMENT
     fnd_global.apps_initialize (vn_user_id, V_org_ville(I).responsibility_id, V_org_ville(I).application_id);
     mo_global.init('SQLAP');
     
     -- Recherche du modele de paiement
     v_ok := TRUE;
   
   --ARA EDB295
   IF vv_type_campagne = 'RBTCLIENT' THEN
      --Dka_Tools_Pkg.put_log_message('type campagne : RBTCLIENT ');
    v_template_name := substr(V_org_ville(I).Organization_Name,0,3)|| vv_type_campagne || substr(V_org_ville(I).Organization_Name,4,7); --result EX : DRWRBTCLIENT0001
   ELSE
    
    v_template_name := substr(V_org_ville(I).Organization_Name,0,3)||vv_type_campagne||'VIR'||substr(V_org_ville(I).Organization_Name,4,7);
   
   END IF;
   --END EDB295
   
     Fnd_File.put_line (Fnd_File.output,'Modèle de paiement : '||v_template_name);
     Dka_Tools_Pkg.put_log_message('Modèle de paiement : '||v_template_name);     
     
     BEGIN

        -- artf07423425 - INC0486848 - INT004 - Correctif sur campagne de règlement - Modèle AP : L'objectif du correctif est de vérifier si le modèle de paiement est actif à la date d¿exécution avant de le lancer.
        SELECT  template_id, inactive_date
        INTO v_template_id, v_inactive_date
        FROM   ap_payment_templates
        WHERE template_name = v_template_name;

     EXCEPTION
     WHEN OTHERS THEN
         Fnd_File.put_line (Fnd_File.output,'==> Erreur lors de la récupération du modèle de paiement '||v_template_name );
         Dka_Tools_Pkg.put_log_message('==> Erreur lors de la récupération du modèle de paiement '||v_template_name );
         pn_retcode := 1; -- RBE artf2084069
         v_ok := FALSE;
   END;        
      
   IF v_ok 
   THEN
         -- Controle que pour l'org, il existe des factures correspondant aux parametres du modele
         -- cad criteres de la requete 1 (avec org_id) + controles sur le modele
         OPEN l_cursor FOR v_sql_2||v_from_2||v_where_2 USING V_org_ville(I).Organization_Id, v_template_id;
         FETCH l_cursor
         BULK COLLECT INTO V_Tab_record_2;
         CLOSE l_cursor; 

/*         Dka_Tools_Pkg.put_log_message('2-----' );
         Dka_Tools_Pkg.put_log_message(v_sql_2||v_from_2||v_where_2 );
         Dka_Tools_Pkg.put_log_message('2-----' );*/
         
         
         IF V_Tab_record_2.COUNT = 0
         THEN
            Fnd_File.put_line (Fnd_File.output,'Des factures a regler existent pour l''organisation '||V_org_ville(I).Organization_Name||' mais ne correspondent pas au modele de demande de traitement des reglements '||v_template_name);
            Dka_Tools_Pkg.put_log_message('Des factures a regler existent pour l''organisation '||V_org_ville(I).Organization_Name||' mais ne correspondent pas au modele de demande de traitement des reglements '||v_template_name);
            v_ok := FALSE;
         END IF;
   END IF;

   IF v_ok THEN
   
    --< OBE artf2812973
  --Si la date est dans une période AP en cours => On garde cette date
    --Si la date est n'est pas dans la période En cours => on prendra le dernier jour de la période AP en cours.
  
  BEGIN
  
       SELECT MAX(start_date), MAX(end_date)
     INTO vd_date_debut, vd_date_fin
       FROM
           gl_period_statuses a, HR_OPERATING_UNITS b
       WHERE
       a.application_id = '200'
       AND a.closing_status = 'O'
       AND a.ledger_id = b.SET_OF_BOOKS_ID
       AND b.organization_id = V_org_ville(I).Organization_Id
       ;   
     
     IF NOT vd_payment_date BETWEEN vd_date_debut AND vd_date_fin THEN
       vd_payment_date := vd_date_fin;
     END IF;
     
    EXCEPTION
      WHEN OTHERS THEN
        NULL;
    END;    
  
  --> OBE artf2812973
        
        /* RBE artf2293446
        --Pour chaque traitement, on se place sur la réponsabilité CSP_ZZZ_REGLEMENT
        
        fnd_global.apps_initialize (vn_user_id, V_org_ville(I).responsibility_id, V_org_ville(I).application_id);
        mo_global.init('SQLAP'); */
        
        -- artf07423425 - INC0486848 - INT004 - Correctif sur campagne de règlement - Modèle AP : L'objectif du correctif est de vérifier si le modèle de paiement est actif à la date d¿exécution avant de le lancer.
        IF v_inactive_date IS NULL OR v_inactive_date > TRUNC(sysdate) THEN
        
        --Lancer le programme du traitement de demande de reglements
        Launch_Program_Payment(pv_errbuf,
                             v_retcode,
                             v_template_id,
                             V_org_ville(I).Organization_Id,
                             V_org_ville(I).Organization_Name,
                             vd_payment_date);
       END IF; 
   END IF;                             

  END LOOP;
  
  --On se replace dans la responsabilité initiale
  fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
  
  
    --  23/06/2017 NBO artf2178593 : BeB - Campagne de Règlements Fournisseurs EMPLOYES - Créer des Règlements en Erreur Defect #794
    --  11/06/2018 NBO artf2691955 : INC0220863 : ALERTE Paiements AP Échéances Fin Mai 2018 TIERS
    FOR I IN 1..g_nbre_Requests
    LOOP

      wait_program_end ( p_errbuf            => v_errbuf,
                         p_retcode           => v_retcode,
                         p_request_id        => g_request_id_Tab(I),
                         p_checkrun_id       => v_checkrun_id,
                         p_checkrun_name     => v_checkrun_name,
                         p_update_table      => TRUE ) ;


      IF NVL(v_retcode_Global,0) < NVL(v_retcode,0)
      THEN
         v_retcode_Global := v_retcode;
         v_errbuf_Global := v_errbuf;
      END IF;
  
  --ARA EDB295LOT1A
  FOR rec_reglee IN cur_avoirs_reglee LOOP
  
  BEGIN
  
  UPDATE DKA_AR_REMB_AVOIR_LIST
  SET REGLEE = 'OUI'
  WHERE ID_AVOIR = rec_reglee.customer_trx_id;
  
  END;
  
  END LOOP;
  
      --Inserer la demande de reglement cree.
      /*IF v_checkrun_id IS NOT NULL THEN
        BEGIN
          INSERT INTO dka_sapautorgt_tmp
            (org_id,
             org_name,
             checkrun_id,
             checkrun_name,
             status_flag)
          VALUES
            (g_Org_Id_Tab(I),
             g_Org_Name_Tab(I),
             v_checkrun_id,
             v_checkrun_name,
             'P'
             );
        EXCEPTION
        WHEN OTHERS THEN
          --Dka_Tools_Pkg.Put_Outdebug_Message('==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP '|| v_checkrun_name);
          Fnd_File.put_line (Fnd_File.output,'==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP '|| v_checkrun_name);
          Dka_Tools_Pkg.put_log_message('==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP '|| v_checkrun_name);
          pn_retcode := 2;
        END;
      END IF;*/

    END LOOP;

    IF v_retcode_Global = 2 THEN
        pn_retcode := 2;
        pv_errbuf := v_errbuf_Global;
    END IF;

    COMMIT;

EXCEPTION
WHEN OTHERS THEN
  pv_errbuf := SQLCODE || ' -' || SQLERRM || ' ';
  pn_retcode := 2;
  Dka_Tools_Pkg.put_log_message('Erreur... : '|| pv_errbuf);
END main;

--------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------
--  Nom           : recalculate
--  Description   : procédure principale du traitement qui enchaînera la compagne de reglement
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--                  pv_vendor_pay_group    Type de fournisseur
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE recalculate(pv_errbuf           IN  OUT     VARCHAR2,
                      pn_retcode          OUT         NUMBER,
                      pv_vendor_pay_group IN         VARCHAR2)

IS
  
  --Declaration de curseur sur les demandes de reglements
  -- Au status CALCULATING

  CURSOR cur_payments_to_request IS
    SELECT v.* FROM (
    SELECT DISTINCT
        hou.organization_id,
        hou.NAME organization_name,
        dsl.return_value csp_ville,
        fr.responsibility_id, 
        fr.responsibility_key,
        fr.application_id,
        Aisc.*
    FROM Ap_Inv_Selection_Criteria_All Aisc
        ,Ap_Payment_Templates Apt
        ,FND_FLEX_VALUE_SETS FFVS
        ,fnd_flex_values_vl ffvv
        ,AP_SELECTED_INVOICES_ALL asia
        ,hr_all_organization_units hou
        ,dka_stransco_lines dsl
        ,dka_stransco_headers dsh
        ,fnd_responsibility fr        
    WHERE 1=1
    AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
    AND FFVS.FLEX_VALUE_SET_NAME = 'DKA_VENDOR_PAY_GROUP'
    and enabled_flag = 'Y'
    AND SYSDATE BETWEEN NVL(FFVV.START_DATE_ACTIVE,SYSDATE)
                    AND NVL(FFVV.END_DATE_ACTIVE,SYSDATE)
    AND Aisc.Status = 'REVIEW'  -- 'CALCULATING'
    AND Apt.Template_Id = Aisc.Template_Id
    -- artf07423425 - INC0486848 - INT004 - Correctif sur campagne de règlement - Modèle AP : L'objectif du correctif est de vérifier si le modèle de paiement est actif à la date d¿exécution avant de le lancer.
    AND (Apt.inactive_date IS NULL OR Apt.inactive_date > TRUNC(sysdate))

    AND Substr(Apt.Template_Name,4,Instr(Apt.Template_Name,'VIR')-4) = ffvv.attribute3
  
    --AND Flv.Meaning = pv_vendor_pay_group
    AND ffvv.flex_value = pv_vendor_pay_group
    --
    AND aisc.checkrun_name = asia.checkrun_name
    AND hou.organization_id = asia.org_id
    AND dsh.set_id = dsl.set_id
    AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
    AND SYSDATE BETWEEN nvl(dsl.start_date,SYSDATE) AND nvl(dsl.end_date,SYSDATE)
    AND dsl.inactive_date IS NULL
    AND dsl.param2_value = substr(hou.NAME,1,3)
    AND fr.responsibility_key = dsl.return_value ||'_REGLEMENTS') v
    ORDER BY v.organization_name 
     ;
     
  --  30/04/2021 NBO artf07423405 : INC0486886 - INT004 - Correctif sur campagne de réglement AP
    CURSOR cur_request IS
    SELECT request_id
      FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
     WHERE fcp.concurrent_program_name = 'IBY_FD_PAYMENT_FORMAT_TEXT'
     AND fcp.CONCURRENT_PROGRAM_ID = fcr.CONCURRENT_PROGRAM_ID
     AND fcr.PHASE_CODE IN ('R') --En cours
     AND fcr.STATUS_CODE IN ('I','R') --Normal
     ORDER BY request_id; 

    v_count NUMBER;

    --v_retcode                     NUMBER;
    --v_errbuf                      VARCHAR2(32000);
    v_retcode_Global              NUMBER := 0;
    v_errbuf_Global               VARCHAR2(32000);

    --v_checkrun_id                 NUMBER;
    --v_checkrun_name               VARCHAR2(150);
    
    vn_user_id           fnd_user.user_id%TYPE;
    vn_responsibility_id fnd_responsibility_vl.responsibility_id%TYPE;
    vn_application_id    fnd_application.application_id%TYPE;
    
    v_phase      VARCHAR2(100);
    v_status     VARCHAR2(100);
    v_dev_phase  VARCHAR2(100);
    v_dev_status VARCHAR2(100);
    v_message    VARCHAR2(100);
    
BEGIN

    Dka_Tools_Pkg.put_log_message('Début du traitement');
    
    --Sauvegarde de la responsabilité courante
    vn_user_id           := fnd_profile.value('USER_ID');
    vn_responsibility_id := fnd_profile.value('RESPONSIBILITY_ID');
    vn_application_id    := fnd_profile.value('APPLICATION_ID'); 
  
    
    FOR rec_cur_payments_to_request IN cur_payments_to_request LOOP

      Dka_Tools_Pkg.put_log_message('Lancement du traitement : Demande de traitement pour recalculer les règlements - '||rec_cur_payments_to_request.checkrun_name);
      fnd_global.apps_initialize (vn_user_id, rec_cur_payments_to_request.responsibility_id, rec_cur_payments_to_request.application_id);
      mo_global.init('SQLAP');
      
      
      -- Mise à jour du statut à CALCULATING
      UPDATE Ap_Inv_Selection_Criteria_All
      SET Status = 'CALCULATING'
      WHERE checkrun_id = rec_cur_payments_to_request.checkrun_id;

      --Inserer la demande de reglement cree hors etape de la campagne

      SELECT count(1)
      INTO v_count
      FROM dka_sapautorgt_tmp
      WHERE checkrun_id = rec_cur_payments_to_request.checkrun_id
      ;

      IF v_count = 0 THEN
        BEGIN
          INSERT INTO dka_sapautorgt_tmp
            (org_id,
             org_name,
             checkrun_id,
             checkrun_name,
             status_flag)
          VALUES
            (rec_cur_payments_to_request.org_id,
             NULL,
             rec_cur_payments_to_request.checkrun_id,
             rec_cur_payments_to_request.checkrun_name,
             'P');

        EXCEPTION
        WHEN OTHERS THEN
          Dka_Tools_Pkg.put_log_message('==> Erreur lors de l''insertion de la demande de règlement dans la table DKA_SAPAUTORGT_TMP ');
        END;
      END IF;

      launch_program_recalculate(pv_errbuf,
                                 pn_retcode,
                                 rec_cur_payments_to_request.checkrun_id,
                                 substr(rec_cur_payments_to_request.organization_name,1,3)
                                 );

    END LOOP;
    
    --  30/04/2021 NBO artf07423405 : INC0486886 - INT004 - Correctif sur campagne de réglement AP
    FOR rec_request IN cur_request LOOP
     IF NOT (fnd_concurrent.wait_for_request(rec_request.request_id,
                                              g_tempo,
                                              0,
                                              v_phase,
                                              v_status,
                                              v_dev_phase,
                                              v_dev_status,
                                              v_message)) THEN
      
        pv_errbuf  := v_message;
        pn_retcode := 2;
        fnd_file.put_line(fnd_file.output,
                          'ERREUR : Attente de la fin du programme  dépassée : Fin du traitement' ||
                          chr(10) || 'MESSAGE : ' || v_message || chr(10));
      END IF;
            
   
      IF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'NORMAL') THEN
      
        fnd_file.put_line(fnd_file.output,
                          'COMPLETION= ' || v_dev_phase || '/' ||
                          v_dev_status);
        fnd_file.put_line(fnd_file.log,
                          'Statut de fin : ' || v_phase || '/' || v_status);
      
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status = 'WARNING') THEN
      
        fnd_file.put_line(fnd_file.output,
                          'Formater les instructions de règlement avec sortie texte en warning ' ||
                          rec_request.request_id);
        v_message := 'ERREUR : Fin du traitement en warning: ' || v_message;
        pn_retcode := 1;
        
      ELSIF (v_dev_phase = 'COMPLETE' AND v_dev_status != 'NORMAL') THEN
        
        pn_retcode := 2;
        v_message := 'ERREUR : Formater les instructions de règlement avec sortie texte : ' ||
                     v_message;
      
        fnd_file.put_line(fnd_file.output,
                          'ERREUR : Fin anormale du traitement ' ||
                          rec_request.request_id || chr(10) || 'Phase/Statut : ' ||
                          v_dev_phase || '/' || v_dev_status || chr(10) ||
                          'MESSAGE : ' || v_message || chr(10));
        fnd_file.put_line(fnd_file.log,
                          '===> ERREUR : Fin anormale du traitement ' ||
                          rec_request.request_id);
      END IF;        
    END LOOP;
    
    --On se replace dans la responsabilité initiale
    fnd_global.apps_initialize (vn_user_id, vn_responsibility_id, vn_application_id);
  
    
    pn_retcode := v_retcode_Global;
    pv_errbuf := v_errbuf_Global;

    Dka_Tools_Pkg.put_log_message('fin du traitement');

EXCEPTION
WHEN OTHERS THEN
  pv_errbuf := SQLCODE || ' -' || SQLERRM || ' ';
  pn_retcode := 2;
  Dka_Tools_Pkg.put_log_message('Erreur... : '|| pv_errbuf);
END RECALCULATE;

END Dka_Sapautorgt_Pkg;

/
SHOW ERRORS;
EXIT
