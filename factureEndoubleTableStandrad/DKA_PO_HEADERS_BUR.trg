--------------------------------------------------------------------------------
-- $Id: DKA_NEW_CLASSIF_ACHAT_V.vue$
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_NEW_CLASSIF_ACHAT_V.vue
-- Description      : Création de la vue DKA_NEW_CLASSIF_ACHAT_V
-- Auteur           : Julien Jardez (Capgemini)
-- Date de création : 14/02/2017
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 14/09/2017 OBE artf2223256 : INT076 - MAJ Vue DKA_NEW_CLASSIF_ACHAT_V - DEFECT 940
-- 29/03/2019 SFA artf07231724 :INC0303464 - INT076 - correction de la vue DKA_NEW_CLASSIF_ACHAT_V 
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_NEW_CLASSIF_ACHAT_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_NEW_CLASSIF_ACHAT_V(
  concatenated_segments,DESCRIPTION)
AS
   SELECT mck.concatenated_segments, mct.description DESCRIPTION  -- OBE artf2223256
FROM 
 FND_ID_FLEX_STRUCTURES fifs, 
 mtl_categories_kfv mck, 
 MTL_CATEGORY_SETS CST,  --SFA : artf07231724
 mtl_categories_tl mct    -- OBE artf2223256
WHERE 
     fifs.application_id = 401 
 AND fifs.id_flex_code= 'MCAT' 
 AND fifs.id_flex_structure_code = 'PO_ITEM_CATEGORY' 
 AND fifs.id_flex_num = mck.structure_id 
 AND fifs.id_flex_num = cst.structure_id
 AND mct.category_id = mck.category_id -- OBE artf2223256
 AND mct.language = 'F'                -- OBE artf2223256
 AND cst.CATEGORY_SET_NAME ='ACHATS'    --SFA : artf07231724
UNION ALL
SELECT 'E', NULL FROM dual  
  ;
/

SHOW ERRORS VIEW DKA_NEW_CLASSIF_ACHAT_V
EXIT
