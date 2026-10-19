----------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOCHGFOU.vue
-- DESCRIPTION	    : Création de la vue DKA_SPOCHGFOU_V (utilisée par le panneau DKA_SPOCHGFOU.fmb)
--
-- AUTEUR           : E.Matuszewski
-- DATE DE CREATION : 24/01/2012
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
-- 14/10/2013 BCO Ajout du cloisonnement sur l'option de profil ORG_ID 
-- 10/04/2017 MEG artf2136805 : SPE119 - Ecran de transfert de commande
--------------------------------------------------------------------------------------------

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SPOCHGFOU_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_SPOCHGFOU_V
(PO_HEADER_ID,
 CONTRAT_SSTR,
 COMMANDE_ID,
 VENDOR_ID,
 VENDOR_SITE_ID,
 LAST_UPDATE_DATE,
 LAST_UPDATED_BY,
 CREATION_DATE,
 ORG_ID)
AS
SELECT PHA.PO_HEADER_ID PO_HEADER_ID,
       PHA.SEGMENT1 CONTRAT_SSTR,
       CASE
         WHEN (PHA.Type_Lookup_Code = 'STANDARD' AND PHA.SEGMENT1 NOT LIKE '%ST%') THEN
          PHA.PO_HEADER_ID
         WHEN (PHA.Type_Lookup_Code = 'CONTRACT' AND PHA.AUTHORIZATION_STATUS = 'REQUIRES REAPPROVAL' AND
              DCS.COMMANDE_ID IS NULL) THEN
          (SELECT DCSAT.COMMANDE_ID
             FROM DKA_CONTRAT_SSTR_ARCHI DCSAT
            WHERE DCSAT.PO_HEADER_ID = PHA.PO_HEADER_ID
              AND DCSAT.REVISION_NUM = DCS.REVISION_NUM - 1)
         WHEN (PHA.Type_Lookup_Code = 'CONTRACT' AND DCS.COMMANDE_ID IS NULL) THEN
          PHA.PO_HEADER_ID
         ELSE
          nvl(DCS.COMMANDE_ID, PHA.PO_HEADER_ID)
       END COMMANDE_ID,
       PHA.VENDOR_ID VENDOR_ID,
       PHA.VENDOR_SITE_ID VENDOR_SITE_ID,
       PHA.LAST_UPDATE_DATE LAST_UPDATE_DATE,
       PHA.LAST_UPDATED_BY LAST_UPDATED_BY,
       TRUNC(PHA.CREATION_DATE) CREATION_DATE,
       PHA.org_id ORG_ID
  FROM PO_HEADERS_ALL PHA, 
       DKA_CONTRAT_SSTR DCS,
       PO_SYSTEM_PARAMETERS PSP
       /*, DKA_CONTRAT_SSTR_ARCHI DCSAT*/
 WHERE DCS.PO_HEADER_ID(+) = PHA.PO_HEADER_ID
   AND PSP.org_id = PHA.org_id
   AND NVL(PHA.CLOSED_CODE, 'OPEN') NOT IN ('CLOSED', 'FINALLY CLOSED')
   AND ((PHA.SEGMENT1 NOT LIKE '%ST%' AND PHA.type_lookup_code = 'STANDARD') OR PHA.type_lookup_code = 'CONTRACT') 
   AND NVL(PHA.CLOSED_DATE, SYSDATE) >= SYSDATE
   ;
     
SHOW ERROR

EXIT
