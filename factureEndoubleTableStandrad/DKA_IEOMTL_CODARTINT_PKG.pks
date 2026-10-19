CREATE OR REPLACE PACKAGE BODY DKA_FUSPOCMDEXP_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_FUSPOCMDEXP_PKG
  -- Description      : Body du package DKA_FUSPOCMDEXP_PKG
  -- Auteur           : Samir EL OUAHABI
  -- Date de création : 01/09/2019
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  ---------------------------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  ---------------------------------------------------------------------------------------------
  -- Version   Date         Qui Description
  ---------- -------------- --- ---------------------------------------------------------------
  -- V1.0    01/09/2019     SELO  Creation
  -- V2.0    17/01/2020     SELO  Modification, SFD : SPE098_ACHATS_SFD20190011_Automatisation de la Fusion PO V1.3
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
  PROCEDURE Main( p_errbuf OUT VARCHAR2, 
				  p_retcode OUT NUMBER --,
				--  P_TRANSCODIFICATION   VARCHAR2,
				--  P_UO_ABSORBEE         NUMBER
				  ) IS

    CURSOR cur_ent_cmd  IS
    SELECT  poha.SEGMENT1
         ,poha.po_header_id
         ,poha.TYPE_LOOKUP_CODE
         ,poha.CURRENCY_CODE
         ,papf.FULL_NAME
         ,pov.VENDOR_NAME
         ,povsa.VENDOR_SITE_CODE
         ,REPLACE(poscvv.CONTACT,',','') CONTACT
         ,hrla.LOCATION_CODE SHIP_TO_LOCATION
         ,hrla2.LOCATION_CODE BILL_TO_LOCATION
         ,poha.COMMENTS
         ,poha.ORG_ID           -- SELO
         ,HROU.name        UO_NAME		 
         ,glcc.SEGMENT1 SOCIETE
         ,glcc.SEGMENT2 REGION
         ,apt.NAME
         ,poha.AUTHORIZATION_STATUS
         ,poha.APPROVED_DATE
         ,poha.REVISION_NUM
         ,poha.NOTE_TO_VENDOR
         ,poha.NOTE_TO_RECEIVER
         ,poha.ATTRIBUTE_CATEGORY
         ,poha.ATTRIBUTE1
         ,poha.ATTRIBUTE2
         ,poha.ATTRIBUTE6
         ,poha.ATTRIBUTE8
		 ,poha.ATTRIBUTE11 -- SELO au lieu de amount_init sur la version 11i
         ,poha.ATTRIBUTE12
         ,poha.ATTRIBUTE13
         ,poha.ATTRIBUTE14
         /*,SUM(pola.unit_price * (SELECT SUM(ll.quantity - ll.quantity_cancelled - ll.quantity_rejected)
                                 FROM  po_line_locations_all ll
                                 WHERE ll.po_line_id = pola.po_line_id
                                 ) 
          )amount_init*/
		  ,poha.CLOSED_CODE
    FROM PO_HEADERS_ALL poha
      ,PER_ALL_PEOPLE_F papf
      ,PO_VENDORS pov
      ,PO_VENDOR_SITES_ALL povsa
      ,PO_SUPPLIER_CONTACTS_VAL_V poscvv
      ,HR_LOCATIONS_ALL hrla
      ,HR_LOCATIONS_ALL hrla2    
      ,GL_CODE_COMBINATIONS glcc
      ,PO_DISTRIBUTIONS_ALL poda
      ,PO_LINES_ALL pola
      ,AP_TERMS apt
	  ,HR_OPERATING_UNITS HROU
    WHERE 1=1 
    AND poha.type_lookup_code        = 'STANDARD'
    AND NVL(poha.closed_code,'OPEN') = 'OPEN'
    AND NVL(poha.cancel_flag,'N')    = 'N'
    AND authorization_status         = 'APPROVED' 
    AND poha.ORG_ID                  = HROU.organization_id
    AND poha.AGENT_ID                = papf.person_id
    AND papf.current_employee_flag   = 'Y' 
    AND poha.VENDOR_ID               = pov.VENDOR_ID
    AND poha.VENDOR_SITE_ID          = povsa.VENDOR_SITE_ID
    AND poha.vendor_contact_id       = poscvv.vendor_contact_id (+)
    AND poha.SHIP_TO_LOCATION_ID     = hrla.location_id
    AND poha.BILL_TO_LOCATION_ID     = hrla2.location_id 
    AND poha.TERMS_ID= apt.TERM_ID 
    AND EXISTS (SELECT '1'
                FROM po_line_locations_all polla, PO_LINES_ALL pola2
                WHERE pola2.po_header_id = poha.po_header_id
                AND   polla.po_header_id = pola2.po_header_id
                AND   polla.po_line_id   = pola2.po_line_id
                AND   polla.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
                AND   NVL(polla.cancel_flag,'N') = 'N'
                AND   (polla.quantity - polla.quantity_cancelled - polla.quantity_rejected - polla.quantity_billed) > 0
                AND   ROWNUM = 1
                )
    AND poda.po_header_id = poha.po_header_id
    AND poda.po_distribution_id = (SELECT MIN(poda2.po_distribution_id)
                                   FROM PO_DISTRIBUTIONS_ALL poda2, PO_LINE_LOCATIONS_ALL polla
                                   WHERE poda2.po_header_id = poha.po_header_id
                                     -- 26/01/2017  NBO  artf2090379 - RUN2 - Extraction des commandes - Erreur unité opérationnelle
                                   AND (poda2.quantity_ordered - poda2.quantity_cancelled - poda2.quantity_billed) > 0
                                   AND   polla.line_location_id         = poda2.line_location_id 
                                   AND   polla.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
                                   AND   NVL(polla.cancel_flag,'N') = 'N'
                                  )

    AND poda.CODE_COMBINATION_ID = glcc.CODE_COMBINATION_ID  
    AND poha.po_header_id        = pola.po_header_id   
--	AND poha.SEGMENT1='4708650' -- SELO
/*	AND ( P_TRANSCODIFICATION = 'Y'
		  OR ( P_TRANSCODIFICATION = 'N'
			   AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )	
*/	
	and 
	    HROU.organization_id in (
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
				-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
				 )
	
	-- AND poha.attribute12 IS NULL  -- SELO
    ----------------------------------------------------------------------------
    GROUP BY poha.SEGMENT1
            ,poha.po_header_id
            ,poha.TYPE_LOOKUP_CODE
            ,poha.CURRENCY_CODE
            ,papf.FULL_NAME
            ,pov.VENDOR_NAME
            ,povsa.VENDOR_SITE_CODE
            ,poscvv.CONTACT
            ,hrla.LOCATION_CODE
            ,hrla2.LOCATION_CODE
            ,poha.COMMENTS
			,poha.ORG_ID           -- SELO
			,HROU.name        			
            ,glcc.SEGMENT1
            ,glcc.SEGMENT2
            ,apt.NAME
            ,poha.AUTHORIZATION_STATUS
            ,poha.APPROVED_DATE
            ,poha.REVISION_NUM
            ,poha.NOTE_TO_VENDOR
            ,poha.NOTE_TO_RECEIVER
            ,poha.ATTRIBUTE_CATEGORY
            ,poha.ATTRIBUTE1
            ,poha.ATTRIBUTE2
            ,poha.ATTRIBUTE6
            ,poha.ATTRIBUTE8
			,poha.ATTRIBUTE11 -- SELO au lieu de amount_init sur la version 11i
            ,poha.ATTRIBUTE12
            ,poha.ATTRIBUTE13
            ,poha.ATTRIBUTE14
			,poha.CLOSED_CODE			
    union
	SELECT  poha.SEGMENT1
         ,poha.po_header_id
         ,poha.TYPE_LOOKUP_CODE
         ,poha.CURRENCY_CODE
         ,papf.FULL_NAME
         ,pov.VENDOR_NAME
         ,povsa.VENDOR_SITE_CODE
         ,REPLACE(poscvv.CONTACT,',','') CONTACT
         ,hrla.LOCATION_CODE SHIP_TO_LOCATION
         ,hrla2.LOCATION_CODE BILL_TO_LOCATION
         ,poha.COMMENTS
         ,poha.ORG_ID           -- SELO
         ,HROU.name        UO_NAME		 
         ,glcc.SEGMENT1 SOCIETE
         ,glcc.SEGMENT2 REGION
         ,apt.NAME
         ,poha.AUTHORIZATION_STATUS
         ,poha.APPROVED_DATE
         ,poha.REVISION_NUM
         ,poha.NOTE_TO_VENDOR
         ,poha.NOTE_TO_RECEIVER
         ,poha.ATTRIBUTE_CATEGORY
         ,poha.ATTRIBUTE1
         ,poha.ATTRIBUTE2
         ,poha.ATTRIBUTE6
         ,poha.ATTRIBUTE8
		 ,poha.ATTRIBUTE11 -- SELO au lieu de amount_init sur la version 11i
         ,poha.ATTRIBUTE12
         ,poha.ATTRIBUTE13
         ,poha.ATTRIBUTE14
         /*,SUM(pola.unit_price * (SELECT SUM(ll.quantity - ll.quantity_cancelled - ll.quantity_rejected)
                                 FROM  po_line_locations_all ll
                                 WHERE ll.po_line_id = pola.po_line_id
                                 ) 
          )amount_init*/
          , poha.CLOSED_CODE
    FROM PO_HEADERS_ALL poha
      ,PER_ALL_PEOPLE_F papf
      ,PO_VENDORS pov
      ,PO_VENDOR_SITES_ALL povsa
      ,PO_SUPPLIER_CONTACTS_VAL_V poscvv
      ,HR_LOCATIONS_ALL hrla
      ,HR_LOCATIONS_ALL hrla2    
      ,GL_CODE_COMBINATIONS glcc
      ,PO_DISTRIBUTIONS_ALL poda
      ,PO_LINES_ALL pola
      ,AP_TERMS apt
	  ,HR_OPERATING_UNITS HROU
    WHERE 1=1 
    AND poha.type_lookup_code        = 'STANDARD'
   -- AND NVL(poha.closed_code,'OPEN') = 'OPEN'
    AND NVL(poha.cancel_flag,'N')    = 'N'
    AND authorization_status         = 'APPROVED' 
    AND poha.ORG_ID                  = HROU.organization_id
    AND poha.AGENT_ID                = papf.person_id
    AND papf.current_employee_flag   = 'Y' 
    AND poha.VENDOR_ID               = pov.VENDOR_ID
    AND poha.VENDOR_SITE_ID          = povsa.VENDOR_SITE_ID
    AND poha.vendor_contact_id       = poscvv.vendor_contact_id (+)
    AND poha.SHIP_TO_LOCATION_ID     = hrla.location_id
    AND poha.BILL_TO_LOCATION_ID     = hrla2.location_id 
    AND poha.TERMS_ID= apt.TERM_ID 
    AND NOT EXISTS (SELECT '1'
                FROM po_line_locations_all polla, PO_LINES_ALL pola2
                WHERE pola2.po_header_id = poha.po_header_id
                AND   polla.po_header_id = pola2.po_header_id
                AND   polla.po_line_id   = pola2.po_line_id
                AND   NVL(polla.cancel_flag,'N') = 'N'
                    AND   ((polla.quantity - polla.quantity_cancelled - polla.quantity_rejected - polla.quantity_billed) > 0 
                       and
                       polla.CLOSED_CODE NOT IN ('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE'))
                AND   ROWNUM = 1
                )
    AND poda.po_header_id = poha.po_header_id
    AND poda.po_distribution_id = (SELECT MIN(poda2.po_distribution_id)
                                   FROM PO_DISTRIBUTIONS_ALL poda2, PO_LINE_LOCATIONS_ALL polla
                                   WHERE poda2.po_header_id = poha.po_header_id
                                     -- 26/01/2017  NBO  artf2090379 - RUN2 - Extraction des commandes - Erreur unité opérationnelle
                                   AND ((poda2.quantity_ordered - poda2.quantity_cancelled - poda2.quantity_billed) <= 0
                                        or
                                         polla.CLOSED_CODE  IN ('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE'))
                                   AND   polla.line_location_id         = poda2.line_location_id 
                                   
                                   AND   NVL(polla.cancel_flag,'N') = 'N'
                                  )

    AND poda.CODE_COMBINATION_ID = glcc.CODE_COMBINATION_ID  
    AND poha.po_header_id        = pola.po_header_id   
 	AND poha.SEGMENT1 like '%ST%' -- SELO
/*	AND ( P_TRANSCODIFICATION = 'Y'
		  OR ( P_TRANSCODIFICATION = 'N'
			   AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )	
*/	
	and 
	    HROU.organization_id in (
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
				-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
				 )
--	and rownum<2
  --  AND poha.SEGMENT1 like '4016984ST1801' -- SELO
    AND exists (    select 1
                      from DKA_CONTRAT_SSTR ss
                         , po_headers_all              pha
                     where 1=1
                       and poha.po_header_id=ss.commande_id
					   and pha.po_header_id=ss.po_header_id
                    and pha.org_id 					= hrou.ORGANIZATION_ID
                    AND pha.type_lookup_code        = 'CONTRACT'
                    AND pha.attribute4 IS NOT NULL
                    AND NVL(pha.closed_code,'OPEN') = 'OPEN'
                    AND NVL(pha.cancel_flag,'N')    = 'N'
                    --AND authorization_status         = 'APPROVED'
                )
	-- AND poha.attribute12 IS NULL  -- SELO
    ----------------------------------------------------------------------------
    GROUP BY poha.SEGMENT1
            ,poha.po_header_id
            ,poha.TYPE_LOOKUP_CODE
            ,poha.CURRENCY_CODE
            ,papf.FULL_NAME
            ,pov.VENDOR_NAME
            ,povsa.VENDOR_SITE_CODE
            ,poscvv.CONTACT
            ,hrla.LOCATION_CODE
            ,hrla2.LOCATION_CODE
            ,poha.COMMENTS
			,poha.ORG_ID           -- SELO
			,HROU.name        			
            ,glcc.SEGMENT1
            ,glcc.SEGMENT2
            ,apt.NAME
            ,poha.AUTHORIZATION_STATUS
            ,poha.APPROVED_DATE
            ,poha.REVISION_NUM
            ,poha.NOTE_TO_VENDOR
            ,poha.NOTE_TO_RECEIVER
            ,poha.ATTRIBUTE_CATEGORY
            ,poha.ATTRIBUTE1
            ,poha.ATTRIBUTE2
            ,poha.ATTRIBUTE6
            ,poha.ATTRIBUTE8
			,poha.ATTRIBUTE11 -- SELO au lieu de amount_init sur la version 11i
            ,poha.ATTRIBUTE12
            ,poha.ATTRIBUTE13
            ,poha.ATTRIBUTE14  
            ,poha.CLOSED_CODE
    ;
    
  CURSOR cur_lig_cmd (p_header_id IN VARCHAR2) IS  
    SELECT poha.SEGMENT1
	,poha.ORG_ID           -- SELO
    ,polla.line_location_id
    ,poha.po_header_id
    ,pola.LINE_NUM
    ,poltt.LINE_TYPE
	,mtlcb.SEGMENT1   CATEGORY_SEGMENT1      -- SELO
    ,mtlcb.SEGMENT2
    ,mtlcb.SEGMENT3
    ,mtlcb.SEGMENT4
    ,mtlcb.SEGMENT5
	,msib.SEGMENT1   ITEM_SEGMENT1      -- SELO
    ,msib.SEGMENT2   ITEM_SEGMENT2      -- SELO
     -- 26/01/2017    NBO    artf2090379 - RUN2 - Extraction des commandes - Erreur unité opérationnelle
    ,replace(replace(pola.ITEM_DESCRIPTION,chr(13)||chr(10),' '),'|', '/') ITEM_DESCRIPTION
    ,replace(pola.VENDOR_PRODUCT_NUM,'|','') VENDOR_PRODUCT_NUM
    ,pola.UNIT_MEAS_LOOKUP_CODE
    ,pola.UNIT_PRICE
    ,pola.LIST_PRICE_PER_UNIT
    ,pola.NOTE_TO_VENDOR
    ,pola.ATTRIBUTE2 LINE_ATTRIBUTE2
    ,polla.SHIPMENT_NUM
    ,polla.SHIPMENT_TYPE
    ,(polla.QUANTITY - polla.QUANTITY_REJECTED - polla.QUANTITY_CANCELLED) QUANTITY_CMD
    ,polla.QUANTITY_RECEIVED
    ,polla.QUANTITY_BILLED
    ,hrla.LOCATION_CODE
    ,polla.NEED_BY_DATE
    ,polla.PROMISED_DATE
    ,polla.inspection_required_flag
    ,polla.RECEIPT_REQUIRED_FLAG
    ,polla.qty_rcv_tolerance
    ,polla.QTY_RCV_EXCEPTION_CODE
    ,polla.ENFORCE_SHIP_TO_LOCATION_CODE
    ,polla.ALLOW_SUBSTITUTE_RECEIPTS_FLAG
    ,polla.DAYS_EARLY_RECEIPT_ALLOWED
    ,polla.DAYS_LATE_RECEIPT_ALLOWED
    ,polla.receipt_days_exception_code
    ,polla.INVOICE_CLOSE_TOLERANCE
    ,polla.RECEIVE_CLOSE_TOLERANCE
    ,rcvrh.ROUTING_NAME
    ,polla.MATCH_OPTION
    ,pola.ATTRIBUTE3  -- SELO

    FROM PO_HEADERS_ALL poha
      ,PO_LINES_ALL pola
      ,PO_LINE_TYPES_TL poltt
      ,MTL_CATEGORIES_B mtlcb
	  ,MTL_SYSTEM_ITEMS_B msib  -- SELO
      ,PO_LINE_LOCATIONS_ALL polla
      ,HR_LOCATIONS_ALL hrla
      ,RCV_ROUTING_HEADERS rcvrh
    WHERE poha.po_header_id IN (p_header_id)
    AND   poha.po_header_id = polla.po_header_id
    AND   polla.po_line_id  = pola.po_line_id
    AND   polla.CLOSED_CODE NOT IN ('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
    AND   NVL(polla.cancel_flag,'N') = 'N'
    AND   (polla.quantity - polla.quantity_cancelled - polla.quantity_rejected - polla.quantity_billed) > 0
    AND   poha.SEGMENT1 NOT LIKE '%ST%'
    AND   pola.LINE_TYPE_ID          = poltt.line_type_id --(+)
    AND   poltt.language             = 'F'
    AND   pola.CATEGORY_ID           = mtlcb.category_id --(+)
    AND   polla.SHIP_TO_LOCATION_ID  = hrla.location_id --(+) 
    AND   polla.RECEIVING_ROUTING_ID = rcvrh.routing_header_id --(+)
--	AND   poha.SEGMENT1='4708650' -- SELO
	and   msib.INVENTORY_ITEM_ID(+) = pola.ITEM_ID    -- SELO
    and   msib.ORGANIZATION_ID(+) = pola.ORG_ID       -- SELO
	
    UNION

    SELECT poha.SEGMENT1
	,poha.ORG_ID           -- SELO
    ,polla.line_location_id
    ,poha.po_header_id
    ,pola.LINE_NUM
    ,poltt.LINE_TYPE
	,mtlcb.SEGMENT1
    ,mtlcb.SEGMENT2
    ,mtlcb.SEGMENT3
    ,mtlcb.SEGMENT4
    ,mtlcb.SEGMENT5
	,msib.SEGMENT1         -- SELO
    ,msib.SEGMENT2         -- SELO
     -- 26/01/2017    NBO    artf2090379 - RUN2 - Extraction des commandes - Erreur unité opérationnelle
    ,replace(replace(pola.ITEM_DESCRIPTION,chr(13)||chr(10),' '),'|', '/') ITEM_DESCRIPTION
    ,replace(pola.VENDOR_PRODUCT_NUM,'|','') VENDOR_PRODUCT_NUM
    ,pola.UNIT_MEAS_LOOKUP_CODE
    ,pola.UNIT_PRICE
    ,pola.LIST_PRICE_PER_UNIT
    ,pola.NOTE_TO_VENDOR
    ,pola.ATTRIBUTE2 LINE_ATTRIBUTE2
    ,polla.SHIPMENT_NUM
    ,polla.SHIPMENT_TYPE
    ,(polla.QUANTITY - polla.QUANTITY_REJECTED - polla.QUANTITY_CANCELLED) QUANTITY_CMD
    ,polla.QUANTITY_RECEIVED
    ,polla.QUANTITY_BILLED
    ,hrla.LOCATION_CODE
    ,polla.NEED_BY_DATE
    ,polla.PROMISED_DATE
    ,polla.inspection_required_flag
    ,polla.RECEIPT_REQUIRED_FLAG
    ,polla.qty_rcv_tolerance
    ,polla.QTY_RCV_EXCEPTION_CODE
    ,polla.ENFORCE_SHIP_TO_LOCATION_CODE
    ,polla.ALLOW_SUBSTITUTE_RECEIPTS_FLAG
    ,polla.DAYS_EARLY_RECEIPT_ALLOWED
    ,polla.DAYS_LATE_RECEIPT_ALLOWED
    ,polla.receipt_days_exception_code
    ,polla.INVOICE_CLOSE_TOLERANCE
    ,polla.RECEIVE_CLOSE_TOLERANCE
    ,rcvrh.ROUTING_NAME
    ,polla.MATCH_OPTION
    ,pola.ATTRIBUTE3  -- SELO

    FROM PO_HEADERS_ALL poha
      ,PO_LINES_ALL pola
      ,PO_LINE_TYPES_TL poltt
      ,MTL_CATEGORIES_B mtlcb
      ,PO_LINE_LOCATIONS_ALL polla
      ,HR_LOCATIONS_ALL hrla
      ,RCV_ROUTING_HEADERS rcvrh
	  ,MTL_SYSTEM_ITEMS_B msib  -- SELO
    WHERE poha.po_header_id IN (p_header_id)
    AND   poha.po_header_id = polla.po_header_id
    AND   polla.po_line_id  = pola.po_line_id
    AND EXISTS (SELECT distinct '1'
          FROM PO_LINE_LOCATIONS_ALL polla2
          WHERE polla2.po_header_id IN (p_header_id)
        --  AND   polla2.CLOSED_CODE NOT IN('CLOSED', 'FINALLY CLOSED', 'CLOSED FOR INVOICE')
          AND   NVL(polla2.cancel_flag,'N') = 'N'
        --  AND   (polla2.quantity - polla2.quantity_cancelled - polla2.quantity_rejected - polla2.quantity_billed) > 0
          AND   ROWNUM = 1
           )
    AND   poha.SEGMENT1 LIKE '%ST%'
    AND   pola.LINE_TYPE_ID          = poltt.line_type_id --(+)
    AND   poltt.language             = 'F'
    AND   pola.CATEGORY_ID           = mtlcb.category_id --(+)
    AND   polla.SHIP_TO_LOCATION_ID  = hrla.location_id --(+) 
    AND   polla.RECEIVING_ROUTING_ID = rcvrh.routing_header_id --(+)  
--	AND   poha.SEGMENT1='4708650' -- SELO
	and   msib.INVENTORY_ITEM_ID(+) = pola.ITEM_ID    -- SELO
    and   msib.ORGANIZATION_ID(+) = pola.ORG_ID       -- SELO
  ;
  
  CURSOR cur_vent_cmd (p_line_location_id IN NUMBER) IS
    SELECT poha.SEGMENT1
	  ,poha.ORG_ID           -- SELO
      ,pola.LINE_NUM
      ,polla.SHIPMENT_NUM
      ,poda.DISTRIBUTION_NUM
      ,(poda.QUANTITY_ORDERED - poda.QUANTITY_CANCELLED) QTY_ORDERED 
      ,poda.QUANTITY_DELIVERED
      ,poda.QUANTITY_BILLED
      ,hrla.LOCATION_CODE
      ,(select distinct papf.FULL_NAME
        from PER_ALL_PEOPLE_F papf
        where poda.deliver_to_person_id      = papf.person_id 
          AND papf.current_employee_flag (+) = 'Y'
		  and rownum<2) FULL_NAME
      ,poda.DESTINATION_TYPE_CODE
      ,glcc.SEGMENT1 CHARGE_SEGMENT1
      ,glcc.SEGMENT2 CHARGE_SEGMENT2
      ,glcc.SEGMENT3 CHARGE_SEGMENT3
      ,glcc.SEGMENT4 CHARGE_SEGMENT4
      ,glcc.SEGMENT5 CHARGE_SEGMENT5
      ,glcc.SEGMENT6 CHARGE_SEGMENT6
      ,glcc.SEGMENT7 CHARGE_SEGMENT7
      ,glcc.SEGMENT8 CHARGE_SEGMENT8
      ,glcc.SEGMENT9 CHARGE_SEGMENT9
      ,glcc.SEGMENT10 CHARGE_SEGMENT10
      ,glcc2.SEGMENT1 ACCRUAL_SEGMENT1
      ,glcc2.SEGMENT2 ACCRUAL_SEGMENT2
      ,glcc2.SEGMENT3 ACCRUAL_SEGMENT3
      ,glcc2.SEGMENT4 ACCRUAL_SEGMENT4
      ,glcc2.SEGMENT5 ACCRUAL_SEGMENT5
      ,glcc2.SEGMENT6 ACCRUAL_SEGMENT6
      ,glcc2.SEGMENT7 ACCRUAL_SEGMENT7
      ,glcc2.SEGMENT8 ACCRUAL_SEGMENT8
      ,glcc2.SEGMENT9 ACCRUAL_SEGMENT9
      ,glcc2.SEGMENT10 ACCRUAL_SEGMENT10
      ,glcc3.SEGMENT1 VARIANCE_SEGMENT1
      ,glcc3.SEGMENT2 VARIANCE_SEGMENT2
      ,glcc3.SEGMENT3 VARIANCE_SEGMENT3
      ,glcc3.SEGMENT4 VARIANCE_SEGMENT4
      ,glcc3.SEGMENT5 VARIANCE_SEGMENT5
      ,glcc3.SEGMENT6 VARIANCE_SEGMENT6
      ,glcc3.SEGMENT7 VARIANCE_SEGMENT7
      ,glcc3.SEGMENT8 VARIANCE_SEGMENT8
      ,glcc3.SEGMENT9 VARIANCE_SEGMENT9
      ,glcc3.SEGMENT10 VARIANCE_SEGMENT10
      ,papa.SEGMENT1 PROJECT_CODE
	  , pt.TASK_NUMBER  TASK_CODE    --SELO
      ,poda.EXPENDITURE_TYPE
      ,poda.PROJECT_ACCOUNTING_CONTEXT
      ,hraou.NAME
      ,poda.EXPENDITURE_ITEM_DATE
      ,poda.ATTRIBUTE_CATEGORY
      ,poda.ATTRIBUTE3

  FROM PO_HEADERS_ALL poha
    ,PO_LINES_ALL pola
    ,PO_LINE_LOCATIONS_ALL polla
    ,PO_DISTRIBUTIONS_ALL poda
    ,HR_LOCATIONS_ALL hrla
    --,PER_ALL_PEOPLE_F papf
    ,GL_CODE_COMBINATIONS glcc
    ,GL_CODE_COMBINATIONS glcc2
    ,GL_CODE_COMBINATIONS glcc3    
    ,PA_PROJECTS_ALL papa
	,PA_TASKS PT	--SELO
    ,hr_all_organization_units hraou
  WHERE polla.line_location_id in (p_line_location_id)
  AND   polla.line_location_id         = poda.line_location_id 
  AND   poda.po_header_id              = poha.po_header_id
  AND   poda.po_line_id                = pola.po_line_id
  AND   poda.deliver_to_location_id    = hrla.location_id (+)
  AND   poda.CODE_COMBINATION_ID       = glcc.CODE_COMBINATION_ID (+)
  AND   poda.accrual_account_id        = glcc2.CODE_COMBINATION_ID (+)
  AND   poda.variance_account_id       = glcc3.CODE_COMBINATION_ID (+)
  AND   poda.PROJECT_ID                = papa.project_id (+)
 -- AND   poda.deliver_to_person_id      = papf.person_id (+)
 -- AND   papf.current_employee_flag (+) = 'Y'
  AND   hraou.organization_id      (+) = poda.expenditure_organization_id  
  AND   ((poda.quantity_ordered - poda.quantity_cancelled - poda.quantity_billed) > 0 OR poha.SEGMENT1 like '%ST%')
--  AND 	poha.SEGMENT1='4708650' -- SELO
  AND   PT.TASK_ID   = poda.TASK_ID
   ;  

  CURSOR cur_liste_cmd  IS  
  select DSHT.uo_name, DSHT.document_num, DSHT.vendor_name, DSHT.vendor_site_code
  from DKA_SPOFUSION_HEADERS_TMP DSHT,
       hr_organization_units HROU
  where DSHT.ORG_ID                  = HROU.organization_id
  and HROU.organization_id in (
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
                 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE));
  
  v_compteur_export_ent_cmd NUMBER;
  v_compteur_export_lig_cmd NUMBER;
  v_compteur_export_vent_cmd NUMBER;
  
  -- fichiers de sortie
  
  p_fic_out_ptr     UTL_FILE.FILE_TYPE;
  p_dir_out         VARCHAR2(120);
 -- p_fic_out_name    VARCHAR2(80);
 -- p_fic_out_name2   VARCHAR2(80);
 -- p_fic_out_name3   VARCHAR2(80);  
  
  TYPE entetes IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  entetes_cmd_list entetes;

  TYPE lignes_cmd IS TABLE OF NUMBER INDEX BY BINARY_INTEGER;
  lignes_cmd_list lignes_cmd;
  
  v_cpt         INTEGER      := 0;
  v_cpt2        INTEGER      := 0;  
  v_temp        NUMBER       := 0;
  v_sep         VARCHAR2(1)  := '|';
  v_org_id      NUMBER;
  v_RG_EXP01    INTEGER;  
  
  
  BEGIN
  
	g_user_id                       := fnd_global.user_id;
	BEGIN
		SELECT
					 distinct 1 into v_RG_EXP01
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
					-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE) )  <= TRUNC(SYSDATE)
					 group by DSTL.PARAM1_VALUE,
							  DSTL.RetuRN_VALUE
					 having count(PARAM1_VALUE)>1;
	exception
		  when others then
		        v_RG_EXP01:=0;										  
		  end;
	
	
	
	
	
    p_errbuf  := NULL;
    p_retcode := 0;
  
    -- Initialisation des compteurs
    v_compteur_export_ent_cmd := 0;
    v_compteur_export_lig_cmd := 0;
    v_compteur_export_vent_cmd := 0;  
  
  
    -- Ouverture fichier de sortie
    --p_fic_out_name  := 'DKA_PO_HEADERS'        || '.csv';
    --p_fic_out_name2 := 'DKA_PO_LINE_LOCATIONS' || '.csv';
    --p_fic_out_name3 := 'DKA_PO_DISTRIBUTIONS'  || '.csv';             
    --p_dir_out       := 'DKA_OUT_DIR';
    --p_fic_out_ptr   := UTL_FILE.FOPEN(p_dir_out,
                      --                p_fic_out_name,
                          --            'W',
                         --             32764);
  
    Dka_Tools_Pkg.Put_Outdebug_Message('-----------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Traitement                                                : DKA : Fusion PO - Etape Export pour reprise commandes');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Table temporaire de commandes                             : DKA_SPOFUSION_HEADERS_TMP');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Table temporaire des lignes et livraisons de commandes    : DKA_SPOFUSION_LINES_TMP');   
    Dka_Tools_Pkg.Put_Outdebug_Message('    Table temporaire des lignes de ventilations de commandes  : DKA_SPOFUSION_DISTRIBS_TMP');                                          
    Dka_Tools_Pkg.Put_Outdebug_Message('    Date et Heure                                             : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message('------------------------------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('');
    
	
	if  v_RG_EXP01 = 1 then
	
	    Dka_Tools_Pkg.put_log_message('RG_EXP01: Plusieurs couples actifs dans la table de transco ');
		Dka_Tools_Pkg.Put_Outdebug_Message('RG_EXP01: Plusieurs couples actifs dans la table de transco ');
	end if;
  -- Récupération de l'organization_id


-- SELO
/*
  BEGIN
    SELECT organization_id 
    INTO   v_org_id
    FROM   hr_operating_units
    WHERE  name = 'DCW0001';
  EXCEPTION
    WHEN OTHERS THEN
          v_org_id := NULL;
  END;
*/  
  -- Ecriture des noms de colonnes dans le fichier des entetes de commandes
 /* 
    UTL_FILE.PUT_LINE(p_fic_out_ptr,
            'DOCUMENT_NUM'                   || v_sep ||
            'TYPE_LOOKUP_CODE'               || v_sep ||
            'CURRENCY_CODE'                  || v_sep ||
            'AGENT_NAME'                     || v_sep ||
            'VENDOR_NAME'                    || v_sep ||
            'VENDOR_SITE_CODE'               || v_sep ||
            'VENDOR_CONTACT'                 || v_sep ||
            'SHIP_TO_LOCATION'               || v_sep ||
            'BILL_TO_LOCATION'               || v_sep ||
            'COMMENTS'                       || v_sep ||
            'SOCIETE'                        || v_sep ||
            'REGION'                         || v_sep ||
            'PAYMENT_TERMS'                  || v_sep ||
            'APPROVAL_STATUS'                || v_sep ||
            'APPROVAL_DATE'                  || v_sep ||
            'REVISION_NUM'                   || v_sep ||
            'NOTE_TO_VENDOR'                 || v_sep ||
            'NOTE_TO_RECEIVER'               || v_sep ||
            'ATTRIBUTE_CATEGORY'             || v_sep ||
            'ATTRIBUTE1'                     || v_sep ||
            'ATTRIBUTE2'                     || v_sep ||
            'ATTRIBUTE6'                     || v_sep ||
            'ATTRIBUTE8'                     || v_sep ||
            'ATTRIBUTE12'                    || v_sep ||
            'ATTRIBUTE13'                    || v_sep ||
            'ATTRIBUTE14'                    || v_sep ||    
            'AMOUNT_INIT'
              );  
			
		*/	
    
	-- Supprimer toutes les lignes liee a UO absorbe dans les tables de travail.
	
	delete from DKA_SPOFUSION_HEADERS_TMP  
	      where org_id in (SELECT
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
									 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
									-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
							);
  
  
	delete from DKA_SPOFUSION_LINES_TMP
		  where org_id in (SELECT
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
									 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
									-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
							);


	delete from DKA_SPOFUSION_DISTRIBS_TMP
		  where org_id in (SELECT
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
									 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
									-- AND NVL(DSTL.START_DATE,TRUNC(SYSDATE))  <= TRUNC(SYSDATE)
								);
	
	
	
	
	-- Ecriture des enregistrements dans le fichier des entetes de commandes
	FOR ent_cmd IN cur_ent_cmd  LOOP
      BEGIN
        --dka_tools_pkg.put_debug_message('Extraction des entetes de commandes. COMMANDE N° : ' ||
                                        --ent_cmd.po_header_id);
        v_cpt := v_cpt + 1;
        entetes_cmd_list(v_cpt) := ent_cmd.po_header_id;
    
	/*
        UTL_FILE.PUT_LINE(p_fic_out_ptr,
            ent_cmd.SEGMENT1                                                       || v_sep ||
            ent_cmd.TYPE_LOOKUP_CODE                                               || v_sep ||
            ent_cmd.CURRENCY_CODE                                                  || v_sep ||
            ent_cmd.FULL_NAME                                                      || v_sep ||
            ent_cmd.VENDOR_NAME                                                    || v_sep ||
            ent_cmd.VENDOR_SITE_CODE                                               || v_sep ||
            ent_cmd.CONTACT                                                        || v_sep ||
            ent_cmd.SHIP_TO_LOCATION                                               || v_sep ||
            ent_cmd.BILL_TO_LOCATION                                               || v_sep ||
            ent_cmd.COMMENTS                                                       || v_sep ||
            ent_cmd.SOCIETE                                                        || v_sep ||
            ent_cmd.REGION                                                         || v_sep ||
            ent_cmd.NAME                                                           || v_sep ||
            ent_cmd.AUTHORIZATION_STATUS                                           || v_sep ||
            TO_CHAR(ent_cmd.APPROVED_DATE,'YYYY/MM/DD')                            || v_sep ||
            ent_cmd.REVISION_NUM                                                   || v_sep ||
            ent_cmd.NOTE_TO_VENDOR                                                 || v_sep ||
            ent_cmd.NOTE_TO_RECEIVER                                               || v_sep ||
            ent_cmd.ATTRIBUTE_CATEGORY                                             || v_sep ||
            ent_cmd.ATTRIBUTE1                                                     || v_sep ||
            ent_cmd.ATTRIBUTE2                                                     || v_sep ||
            ent_cmd.ATTRIBUTE6                                                     || v_sep ||
            ent_cmd.ATTRIBUTE8                                                     || v_sep ||
            ent_cmd.ATTRIBUTE12                                                    || v_sep ||
            ent_cmd.ATTRIBUTE13                                                    || v_sep ||
            ent_cmd.ATTRIBUTE14                                                    || v_sep ||
            TRIM(TO_CHAR(TRUNC(ent_cmd.amount_init,2),'9999999999990.99'))
            --REPLACE(TRIM(TO_CHAR(TRUNC(ent_cmd.amount_init,2),'9999999999990.99')),'.',',')
        );
        */
		--SELO
		begin
			insert into DKA_SPOFUSION_HEADERS_TMP values
			(
			ent_cmd.SEGMENT1                                              
			,ent_cmd.TYPE_LOOKUP_CODE                                      
			,ent_cmd.CURRENCY_CODE                                         
			,ent_cmd.FULL_NAME                                             
			,ent_cmd.VENDOR_NAME                                           
			,ent_cmd.VENDOR_SITE_CODE                                      
			,ent_cmd.CONTACT                                               
			,ent_cmd.SHIP_TO_LOCATION                                      
			,ent_cmd.BILL_TO_LOCATION                                      
			,ent_cmd.COMMENTS  
			,ent_cmd.org_id
			,ent_cmd.UO_NAME
		--	,ent_cmd.SOCIETE                                               
		--	,ent_cmd.REGION                                                
			,ent_cmd.NAME                                                  
			,ent_cmd.AUTHORIZATION_STATUS                                  
			,ent_cmd.APPROVED_DATE                  
			,ent_cmd.REVISION_NUM                                          
			,ent_cmd.NOTE_TO_VENDOR                                        
			,ent_cmd.NOTE_TO_RECEIVER                                      
			,ent_cmd.ATTRIBUTE_CATEGORY                                    
			,ent_cmd.ATTRIBUTE1                                            
			,ent_cmd.ATTRIBUTE2                                            
			,ent_cmd.ATTRIBUTE6                                            
			,ent_cmd.ATTRIBUTE8
			,ent_cmd.ATTRIBUTE11			
			,ent_cmd.ATTRIBUTE12                                           
			,ent_cmd.ATTRIBUTE13                                           
			,ent_cmd.ATTRIBUTE14                                           
		--	,TRIM(TO_CHAR(TRUNC(ent_cmd.amount_init,2),'9999999999990.99'))
			,							 -- SELO
							null,
							null,
							null,
							null,
							null,
							null,
							null,
							null,
							null,
							null
              ,SYSDATE
              ,g_user_id
              ,SYSDATE
              ,g_user_id
			  ,ent_cmd.CLOSED_CODE
			);
			
            commit;
		
		
		exception
		  when others then
			
                dka_Tools_Pkg.put_log_message('PB insertion dans la table DKA_SPOFUSION_HEADERS_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);										  
		  end;
		
		
		
		-- SELO
     /*   --RBE artf2232818 - Extraction complémentaire
        UPDATE PO_HEADERS_ALL
        SET ATTRIBUTE12 = 'Fusion R12 : '||TO_CHAR(sysdate,'DD/MM/YYYY')
        WHERE po_header_id = ent_cmd.po_header_id;
     */                     
        -- Mise à jour du compteur
        v_compteur_export_ent_cmd := v_compteur_export_ent_cmd + 1;

      EXCEPTION
        WHEN OTHERS THEN
          dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                          ' - ' || SQLERRM);
          p_retcode := 1;
      END;
    
    END LOOP;

    -- Ecriture des noms de colonnes dans le fichier des lignes et livraisons des commandes
    /*
	p_fic_out_ptr    := UTL_FILE.FOPEN(p_dir_out,
                                      p_fic_out_name2,
                                      'W',
                                      32764);
                    
    UTL_FILE.PUT_LINE(p_fic_out_ptr,
            'DOCUMENT_NUM'                        || v_sep ||
            'LINE_NUM'                            || v_sep ||
            'LINE_TYPE'                           || v_sep ||
            'CATEGORY_SEGMENT2'                   || v_sep ||
            'CATEGORY_SEGMENT3'                   || v_sep ||
            'CATEGORY_SEGMENT4'                   || v_sep ||
            'CATEGORY_SEGMENT5'                   || v_sep ||
            'ITEM_DESCRIPTION'                    || v_sep ||
            'VENDOR_PRODUCT_NUM'                  || v_sep ||
            'UOM_CODE'                            || v_sep ||
            'UNIT_PRICE'                          || v_sep ||
            'LIST_PRICE_PER_UNIT'                 || v_sep ||
            'LINE_NOTE_TO_VENDOR'                 || v_sep ||
            'LINE_ATTRIBUTE2'                     || v_sep ||
            'SHIPMENT_NUM'                        || v_sep ||
            'SHIPMENT_TYPE'                       || v_sep ||
            'QUANTITY'                            || v_sep ||
            'QUANTITY_RECEIVED'                   || v_sep ||
            'QUANTITY_BILLED'                     || v_sep ||
            'SHIP_TO_LOCATION'                    || v_sep ||
            'NEED_BY_DATE'                        || v_sep ||
            'PROMISED_DATE'                       || v_sep ||
            'INSPECTED_REQUIRED_FLAG'             || v_sep ||
            'RECEIPT_REQUIRED_FLAG'               || v_sep ||
            'QTY_RECEIVED_TOLERANCE'              || v_sep ||
            'QTY_RCV_EXCEPTION_CODE'              || v_sep ||
            'ENFORCE_SHIP_TO_LOCATION_CODE'       || v_sep ||
            'ALLOW_SUBSTITUTE_RECEIPTS_FLAG'      || v_sep ||
            'DAYS_EARLY_RECEIPT_ALLOWED'          || v_sep ||
            'DAYS_LATE_RECEIPT_ALLOWED'           || v_sep ||
            'RECEIPTS_DAYS_EXCEPTION_CODE'        || v_sep ||
            'INVOICE_CLOSE_TOLERANCE'             || v_sep ||
            'RECEIVE_CLOSE_TOLERANCE'             || v_sep ||
            'RECEIVING_ROUTING'                   || v_sep ||
            'MATCH_OPTION'                 
              );                    
            */
  --Ecriture des enregistrements dans le fichier des lignes et livraisons de commandes
  
    FOR var IN 1..v_cpt LOOP
      IF v_cpt = 1 OR entetes_cmd_list(var) <> v_temp THEN
        FOR ligne_cmd IN cur_lig_cmd(entetes_cmd_list(var)) LOOP
          BEGIN
            --dka_tools_pkg.put_debug_message('Extraction des lignes et livraisons de commandes. COMMANDE N° : ' ||
                            --entetes_cmd_list(var));
            v_cpt2 := v_cpt2 + 1;
            lignes_cmd_list(v_cpt2) := ligne_cmd.line_location_id;
            
            /*
			UTL_FILE.PUT_LINE(p_fic_out_ptr,
                    ligne_cmd.SEGMENT1                                                      || v_sep ||
                    ligne_cmd.LINE_NUM                                                      || v_sep ||
                    ligne_cmd.LINE_TYPE                                                     || v_sep ||
                    ligne_cmd.SEGMENT2                                                      || v_sep ||
                    ligne_cmd.SEGMENT3                                                      || v_sep ||
                    ligne_cmd.SEGMENT4                                                      || v_sep ||
                    ligne_cmd.SEGMENT5                                                      || v_sep ||
                    REPLACE(ligne_cmd.ITEM_DESCRIPTION,CHR(10),' ')                         || v_sep ||
                    ligne_cmd.VENDOR_PRODUCT_NUM                                            || v_sep ||
                    ligne_cmd.UNIT_MEAS_LOOKUP_CODE                                         || v_sep ||
                    --REPLACE(TRIM(TO_CHAR(TRUNC(ligne_cmd.UNIT_PRICE ,2),'9999999999990.99')),'.',',')   || v_sep ||
                    TRIM(TO_CHAR(TRUNC(ligne_cmd.UNIT_PRICE ,2),'9999999999990.99'))        || v_sep ||
                    REPLACE(ligne_cmd.LIST_PRICE_PER_UNIT,',','.')                          || v_sep ||
                    ligne_cmd.NOTE_TO_VENDOR                                                || v_sep ||
                    ligne_cmd.LINE_ATTRIBUTE2                                               || v_sep ||
                    ligne_cmd.SHIPMENT_NUM                                                  || v_sep ||
                    ligne_cmd.SHIPMENT_TYPE                                                 || v_sep ||
                    REPLACE(ligne_cmd.QUANTITY_CMD,',','.')                                 || v_sep ||
                    REPLACE(ligne_cmd.QUANTITY_RECEIVED,',','.')                            || v_sep ||
                    REPLACE(ligne_cmd.QUANTITY_BILLED,',','.')                              || v_sep ||
                    ligne_cmd.LOCATION_CODE                                                 || v_sep ||
                    TO_CHAR(ligne_cmd.NEED_BY_DATE,'YYYY/MM/DD')                            || v_sep ||
                    TO_CHAR(ligne_cmd.PROMISED_DATE,'YYYY/MM/DD')                           || v_sep ||
                    ligne_cmd.inspection_required_flag                                      || v_sep ||
                    ligne_cmd.RECEIPT_REQUIRED_FLAG                                         || v_sep ||
                    REPLACE(ligne_cmd.qty_rcv_tolerance,',','.')                            || v_sep ||
                    REPLACE(ligne_cmd.QTY_RCV_EXCEPTION_CODE,',','.')                       || v_sep ||
                    ligne_cmd.ENFORCE_SHIP_TO_LOCATION_CODE                                 || v_sep ||
                    ligne_cmd.ALLOW_SUBSTITUTE_RECEIPTS_FLAG                                || v_sep ||
                    REPLACE(ligne_cmd.DAYS_EARLY_RECEIPT_ALLOWED,',','.')                   || v_sep ||
                    REPLACE(ligne_cmd.DAYS_LATE_RECEIPT_ALLOWED,',','.')                    || v_sep ||
                    ligne_cmd.receipt_days_exception_code                                   || v_sep ||
                    REPLACE(ligne_cmd.INVOICE_CLOSE_TOLERANCE,',','.')                      || v_sep ||
                    REPLACE(ligne_cmd.RECEIVE_CLOSE_TOLERANCE,',','.')                      || v_sep ||
                    ligne_cmd.ROUTING_NAME                                                  || v_sep ||
                    ligne_cmd.MATCH_OPTION                       
                      );
                */      
            -- Mise à jour du compteur
            v_compteur_export_lig_cmd := v_compteur_export_lig_cmd + 1;
			
			--SELO
					begin
						insert into DKA_SPOFUSION_LINES_TMP values
						(
							ligne_cmd.SEGMENT1                                                      ,
							ligne_cmd.org_id                                                        ,  -- SELO
							ligne_cmd.LINE_NUM                                                      ,
							ligne_cmd.LINE_TYPE                                                     ,
							ligne_cmd.CATEGORY_SEGMENT1                                             ,
							ligne_cmd.SEGMENT2                                                      ,
							ligne_cmd.SEGMENT3                                                      ,
							ligne_cmd.SEGMENT4                                                      ,
							ligne_cmd.ITEM_SEGMENT1													,   -- SELO
							ligne_cmd.ITEM_SEGMENT2													,   -- SELO
							REPLACE(ligne_cmd.ITEM_DESCRIPTION,CHR(10),' ')                         ,
							ligne_cmd.VENDOR_PRODUCT_NUM                                            ,
							ligne_cmd.UNIT_MEAS_LOOKUP_CODE                                         ,
							--REPLACE(TRIM(TO_CHAR(TRUNC(ligne_cmd.UNIT_PRICE ,2),'9999999999990.99')),'.',',')   ,
							ligne_cmd.UNIT_PRICE											        ,
							ligne_cmd.LIST_PRICE_PER_UNIT                        					,
							ligne_cmd.NOTE_TO_VENDOR                                                ,
							ligne_cmd.LINE_ATTRIBUTE2                                               ,
							ligne_cmd.SHIPMENT_NUM                                                  ,
							ligne_cmd.SHIPMENT_TYPE                                                 ,
							ligne_cmd.QUANTITY_CMD                                 					,
							ligne_cmd.QUANTITY_RECEIVED                            					,
							ligne_cmd.QUANTITY_BILLED                              					,
							ligne_cmd.LOCATION_CODE                                                 ,
							ligne_cmd.NEED_BY_DATE                       						    ,
							ligne_cmd.PROMISED_DATE							                        ,
							ligne_cmd.inspection_required_flag                                      ,
							ligne_cmd.RECEIPT_REQUIRED_FLAG                                         ,
							ligne_cmd.qty_rcv_tolerance                            					,
							ligne_cmd.QTY_RCV_EXCEPTION_CODE				                        ,  --SELO
							ligne_cmd.ENFORCE_SHIP_TO_LOCATION_CODE                                 ,
							ligne_cmd.ALLOW_SUBSTITUTE_RECEIPTS_FLAG                                ,
							ligne_cmd.DAYS_EARLY_RECEIPT_ALLOWED                   					,
							ligne_cmd.DAYS_LATE_RECEIPT_ALLOWED                    					,
							ligne_cmd.receipt_days_exception_code                                   ,
							ligne_cmd.INVOICE_CLOSE_TOLERANCE                      					,
							ligne_cmd.RECEIVE_CLOSE_TOLERANCE                      					,
							ligne_cmd.ROUTING_NAME                                                  ,
							ligne_cmd.MATCH_OPTION 													,
							ligne_cmd.ATTRIBUTE3,							 -- SELO
							null,
							null,
							null,
							null,
							null,
							null,
							null
							,SYSDATE
						  ,g_user_id
						  ,SYSDATE
						  ,g_user_id
						);
						
						commit;
					
					
					exception
					  when others then
					
							dka_Tools_Pkg.put_log_message('PB insertion dans la table DKA_SPOFUSION_LINES_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);
												
					  end;
		
			
			

          EXCEPTION
            WHEN OTHERS THEN
              dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                              ' - ' || SQLERRM);
              p_retcode := 1;
          END;
        
        END LOOP;
      v_temp := entetes_cmd_list(var);
      END IF;
    END LOOP;  
  
  -- Ecriture des noms de colonnes dans le fichier des lignes de ventilations
    v_temp := 0;
    /*
	p_fic_out_ptr    := UTL_FILE.FOPEN(p_dir_out,
                                      p_fic_out_name3,
                                      'W',
                                      32764);
                    
    UTL_FILE.PUT_LINE(p_fic_out_ptr,
            'DOCUMENT_NUM'                          || v_sep ||
            'LINE_NUM'                              || v_sep ||
            'SHIPMENT_NUM'                          || v_sep ||
            'DISTRIBUTION_NUM'                      || v_sep ||
            'QUANTITY_ORDERED'                      || v_sep ||
            'QUANTITY_DELIVERED'                    || v_sep ||
            'QUANTITY_BILLED'                       || v_sep ||
            'DELIVER_TO_LOCATION'                   || v_sep ||
            'DELIVER_TO_PERSON'                     || v_sep ||
            'DESTINATION_TYPE_CODE'                 || v_sep ||
            'CHARGE_SEGMENT1'                       || v_sep ||
            'CHARGE_SEGMENT2'                       || v_sep ||
            'CHARGE_SEGMENT3'                       || v_sep ||
            'CHARGE_SEGMENT4'                       || v_sep ||
            'CHARGE_SEGMENT5'                       || v_sep ||
            'CHARGE_SEGMENT6'                       || v_sep ||
            'CHARGE_SEGMENT7'                       || v_sep ||
            'CHARGE_SEGMENT8'                       || v_sep ||
            'CHARGE_SEGMENT9'                       || v_sep ||
            'CHARGE_SEGMENT10'                      || v_sep ||
            'ACCRUAL_SEGMENT1'                      || v_sep ||
            'ACCRUAL_SEGMENT2'                      || v_sep ||
            'ACCRUAL_SEGMENT3'                      || v_sep ||
            'ACCRUAL_SEGMENT4'                      || v_sep ||
            'ACCRUAL_SEGMENT5'                      || v_sep ||
            'ACCRUAL_SEGMENT6'                      || v_sep ||
            'ACCRUAL_SEGMENT7'                      || v_sep ||
            'ACCRUAL_SEGMENT8'                      || v_sep ||
            'ACCRUAL_SEGMENT9'                      || v_sep ||
            'ACCRUAL_SEGMENT10'                     || v_sep ||
            'VARIANCE_SEGMENT1'                     || v_sep ||
            'VARIANCE_SEGMENT2'                     || v_sep ||
            'VARIANCE_SEGMENT3'                     || v_sep ||
            'VARIANCE_SEGMENT4'                     || v_sep ||
            'VARIANCE_SEGMENT5'                     || v_sep ||
            'VARIANCE_SEGMENT6'                     || v_sep ||
            'VARIANCE_SEGMENT7'                     || v_sep ||
            'VARIANCE_SEGMENT8'                     || v_sep ||
            'VARIANCE_SEGMENT9'                     || v_sep ||
            'VARIANCE_SEGMENT10'                    || v_sep ||
            'PROJECT_CODE'                          || v_sep ||
            'EXPENDITURE_TYPE'                      || v_sep ||
            'PROJECT_ACCOUNTING_CONTEXT'            || v_sep ||
            'EXPENDITURE_ORGANIZATION'              || v_sep ||
            'EXPENDITURE_ITEM_DATE'                 || v_sep ||
            'DIST_ATTRIBUTE_CATEGORY'               || v_sep ||
            'DIST_ATTRIBUTE3'             
              );
            */

    -- Ecriture des enregistrements dans le fichier des lignes de ventilations

    FOR var IN 1..v_cpt2 LOOP
      IF v_cpt2 = 1 OR lignes_cmd_list(var) <> v_temp THEN
        FOR vent_cmd IN cur_vent_cmd(lignes_cmd_list(var)) LOOP
          BEGIN
            --dka_tools_pkg.put_debug_message('Extraction des lignes de ventilations. N° : ' ||
                           -- lignes_cmd_list(var));
            
            /*
			UTL_FILE.PUT_LINE(p_fic_out_ptr,
                    vent_cmd.SEGMENT1                                                            || v_sep ||
                    vent_cmd.LINE_NUM                                                            || v_sep ||
                    vent_cmd.SHIPMENT_NUM                                                        || v_sep ||
                    vent_cmd.DISTRIBUTION_NUM                                                    || v_sep ||
                    REPLACE(vent_cmd.QTY_ORDERED,',','.')                                        || v_sep ||
                    REPLACE(vent_cmd.QUANTITY_DELIVERED,',','.')                                 || v_sep ||
                    REPLACE(vent_cmd.QUANTITY_BILLED,',','.')                                    || v_sep ||
                    vent_cmd.LOCATION_CODE                                                       || v_sep ||
                    vent_cmd.FULL_NAME                                                           || v_sep ||
                    vent_cmd.DESTINATION_TYPE_CODE                                               || v_sep ||
                    vent_cmd.CHARGE_SEGMENT1                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT2                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT3                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT4                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT5                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT6                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT7                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT8                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT9                                                     || v_sep ||
                    vent_cmd.CHARGE_SEGMENT10                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT1                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT2                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT3                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT4                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT5                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT6                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT7                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT8                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT9                                                    || v_sep ||
                    vent_cmd.ACCRUAL_SEGMENT10                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT1                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT2                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT3                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT4                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT5                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT6                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT7                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT8                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT9                                                   || v_sep ||
                    vent_cmd.VARIANCE_SEGMENT10                                                  || v_sep ||
                    vent_cmd.PROJECT_CODE                                                        || v_sep ||
                    vent_cmd.EXPENDITURE_TYPE                                                    || v_sep ||
                    vent_cmd.PROJECT_ACCOUNTING_CONTEXT                                          || v_sep ||
                    vent_cmd.NAME                                                                || v_sep ||
                    TO_CHAR(vent_cmd.EXPENDITURE_ITEM_DATE,'YYYY/MM/DD')                         || v_sep ||
                    vent_cmd.ATTRIBUTE_CATEGORY                                                  || v_sep ||
                    vent_cmd.ATTRIBUTE3                                                   
                      );
                    */
					
            -- Mise à jour du compteur
            v_compteur_export_vent_cmd := v_compteur_export_vent_cmd + 1;
			    begin 
					insert into DKA_SPOFUSION_DISTRIBS_TMP values
					(
						vent_cmd.SEGMENT1                                                            ,
						vent_cmd.org_id																 , --SELO
						vent_cmd.LINE_NUM                                                            ,
						vent_cmd.SHIPMENT_NUM                                                        ,
						vent_cmd.DISTRIBUTION_NUM                                                    ,
						vent_cmd.QTY_ORDERED                                        				 ,
						vent_cmd.QUANTITY_DELIVERED                          				         ,
						vent_cmd.QUANTITY_BILLED				                                     ,
						vent_cmd.LOCATION_CODE                                                       ,
						vent_cmd.FULL_NAME                                                           ,
						vent_cmd.DESTINATION_TYPE_CODE                                               ,
						vent_cmd.PROJECT_CODE                                                        ,
						vent_cmd.TASK_CODE															 ,
						vent_cmd.EXPENDITURE_TYPE                                                    ,
						vent_cmd.PROJECT_ACCOUNTING_CONTEXT                                          ,
						vent_cmd.NAME                                                                ,
						vent_cmd.EXPENDITURE_ITEM_DATE						                         ,
						vent_cmd.ATTRIBUTE_CATEGORY                                                  ,
						vent_cmd.ATTRIBUTE3   ,							 -- SELO
							null,
							null,
							null,
							null,
							null,
							null,
							null,
							null,
							null,
							null 
						  ,SYSDATE
						  ,g_user_id
						  ,SYSDATE
						  ,g_user_id							
                    );
					  
						commit;
					
					
					exception
					  when others then
							dka_Tools_Pkg.put_log_message('PB insertion dans la table DKA_SPOFUSION_DISTRIBS_TMP : '|| SQLCODE ||
                                              ' - ' || SQLERRM);
												
					  end;

          EXCEPTION
            WHEN OTHERS THEN
              dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                              ' - ' || SQLERRM);
              p_retcode := 1;
          END;       
        END LOOP;
        v_temp := lignes_cmd_list(var);
      END IF;
    END LOOP;  

            
  
    -- Log du nombre d'enregistrements
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre d''entetes de commandes extraits     : ' ||
                                       v_compteur_export_ent_cmd);
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre de lignes de commandes extraits     : ' ||
                                       v_compteur_export_lig_cmd);
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre de lignes de ventilations extraits  : ' ||
                                       v_compteur_export_vent_cmd);                     
    Dka_Tools_Pkg.Put_Outdebug_Message('');
	
	
	Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('Liste des commandes extraites');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
	Dka_Tools_Pkg.Put_Outdebug_Message('Unité opérationnelle         Commande');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
	
		FOR liste_cmd IN cur_liste_cmd  LOOP
		Dka_Tools_Pkg.Put_Outdebug_Message(liste_cmd.uo_name||'                      '||liste_cmd.document_num);
		END LOOP;

    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('Fin des logs de traitements DKA : Extraction des commandes standards');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      IF cur_ent_cmd%ISOPEN THEN
         CLOSE cur_ent_cmd;
      END IF;
    
      IF cur_lig_cmd%ISOPEN THEN
         CLOSE cur_lig_cmd;
      END IF;    
    
      ROLLBACK;
      p_errbuf  := 'Erreur dans la procécure Main : ' || SQLCODE || '-' ||
                    Substr(SQLERRM, 1, 80);
      p_retcode := 2;
    
      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message(p_errbuf);
  END Main;

END DKA_FUSPOCMDEXP_PKG;

/
SHOW ERRORS;
EXIT
