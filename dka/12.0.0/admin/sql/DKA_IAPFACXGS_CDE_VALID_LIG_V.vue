--------------------------------------------------------------------------------
-- $Id: DKA_IAPFACXGS_CDE_VALID_LIG_V.vue 210 2008-03-18 15:46:15Z NORDEST\tbonduae $
-- Capgemini
-- Projet           : DALKIA Oracle Applications
-- Nom              : DKA_IAPFACXGS_CDE_VALID_LIG_V.vue
-- Description      : Création de la vue dka_iapfacxgs_cde_valid_lig_v
-- Auteur           : Thomas Bonduaeux (Capgemini)
-- Date de création : 27/02/2008
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
--- 2016/09/02 JJA Portage Helios R12
--- 2017/04/25 RBE Correction artf2144838 : INT047 - Doublon dans la vue
--- 2020/05/11 MTIA : INC0319253 & INC0317017 - Quickmatch PF et TF fermé - Refacturation
--- 2020/08/19 MTIA : EDB260 - Gestion de la TVA immobilisation
--- 2020/09/22 MTIA EDB260b - Gestion quickmatch sur tache fermée
--------------------------------------------------------------------------------

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA VUE DKA_IAPFACXGS_CDE_VALID_LIG_V
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

CREATE OR REPLACE VIEW DKA_IAPFACXGS_CDE_VALID_LIG_V
(id_cde, num_cde, id_lig, num_lig, id_location, id_distribution, num_distribution, qte_cde, qte_fact, prix_unit, id_br, num_br, packing_slip, num_ligne_br, societe_projet, id_projet, id_tache, type_depense, date_depense, orgid_depense, class_code, date_ferm_projet, org_id, date_ferm_tache,type_tache)
AS
SELECT   ph.po_header_id,
           ph.segment1,
           pl.po_line_id,
           pl.line_num,
           pll.line_location_id,
           pd.po_distribution_id,
           pd.distribution_num,
           pd.quantity_ordered,
           pd.quantity_billed,
           pl.unit_price,
           dka_iapfacxgs_pkg.get_id_br(pl.po_line_id),
           dka_iapfacxgs_pkg.get_num_br(pl.po_line_id),
           dka_iapfacxgs_pkg.get_packing_slip(pl.po_line_id),
           dka_iapfacxgs_pkg.get_num_ligne_br(pl.po_line_id),
           substr(haou.name,4),
           pd.project_id,
           pd.task_id,
           pd.expenditure_type,
           pd.expenditure_item_date,
           pd.expenditure_organization_id,
           substr(haou.name,4),
           pp.completion_date,
           haou.organization_id,
		   pt.completion_date,
       substr(pt.TASK_NUMBER, 1 , 2)
  FROM     po_headers_all           ph,
           po_lines_all             pl,
           po_line_locations_all    pll,
           po_distributions_all     pd,
           pa_tasks                 pt,
           pa_projects_all          pp,
           pa_transaction_controls  ptc,
           hr_all_organization_units haou
  WHERE        -- jointures
               ph.po_header_id      = pl.po_header_id
           --AND pl.po_line_id      = pd.po_line_id
           AND pl.po_line_id        = pll.po_line_id
           and pll.line_location_id = pd.line_location_id
           and pl.po_line_id        = pd.po_line_id
           AND pd.task_id           = pt.task_id
           AND pd.project_id        = pt.project_id
           AND pp.project_id        = pt.project_id
           AND ptc.project_id       = pp.project_id
           AND pd.expenditure_type  = ptc.expenditure_type
               -- criteres
           AND NVL(pll.closed_code, 'OPEN') IN ('OPEN', 'CLOSED FOR RECEIVING')
           AND pll.approved_flag = 'Y'
           AND NVL(pll.cancel_flag, 'N') = 'N'
          AND pll.quantity > pll.quantity_billed
           AND pp.project_status_code != 'CLOSED'
           AND ptc.chargeable_flag = 'Y'
           AND ptc.start_date_active <= SYSDATE
           AND NVL(ptc.end_date_active, SYSDATE) >= SYSDATE
           AND haou.organization_id = ph.org_id
           AND ptc.task_id = pt.task_id -- RBE
	--	   AND pd.quantity_billed >= 0 -- SNK artf07147602 EDB223 17/04/19
;
/

SHOW ERRORS VIEW DKA_IAPFACXGS_CDE_VALID_LIG_V
EXIT
