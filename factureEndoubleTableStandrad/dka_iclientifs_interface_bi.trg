----------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOCHGMNT.vue
-- DESCRIPTION	    : Création de la vue DKA_SPOCHGMNT_V (utilisée par le panneau DKA_SPOCHGMNT.fmb)
--
-- AUTEUR           : B.Coudrier
-- DATE DE CREATION : 13/01/2014
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- 26/04/2017 RBE Correction artf2143725 : SPE119 - DEFECT 626 - Ecran de changement de montant
-- 31/01/2018 OBE artf2329097 : SPE119 - Panneau de changement de montant - modification impossible
-- 15/02/2018 RBE artf2376255 : SPE119 - Correction de la sélection Employés
-- 04/09/2018 RBE artf3025989 : INC0243936 - SPE119 - Problème recherche gestionnaire contrat SSTR
-- ---------- --- -------------------------------------------------------------------------
 

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SPOCHGMNT_V
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_SPOCHGMNT_V
(PO_HEADER_ID,
 CONTRAT_SSTR,
 COMMANDE_ID,
 COMMANDE_SSTR,
 VENDOR_ID,
 VENDOR_SITE_ID,
 LAST_UPDATE_DATE,
 LAST_UPDATED_BY,
 BLANKET_TOTAL_AMOUNT,
 AGENT_ID)
AS
SELECT PHA_CONTRAT.PO_HEADER_ID         PO_HEADER_ID,
       PHA_CONTRAT.SEGMENT1             CONTRAT_SSTR,
       PHA_COMMANDE.PO_HEADER_ID        COMMANDE_ID,
       PHA_COMMANDE.SEGMENT1            COMMANDE_SSTR,
       PHA_CONTRAT.VENDOR_ID            VENDOR_ID,
       PHA_CONTRAT.VENDOR_SITE_ID       VENDOR_SITE_ID,
       PHA_CONTRAT.LAST_UPDATE_DATE     LAST_UPDATE_DATE,
       PHA_CONTRAT.LAST_UPDATED_BY      LAST_UPDATED_BY,
       PHA_CONTRAT.BLANKET_TOTAL_AMOUNT BLANKET_TOTAL_AMOUNT,
       PHA_CONTRAT.AGENT_ID             AGENT_ID
  FROM PO_HEADERS_ALL       PHA_CONTRAT,
       PO_HEADERS_ALL       PHA_COMMANDE,
       DKA_CONTRAT_SSTR     DCS,
       PO_VENDOR_SITES_ALL  PVS,
       GL_CODE_COMBINATIONS GCC,
       PER_SECURITY_ORGANIZATIONS_V pso --RBE artf2143725
 WHERE DCS.PO_HEADER_ID = PHA_CONTRAT.PO_HEADER_ID
   AND DCS.COMMANDE_ID = PHA_COMMANDE.PO_HEADER_ID
   AND NVL(PHA_CONTRAT.CLOSED_CODE, 'OPEN') NOT IN
       ('CLOSED', 'FINALLY CLOSED')
   AND PHA_CONTRAT.TYPE_LOOKUP_CODE = 'CONTRACT'
   AND NVL(PHA_CONTRAT.CLOSED_DATE, SYSDATE) >= SYSDATE
   AND PHA_CONTRAT.AUTHORIZATION_STATUS = 'APPROVED'
   AND PHA_COMMANDE.REVISION_NUM = 0
   AND ADD_MONTHS(PHA_CONTRAT.Approved_Date, 3) >= SYSDATE
   --RBE artf2143725
   --AND PHA_CONTRAT.ORG_ID = fnd_profile.value('ORG_ID') --RBE artf2143725
   AND PHA_CONTRAT.ORG_ID = PSO.ORGANIZATION_ID           --RBE artf2143725
   AND PSO.SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL') --RBE artf2143725
   AND PHA_CONTRAT.VENDOR_ID = PVS.VENDOR_ID
   AND PHA_CONTRAT.VENDOR_SITE_ID = PVS.VENDOR_SITE_ID
   AND GCC.CODE_COMBINATION_ID = PVS.ACCTS_PAY_CODE_COMBINATION_ID
   AND EXISTS
       (SELECT 'X'
          FROM AK_WEB_USER_SEC_ATTR_VALUES ATTRIBUT,
               FND_APPLICATION             APPLI,
               FND_USER                    FU,
               --PER_ALL_PEOPLE_F            SIGNATAIRE -- RBE artf2376255
               per_people_f SIGNATAIRE -- RBE artf2376255 -- artf3025989
         WHERE ATTRIBUT.VARCHAR2_VALUE = SIGNATAIRE.ATTRIBUTE2 
         AND TRUNC(SYSDATE) BETWEEN TRUNC(SIGNATAIRE.effective_start_date) AND NVL(SIGNATAIRE.effective_end_date,SYSDATE) --RBE artf3025989
           AND SIGNATAIRE.PERSON_ID = PHA_CONTRAT.AGENT_ID
           AND ATTRIBUT.WEB_USER_ID = FU.USER_ID
           --AND ATTRIBUT.WEB_USER_ID = FND_PROFILE.VALUE('USER_ID') -- OBE artf2329097
           AND ATTRIBUT.ATTRIBUTE_CODE = 'DKA_CONTRAT_SSTR_REGION'
           AND ATTRIBUT.ATTRIBUTE_APPLICATION_ID = APPLI.APPLICATION_ID
           AND APPLI.APPLICATION_SHORT_NAME = 'ICX');

SHOW ERROR

EXIT
