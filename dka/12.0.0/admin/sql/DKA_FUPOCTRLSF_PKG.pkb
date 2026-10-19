CREATE OR REPLACE PACKAGE BODY DKA_FUSPOCTRSUP_PKG AS
  --------------------------------------------------------------------------------
  -- 
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_FUSPOCTRSUP_PKG
  -- Description      : Body du package DKA_FUSPOCTRSUP_PKG
  -- Auteur           : Saloua HAHIOUI 
  -- Date de création : 25/09/2019
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  
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
  PROCEDURE Main( p_errbuf OUT VARCHAR2, 
				  p_retcode OUT NUMBER ,
				  P_UO_ABSORBEE    number,
				  P_UO_ABSORBANTE  number
				  ) IS
				  
  v_compteur_export_site_inex             NUMBER;
  v_compteur_export_site_exts             NUMBER;
  p_fic_out_exi    					    UTL_FILE.FILE_TYPE;
  p_fic_out        				        UTL_FILE.FILE_TYPE;
  p_dir_out        					    VARCHAR2(120); 
  v_sep         						VARCHAR2(1)  := '|';
  p_fic_out_name_1           			VARCHAR2(80);
  p_fic_out_name_2          			VARCHAR2(80);
  commentaire                           VARCHAR2(250);  
  
--------sites fournisseurs inexistants sur la société absorbante 
----------------------------------------------------------------
	--- commande
CURSOR cur_site_inex IS
    SELECT distinct
           pov.VENDOR_NAME            VENDOR_NAME 
         , povsa.VENDOR_SITE_CODE     VENDOR_SITE_CODE
         , HROU_abs.NAME        		  NAME
      FROM PO_HEADERS_ALL poha
         , PO_VENDORS pov
         , PO_VENDOR_SITES_ALL povsa
         , PO_DISTRIBUTIONS_ALL poda
         , PO_LINES_ALL pola
         , HR_OPERATING_UNITS HROU
		 , HR_OPERATING_UNITS HROU_abs
    WHERE 1=1 
	  AND nvl(pov.vendor_type_lookup_code,'A') <>'EMPLOYEE'
      AND poha.type_lookup_code        = 'STANDARD'
      AND NVL(poha.closed_code,'OPEN') = 'OPEN'
      AND NVL(poha.cancel_flag,'N')    = 'N'
      AND authorization_status         = 'APPROVED' 
      AND poha.ORG_ID                  = HROU.organization_id
      AND poha.VENDOR_ID               = pov.VENDOR_ID
      AND poha.VENDOR_SITE_ID          = povsa.VENDOR_SITE_ID
	  and HROU_abs.organization_id     = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
																				  FROM HR_ORGANIZATION_UNITS HOU,
																					   DKA_STRANSCO_LINES DSTL,
																					   DKA_STRANSCO_HEADERS DSTH
																				 WHERE DSTL.SET_ID = DSTH.SET_ID
																				   AND HOU.NAME = DSTL.RETURN_VALUE
																				   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
																				   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
																				   AND DSTL.ENABLE = 'Y'
																				   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
																				   and rownum<2))
	  AND povsa.location_id not in ( select PVS_ABS.location_id 
                                     FROM ap_supplier_sites_all pvs_abs 
									 WHERE pvs_abs.location_id=povsa.location_id
				                      and pov.vendor_id = pvs_abs.vendor_id
				                   	  and pvs_abs.org_id = HROU_abs.organization_id
				                     -- and pvs_abs.purchasing_site_flag = 'Y'
                                    )
      AND EXISTS (SELECT '1'
					FROM po_line_locations_all polla, 
					     PO_LINES_ALL pola2
				   WHERE pola2.po_header_id = poha.po_header_id
					 AND polla.po_header_id = pola2.po_header_id
					 AND polla.po_line_id   = pola2.po_line_id
					 AND polla.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
					 AND NVL(polla.cancel_flag,'N') = 'N'
					 AND (polla.quantity - polla.quantity_cancelled - polla.quantity_rejected - polla.quantity_billed) > 0
					 AND ROWNUM = 1
                 )
      AND poda.po_header_id = poha.po_header_id
      AND poda.po_distribution_id = (SELECT MIN(poda2.po_distribution_id)
                                       FROM PO_DISTRIBUTIONS_ALL poda2, PO_LINE_LOCATIONS_ALL polla
                                      WHERE poda2.po_header_id = poha.po_header_id
                                        AND (poda2.quantity_ordered - poda2.quantity_cancelled - poda2.quantity_billed) > 0
                                        AND polla.line_location_id         = poda2.line_location_id 
                                        AND polla.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
                                        AND NVL(polla.cancel_flag,'N') = 'N'
                                    )
    AND poda.po_header_id        = pola.po_header_id   
	AND povsa.org_id        =     HROU.organization_id 
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,(SELECT HOU.organization_id 
													FROM HR_ORGANIZATION_UNITS HOU,
														 DKA_STRANSCO_LINES DSTL,
														 DKA_STRANSCO_HEADERS DSTH
												   WHERE DSTL.SET_ID = DSTH.SET_ID
													 AND HOU.NAME = DSTL.PARAM1_VALUE
													 and HOU.organization_id=HROU.organization_id
													 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
													 AND DSTL.ENABLE = 'Y'
													 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
													 AND rownum <2 ))
													 
 union 
	--- facture 
SELECT distinct
	   Pv.Vendor_Name                    VENDOR_NAME 
	 , Pvsa.Vendor_Site_Code             VENDOR_SITE_CODE
	 , HROU_abs.name                     NAME
  FROM Dka_Stransco_Headers Dsh
	 , Dka_Stransco_Lines Dsl
	 , Ap_Invoices_All  Aia
	 , Ap_Payment_Schedules_All Apsa
	 , Fnd_Doc_Sequence_Categories Fdsc
	 , Po_Vendor_Sites_All Pvsa
	 , Ap_Terms Ate
	 , Po_Vendors Pv
	 , Hr_operating_units hrou
	 , Hr_operating_units hrou_abs
 WHERE Dsh.Set_Name = 'FUSION_SOCIETE_VERS_SOCIETE'
   AND Dsl.Set_Id = Dsh.Set_Id
   AND nvl(pv.vendor_type_lookup_code,'A') <>'EMPLOYEE'   
   AND Dsl.Enable = 'Y'
       -- RG1: Type de la facture
   AND Aia.invoice_type_lookup_code IN ('STANDARD','CREDIT','EXPENSE REPORT' ,'DEBIT')
   AND Fdsc.Application_Id = 200
       -- RG3: Mouvement doit appartenir a la societe absorbee
   AND Fdsc.Code = Aia.Doc_Category_Code
  -- AND Fdsc.Name LIKE (substr(Dsl.Param1_Value,4,4)||'%')
   AND hrou.name = dsl.param1_value
   AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id)
   AND aia.org_id = hrou.organization_id
   AND Apsa.Invoice_Id = Aia.Invoice_Id
   AND Pvsa.Vendor_Site_Id = Aia.Vendor_Site_Id
   and HROU_abs.organization_id     = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
																				  FROM HR_ORGANIZATION_UNITS HOU,
																					   DKA_STRANSCO_LINES DSTL,
																					   DKA_STRANSCO_HEADERS DSTH
																				 WHERE DSTL.SET_ID = DSTH.SET_ID
																				   AND HOU.NAME = DSTL.RETURN_VALUE
																				   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
																				   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
																				   AND DSTL.ENABLE = 'Y'
																				   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
																				   and rownum<2))
   AND Pvsa.location_id not in ( select PVS_ABS.location_id 
                                     FROM ap_supplier_sites_all pvs_abs 
									 WHERE pvs_abs.location_id=pvsa.location_id
				                      and pv.vendor_id = pvs_abs.vendor_id
				                   	  and pvs_abs.org_id = HROU_abs.organization_id
				                     -- and pvs_abs.purchasing_site_flag = 'Y'
                                    )
   AND Ate.Term_Id = Aia.Terms_Id
   AND Pv.Vendor_Id = Aia.Vendor_Id
      -- RG1: Ensemble des lignes de la facture postees
   AND NOT EXISTS ( SELECT 'x'
					  FROM Ap_Invoice_Distributions_All Aida
					 WHERE Aida.Invoice_id = Aia.Invoice_Id
					   AND NVL(Aida.Accrual_Posted_Flag,'N') <> 'Y' )
 
	
  UNION 
 -- Acomptes
 SELECT distinct
        Pv.Vendor_Name                          VENDOR_NAME   
      , Pvsa.Vendor_Site_Code                   VENDOR_SITE_CODE
      , hrou_abs.name                                NAME
   FROM Dka_Stransco_Headers Dsh
	  , Dka_Stransco_Lines Dsl
	  , Ap_Invoices_All  Aia
	  , Fnd_Doc_Sequence_Categories Fdsc
	  , Po_Vendor_Sites_All Pvsa
	  , Ap_Terms Ate
	  , Po_Vendors Pv
	  , hr_operating_units hrou
	  , hr_operating_units hrou_abs
  WHERE Dsh.Set_Name = 'FUSION_SOCIETE_VERS_SOCIETE'
    AND Dsl.Set_Id = Dsh.Set_Id
    AND Dsl.Enable = 'Y'
    AND nvl(pv.vendor_type_lookup_code,'A') <>'EMPLOYEE' 	
        -- RG2: Type de la facture
    AND Aia.invoice_type_lookup_code = 'PREPAYMENT'
        -- RG2: Amount_Paid <> Invoice_Amount
    AND NVL(Aia.Invoice_Amount,0) = NVL(Aia.Amount_Paid,0)
    AND Fdsc.Application_Id = 200
    AND Fdsc.Code = Aia.Doc_Category_Code
        -- RG3: Mouvement doit appartenir a la societe absorbee
   -- AND Fdsc.Name LIKE (substr(Dsl.Param1_Value,4,4)||'%')
    AND hrou.name = dsl.param1_value
    AND aia.org_id = hrou.organization_id
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id)
    AND Pvsa.Vendor_Site_Id = Aia.Vendor_Site_Id
    and HROU_abs.organization_id     = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
																				  FROM HR_ORGANIZATION_UNITS HOU,
																					   DKA_STRANSCO_LINES DSTL,
																					   DKA_STRANSCO_HEADERS DSTH
																				 WHERE DSTL.SET_ID = DSTH.SET_ID
																				   AND HOU.NAME = DSTL.RETURN_VALUE
																				   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
																				   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
																				   AND DSTL.ENABLE = 'Y'
																				   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
																				   and rownum<2))
   AND Pvsa.location_id not in ( select PVS_ABS.location_id 
                                     FROM ap_supplier_sites_all pvs_abs 
									 WHERE pvs_abs.location_id=pvsa.location_id
				                      and pv.vendor_id = pvs_abs.vendor_id
				                   	  and pvs_abs.org_id = HROU_abs.organization_id
				                     -- and pvs_abs.purchasing_site_flag = 'Y'
                                    )
    AND Ate.Term_Id = Aia.Terms_Id
    AND Pv.Vendor_Id = Aia.Vendor_Id
      -- RG2: Ensemble des lignes de la facture postees
    AND NOT EXISTS ( SELECT 'x'
					   FROM Ap_Invoice_Distributions_All Aida
					  WHERE Aida.Invoice_id = Aia.Invoice_Id
					    AND NVL(Aida.Accrual_Posted_Flag,'N') <> 'Y' )
 union 
---contrat SSTR
 SELECT pv.vendor_name                           VENDOR_NAME
      , pvs.vendor_site_code                     VENDOR_SITE_CODE
      , hrou_abs.NAME                                 NAME
   FROM po_headers_all              pha
      , po_vendors                  PV
      , po_vendor_sites_all         pvs
      , dka_contrat_sstr_imputation dcsi 
	  , hr_operating_units          hrou
	  , hr_operating_units          hrou_abs
  WHERE 1=1
    AND pha.type_lookup_code        = 'CONTRACT'
    AND pha.attribute4 IS NOT NULL
    AND NVL(pha.closed_code,'OPEN') = 'OPEN'
    AND nvl(pv.vendor_type_lookup_code,'A') <>'EMPLOYEE' 	
    AND NVL(pha.cancel_flag,'N')    = 'N'
    AND pha.vendor_id               = pv.vendor_id
    AND pha.vendor_site_id          = pvs.vendor_site_id
	and HROU_abs.organization_id     = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
																				  FROM HR_ORGANIZATION_UNITS HOU,
																					   DKA_STRANSCO_LINES DSTL,
																					   DKA_STRANSCO_HEADERS DSTH
																				 WHERE DSTL.SET_ID = DSTH.SET_ID
																				   AND HOU.NAME = DSTL.RETURN_VALUE
																				   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
																				   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
																				   AND DSTL.ENABLE = 'Y'
																				   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
																				   and rownum<2))
   AND pvs.location_id not in ( select PVS_ABS.location_id 
                                     FROM ap_supplier_sites_all pvs_abs 
									 WHERE pvs_abs.location_id=pvs.location_id
				                      and pv.vendor_id = pvs_abs.vendor_id
				                   	  and pvs_abs.org_id = HROU_abs.organization_id
				                     -- and pvs_abs.purchasing_site_flag = 'Y'
                                    )
    AND dcsi.po_header_id           = pha.po_header_id
    AND dcsi.contrat_imputation_id  = ( SELECT MIN(contrat_imputation_id)
                                          FROM dka_contrat_sstr_imputation
                                         WHERE po_header_id = pha.po_header_id
                                      )  
    AND (
	      (--LE CONTRAT NE PEUT PLUS ETRE RENOUVELE 
		     EXISTS (SELECT 1 
				       FROM DKA_CONTRAT_SSTR_ARCHI DCSA,
					        DKA_CONTRAT_SSTR DCS 
				      WHERE DCSA.PO_HEADER_ID = PHA.PO_HEADER_ID
				        AND DCS.PO_HEADER_ID = PHA.PO_HEADER_ID
				        AND DCSA.NB_RECONDUCTION = DCSA.RECONDUCTION_NUM
				  )
         --  AND PHA.END_DATE > v_date_fin_renouv --TO_DATE('31/12/2016','DD/MM/RRRR') -- RBE
          )
        OR
      --(LE CONTRAT PEUT ETRE RENOUVELE)
            NOT EXISTS (SELECT 1 
                          FROM DKA_CONTRAT_SSTR_ARCHI DCSA,
							   DKA_CONTRAT_SSTR DCS 
                         WHERE DCSA.PO_HEADER_ID = PHA.PO_HEADER_ID
						   AND DCSA.PO_HEADER_ID = DCS.PO_HEADER_ID
                           AND DCSA.NB_RECONDUCTION = DCSA.RECONDUCTION_NUM
                        )
        )
	AND pha.org_id       =      HROU.organization_id 
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,(SELECT HOU.organization_id 
													FROM HR_ORGANIZATION_UNITS HOU,
														 DKA_STRANSCO_LINES DSTL,
														 DKA_STRANSCO_HEADERS DSTH
												   WHERE DSTL.SET_ID = DSTH.SET_ID
													 AND HOU.NAME = DSTL.PARAM1_VALUE
													 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
													 AND DSTL.ENABLE = 'Y'
													 AND HOU.organization_id=HROU.organization_id
													 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
													 AND rownum <2 ))
;
--------sites fournisseurs existants sur la société absorbante
--------------------------------------------------------------
  CURSOR cur_site_exi_PO IS 
  --commande
       SELECT distinct
           pov.VENDOR_NAME            VENDOR_NAME 
         , povsa.VENDOR_SITE_CODE     VENDOR_SITE_CODE
         , HROU.NAME        		  NAME
         , pov.vendor_id
         , povsa.VENDOR_SITE_id       
         , HROU.organization_id
		 , povsa.location_id
		 , pvs_abs.VENDOR_SITE_CODE     VENDOR_SITE_CODE_ABS
		 , pvs_abs.VENDOR_SITE_ID     VENDOR_SITE_ID_ABS	
		 , pvs_abs.org_id				ORG_ABS
		 , (select name from hr_organization_units
	       where organization_id= pvs_abs.org_id	)			  ORG_NAME_ABS		 
      FROM PO_HEADERS_ALL poha
         , PO_VENDORS pov
         , PO_VENDOR_SITES_ALL povsa
         , PO_DISTRIBUTIONS_ALL poda
         , PO_LINES_ALL pola
         , HR_OPERATING_UNITS HROU
		 , PO_VENDOR_SITES_ALL pvs_abs
    WHERE 1=1 
      AND poha.type_lookup_code        = 'STANDARD'
      AND NVL(poha.closed_code,'OPEN') = 'OPEN'
      AND NVL(poha.cancel_flag,'N')    = 'N'
      AND authorization_status         = 'APPROVED' 
      AND poha.ORG_ID                  = HROU.organization_id
      AND poha.VENDOR_ID               = pov.VENDOR_ID
      AND poha.VENDOR_SITE_ID          = povsa.VENDOR_SITE_ID
	  AND EXISTS (SELECT '1'
					FROM po_line_locations_all polla, 
					     PO_LINES_ALL pola2
				   WHERE pola2.po_header_id = poha.po_header_id
					 AND polla.po_header_id = pola2.po_header_id
					 AND polla.po_line_id   = pola2.po_line_id
					 AND polla.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
					 AND NVL(polla.cancel_flag,'N') = 'N'
					 AND (polla.quantity - polla.quantity_cancelled - polla.quantity_rejected - polla.quantity_billed) > 0
					 AND ROWNUM = 1
                 )
      AND poda.po_header_id = poha.po_header_id
      AND poda.po_distribution_id = (SELECT MIN(poda2.po_distribution_id)
                                       FROM PO_DISTRIBUTIONS_ALL poda2, PO_LINE_LOCATIONS_ALL polla
                                      WHERE poda2.po_header_id = poha.po_header_id
                                        AND (poda2.quantity_ordered - poda2.quantity_cancelled - poda2.quantity_billed) > 0
                                        AND polla.line_location_id         = poda2.line_location_id 
                                        AND polla.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
                                        AND NVL(polla.cancel_flag,'N') = 'N'
                                    )
    AND poda.po_header_id        = pola.po_header_id   
	AND povsa.org_id        =     HROU.organization_id 
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,(SELECT HOU.organization_id 
													FROM HR_ORGANIZATION_UNITS HOU,
														 DKA_STRANSCO_LINES DSTL,
														 DKA_STRANSCO_HEADERS DSTH
												   WHERE DSTL.SET_ID = DSTH.SET_ID
													 AND HOU.NAME = DSTL.PARAM1_VALUE
													 and HOU.organization_id=HROU.organization_id
													 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
													 AND DSTL.ENABLE = 'Y'
													 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
													 AND rownum <2 ))
   AND povsa.location_id in ( select PVS_ABS.location_id 
                                     FROM ap_supplier_sites_all pvs_abs 
									 WHERE pvs_abs.location_id=povsa.location_id
				                      and pov.vendor_id = pvs_abs.vendor_id
				                   	  and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
																				  FROM HR_ORGANIZATION_UNITS HOU,
																					   DKA_STRANSCO_LINES DSTL,
																					   DKA_STRANSCO_HEADERS DSTH
																				 WHERE DSTL.SET_ID = DSTH.SET_ID
																				   AND HOU.NAME = DSTL.RETURN_VALUE
																				   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
																				   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
																				   AND DSTL.ENABLE = 'Y'
																				   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
																				   and rownum<2))
				                     -- and pvs_abs.purchasing_site_flag = 'Y'
                                    )   
   AND povsa.location_id =  PVS_ABS.location_id 
   AND povsa.vendor_id    = pvs_abs.vendor_id
   and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
											  FROM HR_ORGANIZATION_UNITS HOU,
												   DKA_STRANSCO_LINES DSTL,
												   DKA_STRANSCO_HEADERS DSTH
											 WHERE DSTL.SET_ID = DSTH.SET_ID
											   AND HOU.NAME = DSTL.RETURN_VALUE
											   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
											   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
											   AND DSTL.ENABLE = 'Y'
											   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
											   and rownum<2))
				                     -- and pvs_abs.purchasing_site_flag = 'Y'
                                     									
 union 
 SELECT distinct pv.vendor_name                           VENDOR_NAME
      , pvs.vendor_site_code                     VENDOR_SITE_CODE
      , hrou.NAME                                 NAME
    , Pv.vendor_id
    , pvs.VENDOR_SITE_id       
    , hrou.organization_id 
    , pvs.location_id	
	 , pvs_abs.VENDOR_SITE_CODE     VENDOR_SITE_CODE_ABS
	 , pvs_abs.VENDOR_SITE_ID     VENDOR_SITE_ID_ABS	
	 , pvs_abs.org_id				ORG_ABS
	, (select name from hr_organization_units
	       where organization_id= pvs_abs.org_id	)			  ORG_NAME_ABS	 
   FROM po_headers_all              pha
      , po_vendors                  PV
      , po_vendor_sites_all         pvs
      , dka_contrat_sstr_imputation dcsi 
	  , hr_operating_units          hrou
	  , PO_VENDOR_SITES_ALL pvs_abs
  WHERE 1=1
    AND pha.type_lookup_code        = 'CONTRACT'
    AND pha.attribute4 IS NOT NULL
    AND NVL(pha.closed_code,'OPEN') = 'OPEN'
    AND NVL(pha.cancel_flag,'N')    = 'N'
    AND pha.vendor_id               = pv.vendor_id
    AND pha.vendor_site_id          = pvs.vendor_site_id
	AND dcsi.po_header_id           = pha.po_header_id
    AND dcsi.contrat_imputation_id  = ( SELECT MIN(contrat_imputation_id)
                                          FROM dka_contrat_sstr_imputation
                                         WHERE po_header_id = pha.po_header_id
                                      )  
    AND (
	      (--LE CONTRAT NE PEUT PLUS ETRE RENOUVELE 
		     EXISTS (SELECT 1 
				       FROM DKA_CONTRAT_SSTR_ARCHI DCSA,
					        DKA_CONTRAT_SSTR DCS 
				      WHERE DCSA.PO_HEADER_ID = PHA.PO_HEADER_ID
				        AND DCS.PO_HEADER_ID = PHA.PO_HEADER_ID
				        AND DCSA.NB_RECONDUCTION = DCSA.RECONDUCTION_NUM
				  )
         --  AND PHA.END_DATE > v_date_fin_renouv --TO_DATE('31/12/2016','DD/MM/RRRR') -- RBE
          )
        OR
      --(LE CONTRAT PEUT ETRE RENOUVELE)
            NOT EXISTS (SELECT 1 
                          FROM DKA_CONTRAT_SSTR_ARCHI DCSA,
							   DKA_CONTRAT_SSTR DCS 
                         WHERE DCSA.PO_HEADER_ID = PHA.PO_HEADER_ID
						   AND DCSA.PO_HEADER_ID = DCS.PO_HEADER_ID
                           AND DCSA.NB_RECONDUCTION = DCSA.RECONDUCTION_NUM
                        )
        )
	AND pha.org_id       =      HROU.organization_id 
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,(SELECT HOU.organization_id 
													FROM HR_ORGANIZATION_UNITS HOU,
														 DKA_STRANSCO_LINES DSTL,
														 DKA_STRANSCO_HEADERS DSTH
												   WHERE DSTL.SET_ID = DSTH.SET_ID
													 AND HOU.NAME = DSTL.PARAM1_VALUE
													 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
													 AND DSTL.ENABLE = 'Y'
													 AND HOU.organization_id=HROU.organization_id
													 AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
													 )
                                 )
   AND Pvs.location_id =  PVS_ABS.location_id 
   AND Pvs.vendor_id    = pvs_abs.vendor_id
   and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
											  FROM HR_ORGANIZATION_UNITS HOU,
												   DKA_STRANSCO_LINES DSTL,
												   DKA_STRANSCO_HEADERS DSTH
											 WHERE DSTL.SET_ID = DSTH.SET_ID
											   AND HOU.NAME = DSTL.RETURN_VALUE
											   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
											   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
											   AND DSTL.ENABLE = 'Y'
											   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
											   and rownum<2)) 
    							   
   union
   select distinct 
		 pv.vendor_name                           	VENDOR_NAME
	   , pvs.vendor_site_code                       VENDOR_SITE_CODE
	   , hrou.NAME                                   NAME
	   , Pv.vendor_id
       , pvs.VENDOR_SITE_id       
       , hrou.organization_id
       , pvs.location_id	
	 , pvs_abs.VENDOR_SITE_CODE     VENDOR_SITE_CODE_ABS
	 , pvs_abs.VENDOR_SITE_ID     VENDOR_SITE_ID_ABS	
	 , pvs_abs.org_id				ORG_ABS	
     , (select name from hr_organization_units
	       where organization_id= pvs_abs.org_id	)			  ORG_NAME_ABS	 
	from po_headers_all              				pha
	   , po_vendors                  				PV
	   , po_vendor_sites_all         				pvs
	   , hr_operating_units          				hrou 
	   , PO_VENDOR_SITES_ALL pvs_abs
   where pha.vendor_id               				= pv.vendor_id
     AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id)
     AND pha.vendor_site_id          				= pvs.vendor_site_id
     AND pha.org_id                  				= hrou.organization_id
     AND pv.vendor_id          				    	= pvs.vendor_id
	 AND pvs.STATUS        			  	  		    ='A'
     and pha.type_lookup_code in ('STANDARD','CONTRACT')
 ---------------------RG-FRS4 
     AND NVL(pha.creation_date,TRUNC(SYSDATE) ) >= to_date(add_months(sysdate,-18),'dd-mm-rrrr')

     AND Pvs.location_id =  PVS_ABS.location_id 
     AND Pvs.vendor_id    = pvs_abs.vendor_id
     and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
											  FROM HR_ORGANIZATION_UNITS HOU,
												   DKA_STRANSCO_LINES DSTL,
												   DKA_STRANSCO_HEADERS DSTH
											 WHERE DSTL.SET_ID = DSTH.SET_ID
											   AND HOU.NAME = DSTL.RETURN_VALUE
											   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
											   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
											   AND DSTL.ENABLE = 'Y'
											   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
											   and rownum<2)) 	 
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id) ;
	--- cursor facture AP
CURSOR cur_site_exi_AP IS 
SELECT distinct
	   Pv.Vendor_Name                    VENDOR_NAME 
	 , Pvsa.Vendor_Site_Code             VENDOR_SITE_CODE
	 , hrou.name                          NAME
    , Pv.vendor_id
    , Pvsa.VENDOR_SITE_id       
    , hrou.organization_id
	, Pvsa.location_id
	 , pvs_abs.VENDOR_SITE_CODE     VENDOR_SITE_CODE_ABS
	 , pvs_abs.VENDOR_SITE_ID     VENDOR_SITE_ID_ABS	
	 , pvs_abs.org_id				ORG_ABS	
	 , (select name from hr_organization_units
	       where organization_id= pvs_abs.org_id	)			  ORG_NAME_ABS
  FROM Dka_Stransco_Headers Dsh
	 , Dka_Stransco_Lines Dsl
	 , Ap_Invoices_All  Aia
	 , Ap_Payment_Schedules_All Apsa
	 , Fnd_Doc_Sequence_Categories Fdsc
	 , Po_Vendor_Sites_All Pvsa
	 , Ap_Terms Ate
	 , Po_Vendors Pv
	 , Hr_operating_units hrou
	 , PO_VENDOR_SITES_ALL pvs_abs
 WHERE Dsh.Set_Name = 'FUSION_SOCIETE_VERS_SOCIETE'
   AND Dsl.Set_Id = Dsh.Set_Id
   AND Dsl.Enable = 'Y'
       -- RG1: Type de la facture
   AND Aia.invoice_type_lookup_code IN ('STANDARD','CREDIT','EXPENSE REPORT' ,'DEBIT')
   AND Fdsc.Application_Id = 200
       -- RG3: Mouvement doit appartenir a la societe absorbee
   AND Fdsc.Code = Aia.Doc_Category_Code
  -- AND Fdsc.Name LIKE (substr(Dsl.Param1_Value,4,4)||'%')
   AND hrou.name = dsl.param1_value
   AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id)
   AND aia.org_id = hrou.organization_id
   AND Apsa.Invoice_Id = Aia.Invoice_Id
   AND Pvsa.Vendor_Site_Id = Aia.Vendor_Site_Id
   AND Ate.Term_Id = Aia.Terms_Id
   AND Pv.Vendor_Id = Aia.Vendor_Id
      -- RG1: Ensemble des lignes de la facture postees
   AND NOT EXISTS ( SELECT 'x'
					  FROM Ap_Invoice_Distributions_All Aida
					 WHERE Aida.Invoice_id = Aia.Invoice_Id
					   AND NVL(Aida.Accrual_Posted_Flag,'N') <> 'Y' )
 
   AND Pvsa.location_id =  PVS_ABS.location_id 
   AND Pvsa.vendor_id    = pvs_abs.vendor_id
   and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
											  FROM HR_ORGANIZATION_UNITS HOU,
												   DKA_STRANSCO_LINES DSTL,
												   DKA_STRANSCO_HEADERS DSTH
											 WHERE DSTL.SET_ID = DSTH.SET_ID
											   AND HOU.NAME = DSTL.RETURN_VALUE
											   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
											   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
											   AND DSTL.ENABLE = 'Y'
											   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
											   and rownum<2)) 
  UNION 
 -- Acomptes
 SELECT distinct
        Pv.Vendor_Name                          VENDOR_NAME   
      , Pvsa.Vendor_Site_Code                   VENDOR_SITE_CODE
      , hrou.name                                NAME
    , Pv.vendor_id
    , Pvsa.VENDOR_SITE_id       
    , hrou.organization_id
    , Pvsa.location_id	
	 , pvs_abs.VENDOR_SITE_CODE     VENDOR_SITE_CODE_ABS
	 , pvs_abs.VENDOR_SITE_ID     VENDOR_SITE_ID_ABS	
	 , pvs_abs.org_id				ORG_ABS
     , (select name from hr_organization_units
	       where organization_id= pvs_abs.org_id	)			  ORG_NAME_ABS	 
   FROM Dka_Stransco_Headers Dsh
	  , Dka_Stransco_Lines Dsl
	  , Ap_Invoices_All  Aia
	  , Fnd_Doc_Sequence_Categories Fdsc
	  , Po_Vendor_Sites_All Pvsa
	  , Ap_Terms Ate
	  , Po_Vendors Pv
	  , hr_operating_units hrou
	  , PO_VENDOR_SITES_ALL pvs_abs
  WHERE Dsh.Set_Name = 'FUSION_SOCIETE_VERS_SOCIETE'
    AND Dsl.Set_Id = Dsh.Set_Id
    AND Dsl.Enable = 'Y'
        -- RG2: Type de la facture
    AND Aia.invoice_type_lookup_code = 'PREPAYMENT'
        -- RG2: Amount_Paid <> Invoice_Amount
    AND NVL(Aia.Invoice_Amount,0) = NVL(Aia.Amount_Paid,0)
    AND Fdsc.Application_Id = 200
    AND Fdsc.Code = Aia.Doc_Category_Code
        -- RG3: Mouvement doit appartenir a la societe absorbee
  --  AND Fdsc.Name LIKE (substr(Dsl.Param1_Value,4,4)||'%')
    AND hrou.name = dsl.param1_value
    AND aia.org_id = hrou.organization_id
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id)
    AND Pvsa.Vendor_Site_Id = Aia.Vendor_Site_Id
    AND Ate.Term_Id = Aia.Terms_Id
    AND Pv.Vendor_Id = Aia.Vendor_Id
      -- RG2: Ensemble des lignes de la facture postees
    AND NOT EXISTS ( SELECT 'x'
					   FROM Ap_Invoice_Distributions_All Aida
					  WHERE Aida.Invoice_id = Aia.Invoice_Id
					    AND NVL(Aida.Accrual_Posted_Flag,'N') <> 'Y' )
   AND Pvsa.location_id =  PVS_ABS.location_id 
   AND Pvsa.vendor_id    = pvs_abs.vendor_id
   and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
											  FROM HR_ORGANIZATION_UNITS HOU,
												   DKA_STRANSCO_LINES DSTL,
												   DKA_STRANSCO_HEADERS DSTH
											 WHERE DSTL.SET_ID = DSTH.SET_ID
											   AND HOU.NAME = DSTL.RETURN_VALUE
											   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
											   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
											   AND DSTL.ENABLE = 'Y'
											   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
											   and rownum<2))  
 union 
-- Acomptes
 SELECT distinct
	    Pv.Vendor_Name                          VENDOR_NAME   
	  , Pvsa.Vendor_Site_Code                   VENDOR_SITE_CODE
	  , HROU.name                                NAME
	   , Pv.vendor_id
       , Pvsa.VENDOR_SITE_id       
       , HROU.organization_id
       , Pvsa.location_id	
	   , pvs_abs.VENDOR_SITE_CODE              VENDOR_SITE_CODE_ABS
	   , pvs_abs.VENDOR_SITE_ID                VENDOR_SITE_ID_ABS	   
	   , pvs_abs.org_id				  		   ORG_ABS
	   , (select name from hr_organization_units
	       where organization_id= pvs_abs.org_id	)			  ORG_NAME_ABS
   FROM Ap_Invoices_All  Aia
	  , Po_Vendor_Sites_All Pvsa
	  , Po_Vendors Pv
	  , HR_OPERATING_UNITS HROU
	  , PO_VENDOR_SITES_ALL pvs_abs
  WHERE Aia.org_id          					= HROU.organization_id
    AND Aia.vendor_id       					= Pv.vendor_id
    AND Pvsa.Vendor_Site_Id 					= Aia.Vendor_Site_Id
    AND Pvsa.vendor_id      					= Pv.vendor_id
	AND pvsa.STATUS         					='A'
	AND pvsa.location_id =  PVS_ABS.location_id 
    AND pvsa.vendor_id    = pvs_abs.vendor_id
	AND HROU.organization_id = nvl(P_UO_ABSORBEE,HROU.organization_id)
    and pvs_abs.org_id = nvl(P_UO_ABSORBANTE,(SELECT HOU.ORGANIZATION_ID
											  FROM HR_ORGANIZATION_UNITS HOU,
												   DKA_STRANSCO_LINES DSTL,
												   DKA_STRANSCO_HEADERS DSTH
											 WHERE DSTL.SET_ID = DSTH.SET_ID
											   AND HOU.NAME = DSTL.RETURN_VALUE
											   AND DSTL.param1_value=(select name from HR_ORGANIZATION_UNITS hr where hr.organization_id=hrou.organization_id)
											   AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
											   AND DSTL.ENABLE = 'Y'
											   AND NVL(DSTL.END_DATE  ,TRUNC(SYSDATE) )   >= TRUNC(SYSDATE)
											   and rownum<2)) 
	--------------------RG-FRS4 
   and NVL(Aia.creation_date,TRUNC(SYSDATE) ) >= to_date(add_months(sysdate,-18),'dd-mm-rrrr')
;
	
	IBAN     				 varchar2(50);
	IBAN_ABS 				 varchar2(50);
	Relation_location_id     number;
	Relation_location_ABS    number;
	CDT_REGLEMENT            varchar2(50);
	CDT_REGLEMENT_ABS        varchar2(50);
	STATUS					 varchar2(50);
	SITE_ACHAT				 varchar2(50);
	SITE_REGLEMENT			 varchar2(50);
	inactive_date            date;
	
  BEGIN
  
  
    Dka_Tools_Pkg.Put_Outdebug_Message('-----------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Traitement                                                : DKA : FUSION PO - Etape Contrôle des sites fournisseurs');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Date et Heure                                             : ' ||
                                            to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message('------------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('');
 -- initialisation des compteurs   
	  v_compteur_export_site_inex := 0;
      v_compteur_export_site_exts := 0; 
	  commentaire                 := null;
-- Ecriture des noms de colonnes dans le fichier des entetes de commandes
	p_fic_out_name_1 := 'DKA_SITES_FOURNISSEURS_MQTS.csv';
	p_fic_out_name_2 := 'DKA_SITES_FOURNISSEURS_EXTS.csv';
	p_dir_out        := 'DKA_OUT_DIR';
    p_fic_out        := UTL_FILE.FOPEN(p_dir_out,
                                      p_fic_out_name_1,
                                      'W',
                                      32764); 
	p_fic_out_exi       := UTL_FILE.FOPEN(p_dir_out,
                                      p_fic_out_name_2,
                                      'W',
                                      32764); 
 
    UTL_FILE.PUT_LINE(p_fic_out,
            'NOM FOURNISSEUR'                    || v_sep ||
            'CODE SITE'                          || v_sep ||
            'UO DUPLICATION '                    || v_sep     
           
              ); 
    UTL_FILE.PUT_LINE(p_fic_out_exi,
            'NOM FOURNISSEUR'                    || v_sep ||
            'CODE SITE'                          || v_sep ||
            'UO DUPLICATION '                    || v_sep ||
            'ACTION'                             || v_sep			
           
              );  
	-- Log du nombre d'enregistrements		 
	
	    Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('*********LISTE DES SITES FOURNISSEURS A DUPLIQUER SUR LA SOCIETE ABSORBANTE*********');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('Nom fournisseur;code site;Unité opérationnelle         ');
		Dka_Tools_Pkg.Put_Outdebug_Message('');

	-- Ecriture des enregistrements dans le fichier des entetes de commandes
	FOR site_inex IN cur_site_inex  LOOP
		begin
       
   -- Ouverture des fichiers de sortie
		--- fichier 1: sites inexistants
            UTL_FILE.PUT_LINE(p_fic_out,
										site_inex.VENDOR_NAME                                      || v_sep ||
										site_inex.VENDOR_SITE_CODE                                 || v_sep ||
										site_inex.NAME                                             || v_sep 
                              );
            v_compteur_export_site_inex:= v_compteur_export_site_inex + 1;
		EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                          ' - ' || SQLERRM);
          p_retcode := 1;
		end ;
        Dka_Tools_Pkg.Put_Outdebug_Message(site_inex.VENDOR_NAME||';'||site_inex.VENDOR_SITE_CODE ||';'||site_inex.NAME);		
	END LOOP;
	    Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------');
	    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre des sites fournisseurs manquants sur la société absorbante     : ' ||
										v_compteur_export_site_inex);
		Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------');
		Dka_Tools_Pkg.Put_Outdebug_Message('');
	    Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('*********           LISTE DES SITES FOURNISSEURS A METTRE A JOUR             *********');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('Nom fournisseur;code site absorbé;code site absorbant;Action         ');
		Dka_Tools_Pkg.Put_Outdebug_Message('');
	
    FOR site_exitant IN cur_site_exi_AP  LOOP 
    -- Ouverture des fichiers de sortie	
	     --- fichier 1: sites inexistants
		 begin 
		    Relation_location_id := null;
		    Relation_location_ABS := null;
            IBAN :=null;	
            IBAN_ABS := null;
            CDT_REGLEMENT := null;
			CDT_REGLEMENT_ABS := null;
		    -- Reccuperation des informations sur les sites  (IBAN, Statut, Relation ..)
			-- IBAN Absorbe
			BEGIN   
				select ieb.iban into IBAN
				  from iby_ext_bank_accounts             ieb,
					   iby_pmt_instr_uses_all            ipi,
					   iby_external_payees_all           iep
				where 1=1
				 AND iep.supplier_site_id            = site_exitant.VENDOR_SITE_ID
				 AND iep.ext_payee_id                = ipi.ext_pmt_party_id
				 AND ipi.instrument_id               = ieb.ext_bank_account_id
				 AND NVL(IEB.START_DATE ,SYSDATE)      <=  SYSDATE  
				 AND NVL(IEB.END_DATE ,SYSDATE)      >=  SYSDATE 
				 and ipi.PAYMENT_FUNCTION  = 'PAYABLES_DISB'
				 and ipi.order_of_preference=1; 
		    exception 
			    When others then 
				    Fnd_File.put_line (Fnd_File.LOG, 'Iban inexistant pour le site ' ||site_exitant.Vendor_Site_Code || ' - Organization :' ||site_exitant.name);
				end;
		    
			-- IBAN Absorbant
			BEGIN
				select ieb.iban into IBAN_ABS
				  from iby_ext_bank_accounts             ieb,
					   iby_pmt_instr_uses_all            ipi,
					   iby_external_payees_all           iep
				where 1=1
				 AND iep.supplier_site_id            = site_exitant.VENDOR_SITE_ID_ABS
				 AND iep.ext_payee_id                = ipi.ext_pmt_party_id
				 AND ipi.instrument_id               = ieb.ext_bank_account_id
				 AND NVL(IEB.START_DATE ,SYSDATE)      <=  SYSDATE  
				 AND NVL(IEB.END_DATE ,SYSDATE)      >=  SYSDATE  
				 and ipi.PAYMENT_FUNCTION  = 'PAYABLES_DISB'
				 and ipi.order_of_preference=1;
		    exception 
			    When others then 
				    Fnd_File.put_line (Fnd_File.LOG, 'Iban inexistant pour le site ' ||site_exitant.Vendor_Site_Code ||' - Organization :' ||site_exitant.name);
				end;
			
			if nvl(IBAN_ABS,'A') <> nvl(IBAN,'A') then
				Commentaire := 'compte bancaire non conforme - IBAN absorbé :'||IBAN||' - IBAN absorbant :'||IBAN_ABS ;
				Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);
				UTL_FILE.PUT_LINE(p_fic_out_exi,
								site_exitant.VENDOR_NAME                                      || v_sep ||
								site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
								site_exitant.NAME                                             || v_sep ||
								Commentaire                                                   || v_sep
				 );
				 v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;
			end if;
			
			
			-- FACTOR ABSORBE
		    BEGIN
				   select apsite_rmt.location_id  into   Relation_location_id
					from ap_supplier_sites_all             apsite_rmt
						 , iby_ext_payee_relationships       iepr/*
						 , hz_parties                        hzp          
						 , hz_parties                        hzp_rmt*/
				   where iepr.supplier_site_id           = site_exitant.VENDOR_SITE_id
					 AND iepr.remit_supplier_site_id     = apsite_rmt.vendor_site_id 
                     and sysdate between iepr.from_date and iepr.to_date;
					 
					 
		    exception 
			    When others then 
				    Fnd_File.put_line (Fnd_File.LOG, 'Factor inexistant ' ||site_exitant.Vendor_Site_Code ||' - Organization :' ||site_exitant.name);
				end;
            -- FACTOR ABSORBANT
		    BEGIN
				   select apsite_rmt.location_id  into   Relation_location_ABS
					from ap_supplier_sites_all             apsite_rmt
						 , iby_ext_payee_relationships       iepr/*
						 , hz_parties                        hzp          
						 , hz_parties                        hzp_rmt*/
				   where iepr.supplier_site_id           = site_exitant.VENDOR_SITE_ID_ABS
					 AND iepr.remit_supplier_site_id     = apsite_rmt.vendor_site_id  
					 and sysdate between iepr.from_date and iepr.to_date;
		    exception 
			    When others then 
				    Fnd_File.put_line (Fnd_File.LOG, 'Factor inexistant ' ||site_exitant.Vendor_Site_Code ||' - Organization :' ||site_exitant.ORG_NAME_ABS);
				end;
			--if Relation_location_id is not null then
				if nvl(Relation_location_ABS,1) <> nvl(Relation_location_id,nvl(Relation_location_ABS,1)) then
					Commentaire := 'Factor non conforme' ;
					Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);
					UTL_FILE.PUT_LINE(p_fic_out_exi,
									site_exitant.VENDOR_NAME                                      || v_sep ||
									site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
									site_exitant.NAME                                             || v_sep ||
									Commentaire                                                   || v_sep
					 );
					 v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;

				end if;
            --end if;
				
			-- SITE REGLEMENT ABSORBE
			BEGIN
				select apt.name        into		 CDT_REGLEMENT
				  from ap_terms                          apt
					 , PO_VENDOR_SITES_ALL               povsa
				 where povsa.terms_id                  = apt.term_id
				   and povsa.vendor_site_id   = site_exitant.vendor_site_id ;
		    exception 
			    When others then 
				    Fnd_File.put_line (Fnd_File.LOG, 'Condition de reglement inexistante ' ||site_exitant.Vendor_Site_Code ||' - Organization :' ||site_exitant.name);
				end;
			-- SITE REGLEMENT ABSORBANT
			BEGIN
				select apt.name        into		 CDT_REGLEMENT_ABS
				  from ap_terms                          apt
					 , PO_VENDOR_SITES_ALL               povsa
				 where povsa.terms_id                  = apt.term_id
				   and povsa.vendor_site_id   = site_exitant.VENDOR_SITE_ID_ABS ;
		    exception 
			    When others then 
				    Fnd_File.put_line (Fnd_File.LOG, 'Condition de reglement inexistante ' ||site_exitant.Vendor_Site_Code ||' - Organization :' ||site_exitant.name);
				end;
			if CDT_REGLEMENT <> CDT_REGLEMENT_ABS then
				Commentaire := 'Condition de reglement non conforme - Condition de reglement absorbé :'||CDT_REGLEMENT||' - Condition de reglement  absorbant :'||CDT_REGLEMENT_ABS ;
				Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);
				UTL_FILE.PUT_LINE(p_fic_out_exi,
								site_exitant.VENDOR_NAME                                      || v_sep ||
								site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
								site_exitant.NAME                                             || v_sep ||
								Commentaire                                                   || v_sep
				 );
                v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;
			end if;
			
			
			
			  select  pvs_abs.status                                	
					, pvs_abs.purchasing_site_flag       	
					, pvs_abs.pay_site_flag          
                    , pvs_abs.inactive_date   					
				into STATUS
				    , SITE_ACHAT
					, SITE_REGLEMENT
					, inactive_date
				from Po_Vendor_Sites_All pvs_abs
			   where pvs_abs.VENDOR_SITE_ID =site_exitant.VENDOR_SITE_ID_ABS;
			
		 ---- RG-FRS3-A : site désactivé  
	        
			
			IF ((status = 'I') or (nvl(inactive_date,sysdate) < sysdate))
				THEN
				Commentaire :='Site désactivé'; 
				Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);
				UTL_FILE.PUT_LINE(p_fic_out_exi,
								site_exitant.VENDOR_NAME                                      || v_sep ||
								site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
								site_exitant.NAME                                             || v_sep ||
								Commentaire                                                   || v_sep
				 );
				 v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;
				end if;
			IF SITE_REGLEMENT = 'N'
				THEN
				Commentaire :='Site de Reglement à réactiver';
				Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);				
				UTL_FILE.PUT_LINE(p_fic_out_exi,
								site_exitant.VENDOR_NAME                                      || v_sep ||
								site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
								site_exitant.NAME                                             || v_sep ||
								Commentaire                                                   || v_sep
				 );
				 v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;
			END IF;	
							
			

				
		EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                          ' - ' || SQLERRM);
          p_retcode := 1;
		
		END ;
    END LOOP;	
	
	
        FOR site_exitant IN cur_site_exi_PO  LOOP 	
		      select  pvs_abs.status                                 	
					, pvs_abs.purchasing_site_flag        	
					, pvs_abs.pay_site_flag            
                    , pvs_abs.inactive_date   					
				into STATUS
				    , SITE_ACHAT
					, SITE_REGLEMENT
					, inactive_date
				from Po_Vendor_Sites_All pvs_abs
			   where pvs_abs.VENDOR_SITE_ID =site_exitant.VENDOR_SITE_ID_ABS;
			   
				IF ((status = 'I') or (nvl(inactive_date,sysdate) < sysdate))
				THEN
				Commentaire :='Site désactivé'; 
				Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);
				UTL_FILE.PUT_LINE(p_fic_out_exi,
								site_exitant.VENDOR_NAME                                      || v_sep ||
								site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
								site_exitant.NAME                                             || v_sep ||
								Commentaire                                                   || v_sep
				 );
				 v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;
				end if;
				
				IF SITE_ACHAT = 'N'
					THEN
					Commentaire :='Site d''ACHAT à réactiver'; 
					Dka_Tools_Pkg.Put_Outdebug_Message(site_exitant.VENDOR_NAME||';'||site_exitant.NAME||'-'||site_exitant.VENDOR_SITE_CODE ||';'||site_exitant.ORG_NAME_ABS||'-'||site_exitant.VENDOR_SITE_CODE_abs ||';'||Commentaire);				
					UTL_FILE.PUT_LINE(p_fic_out_exi,
									site_exitant.VENDOR_NAME                                      || v_sep ||
									site_exitant.VENDOR_SITE_CODE                                 || v_sep ||
									site_exitant.NAME                                             || v_sep ||
									Commentaire                                                   || v_sep
					 );
					 v_compteur_export_site_exts:= v_compteur_export_site_exts + 1;
				END IF;	
		END LOOP;
	
	
	
	
	
	    Dka_Tools_Pkg.Put_Outdebug_Message('');
	    Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------');
		Dka_Tools_Pkg.Put_Outdebug_Message('Nombre de modifications sur les sites fournisseurs absorbant     : ' ||
										v_compteur_export_site_exts);
        Dka_Tools_Pkg.Put_Outdebug_Message('---------------------------------------------------------------------------------------');
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('*********Fin des logs de traitements DKA : FUSION PO -Controle site fournisseur*******');
		Dka_Tools_Pkg.Put_Outdebug_Message('**************************************************************************************');
		Dka_Tools_Pkg.Put_Outdebug_Message('');
		Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
		Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
		Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
		Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuf);
	 
END Main;

END DKA_FUSPOCTRSUP_PKG;



/
SHOW ERRORS
EXIT