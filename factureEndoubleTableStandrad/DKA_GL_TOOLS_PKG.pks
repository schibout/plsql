----------------------------------------------------------------------------------------------
-- $$
-- Capgemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SPOCHGGEST.vue
-- DESCRIPTION	    : Création de la vue DKA_SPOCHGGEST (utilisée par le panneau DKA_SPOCHGGEST.fmb)
--
-- AUTEUR           : Grégory Vanackère
-- DATE DE CREATION : 15/10/2009
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- -------------------------------------------------------------------------
--
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_SPOCHGGEST
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_SPOCHGGEST_V
(PO_HEADER_ID,
 CONTRAT_SSTR,
 DESC_CONTRAT,
 AGENT_ID,
 LAST_UPDATE_DATE,
 LAST_UPDATED_BY
)
AS
SELECT PHA.PO_HEADER_ID PO_HEADER_ID,
       PHA.SEGMENT1 CONTRAT_SSTR,
       DCS.DESCRIPTION_SPECIFIQUE_CONTRAT DESC_CONTRAT,
       DCS.SIGNATAIRE_CONTRAT AGENT_ID,
       DCS.LAST_UPDATE_DATE,
       DCS.LAST_UPDATED_BY   
FROM DKA_CONTRAT_SSTR DCS,
     PO_HEADERS_ALL PHA
WHERE DCS.PO_HEADER_ID = PHA.PO_HEADER_ID
  AND NVL(PHA.CLOSED_CODE, 'OPEN') NOT IN ('CLOSED', 'FINALLY CLOSED')
  AND NVL(PHA.CLOSED_DATE, SYSDATE) >= SYSDATE;
;

SHOW ERROR

EXIT
