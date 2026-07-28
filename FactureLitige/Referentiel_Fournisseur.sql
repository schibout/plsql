/* LISTE DES SITES FOURNISSEURS ACTIFS PAR REGION R12 */
/* Formatted on 01/12/2011 10:17:34 (QP5 v5.185.11230.41888) */
WITH        
       ACCORD
       AS (select distinct FFV2.FLEX_VALUE,
                  FFVT2.DESCRIPTION
            FROM APPLSYS.FND_FLEX_VALUE_SETS FFVS2
            INNER JOIN APPLSYS.FND_FLEX_VALUES FFV2
               ON FFV2.FLEX_VALUE_SET_ID = FFVS2.FLEX_VALUE_SET_ID
            INNER JOIN APPLSYS.FND_FLEX_VALUES_TL FFVT2
              ON FFVT2.FLEX_VALUE_ID = FFV2.FLEX_VALUE_ID AND FFVT2.LANGUAGE = 'F'
            WHERE FFVS2.FLEX_VALUE_SET_NAME = 'DKA_CODE_ACCORD'
              AND FFVT2.LANGUAGE = 'F')               
SELECT   --ASU.SEGMENT1||'.'||ASSA.ATTRIBUTE13 "Clé 11i", 
         ASU.SEGMENT1||'.'||HAOU.NAME||'.'||translate(translate(translate(translate(translate(ASSA.VENDOR_SITE_CODE, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Clé", 
         HAOU.NAME "OU",
         ASU.SEGMENT1 "Num. Fourn.",
         translate(translate(translate(translate(translate(ASU.VENDOR_NAME, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Nom",
         HP.PARTY_NUMBER "Num Partie",
         decode(HP.STATUS,'A','Actif','I','Inactif',HP.STATUS) "Statut Partie",
         ASP.SEGMENT1 "Num Parent",
         ASP.VENDOR_NAME "Nom Parent",
         ASU.NUM_1099 "Siren",
         ASU.ATTRIBUTE1 "Fourn. Serv.",
         ASU.ATTRIBUTE3 "Fourn. Combus.",
         ASU.ATTRIBUTE4 "Code Accord",
         ACCORD.DESCRIPTION "Nom Accord",
--         ASU.ATTRIBUTE7 "Création Auto. Cde",
         ASU.ATTRIBUTE6 "Code surtaxe",
         ASU.VENDOR_TYPE_LOOKUP_CODE "Type",
         ASU.MINORITY_GROUP_LOOKUP_CODE "Sous/type",
         ASU.ATTRIBUTE2 "Code Part.",
         ASU.STANDARD_INDUSTRY_CLASS "Code NACE",
         ASU.VAT_REGISTRATION_NUM "TVA Intracom",
         ASU.FEDERAL_REPORTABLE_FLAG "Honoraires" ,
         ASU.TYPE_1099 "Code DAS2" ,
         FLV1.MEANING "Mode paiement",
         ATT1.NAME "Condition paiement",
         ASU.END_DATE_ACTIVE "Date fin",
         HPS.PARTY_SITE_NUMBER "Num Site Partie",
         HPS.PARTY_SITE_NAME "Nom Site Partie",
         decode(HPS.STATUS,'A','Actif','I','Inactif',HPS.STATUS) "Statut Site Partie",
         SUBSTR (HAOU.NAME , 1, 3) "Etab",
         SUBSTR (HAOU.NAME , 4, 4) "Sté",
         ASSA.VENDOR_SITE_ID "ID Site",
         translate(translate(translate(translate(translate(ASSA.VENDOR_SITE_CODE, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Code Site",
         translate(translate(translate(translate(translate(ASSA.VENDOR_SITE_CODE_ALT, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Autre code",
         translate(translate(translate(translate(translate(ASSA.ADDRESS_LINES_ALT, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Autre adresse",
         ASSA.ATTRIBUTE1 "Siret",
--         ASSA.ATTRIBUTE8 "Code partenaire",
         translate(translate(translate(translate(translate(ASSA.ADDRESS_LINE1, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Ligne adresse 1",
         translate(translate(translate(translate(translate(ASSA.ADDRESS_LINE2, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Ligne adresse 2",
         translate(translate(translate(translate(translate(ASSA.ADDRESS_LINE3, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Ligne adresse 3",
         translate(translate(translate(translate(translate(ASSA.ADDRESS_LINE4, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Ligne adresse 4",
         translate(translate(translate(translate(translate(ASSA.ZIP, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Code Postal",
         translate(translate(translate(translate(translate(ASSA.CITY, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Ville",
         translate(translate(translate(translate(translate(ASSA.COUNTY, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Région",
         translate(translate(translate(translate(translate(ASSA.PROVINCE, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Province",
         translate(translate(translate(translate(translate(ASSA.STATE, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Etat / Département",
         ASSA.ATTRIBUTE6 "Code INSEE",
         ASSA.ATTRIBUTE6 "Bureau distributeur",
         ASSA.COUNTRY "Pays",
         ASSA.PAY_SITE_FLAG "Site Rglt",
         ASSA.PURCHASING_SITE_FLAG "Site Achat",
         decode(ASSA.SUPPLIER_NOTIF_METHOD,'FAX','Fax','EMAIL','Mail','PRINT','Papier',null) "Notif. Cde",
         ASSA.FAX_AREA_CODE||' '||ASSA.FAX "Fax",
         ASSA.AREA_CODE||' '||ASSA.PHONE "Tel",
         translate(translate(translate(translate(translate(ASSA.EMAIL_ADDRESS, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Mail commande",
         translate(translate(translate(translate(translate(IEPA.REMIT_ADVICE_EMAIL, chr(9), ' '), chr(10), ' '), chr(13), ' '), chr(34), ' '), chr(124), ' ') "Mail avis Paiement",
         FLV.MEANING "Mode paiement site",
         ATT.NAME "Condition paiement site",
         ASSA.PAY_GROUP_LOOKUP_CODE "Classe de reglement",
         ASSA.OFFSET_TAX_FLAG "TVA Intra",
         DECODE (ASSA.AUTO_TAX_CALC_FLAG,
                 'L', 'Ligne',
                 'T', 'Code TVA',
                 'N', 'Aucun',
                 'Y', 'En-tête',
                 'En-tête')
            "Niveau calcul",
         nvl(ASSA.ATTRIBUTE5,'N') "Factor",
         ASSA.ATTRIBUTE9 "Four. Stratégique",
         HL1.LOCATION_CODE "Adresse Livraison",
         HL2.LOCATION_CODE "Adresse Facturation",
         decode(ASSA.MATCH_OPTION,'P','Commande','R','Réception',ASSA.MATCH_OPTION) "Option rappro facture",
         to_date(ASSA.ATTRIBUTE12,'YYYY/MM/DD HH24:MI:SS') "Extraction Xerox",
         GCC1.CONCATENATED_SEGMENTS "Compte Fournisseur",
         GCC2.CONCATENATED_SEGMENTS "Compte Acompte",
         GCC3.CONCATENATED_SEGMENTS "Compte LCR",
         ASU.CREATION_DATE "Date création Fourn.",
         FU4.USER_NAME "Util. création Fourn.",
         FU4.DESCRIPTION "Nom création Fourn.",
         ASU.LAST_UPDATE_DATE "Date modif Fourn.",
         FU5.USER_NAME "Util. Modif Fourn.",
         FU5.DESCRIPTION "Nom modif Fourn.",
         HP.CREATION_DATE "Date création Partie",
         FU2.USER_NAME "Util. création Partie",
         FU2.DESCRIPTION "Nom création Partie",
         HP.LAST_UPDATE_DATE "Date modif Partie",
         FU3.USER_NAME "Util. Modif Partie",
         FU3.DESCRIPTION "Nom modif Partie",
         ASSA.CREATION_DATE "Date création site",
         FU1.USER_NAME "Util. création site",
         FU1.DESCRIPTION "Nom création site",
         ASSA.INACTIVE_DATE "Fin site",
         ASSA.LAST_UPDATE_DATE "Dernière modif.",
         FU.USER_NAME "Util. Modif site",
         FU.DESCRIPTION "Nom modif site"
    FROM APPS.AP_SUPPLIER_SITES_ALL ASSA
        inner join AR.HZ_PARTY_SITES HPS on HPS.PARTY_SITE_ID = ASSA.PARTY_SITE_ID
        inner join AP.AP_SUPPLIERS ASU on ASSA.VENDOR_ID = ASU.VENDOR_ID  
        inner join AR.HZ_PARTIES HP on HP.PARTY_ID = ASU.PARTY_ID
        left outer join IBY.IBY_EXTERNAL_PAYEES_ALL IEPA on (IEPA.ORG_ID = ASSA.ORG_ID 
                                                         and IEPA.PAYEE_PARTY_ID = ASU.PARTY_ID 
                                                         and IEPA.PARTY_SITE_ID = ASSA.PARTY_SITE_ID
                                                         and IEPA.SUPPLIER_SITE_ID = ASSA.VENDOR_SITE_ID 
                                                         and IEPA.PAYMENT_FUNCTION = 'PAYABLES_DISB')
        left outer join AP.AP_SUPPLIERS ASP on ASP.VENDOR_ID = ASU.PARENT_VENDOR_ID
        left outer join APPLSYS.FND_LOOKUP_VALUES FLV1 on (FLV1.LOOKUP_CODE = ASU.PAYMENT_METHOD_LOOKUP_CODE
                                                     AND FLV1.LOOKUP_TYPE = 'PAYMENT METHOD'
                                                     AND FLV1.LANGUAGE = 'F')
        left outer join AP.AP_TERMS_TL ATT1 on (ATT1.TERM_ID = ASU.TERMS_ID
                                             AND ATT1.LANGUAGE = 'F')
        left outer join ACCORD on ACCORD.FLEX_VALUE = ASU.ATTRIBUTE4
       /* left outer join APPLSYS.FND_LOOKUP_VALUES FLV1 on (FLV1.LOOKUP_CODE = ASU.PAYMENT_METHOD_LOOKUP_CODE
                                                     AND FLV1.LOOKUP_TYPE = 'PAYMENT METHOD'
                                                     AND FLV1.LANGUAGE = 'F')
        left outer join AP.AP_TERMS_TL ATT1 on (ATT1.TERM_ID = ASU.TERMS_ID
                                         AND ATT1.LANGUAGE = 'F')*/
        left outer join HR.HR_LOCATIONS_ALL HL3 on HL3.LOCATION_ID = ASU.SHIP_TO_LOCATION_ID
        left outer join HR.HR_LOCATIONS_ALL HL4 on HL4.LOCATION_ID = ASU.BILL_TO_LOCATION_ID
        inner join HR.HR_ALL_ORGANIZATION_UNITS HAOU on HAOU.ORGANIZATION_ID = ASSA.ORG_ID     
        inner join APPS.GL_CODE_COMBINATIONS_KFV GCC1 on GCC1.CODE_COMBINATION_ID = ASSA.ACCTS_PAY_CODE_COMBINATION_ID        
        inner join APPS.GL_CODE_COMBINATIONS_KFV GCC2 on GCC2.CODE_COMBINATION_ID = ASSA.PREPAY_CODE_COMBINATION_ID
        inner join APPS.GL_CODE_COMBINATIONS_KFV GCC3 on GCC3.CODE_COMBINATION_ID = ASSA.FUTURE_DATED_PAYMENT_CCID
        inner join AP.AP_TERMS_TL ATT on (ATT.TERM_ID = ASSA.TERMS_ID AND ATT.LANGUAGE = 'F')
        left outer join  HR.HR_LOCATIONS_ALL HL1 on HL1.LOCATION_ID = ASSA.SHIP_TO_LOCATION_ID
        left outer join  HR.HR_LOCATIONS_ALL HL2 on HL2.LOCATION_ID = ASSA.BILL_TO_LOCATION_ID
        left outer join APPLSYS.FND_LOOKUP_VALUES FLV on (FLV.LOOKUP_CODE = ASSA.PAYMENT_METHOD_LOOKUP_CODE
                                                     AND FLV.LOOKUP_TYPE = 'PAYMENT METHOD'
                                                     AND FLV.LANGUAGE = 'F')
        inner join APPLSYS.FND_USER FU on FU.USER_ID = ASSA.LAST_UPDATED_BY
        inner join APPLSYS.FND_USER FU1 on FU1.USER_ID = ASSA.CREATED_BY
        inner join APPLSYS.FND_USER FU2 on FU2.USER_ID = HP.CREATED_BY
        inner join APPLSYS.FND_USER FU3 on FU3.USER_ID = HP.LAST_UPDATED_BY
        inner join APPLSYS.FND_USER FU4 on FU4.USER_ID = ASU.CREATED_BY
        inner join APPLSYS.FND_USER FU5 on FU5.USER_ID = ASU.LAST_UPDATED_BY
  WHERE (ASU.VENDOR_TYPE_LOOKUP_CODE <> 'EMPLOYEE' or ASU.VENDOR_TYPE_LOOKUP_CODE is null)
         AND ((NULL IS NULL 
             AND ASU.SEGMENT1 LIKE '%' )
              OR (NULL IS NOT NULL 
             AND  ASU.SEGMENT1 = NULL) )
         AND ((NULL IS NULL 
             AND HAOU.NAME LIKE '%' )
              OR (NULL IS NOT NULL 
             AND  substr(HAOU.NAME,1,3) like nvl(upper(NULL),'%')) )
         AND ((('Y' = 'Y' or 'Y' is null)
             AND ((ASU.END_DATE_ACTIVE IS NULL or trunc(ASU.END_DATE_ACTIVE) >= trunc(sysdate))
                  AND (ASSA.INACTIVE_DATE IS NULL or trunc(ASSA.INACTIVE_DATE) >= trunc(sysdate))))
              OR ('Y' = 'N'
             AND ((ASU.END_DATE_ACTIVE like '%' or ASU.END_DATE_ACTIVE is null)
                 and (ASSA.INACTIVE_DATE like '%' or ASSA.INACTIVE_DATE is null)))) 
         AND IEPA.OBJECT_VERSION_NUMBER = (select max(IEPA1.OBJECT_VERSION_NUMBER)
                                            from IBY.IBY_EXTERNAL_PAYEES_ALL IEPA1
                                            where IEPA1.EXT_PAYEE_ID = IEPA.EXT_PAYEE_ID 
                                                and IEPA1.PAYMENT_FUNCTION = 'PAYABLES_DISB'
                                            group by IEPA1.EXT_PAYEE_ID) 
ORDER BY 1,2;

