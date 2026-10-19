CREATE OR REPLACE PACKAGE BODY DKA_SPOASS_FOURN_PKG IS 
------------------------------------------------------------------------------------
-- $Id: DKA_SPOASS_FOURN_PKG.pkb 654 2008-05-14 13:18:59Z CORP\viknab $
-- Capgemini
-- PROJET            : VEOLIA Oracle Applications
-- NOM               : DKA_SPOASS_FOURN_PKG
-- DESCRIPTION       : package d'assainissement des référentiels fournisseurs
---
--- AUTEUR           : Jonathan Dequidt (Capgemini)
--- DATE DE CREATION : 26/02/2008
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 14/05/2008 VKN Modifications suite artf339237
--- 23/05/2008 ADR MAIN_2 : Correction de la requete de la periode AP.    
--- 24/09/2008 DMD Test attribute3 de po_vendors different "Y" Main1 Main2 Main3
--- 29/01/2014 JJA Correction : INC000000493207: Désactivation automatique des fournisseurs
--- 23/08/2016 JPE MIGRATION R12
--- 23/12/2019 SEL SPE130 - 0SPF20080028 DESACTIVATION DES ENTETES FOURNISSEURS.DOC VERSION : 4.1
--- 22/07/2020 SHA SPE130 - 0SPF20080028 DÉSACTIVATION/RÉACTIVATION D’UN SITE DE RÈGLEMENT FOURNISSEUR  : 3.3
--- 17/08/2020 AAM SPE130 - 0SPF20080028 DÉSACTIVATION/RÉACTIVATION D’UN SITE DE RÈGLEMENT FOURNISSEUR (retour intégartion)
---.19/10/2020 SHA EDB261 - Modifications des traitements pour Projet PFAD
------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
e_main    EXCEPTION;
g_user    NUMBER        := fnd_profile.value('USER_ID');

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
--  Nom           : main_1
--  Description   : désactivation des sites fournisseurs jamais utilisés
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--      pn_org_ope      organisation opérationnelle
--      pd_date         date de validation
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_1(pv_errbuf   OUT VARCHAR2,
                   pn_retcode  OUT NUMBER,
                   pn_org_ope  IN  NUMBER,
                   pd_date     IN  VARCHAR2)
  IS
    
    e_error EXCEPTION;
    
	vn_cpt                PLS_INTEGER := 0;
	vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
    
	--API
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2(200);
    vv_commit             VARCHAR2(200);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2(200);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2(200);
    vn_msg_index_out      NUMBER;
    vv_calling_prog       VARCHAR2(200);
	vv_message  		  VARCHAR2(500);
    
   
    CURSOR c_fournisseur IS
     SELECT pv.vendor_id
      FROM   po_vendors pv
      WHERE  1=1 
        AND  pv.attribute3 != 'Y'	-- SELO -- un fournisseur qui n’est pas un -fournisseur de combustible-
        AND  pv.vendor_type_lookup_code = 'VENDOR'
		-- le site fournisseur correspond à un fournisseur de type TIERS
      ;
	 
    --- 23/08/2016 JPE MIGRATION R12 Ajout du curseur c_fourn_a_desac
	CURSOR c_fourn_a_desac(pn_vendor_id number, pn_org_id number, pd_datecur date) IS
      SELECT  pvs.vendor_site_id  
      FROM 	  po_vendor_sites_all pvs
	  WHERE	  pvs.vendor_id = pn_vendor_id
      AND pvs.org_id = nvl(pn_org_id, pvs.org_id)         -- uniquement pour l'unité opérationnelle considérée
	  AND	pvs.org_id in (select organization_id from hr_operating_units where name <> 'REF9999')
      AND  (   pvs.inactive_date IS NULL OR pvs.inactive_date > SYSDATE) -- le site fournisseur est actif 	  
      AND  pvs.creation_date < pd_datecur     -- le site fournisseur a été créé avant cette date
      AND  NOT EXISTS (SELECT 'x'           -- le site fournisseur n'est présent dans aucune demande d'achat
                       FROM   po_requisition_lines_all prl
                       WHERE  prl.org_id = pvs.org_id -- pour l'unité opérationnelle consdérée
                         AND  prl.vendor_site_id = pvs.vendor_site_id)
      AND  NOT EXISTS (SELECT 'x'           -- le site fournisseur n'est présent dans aucune commande
                       FROM   po_headers_all ph
                       WHERE  ph.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                         AND  ph.vendor_site_id = pvs.vendor_site_id
                         AND  ph.vendor_id = pn_vendor_id)
      AND  NOT EXISTS (SELECT 'x'           -- le site fournisseur n'est présent dans aucune facture
                       FROM   ap_invoices_all ai
                       WHERE  ai.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                         AND  ai.vendor_site_id = pvs.vendor_site_id
                         AND  ai.vendor_id = pn_vendor_id)
      AND  NOT EXISTS (SELECT 'x'           -- le site fournisseur n'est présent dans aucun réglement
                       FROM   ap_checks_all ac
                       WHERE  ac.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                         AND  ac.vendor_site_id = pvs.vendor_site_id
                         AND  ac.vendor_id = pn_vendor_id);
      --and pvs.vendor_site_id = 192799						 ;    
  BEGIN
    dka_tools_pkg.put_log_message('Début du traitement de désactivation des sites fournisseurs jamais utilisés');
    
	vn_api_version      := 1.0;
	vv_init_msg_list    := FND_API.G_TRUE;
	vv_commit           := FND_API.G_FALSE;
	vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
	vv_return_status    := NULL;
	vn_msg_count        := NULL;
	vv_msg_data         := NULL;
	vn_vendor_site_id   := NULL;
	vv_message          := NULL;
	
    FOR l IN c_fournisseur LOOP      
		--- 23/08/2016 JPE MIGRATION R12 Mise en place du curseur c_fourn_a_desac et MAJ avec l'api standard ap_vendor_pub_pkg.update_Vendor_Site
		FOR m IN c_fourn_a_desac(l.vendor_id, pn_org_ope, fnd_date.canonical_to_date(pd_date)) LOOP
		    vr_vendor_site_rec.inactive_date	:= SYSDATE;
			vn_vendor_site_id := m.vendor_site_id;
			
			dka_tools_pkg.put_log_message('Désactivation du site fournisseur : '|| m.vendor_site_id || ' du fournisseur : ' || l.vendor_id);      
			-- désactivation des sites jamais utilisés    
			ap_vendor_pub_pkg.update_Vendor_Site (  vn_api_version,
													vv_init_msg_list,
													vv_commit,
													vn_validation_level,
													vv_return_status,
													vn_msg_count,
													vv_msg_data,
													vr_vendor_site_rec,
													vn_vendor_site_id,
													vv_calling_prog
												  );
			IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              vn_cpt :=  vn_cpt +	1;
            ELSE
				vv_message := '';
				IF vn_msg_count > 0 THEN

					FOR v_index IN 1 .. vn_msg_count LOOP
					  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
					  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
					END LOOP;

				END IF;            
				RAISE e_error;             
            END IF;
		END LOOP;								   
    END LOOP;
    Fnd_File.put_line (Fnd_File.output, vn_cpt || ' sites fournisseurs jamais utilisés désactivés');                                                 
    dka_tools_pkg.put_log_message(vn_cpt || ' sites fournisseurs jamais utilisés désactivés');
    
    pn_retcode := 0;
    pv_errbuf := '';
    
  EXCEPTION
    WHEN e_error THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM;
      dka_tools_pkg.put_log_message('Erreur de l''api standard lors de la désactivation des sites fournisseurs jamais utilisés');
      dka_tools_pkg.put_log_message(vv_message);
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM;
      dka_tools_pkg.put_log_message('Erreur lors de la désactivation des sites fournisseurs jamais utilisés');
      dka_tools_pkg.put_log_message(SQLERRM);
  END main_1;
  /*============================================================================*/
  -- Procedure         : writeout
  -- Description       : Ecriture dans fichier *.OUT
  -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
  -- Parametres sortie : AUCUN
  -- Auteur            : Saloua HA 
  -- Date              : 23/07/2020
  -- Remarques         :
/*============================================================================*/
 PROCEDURE writeout(P_message IN VARCHAR2) IS
  L_procedure VARCHAR2(30) := 'writeout';
  v_etape     VARCHAR2(100);
  
  BEGIN
  FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);

  
  END writeout;
 /*============================================================================*/
  -- Procedure         : get_UO
  -- Description       : 
  -- Parametres entree : p_org_id
  -- Parametres sortie : uo
  -- Auteur            : Saloua HA 
  -- Date              : 23/07/2020
  -- Remarques         :
/*============================================================================*/
 FUNCTION get_UO (p_org_id IN number) RETURN VARCHAR2 IS
  UO  hr_operating_units.name%type;
  BEGIN
  select name into uo 
  from hr_operating_units 
  where organization_id = p_org_id;

  RETURN uo;
  END get_UO;            
------------------------------------------------------------------------------------
--  Nom           : main_2
--  Description   : désactivation des sites fournisseurs d'achats ou de finances plus utilisés et dont le 
--                  solde SLA est à 0
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--      pn_org_ope      organisation opérationnelle
--      pd_date_achat   date d''achat
--		pd_date_finance date de finance

--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_2(pv_errbuf   OUT VARCHAR2,
                   pn_retcode  OUT NUMBER,
                   pn_org_ope  IN  NUMBER,
                   pn_ssmvt_mois IN VARCHAR2)--SHA
                   --pd_date_achat     IN  VARCHAR2,
                   --pd_date_finance IN  VARCHAR2)
  IS
     
    
    e_error EXCEPTION;
    g_request_id           NUMBER        := fnd_global.conc_request_id; 
    vv_period_name        VARCHAR2(10);
    vv_date_reference     varchar2(200);
    vn_cpt                PLS_INTEGER := 0;
    vn_cpt_err            PLS_INTEGER := 0;
    vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
    vv_ssmvt_mois          VARCHAR2(200);
    --API
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2(200);
    vv_commit             VARCHAR2(200);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2(200);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2(200);
    vn_msg_index_out      NUMBER;
    vv_calling_prog       VARCHAR2(200);
    vv_message            VARCHAR2(500);
    
    vn_solde              NUMBER;
    
/*    CURSOR c_fournisseur IS
     SELECT pv.vendor_id
      FROM   po_vendors pv
      WHERE  
        pv.attribute3 != 'Y'
        AND  pv.vendor_type_lookup_code = 'VENDOR' -- le site fournisseur correspond à un fournisseur de type TIERS
        ;
*/  
/*CURSOR c_fourn_a_desac_achat(pn_vendor_id number, pn_org_id number, pd_datecur date, pn_period_name varchar2) IS
      SELECT  pvs.vendor_site_id  
      FROM 	  po_vendor_sites_all pvs,
	          po_vendors pv
	  WHERE	  pvs.org_id = nvl(pn_org_id,pvs.org_id)   -- uniquement pour l'unité opérationnelle considérée
        AND   pvs.creation_date < pd_datecur      -- le site fournisseur a été créé avant cette date
        AND  (   pvs.inactive_date IS NULL
             OR pvs.inactive_date > SYSDATE) -- le site fournisseur est actif
        AND pvs.vendor_id = pn_vendor_id
		AND pv.vendor_id = pn_vendor_id
		AND  NOT EXISTS ( SELECT 'x'          -- aucune date de création de demande d'achat n'est supérieure à la date donnée
                         FROM   po_requisition_lines_all prl
                         WHERE  prl.org_id = pvs.org_id -- pour l'unité opérationnelle consdérée
                           AND  prl.vendor_site_id = pvs.vendor_site_id
                           AND  prl.creation_date > pd_datecur)
        AND  NOT EXISTS (SELECT 'x'           -- aucune date de création de commande n'est supérieure à la date donnée
                         FROM   po_headers_all ph
                         WHERE  ph.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                           AND  ph.vendor_site_id = pvs.vendor_site_id
                           AND  ph.vendor_id = pn_vendor_id
                           AND  ph.creation_date > pd_datecur)
						   -- SELO
        AND  0 = nvl((select sum(nvl(BEGINNING_BALANCE_DR,0)+nvl(PERIOD_BALANCE_DR,0) - nvl(BEGINNING_BALANCE_CR,0)+nvl(PERIOD_BALANCE_CR,0))
					   from xLA_CONTROL_BALANCES xcb
					  where 1=1
					  --and effective_period_num = '20180002'
						--and xcb.party_site_id=11326
						and pvs.vendor_site_id = xcb.party_site_id
						and pv.vendor_id = xcb.party_id
						and xcb.period_name = pn_period_name
						and xcb.ledger_id=(select hou.set_of_books_id
                                        	 from hr_operating_units hou
										    where hou.organization_id=nvl(pn_org_id,pvs.org_id))),0)
		and	pvs.org_id in (select organization_id from hr_operating_units where name <> 'REF9999')
		and pvs.purchasing_site_flag = 'Y'
							   ;
*/
    CURSOR c_fourn_a_desac_reglement(pn_org_id number, pd_datecur date, pn_period_name varchar2) IS
      SELECT  pvs.vendor_site_id,
              pvs.vendor_id,
              pv.segment1,
              pv.vendor_name ,
              pvs.vendor_site_code ,
              pvs.org_id
      FROM    po_vendor_sites_all pvs,
              po_vendors pv
      WHERE   pvs.org_id = nvl(pn_org_id,pvs.org_id)   -- uniquement pour l'unité opérationnelle considérée
      AND     pvs.org_id != (select organization_id from hr_operating_units where name = 'REF9999')
      AND     pv.vendor_id = pvs.vendor_id
      AND     pvs.creation_date < pd_datecur      -- le site fournisseur a été créé avant cette date
      AND    (   pvs.inactive_date IS NULL
              OR pvs.inactive_date > SYSDATE) -- le site fournisseur est actif
        --AND pvs.vendor_id = pn_vendor_id
        --AND pv.vendor_id = pn_vendor_id
        -- SELO
        /*AND  NOT EXISTS ( SELECT 'x'          -- aucune date de création de demande d'achat n'est supérieure à la date donnée
                         FROM   po_requisition_lines_all prl
                         WHERE  prl.org_id = pvs.org_id -- pour l'unité opérationnelle consdérée
                           AND  prl.vendor_site_id = pvs.vendor_site_id
                           AND  prl.creation_date > pd_datecur)
        AND  NOT EXISTS (SELECT 'x'           -- aucune date de création de commande n'est supérieure à la date donnée
                         FROM   po_headers_all ph
                         WHERE  ph.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                           AND  ph.vendor_site_id = pvs.vendor_site_id
                           AND  ph.vendor_id = pn_vendor_id
                           AND  ph.creation_date > pd_datecur) -- SELO
        */
        -- SELO
        AND  NOT EXISTS (SELECT 'x'           -- aucune date de création de facture n'est supérieure à la date donnée
                         FROM   ap_invoices_all ai
                         WHERE  ai.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                           AND  ai.vendor_site_id = pvs.vendor_site_id
                           AND  ai.creation_date > pd_datecur)
        AND  NOT EXISTS (SELECT 'x'           -- aucune date de réglement réglement n'est supérieure à la date donnée --SELO
                         FROM   ap_checks_all ac
                         WHERE  ac.org_id = pvs.org_id  -- pour l'unité opérationnelle considérée
                           AND  ac.vendor_site_id = pvs.vendor_site_id
                           --AND  ac.vendor_id = pn_vendor_id
                           AND  ac.creation_date > pd_datecur)
        -- SELO
        /*AND  0 = nvl((SELECT SUM(ab.end_balance_dr - ab.end_balance_cr) -- uniquement dont le solde ax est 0
                     FROM   ax_balances ab
                     WHERE  ab.third_party_id = pn_vendor_id
                       AND  ab.sub_id = pvs.vendor_site_id
                       AND  period_name = pn_period_name
                     GROUP  BY ab.third_party_id,
                               ab.sub_id),0)*/
         /*AND  0 = nvl((select sum(nvl(BEGINNING_BALANCE_DR,0)+nvl(PERIOD_BALANCE_DR,0) - nvl(BEGINNING_BALANCE_CR,0)+nvl(PERIOD_BALANCE_CR,0))
                         from xLA_CONTROL_BALANCES xcb
                         where 1=1
                         --and effective_period_num = '20180002'
                         --and xcb.party_site_id=11326
                         and pvs.vendor_site_id = xcb.party_site_id
                         and pv.vendor_id = xcb.party_id
                         and xcb.period_name = pn_period_name
                         and xcb.ledger_id=(select hou.set_of_books_id
                                            from hr_operating_units hou
                                            where hou.organization_id=nvl(pn_org_id,pvs.org_id))),0)
         */
        AND pvs.pay_site_flag = 'Y'
        AND pv.attribute3 != 'Y' -- RG07
        AND nvl(pv.vendor_type_lookup_code,'*') not in ('FACTOR','EMPLOYEE') 
        -- RG07
		;
	

    CURSOR c_site_ref_a_desac IS
      SELECT  pvs.vendor_site_id  ,
              pvs.vendor_id,
              pv.segment1 ,
              pv.vendor_name ,
              pvs.vendor_site_code ,
              pvs.org_id
      FROM    po_vendor_sites_all pvs,
              po_vendors pv
      WHERE   pvs.vendor_id = pv.vendor_id
      AND     pvs.org_id = (select organization_id from hr_operating_units where name = 'REF9999')
      AND    (pvs.inactive_date IS NULL OR pvs.inactive_date > SYSDATE) -- le site fournisseur est actif 	  
      AND     pvs.purchasing_site_flag = 'N'
      AND     pvs.pay_site_flag = 'N'
      AND     pvs.ATTRIBUTE2 ='INACTIF'
      ;
	 
    CURSOR c_site_ref_desac_reglement IS
       SELECT  pvs.vendor_site_id  ,
               pvs.vendor_id,
               pv.segment1 ,
               pv.vendor_name ,
               pvs.vendor_site_code ,
               pvs.org_id
      FROM     po_vendor_sites_all pvs,
               po_vendors pv
      WHERE    pvs.vendor_id = pv.vendor_id
      AND      pvs.org_id = (select organization_id from hr_operating_units where name = 'REF9999')
      AND    (   pvs.inactive_date IS NULL OR pvs.inactive_date > SYSDATE) -- le site fournisseur est actif 	  
      AND NOT EXISTS (SELECT 'x'
                      FROM  po_vendor_sites_all vs
                      WHERE PAY_SITE_FLAG = 'Y'
                      AND   vs.vendor_id = pvs.vendor_id
                      AND   vs.org_id != (select organization_id from hr_operating_units where name = 'REF9999')
                      AND  (vs.inactive_date IS NULL
                                OR vs.inactive_date > SYSDATE)
                      AND vs.location_id = pvs.location_id)
      -- pour exclure les nouveaux sites de référence non encore dupliqués
      AND EXISTS (SELECT 'x'
                  FROM  po_vendor_sites_all vs
                  WHERE vs.vendor_id = pvs.vendor_id
                  AND   vs.org_id in (select organization_id from hr_operating_units where name <> 'REF9999')
                  AND   vs.location_id = pvs.location_id)
      AND pvs.pay_site_flag = 'Y'
	;
	    
  BEGIN
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout(' COMPTE-RENDU DU TRAITEMENT « DKA : Désactivation des sites fournisseurs avec un solde à 0  » ');
    writeout(' Traitement n° '||TO_CHAR(g_request_id));
    writeout(' Le  : '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout('                                                                ');
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' Paramètres');
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' Unité opérationnelle               :  '||pn_org_ope);
    writeout(' Sans mouvement depuis XX mois      :  '||pn_ssmvt_mois);
    writeout('--------------------------------------------------------------------------------------------');
	
	
   -- dka_tools_pkg.put_log_message('Début de désactivation des sites d''achat fournisseurs plus utilisés et dont le solde SLA est à 0');
    
	-- vn_api_version      := 1.0;
	-- vv_init_msg_list    := FND_API.G_TRUE;
	-- vv_commit           := FND_API.G_FALSE;
	-- vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
	-- vv_return_status    := NULL;
	-- vn_msg_count        := NULL;
	-- vv_msg_data         := NULL;
	-- vn_vendor_site_id   := NULL;
	-- vv_message          := NULL;
    -- récupération de la dernière période ouverte sur AP
	--DEBUT SHA
    BEGIN
	
        SELECT  fpov.profile_option_value
        into vv_ssmvt_mois
        FROM FND_PROFILE_OPTIONS_VL fpovl,
             FND_PROFILE_OPTION_VALUES fpov
        WHERE fpovl.profile_option_id = fpov.profile_option_id
        and START_DATE_ACTIVE <= SYSDATE 
        and NVL(END_DATE_ACTIVE,SYSDATE) >= SYSDATE 
        and ( SITE_ENABLED_FLAG = 'Y' or APP_ENABLED_FLAG = 'Y' or RESP_ENABLED_FLAG = 'Y' or USER_ENABLED_FLAG = 'Y' or SERVER_ENABLED_FLAG = 'Y' or SERVERRESP_ENABLED_FLAG = 'Y' or ORG_ENABLED_FLAG = 'Y') and ( UPPER(USER_PROFILE_OPTION_NAME) = 'DKA : NOMBRE DE MOIS MINIMUM POUR DÉSACTIVATION DES SITES FOURNISSEURS' and 
        (USER_PROFILE_OPTION_NAME LIKE 'dk%' or USER_PROFILE_OPTION_NAME LIKE 'dK%' or USER_PROFILE_OPTION_NAME LIKE 'Dk%' or USER_PROFILE_OPTION_NAME LIKE 'DK%')) order by user_profile_option_name;
    EXCEPTION
    WHEN others THEN
           vv_ssmvt_mois := null;
    END;
    
    IF pn_ssmvt_mois  <  vv_ssmvt_mois 
    THEN
       writeout('La valeur minimum pour le paramètre Sans mouvement depuis XX mois est :' ||vv_ssmvt_mois );
       pn_retcode := 1;
       
    ELSE 
       vv_date_reference := ADD_MONTHS(SYSDATE , - pn_ssmvt_mois  );

    --FIN SHA 	

      BEGIN
        SELECT period_name
        INTO   vv_period_name
        FROM   (SELECT   gps.period_name
                FROM     gl_period_statuses gps,
                         fnd_application fa
                WHERE    gps.application_id = fa.application_id
                  AND    fa.application_short_name = 'SQLAP' -- pour l'application AP
                  --AND    gps.set_of_books_id = fnd_profile.value('GL_SET_OF_BKS_ID')
                  AND    gps.adjustment_period_flag = 'N' -- pas une période d'ajustement
                  AND    gps.closing_status = 'O' -- période ouverte
                  -- ADR 23/05/08 AND    gps.end_date <= nvl(SYSDATE, gps.end_date)
                  AND    gps.end_date >= TRUNC(SYSDATE)
                ORDER BY gps.end_date DESC)
        WHERE rownum = 1;
      EXCEPTION
      WHEN no_data_found THEN
        dka_tools_pkg.put_log_message('Erreur : auncune période ouverte trouvée pour AP');
        dka_tools_pkg.put_log_message(SQLERRM);
        RAISE e_main;
      WHEN OTHERS THEN
        dka_tools_pkg.put_log_message('Erreur : impossible de récupérer une période ouverte pour AP');
        dka_tools_pkg.put_log_message(SQLERRM);
        RAISE e_main;
      END;
    
   /* FOR l IN c_fournisseur LOOP		   
		--- 23/08/2016 JPE MIGRATION R12 Mise en place du curseur c_fourn_a_desac et MAJ avec l'api standard ap_vendor_pub_pkg.update_Vendor_Site
		FOR m IN c_fourn_a_desac_achat(l.vendor_id, pn_org_ope, fnd_date.canonical_to_date(vv_date_reference), vv_period_name) LOOP
			
			dka_tools_pkg.put_log_message('Désactivation du flag SITE D''ACHAT du site fournisseur : '|| m.vendor_site_id || ' du fournisseur : ' || l.vendor_id);      
			
			--vr_vendor_site_rec.inactive_date	:= SYSDATE; --SELO
			vr_vendor_site_rec.purchasing_site_flag	:= 'N';
			vn_vendor_site_id := m.vendor_site_id;
			-- désactivation des sites jamais utilisés    
			ap_vendor_pub_pkg.update_Vendor_Site (  vn_api_version,
													vv_init_msg_list,
													vv_commit,
													vn_validation_level,
													vv_return_status,
													vn_msg_count,
													vv_msg_data,
													vr_vendor_site_rec,
													vn_vendor_site_id,
													vv_calling_prog
												  );
			IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              vn_cpt :=  vn_cpt +	1;
            ELSE
				vv_message := '';
				IF vn_msg_count > 0 THEN

					FOR v_index IN 1 .. vn_msg_count LOOP
					  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
					  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
					END LOOP;

				END IF;            
				RAISE e_error;             
            END IF;
		END LOOP;								   
    END LOOP;                                                   
                                                      
	Fnd_File.put_line (Fnd_File.output, vn_cpt || ' sites d''achat fournisseurs désactivés');  												  
    dka_tools_pkg.put_log_message(vn_cpt || ' sites d''achat fournisseurs désactivés');
    */
       writeout('                                                                ');
       writeout('--------------------------------------------------------------------------------------------');
       writeout(' Sites pour lesquels la fonction de règlement a été désactivée dans les UO  ');
       writeout('--------------------------------------------------------------------------------------------');
       writeout('Numéro Fournisseur / Nom Fournisseur / Nom du site / UO : ');
       pn_retcode := 0;
       pv_errbuf := '';
       vn_api_version      := 1.0;
       vv_init_msg_list    := FND_API.G_TRUE;
       vv_commit           := FND_API.G_FALSE;
       vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
       vv_return_status    := NULL;
       vn_msg_count        := NULL;
       vv_msg_data         := NULL;
       vn_vendor_site_id   := NULL;
       vv_message          := NULL;
       vn_cpt              := 0;	
       vn_cpt_err          := 0;
       dka_tools_pkg.put_log_message('Début de désactivation des sites de reglements fournisseurs plus utilisés et dont le solde SLA est à 0');
       --FOR l IN c_fournisseur LOOP    
       --- 23/08/2016 JPE MIGRATION R12 Mise en place du curseur c_fourn_a_desac et MAJ avec l'api standard ap_vendor_pub_pkg.update_Vendor_Site
       FOR m IN c_fourn_a_desac_reglement( pn_org_ope, vv_date_reference, vv_period_name) LOOP
          
          dka_tools_pkg.put_log_message('Traitement du site id : '|| m.vendor_site_id || ' du fournisseur id : ' || m.vendor_id);      
    
          --Controle du solde
          SELECT nvl(sum(nvl(BEGINNING_BALANCE_DR,0)+nvl(PERIOD_BALANCE_DR,0) - nvl(BEGINNING_BALANCE_CR,0)+nvl(PERIOD_BALANCE_CR,0)),0)
          INTO vn_solde
          FROM xLA_CONTROL_BALANCES xcb
          WHERE 1=1
          AND xcb.party_site_id = m.vendor_site_id
          AND xcb.party_id = m.vendor_id 
          AND xcb.period_name = vv_period_name
          AND xcb.ledger_id=(SELECT hou.set_of_books_id
                             FROM hr_operating_units hou
                             WHERE hou.organization_id=m.org_id);
          dka_tools_pkg.put_log_message('Solde : '||vn_solde);
          
          IF vn_solde = 0
          THEN 
             --vr_vendor_site_rec.inactive_date	:= SYSDATE; --SELO
             vr_vendor_site_rec.pay_site_flag	:= 'N';
             vn_vendor_site_id := m.vendor_site_id;
             -- désactivation des sites jamais utilisés    
             ap_vendor_pub_pkg.update_Vendor_Site (  vn_api_version,
                                                     vv_init_msg_list,
                                                     vv_commit,
                                                     vn_validation_level,
                                                     vv_return_status,
                                                     vn_msg_count,
                                                     vv_msg_data,
                                                     vr_vendor_site_rec,
                                                     vn_vendor_site_id,
                                                     vv_calling_prog
                                                    );
             IF vv_return_status = FND_API.G_RET_STS_SUCCESS 
             THEN
                --On continue
                vn_cpt :=  vn_cpt +	1;
                writeout(m.segment1||' / '||m.vendor_name||' / '||m.vendor_site_code||' / '||get_UO(m.org_id));
             ELSE
                vv_message := '';
                IF vn_msg_count > 0 THEN

                     FOR v_index IN 1 .. vn_msg_count LOOP
                        fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                        vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
                     END LOOP;

                 END IF;            
                 --RAISE e_error;             
                 dka_tools_pkg.put_log_message('Traitement KO - Erreur API : '||vv_message);
                 vn_cpt_err :=  vn_cpt_err +	1;
              END IF;
          END IF;
       END LOOP;								   
     --END LOOP;                                         
                                                      
      --Fnd_File.put_line (Fnd_File.output, vn_cpt || ' sites de règlements fournisseurs désactivés');  													  
       dka_tools_pkg.put_log_message(vn_cpt || ' sites fournisseurs désactivés en règlement sur les UO');


      
       vn_api_version      := 1.0;
       vv_init_msg_list    := FND_API.G_TRUE;
       vv_commit           := FND_API.G_FALSE;
       vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
       vv_return_status    := NULL;
       vn_msg_count        := NULL;
       vv_msg_data         := NULL;
       vn_vendor_site_id   := NULL;
       vv_message          := NULL;
       vn_cpt              := 0;
       dka_tools_pkg.put_log_message('Début de désactivation de la fonction règlement sur les sites de la référence');
       writeout('--------------------------------------------------------------------------------------------');
       writeout(' Sites pour lesquels la fonction de règlement a été désactivée dans l''UO de référence   ');
       writeout('--------------------------------------------------------------------------------------------');
       writeout('Numéro Fournisseur / Nom Fournisseur / Nom du site / UO : ');   

       FOR m IN c_site_ref_desac_reglement 
       LOOP

          vr_vendor_site_rec.pay_site_flag := 'N';
          vn_vendor_site_id := m.vendor_site_id;
			
          dka_tools_pkg.put_log_message('Désactivation fonction règlement du site fournisseur : '|| m.vendor_site_id || ' du fournisseur : ' || m.vendor_id);      
          -- désactivation des sites jamais utilisés    
          ap_vendor_pub_pkg.update_Vendor_Site (vn_api_version,
                                                vv_init_msg_list,
                                                vv_commit,
                                                vn_validation_level,
                                                vv_return_status,
                                                vn_msg_count,
                                                vv_msg_data,
                                                vr_vendor_site_rec,
                                                vn_vendor_site_id,
                                                vv_calling_prog
                                                 );
          IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              vn_cpt :=  vn_cpt +	1;
              writeout(m.segment1||' / '||m.vendor_name||' / '||m.vendor_site_code||' / '||get_UO(m.org_id));
          ELSE
              vv_message := '';
             IF vn_msg_count > 0 THEN

                 FOR v_index IN 1 .. vn_msg_count LOOP
                    fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                     vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
                 END LOOP;

             END IF;            
               --RAISE e_error;             
               dka_tools_pkg.put_log_message('Traitement KO - Erreur API : '||vv_message);
               vn_cpt_err :=  vn_cpt_err +	1; 
          END IF;
    
       END LOOP;								   

    
       --Fnd_File.put_line (Fnd_File.output, vn_cpt || ' sites fournisseurs désactivés');	
       dka_tools_pkg.put_log_message(vn_cpt || ' sites fournisseurs désactivés en règlement sur la référence');


       vn_api_version      := 1.0;
       vv_init_msg_list    := FND_API.G_TRUE;
       vv_commit           := FND_API.G_FALSE;
       vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
       vv_return_status    := NULL;
       vn_msg_count        := NULL;
       vv_msg_data         := NULL;
       vn_vendor_site_id   := NULL;
       vv_message          := NULL;
       vn_cpt              := 0;
       dka_tools_pkg.put_log_message('Début de désactivation des sites fournisseurs qui ne sont ni site d''achats, ni site de règlements.');
       writeout('--------------------------------------------------------------------------------------------');
       writeout(' Sites désactivés dans l''UO de référence    ');
       writeout('--------------------------------------------------------------------------------------------');
       writeout('Numéro Fournisseur / Nom Fournisseur / Nom du site / UO : '); 

       FOR m IN c_site_ref_a_desac 
       LOOP

          vr_vendor_site_rec.inactive_date	:= SYSDATE;
          vn_vendor_site_id := m.vendor_site_id;

          dka_tools_pkg.put_log_message('Désactivation du site fournisseur : '|| m.vendor_site_id || ' du fournisseur : ' || m.vendor_id);      
          -- désactivation des sites jamais utilisés    
          ap_vendor_pub_pkg.update_Vendor_Site (vn_api_version,
                                                vv_init_msg_list,
                                                vv_commit,
                                                vn_validation_level,
                                                vv_return_status,
                                                vn_msg_count,
                                                vv_msg_data,
                                                vr_vendor_site_rec,
                                                vn_vendor_site_id,
                                                vv_calling_prog
                                               );
          IF vv_return_status = FND_API.G_RET_STS_SUCCESS 
          THEN
              --On continue
              vn_cpt :=  vn_cpt +	1;
              writeout(m.segment1||' / '||m.vendor_name||' / '||m.vendor_site_code||' / '||get_UO(m.org_id));
          ELSE
              vv_message := '';
              IF vn_msg_count > 0 THEN

                  FOR v_index IN 1 .. vn_msg_count LOOP
                     fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                     vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
                  END LOOP;

              END IF;            
              --RAISE e_error;
              dka_tools_pkg.put_log_message('Traitement KO - Erreur API : '||vv_message);
              vn_cpt_err :=  vn_cpt_err +	1;             
          END IF;

       END LOOP;								   

       IF vn_cpt_err != 0
       THEN
           pn_retcode := 1;
           pv_errbuf := 'Il y a eu des erreurs lors de la désactivation des sites. Voir le détail dans le log.';
           dka_tools_pkg.put_log_message('Nombre de sites en erreur lors de la désactivation : '||vn_cpt_err);
       END IF;
       
    END IF;
    
    
    
    
	--Fnd_File.put_line (Fnd_File.output, vn_cpt || ' sites fournisseurs désactivés');	
    dka_tools_pkg.put_log_message(vn_cpt || ' sites fournisseurs désactivés');
    writeout('                                                                ');
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
  EXCEPTION 
    WHEN e_error THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM;
      dka_tools_pkg.put_log_message('Erreur de l''api standard lors de la désactivation des sites d''achat ou des sites de reglements ou des sites fournisseurs plus utilisés et dont le solde SLA est à 0');
      dka_tools_pkg.put_log_message(vv_message);
	writeout('                                                                ');
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
    WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM;
      dka_tools_pkg.put_log_message('Erreur lors de la désactivation des sites d''achat ou des sites de reglements ou des sites fournisseurs plus utilisés et dont le solde SLA est à 0');
      dka_tools_pkg.put_log_message(SQLERRM);
	writeout('                                                                ');
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
  END main_2;
                   
------------------------------------------------------------------------------------
--  Nom           : main_3
--  Description   : désactivation des entêtes fournisseurs qui n'ont plus de sites 
--                  actifs
--
--  PARAMETRES    :
--      pv_errbuf       message d'erreur
--      pn_retcode      code de retour
--  VALEUR RETOURNEE :
--     Valeurs possibles : 0: deroulement correct
--                         2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_3(pv_errbuf   OUT VARCHAR2,
                   pn_retcode  OUT NUMBER)
  IS
    e_error EXCEPTION;
    g_request_id           NUMBER        := fnd_global.conc_request_id; 
    vn_cpt             	  PLS_INTEGER := 0;
    vr_vendor_rec    	  ap_vendor_pub_pkg.r_vendor_rec_type;
    vn_vendor_id    	  NUMBER;
    
	--API
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2(200);
    vv_commit             VARCHAR2(2000);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2(2000);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2(2000);
    vn_msg_index_out      NUMBER;
    vv_calling_prog       VARCHAR2(2000);
    vv_message  		  VARCHAR2(5000);
	

    vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
    
	

/*    CURSOR c_site_a_desac IS	
    SELECT vs.vendor_site_id  
      FROM po_vendor_sites_all vs 
     WHERE vs.org_id = (SELECT organization_id FROM hr_operating_units WHERE name = 'REF9999')
       AND (vs.inactive_date IS NULL
            OR vs.inactive_date > SYSDATE)
       AND NOT EXISTS (SELECT 'x'
                         FROM  po_vendor_sites_all pvs
                         WHERE  vs.vendor_id = pvs.vendor_id
                         AND  pvs.org_id in (select organization_id from hr_operating_units where name <> 'REF9999')
                          AND  (pvs.inactive_date IS NULL
                                OR pvs.inactive_date > SYSDATE)
                          --and pvs.vendor_site_code = vs.vendor_site_code
                          AND pvs.location_id = vs.location_id)
     -- and vs.vendor_site_id in (624001, 624006)
						  ;
*/              
   						  
    CURSOR c_entete_a_desac IS
      SELECT pv.vendor_id ,
             pv.segment1 ,
             pv.vendor_name
      FROM   po_vendors pv
      WHERE --pv.vendor_type_lookup_code = 'VENDOR' -- pour un fournisseur de type TIERS
      -- dmd 24/09/08
      -- AND pv.attribute3 != 'Y'
      -- DMD 24/09/08
      --AND  
           (pv.end_date_active IS NULL OR pv.end_date_active > SYSDATE) -- on ne considère que les fournisseurs actifs  
      AND  NOT EXISTS (SELECT 'x'
                       FROM   po_vendor_sites_all pvs
                       WHERE  pv.vendor_id = pvs.vendor_id
					            -- AND  pvs.org_id = (select organization_id from hr_operating_units where name = 'REF9999')
                         AND  (pvs.inactive_date IS NULL
                               OR pvs.inactive_date > SYSDATE))
	/*AND EXISTS (SELECT 'x'
                       FROM   po_vendor_sites_all pvs
                       WHERE  pv.vendor_id = pvs.vendor_id
					     AND  pvs.org_id = (select organization_id from hr_operating_units where name = 'REF9999')
                         )
						 */
    --AND pv.vendor_id = 210							   
       ;
  BEGIN
       /* vn_api_version      := 1.0;
		
		FOR m IN c_site_a_desac LOOP
		    vr_vendor_site_rec.inactive_date	:= SYSDATE;
			vn_vendor_site_id := m.vendor_site_id;
			
			dka_tools_pkg.put_log_message('Désactivation du site fournisseur : '|| m.vendor_site_id );      
			-- désactivation des sites jamais utilisés    
			ap_vendor_pub_pkg.update_Vendor_Site (  vn_api_version,
													vv_init_msg_list,
													vv_commit,
													vn_validation_level,
													vv_return_status,
													vn_msg_count,
													vv_msg_data,
													vr_vendor_site_rec,
													vn_vendor_site_id,
													vv_calling_prog
												  );
			IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              vn_cpt :=  vn_cpt +	1;
            ELSE
				vv_message := '';
				IF vn_msg_count > 0 THEN

					FOR v_index IN 1 .. vn_msg_count LOOP
					  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
					  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
					END LOOP;

				END IF;            
				RAISE e_error;             
            END IF;
		END LOOP;								   

    Fnd_File.put_line (Fnd_File.output, vn_cpt || ' site(s) fournisseur(s) jamais utilisé(s) désactivé(s)');	                                                
    dka_tools_pkg.put_log_message(vn_cpt || ' site(s) fournisseur(s) jamais utilisé(s) désactivé(s)');
    */
    pn_retcode := 0;
    pv_errbuf := '';
    vn_cpt := 0;
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout(' COMPTE-RENDU DU TRAITEMENT « DKA : Désactivation des entêtes fournisseurs  » ');
    writeout(' Traitement n° '||TO_CHAR(g_request_id));
    writeout(' Le  : '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout('                                                                ');
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' Liste des fournisseurs désactivés ');
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' Numéro Fournisseur / Nom Fournisseur ');  
    dka_tools_pkg.put_log_message('Début du traitement de désactivation des fournisseurs n''ayant plus aucun site actif sur l''OU de référence REF9999');
	
    vn_api_version      := 1.0;
    vv_init_msg_list    := FND_API.G_TRUE;
    vv_commit           := FND_API.G_FALSE;
    vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
    vv_return_status    := NULL;
    vn_msg_count        := NULL;
    vv_msg_data         := NULL;
	
    FOR l IN c_entete_a_desac LOOP
	
        -- désactivation des fournisseurs nayant plus aucun site actif, quelquesoit lorganisation
        dka_tools_pkg.put_log_message('Désactivation du fournisseur : '||l.vendor_id);
        
        vr_vendor_rec.END_DATE_ACTIVE  := SYSDATE;
        vn_vendor_id := l.vendor_id;					   
        ap_vendor_pub_pkg.update_vendor(vn_api_version,
                                            vv_init_msg_list,
                                            vv_commit,
                                            vn_validation_level,
                                            vv_return_status,
                                            vn_msg_count,
                                            vv_msg_data,
                                            vr_vendor_rec,
                                            vn_vendor_id
                                            ); 
        IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
          --On continue
          vn_cpt :=  vn_cpt + 1; 
          writeout(l.segment1||' / '||l.vendor_name); 
 
        ELSE
          vv_message := '';
          IF vn_msg_count > 0 THEN
			
            FOR v_index IN 1 .. vn_msg_count LOOP
               fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
               vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);
			  
            END LOOP;
		  
          END IF;
		
          RAISE e_error; 
		
        END IF;
    END LOOP;	
    --Fnd_File.put_line (Fnd_File.output, vn_cpt || ' fournisseur(s) désactivé(s)');
    dka_tools_pkg.put_log_message(vn_cpt || ' fournisseur(s) désactivé(s)');
    
    COMMIT;
    
    pn_retcode := 0;
    pv_errbuf := '';
    writeout('                                                                ');
    writeout('+--------------------------------------------------------------------------------------------+');
    writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('+--------------------------------------------------------------------------------------------+');
  EXCEPTION
    WHEN e_error THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM;
      dka_tools_pkg.put_log_message('Erreur de l''api standard lors de la désactivation des fournisseurs n''ayant plus aucun site actif');
      dka_tools_pkg.put_log_message(vv_message);
     writeout('+--------------------------------------------------------------------------------------------+');
     writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
     writeout('+--------------------------------------------------------------------------------------------+');
	WHEN OTHERS THEN
      pn_retcode := 2;
      pv_errbuf := SQLERRM;
      dka_tools_pkg.put_log_message('Erreur lors de la désactivation des fournisseurs n''ayant plus aucun site actif');
      dka_tools_pkg.put_log_message(SQLERRM);
	  writeout('+--------------------------------------------------------------------------------------------+');
      writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
      writeout('+--------------------------------------------------------------------------------------------+');
  END main_3;

 
  ------------------------------------------------------------------------------------
--  Nom           : main_4
--  Description   : Désactivation/réactivation d’un site de règlement fournisseur
--  Auteur        : Saloua HA 
--  PARAMETRES    :
--      pv_errbuf          message d'erreur
--      pn_retcode         code de retour
--      p_perimetre        Perimetre
--      p_fournisseur      Fournisseur
--      p_site_fournisseur Site fournisseur     
--      p_action           Action
--  VALEUR RETOURNEE :
--  Valeurs possibles : 0: deroulement correct
--                      2: deroulement avec erreur
------------------------------------------------------------------------------------
  PROCEDURE main_4(pv_errbuf          OUT VARCHAR2,
                   pn_retcode         OUT NUMBER,
				   p_perimetre        in VARCHAR2,
				   p_fournisseur      in varchar2,
				   p_site_fournisseur in varchar2,
				   p_action           in varchar2)
  IS
  
   g_request_id           NUMBER        := fnd_global.conc_request_id; 
   v_location_id          ap_supplier_sites_all.location_id%type;
 --API
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2(200);
    vv_commit             VARCHAR2(2000);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2(2000);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2(2000);
    vn_msg_index_out      NUMBER;
    vv_calling_prog       VARCHAR2(2000);
	vv_message  		  VARCHAR2(5000);
	vr_vendor_site_rec    ap_vendor_pub_pkg.r_vendor_site_rec_type;
    vn_vendor_site_id     NUMBER;
	vr_vendor_rec    	  ap_vendor_pub_pkg.r_vendor_rec_type;
    vn_vendor_id    	  NUMBER;
	v_vendor_site_id_ref  ap_supplier_sites_all.vendor_site_id%TYPE;
  v_inactive_date_ref   ap_supplier_sites_all.inactive_date%TYPE;
 ---CURSOR 
 CURSOR  C_UO(p_location_id NUMBER) is 
    SELECT  distinct hou.name uo
        ,hou.organization_id
     FROM
           ap_supplier_sites_all ass
          ,hr_operating_units hou
    WHERE   ass.org_id      = hou.organization_id
    AND     ass.location_id = p_location_id   
    AND     hou.name != 'REF9999'
	AND     hou.organization_id  IN (SELECT  ORGANIZATION_ID
                                     FROM PER_SECURITY_ORGANIZATIONS
                                     WHERE SECURITY_PROFILE_ID = (SELECT SECURITY_PROFILE_ID
                                                                  FROM PER_SECURITY_PROFILES
                                                                  WHERE SECURITY_PROFILE_NAME = 'DKA_TOUT')
							        )
    AND     p_perimetre ='ALL'
	
	UNION 
	SELECT  distinct hou.name uo
           ,hou.organization_id
     FROM
           ap_supplier_sites_all ass
          ,hr_operating_units hou
    WHERE   ass.org_id           = hou.organization_id
    AND     ass.location_id      = p_location_id   
    AND     hou.name            != 'REF9999'
    AND     substr(hou.name,1,3) = p_perimetre
	
	UNION 
	SELECT  distinct hou.name uo
           ,hou.organization_id
     FROM
           ap_supplier_sites_all ass
          ,hr_operating_units hou
    WHERE   ass.org_id      = hou.organization_id
    AND     hou.name != 'REF9999'
    AND     hou.name = p_perimetre
    ;

CURSOR c_site_frns( p_location_id     NUMBER
                   ,p_organization_id NUMBER)
   IS
    SELECT  assa.VENDOR_SITE_ID
           ,assa.INACTIVE_DATE
		   ,ass.END_DATE_ACTIVE 
		   ,assa.PAY_SITE_FLAG 
		   ,assa.vendor_id 
    FROM
           ap_supplier_sites_all assa
		   ,ap_suppliers ass
          ,hr_operating_units hou
    WHERE   assa.org_id          = hou.organization_id
	AND     ass.vendor_id        = assa.vendor_id 
    AND     assa.location_id     = p_location_id
    AND     hou.organization_id  = p_organization_id
   ;
BEGIN 
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' COMPTE-RENDU DU TRAITEMENT « DKA : Désactivation/réactivation d''un site de règlement fournisseur » ');
    writeout(' Traitement n° '||TO_CHAR(g_request_id));
    writeout(' Le  : '|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('--------------------------------------------------------------------------------------------');
    writeout('                                                                ');
	writeout('--------------------------------------------------------------------------------------------');
	writeout(' Paramètres de lancement ');
	writeout('--------------------------------------------------------------------------------------------');
	writeout(' Périmètre        :  '||p_perimetre);
	writeout(' Fournisseur      :  '||p_fournisseur);
	writeout(' Site Fournisseur :  '||p_site_fournisseur);
	writeout(' Action           :  '||p_action);
	writeout('--------------------------------------------------------------------------------------------');
	writeout('                                                                ');
	writeout('--------------------------------------------------------------------------------------------');
	writeout(' Compte-rendu des actions ');
	writeout('--------------------------------------------------------------------------------------------');
    BEGIN
        SELECT  location_id
        into    v_location_id 
        FROM
                   ap_supplier_sites_all assa
                  ,hr_operating_units hou
        		  ,ap_suppliers ass
        WHERE   assa.org_id      = hou.organization_id
        and     assa.vendor_site_code = p_site_fournisseur
        and     assa.vendor_id        = ass.vendor_id 
        and     ass.segment1         = p_fournisseur
        and rownum <2
		;
	END;
	
	vn_api_version      := 1.0;
	vv_init_msg_list    := FND_API.G_TRUE;
	vv_commit           := FND_API.G_FALSE;
	vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
	vv_return_status    := NULL;
	vn_msg_count        := NULL;
	vv_msg_data         := NULL;
	
	IF p_action ='Désactivation' THEN 
	    FOR rec_uo in C_UO (v_location_id)
		LOOP
			FOR rec_site_frns IN c_site_frns(v_location_id,rec_uo.organization_id) 
            LOOP
			    IF   rec_site_frns.PAY_SITE_FLAG = 'Y' THEN 
				    vr_vendor_site_rec.PAY_SITE_FLAG	:= 'N';
			        vn_vendor_site_id := rec_site_frns.vendor_site_id;
			        
			        dka_tools_pkg.put_log_message('Désactivation du site fournisseur : '|| rec_site_frns.vendor_site_id );      
			        -- désactivation des sites jamais utilisés    
			        ap_vendor_pub_pkg.update_Vendor_Site (  vn_api_version,
			        										vv_init_msg_list,
			        										vv_commit,
			        										vn_validation_level,
			        										vv_return_status,
			        										vn_msg_count,
			        										vv_msg_data,
			        										vr_vendor_site_rec,
			        										vn_vendor_site_id,
			        										vv_calling_prog
			        									  );
			        IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    writeout('['||p_fournisseur||'] / ['||p_site_fournisseur||'] / ['||rec_uo.uo||']: La désactivation de la fonction de règlement a été effectuée avec succès ');
  
                    ELSE
			        	vv_message := '';
			        	IF vn_msg_count > 0 THEN
			        
			        		FOR v_index IN 1 .. vn_msg_count LOOP
			        		  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
			        		  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
			        		END LOOP;
			        
			        	END IF;            
			        	dka_tools_pkg.put_log_message('Erreur de l''api standard lors de la désactivation de la fonction de règlement ');             
                    END IF;   
				ELSE 
				writeout('['||p_fournisseur||'] / ['||p_site_fournisseur||'] / ['||rec_uo.uo||'] : La désactivation de la fonction de règlement n''a pas été effectuée car la fonction de règlement n''est pas active pour ce site '	);
				END IF ;
				
		    END LOOP;
		END LOOP;
    
		
	END IF;
---------- Réactivation	
	IF p_action ='Réactivation' THEN 
	    FOR rec_uo in C_UO (v_location_id)
		LOOP
			FOR rec_site_frns IN c_site_frns(v_location_id,rec_uo.organization_id) 
            LOOP
			    IF   rec_site_frns.PAY_SITE_FLAG = 'N' THEN 
				    vr_vendor_site_rec.PAY_SITE_FLAG	:= 'Y';
					  vr_vendor_site_rec.INACTIVE_DATE 	:= NULL;
			      vn_vendor_site_id := rec_site_frns.vendor_site_id;
			        
			        dka_tools_pkg.put_log_message('Désactivation du site fournisseur : '|| rec_site_frns.vendor_site_id );      
			        -- désactivation des sites jamais utilisés    
			        ap_vendor_pub_pkg.update_Vendor_Site (  vn_api_version,
			        										vv_init_msg_list,
			        										vv_commit,
			        										vn_validation_level,
			        										vv_return_status,
			        										vn_msg_count,
			        										vv_msg_data,
			        										vr_vendor_site_rec,
			        										vn_vendor_site_id,
			        										vv_calling_prog
			        									  );
			        IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
                    writeout('['||p_fournisseur||'] / ['||p_site_fournisseur||'] / ['||rec_uo.uo||']: La Réactivation de la fonction de règlement a été effectuée avec succès ');
                update  ap_supplier_sites_all 
					      set    INACTIVE_DATE = NULL
                ,      last_update_date =sysdate
                ,      last_updated_by = g_user
					      where  vendor_site_id = vn_vendor_site_id
                ;
					
                    ELSE
			        	vv_message := '';
			        	IF vn_msg_count > 0 THEN
			        
			        		FOR v_index IN 1 .. vn_msg_count LOOP
			        		  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
			        		  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);				  
			        		END LOOP;
			        
			        	END IF;            
			        	dka_tools_pkg.put_log_message('Erreur de l''api standard lors de la Réactivation de la fonction de règlement ');            
                    END IF;
					
                IF  rec_site_frns.END_DATE_ACTIVE IS NOT NULL THEN 
                    vr_vendor_rec.END_DATE_ACTIVE  := NULL;
		            vn_vendor_id := rec_site_frns.vendor_id;					   
		            ap_vendor_pub_pkg.update_vendor(vn_api_version,
                                                    vv_init_msg_list,
                                                    vv_commit,
                                                    vn_validation_level,
                                                    vv_return_status,
                                                    vn_msg_count,
                                                    vv_msg_data,
                                                    vr_vendor_rec,
                                                    vn_vendor_id
                                                    ); 
		            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
		            update  ap_suppliers 
					      set    END_DATE_ACTIVE = NULL
                ,      last_update_date =sysdate
                ,      last_updated_by = g_user
					      where  vendor_id = vn_vendor_id;
					
		             
		            ELSE
		              vv_message := '';
		              IF vn_msg_count > 0 THEN
		            	
		            	FOR v_index IN 1 .. vn_msg_count LOOP
		            	  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
		            	  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);
		            	  
		            	END LOOP;
		              
		              END IF;
		            
		              dka_tools_pkg.put_log_message('Erreur de l''api standard lors de la Réactivation de la fonction de règlement ');   
		            
		            END IF;	
                END IF;

				ELSE 
				writeout('['||p_fournisseur||'] / ['||p_site_fournisseur||'] / ['||rec_uo.uo||'] : La Réactivation de la fonction de règlement n''a pas été effectuée car la fonction de règlement est déjà active pour ce site  '	);
				END IF ;
				COMMIT;
		    END LOOP;
		END LOOP;
    --DEBUT AAM 
    -- En cas de réactivation de la fonction de règlement, le traitement réactivera également si nécessaire : 
    --•	Le site associé dans l’unité opérationnelle de référence REF9999
    BEGIN
      SELECT vendor_site_id,inactive_date
      INTO v_vendor_site_id_ref  
      ,    v_inactive_date_ref   
      FROM ap_supplier_sites_all assa
      ,    hr_operating_units hou
      WHERE assa.org_id = hou.organization_id
      AND   hou.name    = 'REF9999'
      AND   location_id = v_location_id;
    EXCEPTION
      WHEN OTHERS   THEN
        v_vendor_site_id_ref := NULL;
        v_inactive_date_ref  := NULL;      
    END;
    
		IF v_inactive_date_ref IS NOT NULL THEN
      update  ap_supplier_sites_all
		  set    inactive_date = NULL
      ,      last_update_date =sysdate
      ,      last_updated_by = g_user
		  where  vendor_site_id = v_vendor_site_id_ref;
    END IF ;
    --FIN AAM 
	END IF;
	writeout('--------------------------------------------------------------------------------------------');
    writeout('                                                                ');
    writeout('--------------------------------------------------------------------------------------------');
    writeout(' Programme terminé le :'|| TO_CHAR(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    writeout('--------------------------------------------------------------------------------------------');

END main_4;

END DKA_SPOASS_FOURN_PKG;
/
SHOW ERRORS
EXIT;
