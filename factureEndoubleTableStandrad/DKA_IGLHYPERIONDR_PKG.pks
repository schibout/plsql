create or replace PACKAGE BODY DKA_FUSPOEXPCTRSSTR_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_FUSPOEXPCTRSSTR_PKG
  -- Description      : Body du package DKA_FUSPOEXPCTRSSTR_PKG
  -- Auteur           : S.HAHIOUI
  -- Date de création : 04/09/2019
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  --------------------------------------------------------------------------------
  -- 
  -- 
  --------------------------------------------------------------------------------  

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : p_errbuf         Sortie Message d'erreur
  --                    p_retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
   g_user_id                      fnd_user.user_id%TYPE;
  PROCEDURE Main(p_errbuf OUT VARCHAR2, p_retcode OUT NUMBER) 
  IS

    --Declarations des variables locales
    v_compteur_export_header        NUMBER;
    v_compteur_export_detail        NUMBER;
    v_compteur_export_imput         NUMBER;
    v_compteur_export_header_hist   NUMBER;
    v_compteur_export_detail_hist   NUMBER;
    v_compteur_export_imput_hist    NUMBER;
    v_count                         NUMBER := 0;
	v_RG_EXP01    INTEGER;  
	v_name         varchar2(150);
	v_document_num varchar2(150);

    -- Declaration des cursors
    -- Cursor pour entete des contrats
    CURSOR cur_contrat IS
    SELECT  distinct
           pha.po_header_id                         PO_HEADER_ID
          ,'ACTUEL'                                 DATA_TYPE
          ,pha.segment1                             DOCUMENT_NUM
          ,pha.type_lookup_code                     TYPE_LOOKUP_CODE
          ,papf.full_name                           AGENT_NAME
		  ,pv.vendor_name                           VENDOR_NAME
          ,pvs.vendor_site_code                     VENDOR_SITE_CODE
          ,hls.location_code                        SHIP_TO_LOCATION
          ,hlb.location_code                        BILL_TO_LOCATION
          ,apt.name                                 PAYMENT_TERMS
          ,pha.currency_code                        CURRENCY_CODE
          ,pha.rate_date                            RATE_DATE
          ,pha.start_date                           START_DATE             
          ,pha.end_date                             END_DATE
          ,pha.blanket_total_amount                 BLANKET_TOTAL_AMOUNT
          ,pha.authorization_status                 APPROVAL_STATUS
          ,pha.approved_flag                        APPROVED_FLAG
          ,pha.approved_date                        APPROVED_DATE
          ,pha.revision_num                         REVISION_NUM
          ,pha.revised_date                         REVISION_DATE
          ,pha.comments                             COMMENTS
          ,pha.attribute4                           ATTRIBUTE4
          ,pha.attribute5                           ATTRIBUTE5
          ,pha.attribute13                          ATTRIBUTE13
          ,pha.attribute14                          ATTRIBUTE14
          ,pha.attribute15                          ATTRIBUTE15
		  ,hrou.name                                UO_NAME
		  ,pha.org_id                               ORG_ID
		    
    FROM  po_headers_all              pha
         ,per_all_people_f            papf
         ,po_vendors                  PV
         ,po_vendor_sites_all         pvs
         ,hr_locations_all            hls
         ,hr_locations_all            hlb
         ,ap_terms                    apt
         ,dka_contrat_sstr_imputation dcsi 
		 ,HR_ORGANIZATION_UNITS       HROU
    WHERE 1=1
	and pha.org_id 					= hrou.ORGANIZATION_ID
    AND pha.type_lookup_code        = 'CONTRACT'
    AND pha.attribute4 IS NOT NULL
    AND NVL(pha.closed_code,'OPEN') = 'OPEN'
    AND NVL(pha.cancel_flag,'N')    = 'N'
	--AND authorization_status         = 'APPROVED' 
    AND pha.agent_id                = papf.person_id
    AND papf.CURRENT_EMPLOYEE_FLAG  = 'Y'
    AND pha.vendor_id               = pv.vendor_id
    AND pha.vendor_site_id          = pvs.vendor_site_id
    AND pha.ship_to_location_id     = hls.location_id
    AND pha.bill_to_location_id     = hlb.location_id
    AND pha.terms_id                = APt.term_id (+)
    AND dcsi.po_header_id           = pha.po_header_id
    AND dcsi.contrat_imputation_id  = ( SELECT MIN(contrat_imputation_id)
                                        FROM dka_contrat_sstr_imputation
                                        WHERE po_header_id = pha.po_header_id)
   
    AND 
          pha.org_id               in(
                                        SELECT
                                        HOU.organization_id
                                    FROM
                                        HR_ORGANIZATION_UNITS HOU,
                                        DKA_STRANSCO_LINES DSTL,
                                        DKA_STRANSCO_HEADERS DSTH
                                    WHERE
                                        DSTL.SET_ID = DSTH.SET_ID
                                        AND HOU.NAME = DSTL.PARAM1_VALUE
                                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                                        AND DSTL.ENABLE = 'Y'
                                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
                                        --AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
										)
			                         	 
    ;

    -- Cursor pour historique des entetes des contrats
    CURSOR cur_contrat_archi (p_po_header_id IN NUMBER) IS 
    SELECT  distinct 
			pha.po_header_id                        PO_HEADER_ID
          ,'HISTO'                                  DATA_TYPE
          ,pha.segment1                             DOCUMENT_NUM
          ,pha.type_lookup_code                     TYPE_LOOKUP_CODE
          ,papf.full_name                           AGENT_NAME
          ,pv.vendor_name                           VENDOR_NAME
          ,pvs.vendor_site_code                     VENDOR_SITE_CODE
          ,hls.location_code                        SHIP_TO_LOCATION
          ,hlb.location_code                        BILL_TO_LOCATION
          ,apt.name                                 PAYMENT_TERMS
          ,pha.currency_code                        CURRENCY_CODE
          ,pha.rate_date                            RATE_DATE
          ,pha.start_date                           START_DATE             
          ,pha.end_date                             END_DATE
          ,pha.blanket_total_amount                 BLANKET_TOTAL_AMOUNT
          ,pha.authorization_status                 APPROVAL_STATUS
          ,pha.approved_flag                        APPROVED_FLAG
          ,pha.approved_date                        APPROVED_DATE
          ,pha.revision_num                         REVISION_NUM
          ,pha.revised_date                         REVISION_DATE
          ,pha.comments                             COMMENTS
          ,pha.attribute4                           ATTRIBUTE4
          ,pha.attribute5                           ATTRIBUTE5
          ,pha.attribute13                          ATTRIBUTE13
          ,pha.attribute14                          ATTRIBUTE14
          ,pha.attribute15                          ATTRIBUTE15
          ,pha.LATEST_EXTERNAL_FLAG                 LATEST_EXTERNAL_FLAG --RBE artf2212570
		  ,hrou.name                                UO_NAME
		  ,pha.org_id                               ORG_ID
    FROM  po_headers_archive_all        			pha
         ,per_all_people_f              			papf
         ,po_vendors                    			pv
         ,po_vendor_sites_all           			pvs
         ,hr_locations_all              			hls
         ,hr_locations_all              			hlb
         ,ap_terms                      			apt
         ,dka_contrat_sstr_imputation   			dcsi
		 ,HR_ORGANIZATION_UNITS       				HROU
    WHERE 1=1
	and pha.org_id = hrou.ORGANIZATION_ID
    AND pha.agent_id                = papf.person_id
    AND papf.CURRENT_EMPLOYEE_FLAG  = 'Y'
    AND pha.vendor_id               = pv.vendor_id
    AND pha.vendor_site_id          = pvs.vendor_site_id(+)
    AND pha.ship_to_location_id     = hls.location_id
    AND pha.bill_to_location_id     = hlb.location_id
    AND pha.terms_id                = apt.term_id (+)
    AND dcsi.po_header_id           = pha.po_header_id
    AND dcsi.contrat_imputation_id  = ( SELECT MIN(contrat_imputation_id)
                                        FROM dka_contrat_sstr_imputation
                                        WHERE po_header_id = pha.po_header_id
                                      )
    AND pha.po_header_id            = p_po_header_id
	 ;


    -- Cursor pour detail des contrats
    CURSOR cur_contrat_detail (p_po_header_id IN NUMBER) IS 
    SELECT   distinct 'ACTUEL'                          DATA_TYPE
            ,pha.segment1                               DOCUMENT_NUM_CADRE
            ,dcs.flag_tacite_reconduction               FLAG_TACITE_RECONDUCTION
            ,dcs.nb_reconduction                        NB_RECONDUCTION         
            ,dcs.preavis_resiliation                    PREAVIS_RESILIATION     
            ,dcs.flag_revision                          FLAG_REVISION           
            ,dcs.date_revision                          DATE_REVISION
            ,dcs.nb_intervention                        NB_INTERVENTION         
            ,dcs.periodicite_intervention               PERIODICITE_INTERVENTION
            ,dcs.nb_intervention_realise                NB_INTERVENTION_REALISE 
            ,dcs.flag_facturation                       FLAG_FACTURATION        
            ,dcs.commentaire_facturation                COMMENTAIRE_FACTURATION 
            ,dcs.periodicite_facturation                PERIODICITE_FACTURATION 
            ,papf.full_name                             SIGNATAIRE_CONTRAT
            ,dcs.ref_contrat_fournisseur                REF_CONTRAT_FOURNISSEUR       
            ,dcs.description_specifique_contrat         DESCRIPTION_SPECIFIQUE_CONTRAT
            ,dcs.flag_mail_avertissement                FLAG_MAIL_AVERTISSEMENT       
            ,dcs.date_effet                             DATE_EFFET
            ,dcs.reconduction_num                       RECONDUCTION_NUM              
            ,dcs.revision_num                           REVISION_NUM                  
            ,pha2.segment1                              COMMANDE_NUM
            ,dcs.commande_version                       COMMANDE_VERSION
            ,dcs.date_resiliation                       DATE_RESILIATION
            ,dcs.annulation                             ANNULATION  
            ,dcs.org_id                                 org_id
    FROM   dka_contrat_sstr       dcs
          ,po_headers_all         pha
          ,per_all_people_f       papf
          ,po_headers_all         pha2
		  ,HR_ORGANIZATION_UNITS HROU
    WHERE  1=1
	AND  dcs.org_id = hrou.organization_id
    AND    dcs.cadre_po_header_id     = pha.po_header_id (+)
    AND    papf.current_employee_flag = 'Y'
    AND    dcs.signataire_contrat     = papf.person_id
    AND    dcs.commande_id            = pha2.po_header_id (+)
    AND    dcs.po_header_id           = p_po_header_id
	
    ;

    -- Cursor pour historique de detail des contrats
    CURSOR cur_contrat_detail_archi (p_po_header_id IN NUMBER) IS 
    SELECT   distinct 'HISTO'                           DATA_TYPE
            ,pha.segment1                               DOCUMENT_NUM_CADRE
            ,dcs.flag_tacite_reconduction               FLAG_TACITE_RECONDUCTION
            ,dcs.nb_reconduction                        NB_RECONDUCTION
            ,dcs.preavis_resiliation                    PREAVIS_RESILIATION
            ,dcs.flag_revision                          FLAG_REVISION
            ,dcs.date_revision                          DATE_REVISION
            ,dcs.nb_intervention                        NB_INTERVENTION
            ,dcs.periodicite_intervention               PERIODICITE_INTERVENTION
            ,dcs.nb_intervention_realise                NB_INTERVENTION_REALISE
            ,dcs.flag_facturation                       FLAG_FACTURATION
            ,dcs.commentaire_facturation                COMMENTAIRE_FACTURATION
            ,dcs.periodicite_facturation                PERIODICITE_FACTURATION
            ,papf.full_name                             SIGNATAIRE_CONTRAT
            ,dcs.ref_contrat_fournisseur                REF_CONTRAT_FOURNISSEUR
            ,dcs.description_specifique_contrat         DESCRIPTION_SPECIFIQUE_CONTRAT
            ,dcs.flag_mail_avertissement                FLAG_MAIL_AVERTISSEMENT
            ,dcs.date_effet                             DATE_EFFET
            ,dcs.reconduction_num                       RECONDUCTION_NUM
            ,dcs.revision_num                           REVISION_NUM                  
            ,pha2.segment1                              COMMANDE_NUM
            ,dcs.commande_version                       COMMANDE_VERSION
            ,dcs.date_resiliation                       DATE_RESILIATION
            ,dcs.annulation                             ANNULATION
			,dcs.org_id                                 org_id
    FROM   dka_contrat_sstr_archi dcs
          ,po_headers_all         pha
          ,per_all_people_f       papf
          ,po_headers_all         pha2
		  ,HR_ORGANIZATION_UNITS HROU
    WHERE  1=1
	AND    dcs.org_id = hrou.organization_id
    AND    dcs.cadre_po_header_id     = pha.po_header_id (+)
    AND    papf.current_employee_flag = 'Y'
    AND    dcs.signataire_contrat     = papf.person_id
    AND    dcs.commande_id            = pha2.po_header_id (+)
    AND    dcs.po_header_id           = p_po_header_id
	
    ;

    -- Cursor pour imputations des contrats
    CURSOR cur_contrat_imput (p_po_header_id IN NUMBER) IS
    SELECT   'ACTUEL'                     DATA_TYPE
            ,dcsi.contrat_imputation_id   CONTRAT_IMPUTATION_ID
            ,ppa.segment1                 PROJECT_CODE
            ,dcsi.unite_oeuvre            UNITE_OEUVRE
            ,hla.location_code            LOCATION_CODE
            ,dcsi.revision_num            REVISION_NUM
            ,dcsi.expenditure_type        EXPENDITURE_TYPE
            ,gcc.segment1                 CCID_SEGMENT1
            ,gcc.segment2                 CCID_SEGMENT2
            ,gcc.segment3                 CCID_SEGMENT3
            ,gcc.segment4                 CCID_SEGMENT4
            ,gcc.segment5                 CCID_SEGMENT5
            ,gcc.segment6                 CCID_SEGMENT6
            ,gcc.segment7                 CCID_SEGMENT7
            ,gcc.segment8                 CCID_SEGMENT8
            ,gcc.segment9                 CCID_SEGMENT9
            ,gcc.segment10                CCID_SEGMENT10
            ,gcc.segment11                CCID_SEGMENT11
            ,gcc.segment12                CCID_SEGMENT12			
			,DCSI.TASK_ID                 TASK_ID 
			,DCSI.org_id                  org_id
			,(select task_number
			    from PA_TASKS
			   where TASK_ID = DCSI.TASK_ID)			  task_num_absorbe
    FROM    dka_contrat_sstr_imputation DCSI
           ,pa_projects_all             PPA
           ,hr_locations_all            HLA
           ,gl_code_combinations        GCC
		   ,HR_ORGANIZATION_UNITS       HROU
    WHERE  1=1
	AND    dcsi.org_id = hrou.organization_id
    AND    dcsi.project_id          =  ppa.project_id
    AND    dcsi.location_id         =  hla.location_id 
    AND    dcsi.code_combination_id =  gcc.code_combination_id
    AND    po_header_id             =  p_po_header_id
	;

    -- Cursor pour historique des imputations des contrats
    CURSOR cur_contrat_imput_archi (p_po_header_id IN NUMBER) IS 
     SELECT   'HISTO'                     DATA_TYPE
            ,dcsi.contrat_imputation_id   CONTRAT_IMPUTATION_ID
            ,ppa.segment1                 PROJECT_CODE
            ,dcsi.unite_oeuvre            UNITE_OEUVRE
            ,hla.location_code            LOCATION_CODE
            ,dcsi.revision_num            REVISION_NUM
            ,dcsi.expenditure_type        EXPENDITURE_TYPE
            ,gcc.segment1                 CCID_SEGMENT1
            ,gcc.segment2                 CCID_SEGMENT2
            ,gcc.segment3                 CCID_SEGMENT3
            ,gcc.segment4                 CCID_SEGMENT4
            ,gcc.segment5                 CCID_SEGMENT5
            ,gcc.segment6                 CCID_SEGMENT6
            ,gcc.segment7                 CCID_SEGMENT7
            ,gcc.segment8                 CCID_SEGMENT8
            ,gcc.segment9                 CCID_SEGMENT9
            ,gcc.segment10                CCID_SEGMENT10
            ,gcc.segment11                CCID_SEGMENT11
            ,gcc.segment12                CCID_SEGMENT12			
			,DCSI.TASK_ID                 TASK_ID 
			,DCSI.org_id                  org_id
			,(select task_number
			    from PA_TASKS
			   where TASK_ID = DCSI.TASK_ID)			  task_num_absorbe
    FROM    dka_contrat_sstr_imput_archi DCSI
           ,pa_projects_all              PPA
           ,hr_locations_all             HLA
           ,gl_code_combinations         GCC
		   ,HR_ORGANIZATION_UNITS        HROU
    WHERE  1=1
	AND  dcsi.org_id = hrou.organization_id
    AND    dcsi.project_id          =  ppa.project_id
    AND    dcsi.location_id         =  hla.location_id 
    AND    dcsi.code_combination_id =  gcc.code_combination_id
    AND    po_header_id             =  p_po_header_id
	;

  BEGIN

    -- Début du traitement
    g_user_id                       := fnd_global.user_id;
    p_errbuf  := NULL;
    p_retcode := 0;

    -- Initialisation des compteurs
    v_compteur_export_header := 0;
    v_compteur_export_detail := 0;
    v_compteur_export_imput  := 0;
    v_compteur_export_header_hist := 0;
    v_compteur_export_detail_hist := 0;
    v_compteur_export_imput_hist  := 0;


 
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Log des traitements DKA                    : DKA : Fusion PO - Etape Export pour reprise contrat SSTR');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Table des En-têtes de contrats SSTR        : DKA_SPOFUSION_SSTR_HEADERS_TMP' );
    Dka_Tools_Pkg.Put_Outdebug_Message('    Table de Détails des contrats SSTR         : DKA_SPOFUSION_SSTR_DETAIL_TMP' );      
    Dka_Tools_Pkg.Put_Outdebug_Message('    Table de Distributions des contrats SSTR   : DKA_SPOFUSION_SSTR_IMPUT_TMP' );  
    Dka_Tools_Pkg.Put_Outdebug_Message('    Date et Heure                              : ' ||to_char(SYSDATE,'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('');

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- RG_EXP01 : Sociétés absorbées
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	BEGIN
	SELECT distinct 1 into v_RG_EXP01
		 FROM
					   HR_ORGANIZATION_UNITS HOU,
					   DKA_STRANSCO_LINES DSTL,
					   DKA_STRANSCO_HEADERS DSTH
		 WHERE
					   DSTL.SET_ID = DSTH.SET_ID
					   AND HOU.NAME = DSTL.PARAM1_VALUE
					   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
					   AND DSTL.ENABLE = 'Y'
					   AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
					   --AND NVL(DSTL.START_DATE,TRUNC(SYSDATE) )  <= TRUNC(SYSDATE)
					   group by DSTL.PARAM1_VALUE,
								DSTL.RetuRN_VALUE
					   having count(PARAM1_VALUE)>1;
	exception
	when others then
	v_RG_EXP01:=0  ;                                                                                                                                      
	end;


			if  v_RG_EXP01 = 1 then
              
                  Dka_Tools_Pkg.put_log_message('RG_EXPST01: Plusieurs couples actifs dans la table de transco ');
                            Dka_Tools_Pkg.Put_Outdebug_Message('RG_EXP01: Plusieurs couples actifs dans la table de transco ');
            end if;


--- Suppression des tables 
	delete from DKA_SPOFUSION_SSTR_HEADERS_TMP  
        where org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
						AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						--AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
						)
                        ;
	delete from DKA_SPOFUSION_SSTR_DETAIL_TMP 
        where org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						--AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
						)
                        ;
	delete from DKA_SPOFUSION_SSTR_IMPUT_TMP
        where org_abs in (SELECT
                         HROU.ORGANIZATION_ID
                        FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                        WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
						--AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
						)
                        ;



    -- insertion dans les tables :
	-------
	Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('listes des commandes extraites');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
	Dka_Tools_Pkg.Put_Outdebug_Message('Unité opérationnelle        Commande ');

    -- Boucle des entetes contrats
    FOR rec_contrat IN cur_contrat LOOP
      BEGIN
	       v_count:=1;
        IF v_count > 0 THEN
 
        begin
				insert into DKA_SPOFUSION_SSTR_HEADERS_TMP


				values 
                (
				rec_contrat.DATA_TYPE            ,
				rec_contrat.DOCUMENT_NUM         ,
				rec_contrat.TYPE_LOOKUP_CODE     ,
				rec_contrat.AGENT_NAME           ,
				rec_contrat.VENDOR_NAME          ,
				rec_contrat.VENDOR_SITE_CODE     ,
				rec_contrat.SHIP_TO_LOCATION     ,
				rec_contrat.BILL_TO_LOCATION     ,
				rec_contrat.PAYMENT_TERMS        ,
				rec_contrat.CURRENCY_CODE        ,
				rec_contrat.RATE_DATE            ,
				rec_contrat.START_DATE           ,
				rec_contrat.END_DATE             ,
				rec_contrat.BLANKET_TOTAL_AMOUNT ,
				rec_contrat.APPROVAL_STATUS      ,
				rec_contrat.APPROVED_FLAG        ,
				rec_contrat.APPROVED_DATE        ,
				rec_contrat.REVISION_NUM         ,      
				rec_contrat.COMMENTS ,
				 rec_contrat.ATTRIBUTE4          ,
				 rec_contrat.ATTRIBUTE5          ,
				 rec_contrat.ATTRIBUTE13         ,
				 rec_contrat.ATTRIBUTE14         ,
				 rec_contrat.ATTRIBUTE15         ,
				 rec_contrat.UO_NAME                       ,
				 null                            ,
				 rec_contrat.REVISION_DATE       ,
				 null                            ,
				 null                            ,
				 rec_contrat.ORG_ID                             ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 SYSDATE						 ,
				 g_user_id,
				 SYSDATE,
				 g_user_id,
				 null                            ,
				 rec_contrat.ORG_ID               
				);


				   commit;


		  exception
		  when others then

                dka_Tools_Pkg.put_log_message('problème d''insertion dans la table  DKA_SPOFUSION_SSTR_HEADERS_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
	end;


          -- Mise à jour du compteur contrat
          v_compteur_export_header := v_compteur_export_header + 1;

          -- Boucle de l'historique des entetes contrats
          FOR rec_contrat_archi IN cur_contrat_archi(rec_contrat.po_header_id) LOOP
	begin
				insert into DKA_SPOFUSION_SSTR_HEADERS_TMP


				values 
                (
				rec_contrat_archi.DATA_TYPE            ,
				rec_contrat_archi.DOCUMENT_NUM         ,
				rec_contrat_archi.TYPE_LOOKUP_CODE     ,
				rec_contrat_archi.AGENT_NAME           ,
				rec_contrat_archi.VENDOR_NAME          ,
				rec_contrat_archi.VENDOR_SITE_CODE     ,
				rec_contrat_archi.SHIP_TO_LOCATION     ,
				rec_contrat_archi.BILL_TO_LOCATION     ,
				rec_contrat_archi.PAYMENT_TERMS        ,
				rec_contrat_archi.CURRENCY_CODE        ,
				rec_contrat_archi.RATE_DATE            ,
				rec_contrat_archi.START_DATE           ,
				rec_contrat_archi.END_DATE             ,
				rec_contrat_archi.BLANKET_TOTAL_AMOUNT ,
				rec_contrat_archi.APPROVAL_STATUS      ,
				rec_contrat_archi.APPROVED_FLAG        ,
				rec_contrat_archi.APPROVED_DATE        ,
				rec_contrat_archi.REVISION_NUM         ,      
				rec_contrat_archi.COMMENTS ,
				 rec_contrat_archi.ATTRIBUTE4          ,
				 rec_contrat_archi.ATTRIBUTE5          ,
				 rec_contrat_archi.ATTRIBUTE13         ,
				 rec_contrat_archi.ATTRIBUTE14         ,
				 rec_contrat_archi.ATTRIBUTE15         ,
				 rec_contrat_archi.UO_NAME                         ,
				 null                            ,
				 rec_contrat_archi.REVISION_DATE       ,
				 rec_contrat_archi.LATEST_EXTERNAL_FLAG         ,
				 null                            ,
				 rec_contrat_archi.org_id                           ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 null                            ,
				 SYSDATE						 ,
				 g_user_id,
				 SYSDATE,
				 g_user_id,
				 null                            ,
				 rec_contrat_archi.org_id         
				)
				;

				   commit;


		  exception
		  when others then

                dka_Tools_Pkg.put_log_message('problème d''insertion dans la table  DKA_SPOFUSION_SSTR_HEADERS_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
	end;


            -- Mise à jour du compteur contrat
            v_compteur_export_header_hist := v_compteur_export_header_hist + 1;
          END LOOP;

          -- Boucle de detail des contrats
          FOR rec_contrat_detail IN cur_contrat_detail(rec_contrat.po_header_id) LOOP
		  
	
			begin
				insert into DKA_SPOFUSION_SSTR_DETAIL_TMP


				values 
                (
				 rec_contrat_detail.DATA_TYPE                    ,         
				 rec_contrat.DOCUMENT_NUM                        ,         
				 rec_contrat_detail.DOCUMENT_NUM_CADRE           ,         
				 rec_contrat_detail.FLAG_TACITE_RECONDUCTION     ,         
				 rec_contrat_detail.NB_RECONDUCTION              ,         
				 rec_contrat_detail.PREAVIS_RESILIATION          ,         
				 rec_contrat_detail.FLAG_REVISION                ,         
				 rec_contrat_detail.DATE_REVISION                ,         
				 rec_contrat_detail.NB_INTERVENTION              ,         
				 rec_contrat_detail.PERIODICITE_INTERVENTION     ,         
				 rec_contrat_detail.NB_INTERVENTION_REALISE      ,         
				 rec_contrat_detail.FLAG_FACTURATION             ,         
				 rec_contrat_detail.COMMENTAIRE_FACTURATION ,
				 rec_contrat_detail.PERIODICITE_FACTURATION      ,
				 rec_contrat_detail.SIGNATAIRE_CONTRAT           ,
				 rec_contrat_detail.REF_CONTRAT_FOURNISSEUR ,
				 rec_contrat_detail.DESCRIPTION_SPECIFIQUE_CONTRAT,
				 rec_contrat_detail.FLAG_MAIL_AVERTISSEMENT      ,
				 rec_contrat_detail.DATE_EFFET                   ,
				 rec_contrat_detail.RECONDUCTION_NUM             ,
				 rec_contrat_detail.REVISION_NUM                 ,
				 rec_contrat_detail.COMMANDE_NUM                 ,
                 rec_contrat_detail.COMMANDE_VERSION             ,
				rec_contrat_detail.DATE_RESILIATION             ,
				 rec_contrat_detail.ANNULATION                   ,
				 null,
				 null,
				 null,
				 null,
				 SYSDATE						 ,
				 g_user_id,
				 SYSDATE,
				 g_user_id,
				 null,
				 rec_contrat_detail.org_id 						,
				 rec_contrat_detail.org_id 
				);
				   commit;


		  exception
		  when others then

                dka_Tools_Pkg.put_log_message('problème d''insertion dans la table  DKA_SPOFUSION_SSTR_DETAIL_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
	end;	  

            -- Mise à jour du compteur detail
            v_compteur_export_detail := v_compteur_export_detail + 1;
          END LOOP;

          -- Boucle historique de detail des contrats
          FOR rec_contrat_detail_archi IN cur_contrat_detail_archi(rec_contrat.po_header_id) LOOP
       


				  		begin
				insert into DKA_SPOFUSION_SSTR_DETAIL_TMP


				values 
                (
				 rec_contrat_detail_archi.DATA_TYPE                    ,         
				 rec_contrat.DOCUMENT_NUM                        ,         
				 rec_contrat_detail_archi.DOCUMENT_NUM_CADRE           ,         
				 rec_contrat_detail_archi.FLAG_TACITE_RECONDUCTION     ,         
				 rec_contrat_detail_archi.NB_RECONDUCTION              ,         
				 rec_contrat_detail_archi.PREAVIS_RESILIATION          ,         
				 rec_contrat_detail_archi.FLAG_REVISION                ,         
				 rec_contrat_detail_archi.DATE_REVISION                ,         
				 rec_contrat_detail_archi.NB_INTERVENTION              ,         
				 rec_contrat_detail_archi.PERIODICITE_INTERVENTION     ,         
				 rec_contrat_detail_archi.NB_INTERVENTION_REALISE      ,         
				 rec_contrat_detail_archi.FLAG_FACTURATION             ,         
				rec_contrat_detail_archi.COMMENTAIRE_FACTURATION ,
				 rec_contrat_detail_archi.PERIODICITE_FACTURATION      ,
				 rec_contrat_detail_archi.SIGNATAIRE_CONTRAT           ,
				 rec_contrat_detail_archi.REF_CONTRAT_FOURNISSEUR ,
				rec_contrat_detail_archi.DESCRIPTION_SPECIFIQUE_CONTRAT,
				 rec_contrat_detail_archi.FLAG_MAIL_AVERTISSEMENT      ,
				 rec_contrat_detail_archi.DATE_EFFET                   ,
				 rec_contrat_detail_archi.RECONDUCTION_NUM             ,
				 rec_contrat_detail_archi.REVISION_NUM                 ,
				 rec_contrat_detail_archi.COMMANDE_NUM                 ,
                 rec_contrat_detail_archi.COMMANDE_VERSION             ,
				 rec_contrat_detail_archi.DATE_RESILIATION             ,
				 rec_contrat_detail_archi.ANNULATION ,
                 null,
				 null,
				 null,
				 null,
				 SYSDATE						 ,
				 g_user_id,
				 SYSDATE,
				 g_user_id,
				 null,
				  rec_contrat_detail_archi.org_id						,
				  rec_contrat_detail_archi.org_id
				 )  ;     

				   commit;


		  exception
		  when others then

                dka_Tools_Pkg.put_log_message('problème d''insertion dans la table  DKA_SPOFUSION_SSTR_DETAIL_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
	end;

            -- Mise à jour du compteur detail
            v_compteur_export_detail_hist := v_compteur_export_detail_hist + 1;
          END LOOP;

          -- Boucle ditributions des contrats
          FOR rec_contrat_imput IN cur_contrat_imput(rec_contrat.po_header_id) LOOP
		  
		
				begin
				insert into DKA_SPOFUSION_SSTR_IMPUT_TMP


				values 
                (
				   rec_contrat_imput.DATA_TYPE                   ,
				   rec_contrat.DOCUMENT_NUM                      ,
				   rec_contrat_imput.CONTRAT_IMPUTATION_ID       ,
				   rec_contrat_imput.PROJECT_CODE                ,
				   rec_contrat_imput.UNITE_OEUVRE                ,
				   rec_contrat_imput.LOCATION_CODE               ,
				   rec_contrat_imput.REVISION_NUM                ,
				   rec_contrat_imput.EXPENDITURE_TYPE            ,
				   rec_contrat_imput.CCID_SEGMENT1               ,
				   rec_contrat_imput.CCID_SEGMENT2               ,
				   rec_contrat_imput.CCID_SEGMENT3               ,
				   rec_contrat_imput.CCID_SEGMENT4               ,
				   rec_contrat_imput.CCID_SEGMENT5               ,
				   rec_contrat_imput.CCID_SEGMENT6               ,
				   rec_contrat_imput.CCID_SEGMENT7               ,
				   rec_contrat_imput.CCID_SEGMENT8               ,
				   rec_contrat_imput.CCID_SEGMENT9               ,
				   rec_contrat_imput.CCID_SEGMENT10              ,
				   null											 ,
			       rec_contrat_imput.TASK_ID                     ,	 
				   null                                          ,
				   null                                          ,
				   null                                          ,
				   SYSDATE						 				 ,
				   g_user_id                                     ,
				   SYSDATE										 ,
				   g_user_id									 ,
				   null											,
                   rec_contrat_imput.org_id						,
				   rec_contrat_imput.org_id						,
                   rec_contrat_imput.task_num_absorbe           ,
                   rec_contrat_imput.CCID_SEGMENT11             ,
                   rec_contrat_imput.CCID_SEGMENT12				   
				 )    ;   

				   commit;


		  exception
		  when others then

                dka_Tools_Pkg.put_log_message('problème d''insertion dans la table  DKA_SPOFUSION_SSTR_DETAIL_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
	end;	  



            -- Mise à jour du compteur imputations
            v_compteur_export_imput := v_compteur_export_imput + 1;
          END LOOP;

          -- Boucle historique ditributions des contrats
          FOR rec_contrat_imput_archi IN cur_contrat_imput_archi(rec_contrat.po_header_id) LOOP
          
				begin
				insert into DKA_SPOFUSION_SSTR_IMPUT_TMP


				values 
                (

				   rec_contrat_imput_archi.DATA_TYPE                   ,
				   rec_contrat.DOCUMENT_NUM                      ,
				   rec_contrat_imput_archi.CONTRAT_IMPUTATION_ID       ,
				   rec_contrat_imput_archi.PROJECT_CODE                ,
				   rec_contrat_imput_archi.UNITE_OEUVRE                ,
				   rec_contrat_imput_archi.LOCATION_CODE               ,
				   rec_contrat_imput_archi.REVISION_NUM                ,
				   rec_contrat_imput_archi.EXPENDITURE_TYPE            ,
				   rec_contrat_imput_archi.CCID_SEGMENT1               ,
				   rec_contrat_imput_archi.CCID_SEGMENT2               ,
				   rec_contrat_imput_archi.CCID_SEGMENT3               ,
				   rec_contrat_imput_archi.CCID_SEGMENT4               ,
				   rec_contrat_imput_archi.CCID_SEGMENT5               ,
				   rec_contrat_imput_archi.CCID_SEGMENT6               ,
				   rec_contrat_imput_archi.CCID_SEGMENT7               ,
				   rec_contrat_imput_archi.CCID_SEGMENT8               ,
				   rec_contrat_imput_archi.CCID_SEGMENT9               ,
				   rec_contrat_imput_archi.CCID_SEGMENT10              ,
				   null												   ,
				   rec_contrat_imput_archi.TASK_ID                     ,	 
				   null                                                ,
				   null                                                ,
				   null                                                ,
				   SYSDATE						                       ,
				   g_user_id                                           ,
				   SYSDATE                                             ,
				   g_user_id                                           ,
				   null                                                ,
				   rec_contrat_imput_archi.org_id				       ,
				   rec_contrat_imput_archi.org_id				       , 
				   rec_contrat_imput_archi.task_num_absorbe            ,
                   rec_contrat_imput_archi.CCID_SEGMENT11                    ,
                   rec_contrat_imput_archi.CCID_SEGMENT12				  
				 
				 )    ;   

				   commit;


		  exception
		  when others then

                dka_Tools_Pkg.put_log_message('problème d''insertion dans la table  DKA_SPOFUSION_SSTR_DETAIL_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
	end;	  

            -- Mise à jour du compteur imputations
            v_compteur_export_imput_hist := v_compteur_export_imput_hist + 1;
          END LOOP;

        END IF;

        EXCEPTION
          WHEN OTHERS THEN
            dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE || ' - ' || SQLERRM);
            p_retcode := 1;
        END;
    select distinct HR.NAME ,hd.DOCUMENT_NUM
	 into v_name , v_document_num
     from 
     HR_ORGANIZATION_UNITS hr
    ,DKA_SPOFUSION_SSTR_HEADERS_TMP hd
    where HR.ORGANIZATION_ID = HD.ORG_ID 
	and hd.DOCUMENT_NUM= rec_contrat.DOCUMENT_NUM
	group by HR.NAME ,hd.DOCUMENT_NUM ;
	
	Dka_Tools_Pkg.Put_Outdebug_Message( v_name||'                     '||v_document_num  );
	
	
    END LOOP;
		
      -- Log du nombre d'enregistrements
	Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre des en-têtes de contrat SSTR extraits         : ' || TO_CHAR(v_compteur_export_header+v_compteur_export_header_hist));
    Dka_Tools_Pkg.Put_Outdebug_Message('                                                      Actuel     : ' || TO_CHAR(v_compteur_export_header));
    Dka_Tools_Pkg.Put_Outdebug_Message('                                                      Historique : ' || TO_CHAR(v_compteur_export_header_hist));
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre de détail des contrats SSTR  extraits         : ' || TO_CHAR(v_compteur_export_detail+v_compteur_export_detail_hist));
    Dka_Tools_Pkg.Put_Outdebug_Message('                                                      Actuel     : ' || TO_CHAR(v_compteur_export_detail));
    Dka_Tools_Pkg.Put_Outdebug_Message('                                                      Historique : ' || TO_CHAR(v_compteur_export_detail_hist));
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre de distributions des contrats SSTR extraites  : ' || TO_CHAR(v_compteur_export_imput+v_compteur_export_imput_hist));
    Dka_Tools_Pkg.Put_Outdebug_Message('                                                      Actuel     : ' || TO_CHAR(v_compteur_export_imput));
    Dka_Tools_Pkg.Put_Outdebug_Message('                                                      Historique : ' || TO_CHAR(v_compteur_export_imput_hist));
	Dka_Tools_Pkg.Put_Outdebug_Message('');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('Fin des logs de traitements DKA : Extraction contrats sous traitance');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
	

	
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN    
      ROLLBACK;
      p_errbuf  := 'Erreur dans la procécure Main : ' || SQLCODE || '-' || Substr(SQLERRM, 1, 80);
      p_retcode := 2;

      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuf);
  END Main;

END DKA_FUSPOEXPCTRSSTR_PKG;

/
SHOW ERRORS
EXIT