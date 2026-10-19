CREATE OR REPLACE PACKAGE BODY DKA_SPO_REQAPPRV_PKG 
AS

----------------------------------------------------------------------------
-- $Id$
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPO_REQAPPRV_PKG.pks
-- DESCRIPTION       : DKA_SPO_REQAPPRV_PKG package specifications
---
--- AUTEUR           : R. BELAYACHI
--- DATE DE CREATION : 08/05/2017
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- ---------------------------------------------------------
--- 13/04/2018 RBE artf2522185 : INC0208457 - Approbation DA < à 3M
--- 06/09/2018 RBE artf2965197 : SPE209 - Correction des requêtes de création de la hiérarchie AME
----------------------------------------------------------------------------

PROCEDURE decode_result(
   p_document_type IN VARCHAR2
,  p_result_val    IN NUMBER
,  x_authorized_yn OUT NOCOPY VARCHAR2
);

-- Private package types
TYPE AUTH_CHECK_TYPES_REC IS RECORD
 (
    check_accounts         BOOLEAN,
    check_items            BOOLEAN,
    check_item_categories  BOOLEAN,
    check_locations        BOOLEAN,
    check_doc_totals       BOOLEAN
 );

TYPE AUTH_CHECK_IDS_REC IS RECORD
 (
    object_id              NUMBER,
    position_id            NUMBER,
    job_id                 NUMBER,
    ctl_function_id        NUMBER,
    fsp_org_id             NUMBER,
    coa_id                 NUMBER,
    item_cat_struct_id     NUMBER
 );
 
 PROCEDURE get_range_limit_sql(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_check_type          IN     VARCHAR2
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_range_check_sql     OUT NOCOPY VARCHAR2
);

 PROCEDURE get_flex_where_sql(
   p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  p_check_type          IN     VARCHAR2
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_flex_sql            OUT NOCOPY VARCHAR2
);

g_chktype_ITEM_LIMIT     CONSTANT VARCHAR2(20) := 'ITEM LIMIT';
g_chktype_CATEGORY_LIMIT CONSTANT VARCHAR2(20) := 'CATEGORY LIMIT';
g_chktype_LOCATION_LIMIT CONSTANT VARCHAR2(20) := 'LOCATION LIMIT';
g_chktype_ACCOUNT_LIMIT  CONSTANT VARCHAR2(20) := 'ACCOUNT LIMIT';
g_chktype_ACCOUNT_EXISTS CONSTANT VARCHAR2(20) := 'ACCOUNT EXISTS';
g_session_gt_query VARCHAR2(10000) := '(SELECT '
                                        ||' po_calculatereqtotal_pvt.get_req_dist_total( porl.requisition_header_id,porl.requisition_line_id,pord.distribution_id) num1 '
                                        ||' ,  NULL num2 '
                                        ||' ,  pord.code_combination_id num3 '
                                        ||' ,  porl.deliver_to_location_id num4 '
                                        ||' ,  porl.item_id num5 '
                                        ||' ,  porl.category_id num6 '
                                        ||' ,  ''N'' char1 '
                                        ||' ,  ''OPEN'' char2  '
                                        ||' FROM po_req_distributions_all pord '
                                        ||' ,  PO_REQUISITION_LINES_all PORL '
                                        ||' WHERE porl.requisition_header_id = :1 '
                                        ||' AND porl.requisition_line_id = pord.requisition_line_id '
                                        ||' AND NVL(PORL.CANCEL_FLAG, ''N'') = ''N'' '
                                        ||' AND NVL(porl.modified_by_agent_flag, ''N'') = ''N'') '
                                        ;
 
 
 
 /***************************************************************/
 
 
 PROCEDURE check_category_limit(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_session_gt_key      IN     NUMBER
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_authorized_yn       OUT NOCOPY VARCHAR2
)
IS

l_sql                 VARCHAR2(8000);
l_result              NUMBER;
l_ret_sts             VARCHAR2(1);

d_progress            NUMBER;
d_module              VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.check_category_limit';

d_msg                 VARCHAR2(200);

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_session_gt_key', p_session_gt_key);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.object_id', p_auth_check_ids.object_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.position_id', p_auth_check_ids.position_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.job_id', p_auth_check_ids.job_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.ctl_function_id', p_auth_check_ids.ctl_function_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.fsp_org_id', p_auth_check_ids.fsp_org_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.coa_id', p_auth_check_ids.coa_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.item_cat_struct_id', p_auth_check_ids.item_cat_struct_id);
  END IF;

  BEGIN

    d_progress := 10;

    get_range_limit_sql(
       p_document_id     => p_document_id
    ,  p_document_type   => p_document_type
    ,  p_document_subtype => p_document_subtype
    ,  p_check_type       => g_chktype_CATEGORY_LIMIT
    ,  p_auth_check_ids   => p_auth_check_ids
    ,  x_return_status    => l_ret_sts
    ,  x_range_check_sql  => l_sql
    );

    d_progress := 20;

    IF (l_ret_sts <> 'S')
    THEN
      d_msg := 'get_range_limit_sql not successful';
      l_ret_sts := 'U';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_sql', l_sql);
    END IF;

    d_progress := 30;

    EXECUTE IMMEDIATE l_sql
      INTO l_result
      USING p_document_id/*p_session_gt_key*/, p_auth_check_ids.position_id
          , p_auth_check_ids.position_id, p_auth_check_ids.job_id
          , p_auth_check_ids.job_id, p_auth_check_ids.ctl_function_id
          , 'ITEM_CATEGORY_RANGE';

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_result', l_result);
    END IF;

    decode_result(
       p_document_type => p_document_type
    ,  p_result_val => l_result
    ,  x_authorized_yn => x_authorized_yn);

    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END check_category_limit;

 /***************************************************************/
 PROCEDURE check_item_limit(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_session_gt_key      IN     NUMBER
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_authorized_yn       OUT NOCOPY VARCHAR2
)
IS

l_sql                 VARCHAR2(8000);
l_result              NUMBER;
l_ret_sts             VARCHAR2(1);

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.check_item_limit';

d_msg      VARCHAR2(200);

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_session_gt_key', p_session_gt_key);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.object_id', p_auth_check_ids.object_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.position_id', p_auth_check_ids.position_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.job_id', p_auth_check_ids.job_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.ctl_function_id', p_auth_check_ids.ctl_function_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.fsp_org_id', p_auth_check_ids.fsp_org_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.coa_id', p_auth_check_ids.coa_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.item_cat_struct_id', p_auth_check_ids.item_cat_struct_id);
  END IF;

  BEGIN

    d_progress := 10;

    get_range_limit_sql(
       p_document_id     => p_document_id
    ,  p_document_type   => p_document_type
    ,  p_document_subtype => p_document_subtype
    ,  p_check_type       => g_chktype_ITEM_LIMIT
    ,  p_auth_check_ids   => p_auth_check_ids
    ,  x_return_status    => l_ret_sts
    ,  x_range_check_sql  => l_sql
    );

    d_progress := 20;

    IF (l_ret_sts <> 'S')
    THEN
      d_msg := 'get_range_limit_sql not successful';
      l_ret_sts := 'U';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_sql', l_sql);
    END IF;

    d_progress := 30;

    EXECUTE IMMEDIATE l_sql
      INTO l_result
      USING p_document_id/*p_session_gt_key*/, p_auth_check_ids.position_id
          , p_auth_check_ids.position_id, p_auth_check_ids.job_id
          , p_auth_check_ids.job_id, p_auth_check_ids.ctl_function_id
          , 'ITEM_RANGE';

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_result', l_result);
    END IF;

    decode_result(
       p_document_type => p_document_type
    ,  p_result_val => l_result
    ,  x_authorized_yn => x_authorized_yn);

    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END check_item_limit;

 /***************************************************************/
 PROCEDURE check_location_limit(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_session_gt_key      IN     NUMBER
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_authorized_yn       OUT NOCOPY VARCHAR2
)
IS

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.check_location_limit';

l_result           NUMBER;

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_session_gt_key', p_session_gt_key);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.object_id', p_auth_check_ids.object_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.position_id', p_auth_check_ids.position_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.job_id', p_auth_check_ids.job_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.ctl_function_id', p_auth_check_ids.ctl_function_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.fsp_org_id', p_auth_check_ids.fsp_org_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.coa_id', p_auth_check_ids.coa_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.item_cat_struct_id', p_auth_check_ids.item_cat_struct_id);
  END IF;

  SELECT sign(min(nvl(POCR.amount_limit, -1) - sum(pgt.num1)))
  INTO l_result
  FROM po_control_rules pocr
    ,  po_control_groups pocg
    ,  po_position_controls popc
    ,  (SELECT
po_calculatereqtotal_pvt.get_req_dist_total( porl.requisition_header_id,porl.requisition_line_id,pord.distribution_id) num1
,  NULL num2
,  pord.code_combination_id num3
,  porl.deliver_to_location_id num4
,  porl.item_id num5
,  porl.category_id num6
,  'N' char1
,  'OPEN' char2                     -- Bug 4610058
FROM po_req_distributions_ALL pord
,  PO_REQUISITION_LINES_ALL PORL
WHERE porl.requisition_header_id = p_document_id
AND porl.requisition_line_id = pord.requisition_line_id
AND NVL(PORL.CANCEL_FLAG, 'N') = 'N'
AND NVL(porl.modified_by_agent_flag, 'N') = 'N') pgt
  WHERE 1=1 /*pgt.key = p_session_gt_key*/ --RBE
    AND pgt.num1 IS NOT NULL
    AND pgt.num2 IS NULL         -- Bug 4610058
    AND pgt.char1 = 'N'
    AND pgt.char2 <> 'FINALLY CLOSED'
    -- <Bug 4605781 Start>
    AND ((p_auth_check_ids.position_id IS NULL) OR
          (popc.position_id = p_auth_check_ids.position_id))
    AND ((p_auth_check_ids.job_id IS NULL) OR
          (popc.job_id = p_auth_check_ids.job_id))
    -- <Bug 4605781 End>
    AND sysdate BETWEEN NVL(popc.start_date, sysdate - 1) AND NVL(popc.end_date, sysdate + 1)
    AND popc.control_function_id = p_auth_check_ids.ctl_function_id
    AND pocg.enabled_flag = 'Y'
    AND pocg.control_group_id = popc.control_group_id
    AND pocr.control_group_id = pocg.control_group_id
    AND pocr.object_code = 'LOCATION' --Bug#4901549
    AND NVL(pocr.inactive_date, sysdate + 1) > sysdate
    AND pocr.location_id = pgt.num4
  GROUP BY  pocr.control_rule_id, pocr.amount_limit;

  d_progress := 10;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'l_result', l_result);
  END IF;

  decode_result(
     p_document_type => p_document_type
  ,  p_result_val => l_result
  ,  x_authorized_yn => x_authorized_yn);

  d_progress := 20;

  x_return_status := 'S';

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END check_location_limit;

 /*************************************************************/
 
 PROCEDURE get_range_limit_sql(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_check_type          IN     VARCHAR2
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_range_check_sql     OUT NOCOPY VARCHAR2
)
IS

-- x_range_check_sql buffer size should be at least 8000 characters.

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.get_range_limit_sql';

l_flex_segment_where          VARCHAR2(4000);

l_sum_col     VARCHAR2(80);
l_flex_table  VARCHAR2(80);
l_flex_join   VARCHAR2(80);

l_ret_sts     VARCHAR2(1);
l_hint        varchar2(100); -- bug 12359144 declaring variable.
d_msg         VARCHAR2(200);

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_check_type', p_check_type);
  END IF;

  BEGIN

    IF (p_check_type = g_chktype_ACCOUNT_LIMIT)
    THEN

      d_progress := 10;

      l_sum_col := 'pgt.num1';
      l_flex_table := ' , gl_code_combinations glcc ';
      l_flex_join := ' AND glcc.code_combination_id = pgt.num3 ';

    ELSIF (p_check_type = g_chktype_ITEM_LIMIT)
    THEN

      d_progress := 20;

      IF (p_document_type <> 'PA')
      THEN
        l_sum_col := 'pgt.num1';
      ELSE
        l_sum_col := 'pgt.num2';
      END IF;
       -- bug 12359144 : Adding leading hint to improve performance
       -- bug 19911263 : disable merge join cartesian in the hint
       l_hint := ' /*+ leading(pgt mtsi pocr) use_nl(pocr) OPT_PARAM(''_optimizer_mjc_enabled'',''false'')*/ ';
      -- bug =12359144

      l_flex_table := ' , mtl_system_items mtsi ';
      l_flex_join := ' AND mtsi.inventory_item_id = pgt.num5 AND mtsi.organization_id = ' || p_auth_check_ids.fsp_org_id || ' ';

    ELSIF (p_check_type = g_chktype_CATEGORY_LIMIT)
    THEN

      d_progress := 30;

      IF (p_document_type <> 'PA')
      THEN
        l_sum_col := 'pgt.num1';
      ELSE
        l_sum_col := 'pgt.num2';
      END IF;

       -- bug 12359144 : Adding leading hint to improve performance
       -- bug 19911263 : disable merge join cartesian in the hint
       l_hint := ' /*+ leading(pgt mtcat pocr) use_nl(pocr) OPT_PARAM(''_optimizer_mjc_enabled'',''false'')*/ ';
      -- bug =12359144

      l_flex_table := ' , mtl_categories mtcat ';
      l_flex_join := ' AND mtcat.category_id = pgt.num6 ';

    ELSE

      d_progress := 40;
      l_ret_sts := 'U';
      d_msg := 'check type not supported';
      RAISE PO_CORE_S.g_early_return_exc;

    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_sum_col', l_sum_col);
      PO_LOG.stmt(d_module, d_progress, 'l_flex_table', l_flex_table);
      PO_LOG.stmt(d_module, d_progress, 'l_flex_join', l_flex_join);
    END IF;

    d_progress := 50;

    get_flex_where_sql(
       p_auth_check_ids => p_auth_check_ids
    ,  p_check_type     => p_check_type
    ,  x_return_status  => l_ret_sts
    ,  x_flex_sql       => l_flex_segment_where
    );

    IF (l_ret_sts <> 'S') THEN

      d_progress := 60;
      l_ret_sts := 'U';
      d_msg := 'get_flex_where_sql not successful';
      RAISE PO_CORE_S.g_early_return_exc;

    END IF;

    d_progress := 70;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_flex_segment_where', l_flex_segment_where);
    END IF;

    -- Bind variables created in sql string:
    -- 1 - key into po_session_gt table
    -- 2 - p_auth_check_ids.position_id
    -- 3 - p_auth_check_ids.job_id
    -- 4 - p_auth_check_ids.ctl_function_id
    -- 5 - object code in po_control_rules, e.g. 'ACCOUNT_RANGE'

    x_range_check_sql := 'SELECT '
             || l_hint   -- bug 12359144
			 || ' sign(min(nvl(POCR.amount_limit, -1) '
             || ' - sum(' || l_sum_col || ')))'
             || ' FROM '||g_session_gt_query ||' pgt, po_control_rules pocr'
             || ' , po_control_groups pocg, po_position_controls popc'
             || l_flex_table
             || ' WHERE 1=1 /*pgt.key = :1*/ AND ' || l_sum_col || ' IS NOT NULL'
             || ' AND pgt.char1 = DECODE(POCR.RULE_TYPE_CODE,''INCLUDE'',nvl(pgt.char1, ''N''),''EXCLUDE'',''N'') '  --Bug 13835378 fix
             || ' AND pgt.char2 <> ''FINALLY CLOSED'' '
             || l_flex_join
             -- <Bug 4605781 Start>
             || ' AND ((:2 IS NULL) OR (popc.position_id = :3))'
             || ' AND ((:4 IS NULL) OR (popc.job_id = :5))'
             -- <Bug 4605781 End>
             || ' AND sysdate BETWEEN NVL(popc.start_date, sysdate - 1) AND NVL(popc.end_date, sysdate + 1)'
             || ' AND popc.control_function_id = :6'
             || ' AND pocg.enabled_flag = ''Y'' '
             || ' AND pocg.control_group_id = popc.control_group_id'
             || ' AND pocr.control_group_id = pocg.control_group_id'
             || ' AND pocr.object_code = :7 '
             || ' AND NVL(pocr.inactive_date, sysdate + 1) > sysdate '
             || l_flex_segment_where
             || ' GROUP BY  pocr.control_rule_id, pocr.amount_limit';

    d_progress := 80;
    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_range_check_sql', x_range_check_sql);
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END get_range_limit_sql;

/*****************************************************************/
 PROCEDURE check_account_limit(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_session_gt_key      IN     NUMBER
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_authorized_yn       OUT NOCOPY VARCHAR2
)
IS

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.check_account_limit';

l_sql                 VARCHAR2(8000);
l_result              NUMBER;
l_ret_sts             VARCHAR2(1);
d_msg      VARCHAR2(200);

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_session_gt_key', p_session_gt_key);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.object_id', p_auth_check_ids.object_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.position_id', p_auth_check_ids.position_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.job_id', p_auth_check_ids.job_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.ctl_function_id', p_auth_check_ids.ctl_function_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.fsp_org_id', p_auth_check_ids.fsp_org_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.coa_id', p_auth_check_ids.coa_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.item_cat_struct_id', p_auth_check_ids.item_cat_struct_id);
  END IF;

  BEGIN

    d_progress := 10;

    get_range_limit_sql(
       p_document_id     => p_document_id
    ,  p_document_type   => p_document_type
    ,  p_document_subtype => p_document_subtype
    ,  p_check_type       => g_chktype_ACCOUNT_LIMIT
    ,  p_auth_check_ids   => p_auth_check_ids
    ,  x_return_status    => l_ret_sts
    ,  x_range_check_sql  => l_sql
    );

    d_progress := 20;

    IF (l_ret_sts <> 'S')
    THEN
      d_msg := 'get_range_limit_sql not successful';
      l_ret_sts := 'U';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_sql', l_sql);
    END IF;

    d_progress := 30;

    EXECUTE IMMEDIATE l_sql
      INTO l_result
      USING p_document_id/*p_session_gt_key*/, p_auth_check_ids.position_id
          , p_auth_check_ids.position_id, p_auth_check_ids.job_id
          , p_auth_check_ids.job_id, p_auth_check_ids.ctl_function_id
          , 'ACCOUNT_RANGE';

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_result', l_result);
    END IF;

    decode_result(
       p_document_type => p_document_type
    ,  p_result_val => l_result
    ,  x_authorized_yn => x_authorized_yn);

    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;
END check_account_limit;
 
 /**************************************************************/
 PROCEDURE get_flex_where_sql(
   p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  p_check_type          IN     VARCHAR2
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_flex_sql            OUT NOCOPY VARCHAR2
)
IS

l_flexfield_rec  FND_FLEX_KEY_API.flexfield_type;
l_structure_rec  FND_FLEX_KEY_API.structure_type;
l_segment_rec    FND_FLEX_KEY_API.segment_type;
l_segment_tbl    FND_FLEX_KEY_API.segment_list;

l_appl_short_name   VARCHAR2(8);
l_flex_code         VARCHAR2(8);
l_structure_code    NUMBER;
l_table_alias       VARCHAR2(8);

l_segment_number NUMBER;
l_idx            NUMBER;
l_segment        VARCHAR2(160);

d_msg     VARCHAR2(200);
d_progress    NUMBER;
d_module      VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.get_flex_where_sql';

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_check_type', p_check_type);
  END IF;

  x_flex_sql := ' ';

  IF ((p_check_type = g_chktype_ACCOUNT_LIMIT)
       OR (p_check_type = g_chktype_ACCOUNT_EXISTS))
  THEN

    d_progress := 10;
    l_appl_short_name := 'SQLGL';
    l_flex_code := 'GL#';
    l_structure_code := p_auth_check_ids.coa_id;
    l_table_alias := 'glcc';

  ELSIF (p_check_type = g_chktype_ITEM_LIMIT)
  THEN

    d_progress := 20;
    l_appl_short_name := 'INV';
    l_flex_code := 'MSTK';
    l_structure_code := 101;
    l_table_alias := 'mtsi';

  ELSIF (p_check_type = g_chktype_CATEGORY_LIMIT)
  THEN

    d_progress := 30;
    l_appl_short_name := 'INV';
    l_flex_code := 'MCAT';
    l_structure_code := p_auth_check_ids.item_cat_struct_id;
    l_table_alias := 'mtcat';

  ELSE

    d_progress := 40;
    d_msg := 'check type not supported';
    RAISE PO_CORE_S.g_early_return_exc;

  END IF;  -- p_check_type = ...

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'l_appl_short_name', l_appl_short_name);
    PO_LOG.stmt(d_module, d_progress, 'l_flex_code', l_flex_code);
    PO_LOG.stmt(d_module, d_progress, 'l_structure_code', l_structure_code);
    PO_LOG.stmt(d_module, d_progress, 'l_table_alias', l_table_alias);
  END IF;

  d_progress := 50;

  -- Call FND_FLEX_KEY_API to get flexfield information
  FND_FLEX_KEY_API.set_session_mode('customer_data');

  d_progress := 60;

  -- Retrieve flexfield sgements
  l_flexfield_rec := FND_FLEX_KEY_API.find_flexfield(l_appl_short_name,l_flex_code);
  d_progress := 65;
  l_structure_rec := FND_FLEX_KEY_API.find_structure(l_flexfield_rec, l_structure_code);

  d_progress := 70;

  FND_FLEX_KEY_API.get_segments(
     flexfield => l_flexfield_rec
  ,  structure => l_structure_rec
  ,  nsegments => l_segment_number
  ,  segments  => l_segment_tbl
  );

  d_progress := 80;

  -- Construct the where condition for the flexfield values to be
  -- within range of the control rule's values.
  FOR l_idx IN 1..l_segment_number
  LOOP

    d_progress := 90;

    l_segment_rec := FND_FLEX_KEY_API.find_segment(l_flexfield_rec,l_structure_rec,l_segment_tbl(l_idx));

	 l_segment := 'NVL(' || l_table_alias || '.' || l_segment_rec.column_name || ', ''0'')';

    x_flex_sql := x_flex_sql || ' AND '|| l_segment || ' BETWEEN '
       || ' NVL(POCR.' || l_segment_rec.column_name || '_low, ' || l_segment
       || ' ) AND NVL(POCR.' || l_segment_rec.column_name ||'_high, ' || l_segment || ') ';

  END LOOP;  -- FOR l_idx IN 1..l_segment_number

  x_return_status := 'S';

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_flex_sql', x_flex_sql);
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END get_flex_where_sql;
 
 /*************************************************************/
 PROCEDURE get_range_exists_sql(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_check_type          IN     VARCHAR2
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_range_check_sql     OUT NOCOPY VARCHAR2
)
IS

-- x_range_check_sql buffer size should be at least 8000 characters.

l_flex_segment_where          VARCHAR2(4000);
l_flex_table  VARCHAR2(80);
l_flex_join   VARCHAR2(80);

l_ret_sts     VARCHAR2(1);

d_msg     VARCHAR2(200);
d_progress    NUMBER;
d_module      VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.get_range_exists_sql';

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_check_type', p_check_type);
  END IF;

  BEGIN

    IF (p_check_type = g_chktype_ACCOUNT_EXISTS)
    THEN

      d_progress := 10;

      l_flex_table := ' , gl_code_combinations glcc ';
      l_flex_join := ' AND glcc.code_combination_id = pgt.num3 ';

    ELSE

      d_progress := 20;
      l_ret_sts := 'U';
      d_msg := 'check type not supported';
      RAISE PO_CORE_S.g_early_return_exc;

    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_flex_table', l_flex_table);
      PO_LOG.stmt(d_module, d_progress, 'l_flex_join', l_flex_join);
    END IF;

    d_progress := 30;

    get_flex_where_sql(
       p_auth_check_ids => p_auth_check_ids
    ,  p_check_type     => p_check_type
    ,  x_return_status  => l_ret_sts
    ,  x_flex_sql       => l_flex_segment_where
    );
    
    IF (l_ret_sts <> 'S') THEN

      d_progress := 40;
      l_ret_sts := 'U';
      d_msg := 'get_flex_where_sql not successful';
      RAISE PO_CORE_S.g_early_return_exc;

    END IF;

    d_progress := 50;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_flex_segment_where', l_flex_segment_where);
    END IF;

    -- Bind variables created in sql string:
    -- 1 - key into po_session_gt table
    -- 2 - p_auth_check_ids.position_id
    -- 3 - p_auth_check_ids.job_id
    -- 4 - p_auth_check_ids.ctl_function_id
    -- 5 - object code in po_control_rules, e.g. 'ACCOUNT_RANGE'

    x_range_check_sql := 'SELECT nvl(min(-1),0) '
             || ' FROM '||g_session_gt_query ||' pgt '
             || l_flex_table
             || ' WHERE 1=1 /*pgt.key = :1*/ '
	     || ' AND pgt.char1 = ''N'' '   --Bug 13835378 fix. Cancelled lines should not be considered.
             || l_flex_join
             || ' AND NOT EXISTS ( '
             || ' SELECT ''account is in range'' '
             || ' FROM po_control_rules pocr, po_control_groups pocg'
             || ' , po_position_controls popc '
             -- <Bug 4605781 Start>
             || ' WHERE ((:2 IS NULL) OR (popc.position_id = :3))'
             || ' AND ((:4 IS NULL) OR (popc.job_id = :5))'
             -- <Bug 4605781 End>
             || ' AND sysdate BETWEEN NVL(popc.start_date, sysdate - 1) AND NVL(popc.end_date, sysdate + 1)'
             || ' AND popc.control_function_id = :6'
             || ' AND pocg.enabled_flag = ''Y'' '
             || ' AND pocg.control_group_id = popc.control_group_id'
             || ' AND pocr.control_group_id = pocg.control_group_id'
             || ' AND pocr.object_code = :7 '
             || ' AND NVL(pocr.inactive_date, sysdate + 1) > sysdate '
             || l_flex_segment_where
             || ' ) ';


    d_progress := 60;
    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_range_check_sql', x_range_check_sql);
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END get_range_exists_sql;

 /************************************************************/
 
 PROCEDURE check_account_exists(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_session_gt_key      IN     NUMBER
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_authorized_yn       OUT NOCOPY VARCHAR2
)
IS

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.check_account_exists';

l_sql            VARCHAR2(10000);
l_result         NUMBER;
l_ret_sts        VARCHAR2(1);
d_msg           VARCHAR2(200);

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_session_gt_key', p_session_gt_key);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.object_id', p_auth_check_ids.object_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.position_id', p_auth_check_ids.position_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.job_id', p_auth_check_ids.job_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.ctl_function_id', p_auth_check_ids.ctl_function_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.fsp_org_id', p_auth_check_ids.fsp_org_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.coa_id', p_auth_check_ids.coa_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.item_cat_struct_id', p_auth_check_ids.item_cat_struct_id);
  END IF;

  BEGIN

    d_progress := 10;

    get_range_exists_sql(
       p_document_id     => p_document_id
    ,  p_document_type   => p_document_type
    ,  p_document_subtype => p_document_subtype
    ,  p_check_type       => g_chktype_ACCOUNT_EXISTS
    ,  p_auth_check_ids   => p_auth_check_ids
    ,  x_return_status    => l_ret_sts
    ,  x_range_check_sql  => l_sql
    );

    d_progress := 20;

    IF (l_ret_sts <> 'S')
    THEN
      d_msg := 'get_range_exists_sql not successful';
      l_ret_sts := 'U';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_sql', l_sql);
    END IF;

    d_progress := 30;

    EXECUTE IMMEDIATE l_sql
      INTO l_result
      USING p_document_id /*p_session_gt_key*/, p_auth_check_ids.position_id  --RBE
          , p_auth_check_ids.position_id, p_auth_check_ids.job_id
          , p_auth_check_ids.job_id, p_auth_check_ids.ctl_function_id
          , 'ACCOUNT_RANGE';

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_result', l_result);
    END IF;

    decode_result(
       p_document_type => p_document_type
    ,  p_result_val => l_result
    ,  x_authorized_yn => x_authorized_yn);

    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF (PO_LOG.d_exc) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END check_account_exists;
 
 /**************************************************************************/
 
 PROCEDURE decode_result(
   p_document_type IN VARCHAR2
,  p_result_val    IN NUMBER
,  x_authorized_yn OUT NOCOPY VARCHAR2
)
IS

l_result  NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.decode_result';
BEGIN

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_result_val', p_result_val);
  END IF;

  -- Bug 4610058: No need for special case for 'PA', which was a result
  -- of incorrect comments in old Pro*C code. If no rows are returned for 'PA'
  -- check should still pass.

  l_result := NVL(p_result_val, 0);


  IF (l_result < 0)
  THEN
    x_authorized_yn := 'N';
  ELSE
    x_authorized_yn := 'Y';
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

END decode_result;
 
 /*************************************************************************/

 PROCEDURE check_doc_total_limit(
   p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_session_gt_key      IN     NUMBER
,  p_auth_check_ids      IN     AUTH_CHECK_IDS_REC
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_authorized_yn       OUT NOCOPY VARCHAR2
)
IS

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.check_doc_total_limit';

l_result            NUMBER;
l_amt_limit_nvl     NUMBER;

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_session_gt_key', p_session_gt_key);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.object_id', p_auth_check_ids.object_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.position_id', p_auth_check_ids.position_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.job_id', p_auth_check_ids.job_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.ctl_function_id', p_auth_check_ids.ctl_function_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.fsp_org_id', p_auth_check_ids.fsp_org_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.coa_id', p_auth_check_ids.coa_id);
    PO_LOG.proc_begin(d_module, 'p_auth_check_ids.item_cat_struct_id', p_auth_check_ids.item_cat_struct_id);
  END IF;

  IF (p_document_type = 'PA')
  THEN
    l_amt_limit_nvl := 0;
  ELSE
    l_amt_limit_nvl := -1;
  END IF;

  d_progress := 10;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'l_amt_limit_nvl', l_amt_limit_nvl);
  END IF;



  SELECT sign(min(nvl(POCR.amount_limit, l_amt_limit_nvl) - sum(pgt.num1)))
  INTO l_result
  FROM po_control_rules pocr
    ,  po_control_groups pocg
    ,  po_position_controls popc
    ,  (SELECT
po_calculatereqtotal_pvt.get_req_dist_total( porl.requisition_header_id,porl.requisition_line_id,pord.distribution_id) num1
,  NULL num2
,  pord.code_combination_id num3
,  porl.deliver_to_location_id num4
,  porl.item_id num5
,  porl.category_id num6
,  'N' char1
,  'OPEN' char2                     -- Bug 4610058
FROM po_req_distributions_ALL pord
,  PO_REQUISITION_LINES_ALL PORL
WHERE porl.requisition_header_id = p_document_id
AND porl.requisition_line_id = pord.requisition_line_id
AND NVL(PORL.CANCEL_FLAG, 'N') = 'N'
AND NVL(porl.modified_by_agent_flag, 'N') = 'N') pgt --RBE

  WHERE 1=1 --pgt.key = p_session_gt_key --RBE
    AND pgt.num1 IS NOT NULL
    AND pgt.num2 IS NULL                -- Bug 4610058
    -- <Bug 4605781 Start>
    AND ((p_auth_check_ids.position_id IS NULL) OR
          (popc.position_id = p_auth_check_ids.position_id))
    AND ((p_auth_check_ids.job_id IS NULL) OR
          (popc.job_id = p_auth_check_ids.job_id))
    -- <Bug 4605781 End>
    AND sysdate BETWEEN NVL(popc.start_date, sysdate - 1) AND NVL(popc.end_date, sysdate + 1)
    AND popc.control_function_id = p_auth_check_ids.ctl_function_id
    AND pocg.enabled_flag = 'Y'
    AND pocg.control_group_id = popc.control_group_id
    AND pocr.control_group_id = pocg.control_group_id
    AND pocr.object_code = 'DOCUMENT_TOTAL'
    AND NVL(pocr.inactive_date, sysdate + 1) > sysdate
  GROUP BY  pocr.control_rule_id, pocr.amount_limit;

  d_progress := 20;

  -- bug4772633
  -- For PA, if document total control rule is not defined, the above sql
  -- returns NULL. In that case, it means that approval is not allowed
  IF (p_document_type = 'PA') THEN
    l_result := NVL(l_result, -2);
  END IF;

  IF (PO_LOG.d_stmt) THEN
    PO_LOG.stmt(d_module, d_progress, 'l_result', l_result);
  END IF;

  decode_result(
     p_document_type => p_document_type
  ,  p_result_val => l_result
  ,  x_authorized_yn => x_authorized_yn);

  d_progress := 30;
  x_return_status := 'S';

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_authorized_yn', x_authorized_yn);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END check_doc_total_limit;
/***********************************************************************/

PROCEDURE authority_checks_setup(
   p_action_to_verify    IN     VARCHAR2
,  p_document_id         IN     NUMBER
,  p_document_type       IN     VARCHAR2
,  p_document_subtype    IN     VARCHAR2
,  p_employee_id         IN     NUMBER
,  x_auth_checks_to_do   OUT NOCOPY AUTH_CHECK_TYPES_REC
,  x_auth_check_ids      OUT NOCOPY AUTH_CHECK_IDS_REC
,  x_using_positions     OUT NOCOPY BOOLEAN
,  x_return_status       OUT NOCOPY VARCHAR2
,  x_functional_error    OUT NOCOPY VARCHAR2
)
IS

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.authority_checks_setup';

l_ret_sts      VARCHAR2(1);
d_msg      VARCHAR2(200);

l_emp_flag       BOOLEAN;
l_emp_id         PER_EMPLOYEES_CURRENT_X.employee_id%TYPE;
l_emp_name       PER_EMPLOYEES_CURRENT_X.full_name%TYPE;
l_emp_loc_id     PER_EMPLOYEES_CURRENT_X.location_id%TYPE;
l_emp_loc_code   HR_LOCATIONS.location_code%TYPE;
l_emp_is_buyer   BOOLEAN;

l_using_pos_str  FINANCIALS_SYSTEM_PARAMETERS.use_positions_flag%TYPE;

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_action_to_verify', p_action_to_verify);
    PO_LOG.proc_begin(d_module, 'p_document_id', p_document_id);
    PO_LOG.proc_begin(d_module, 'p_document_type', p_document_type);
    PO_LOG.proc_begin(d_module, 'p_document_subtype', p_document_subtype);
    PO_LOG.proc_begin(d_module, 'p_employee_id', p_employee_id);
  END IF;

  d_progress := 10;

  BEGIN

    SELECT structure_id
    INTO x_auth_check_ids.item_cat_struct_id
    FROM mtl_default_sets_view mfsv
    WHERE mfsv.functional_area_id = 2;

    d_progress := 15;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'x_auth_check_ids.item_cat_struct_id', x_auth_check_ids.item_cat_struct_id);
    END IF;

    IF (p_employee_id IS NULL)
    THEN

      d_progress := 20;

      PO_DOCUMENT_ACTION_UTIL.get_employee_info(
         p_user_id       =>  FND_GLOBAL.USER_ID
      ,  x_return_status => l_ret_sts
      ,  x_employee_flag => l_emp_flag
      ,  x_employee_id   => l_emp_id
      ,  x_employee_name => l_emp_name
      ,  x_location_id   => l_emp_loc_id
      ,  x_location_code => l_emp_loc_code
      ,  x_is_buyer_flag => l_emp_is_buyer
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 20;
        l_ret_sts := 'U';
        d_msg := 'get_employee_id not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (NOT l_emp_flag)
      THEN
        d_progress := 30;
        l_ret_sts := 'E';
        d_msg := 'No employee flag returned';
        x_functional_error := fnd_message.get_string('PO', 'PO_ALL_NO_EMP_ID_FOR_USER_ID');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

    ELSE

      d_progress := 40;

      PO_EMPLOYEES_SV.get_employee_name(
         x_emp_id    => p_employee_id
      ,  x_emp_name  => l_emp_name
      );

      l_emp_id := p_employee_id;

    END IF;  -- p_employee_id IS NULL

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_emp_id', l_emp_id);
      PO_LOG.stmt(d_module, d_progress, 'l_emp_name', l_emp_name);
    END IF;

    d_progress := 50;

    SELECT glsob.chart_of_accounts_id
        ,  NVL(fsp.use_positions_flag, 'N')
        ,  fsp.inventory_organization_id
    INTO x_auth_check_ids.coa_id
      ,  l_using_pos_str
      ,  x_auth_check_ids.fsp_org_id
    FROM financials_system_params_all fsp, --financials_system_parameters fsp, -- RBE
         gl_sets_of_books glsob
    WHERE fsp.set_of_books_id = glsob.set_of_books_id
    AND  fsp.org_id = ( select org_id 
                        from po_requisition_headers_all 
                        where requisition_header_id= p_document_id);

    d_progress := 60;

    IF (l_using_pos_str = 'Y')
    THEN
      x_using_positions := TRUE;
    ELSE
      x_using_positions := FALSE;
    END IF;

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'l_using_pos_str', l_using_pos_str);
      PO_LOG.stmt(d_module, d_progress, 'x_using_positions', x_using_positions);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_check_ids.fsp_org_id', x_auth_check_ids.fsp_org_id);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_check_ids.coa_id', x_auth_check_ids.coa_id);
    END IF;

    IF (x_using_positions)
    THEN
    --Bug18652153, add per system status filtering to avoid multiple assignment case
    --'ACTIVE_ASSIGN' for employee assignment
    --'ACTIVE_CWK' for contingent worker
      d_progress := 70;

      SELECT nvl(paf.position_id, 0)
      INTO x_auth_check_ids.position_id
      FROM PER_ALL_ASSIGNMENTS_F paf   -- <BUG 6615913>
      WHERE paf.person_id = l_emp_id
        AND paf.assignment_type IN  ('E','C')    --R12 CWK enhancement
        AND paf.primary_flag = 'Y'
        AND trunc(sysdate) BETWEEN TRUNC(paf.effective_start_date) AND TRUNC(paf.effective_end_date) --RBE artf2965197
        and exists
       (select 1
          from per_assignment_status_types pst
         where pst.assignment_status_type_id = paf.assignment_status_type_id
           and pst.per_system_status in ('ACTIVE_ASSIGN', 'ACTIVE_CWK'));

      d_progress := 80;
      IF (x_auth_check_ids.position_id = 0)
      THEN
        d_progress := 90;
        l_ret_sts := 'E';
        d_msg := 'position_id is 0';
        x_functional_error := fnd_message.get_string('PO', 'PO_ALL_NO_POSITION_ID');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      x_auth_check_ids.job_id := NULL;

    ELSE

      d_progress := 90;

      SELECT nvl(paf.job_id, 0)
      INTO x_auth_check_ids.job_id
      FROM PER_ALL_ASSIGNMENTS_F paf  -- <BUG 6615913>
      WHERE paf.person_id = l_emp_id
        AND paf.assignment_type IN  ('E','C')    --R12 CWK enhancement
        AND paf.primary_flag = 'Y'
        AND trunc(sysdate) BETWEEN TRUNC(paf.effective_start_date) AND TRUNC(paf.effective_end_date); --RBE artf2965197

      d_progress := 100;

      IF (x_auth_check_ids.job_id = 0)
      THEN
        d_progress := 110;
        l_ret_sts := 'E';
        d_msg := 'job_id is 0';
        x_functional_error := fnd_message.get_string('PO', 'PO_ALL_NO_JOB_ID');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      x_auth_check_ids.position_id := NULL;

    END IF;  -- if x_using_positions

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'x_auth_check_ids.position_id', x_auth_check_ids.position_id);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_check_ids.job_id', x_auth_check_ids.job_id);
    END IF;

    d_progress := 120;

    BEGIN

      SELECT pocf.control_function_id
      INTO x_auth_check_ids.ctl_function_id
      FROM po_control_functions pocf
      WHERE pocf.document_type_code = p_document_type
        AND pocf.document_subtype = p_document_subtype
        AND pocf.action_type_code = p_action_to_verify
        AND pocf.enabled_flag = 'Y';

    EXCEPTION
      WHEN no_data_found THEN
        d_progress := 125;
        l_ret_sts := 'E';
        d_msg := 'no control function id available';
        x_functional_error := fnd_message.get_string('PO', 'PO_ALL_NO_CONTROL_FUCNTION_ID');
        RAISE PO_CORE_S.g_early_return_exc;
    END;

    d_progress := 130;
    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'x_auth_check_ids.ctl_function_id', x_auth_check_ids.ctl_function_id);
    END IF;

    x_auth_check_ids.object_id := p_document_id;

    d_progress := 140;

    IF (p_document_type IN ('REQUISITION', 'PO', 'RELEASE'))
    THEN

      -- all checks
      d_progress := 150;
      x_auth_checks_to_do.check_accounts := TRUE;
      x_auth_checks_to_do.check_items := TRUE;
      x_auth_checks_to_do.check_item_categories := TRUE;
      x_auth_checks_to_do.check_locations := TRUE;
      x_auth_checks_to_do.check_doc_totals := TRUE;

    ELSIF ((p_document_type = 'PA') and (p_document_subtype = 'BLANKET'))
    THEN

      -- item only checks, plus doc total check
      d_progress := 160;
      x_auth_checks_to_do.check_accounts := FALSE;
      x_auth_checks_to_do.check_items := TRUE;
      x_auth_checks_to_do.check_item_categories := TRUE;
      x_auth_checks_to_do.check_locations := FALSE;
      x_auth_checks_to_do.check_doc_totals := TRUE;

    ELSIF ((p_document_type = 'PA') and (p_document_subtype = 'CONTRACT'))
    THEN

      -- no checks other than doc total check
      d_progress := 170;
      x_auth_checks_to_do.check_accounts := FALSE;
      x_auth_checks_to_do.check_items := FALSE;
      x_auth_checks_to_do.check_item_categories := FALSE;
      x_auth_checks_to_do.check_locations := FALSE;
      x_auth_checks_to_do.check_doc_totals := TRUE;

    ELSE

      d_progress := 180;
      l_ret_sts := 'U';
      d_msg := 'bad document type or subtype';
      RAISE PO_CORE_S.g_early_return_exc;

    END IF;  -- p_document_type IN ...

    IF (PO_LOG.d_stmt) THEN
      PO_LOG.stmt(d_module, d_progress, 'x_auth_checks_to_do.check_accounts', x_auth_checks_to_do.check_accounts);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_checks_to_do.check_items', x_auth_checks_to_do.check_items);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_checks_to_do.check_item_categories', x_auth_checks_to_do.check_item_categories);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_checks_to_do.check_locations', x_auth_checks_to_do.check_locations);
      PO_LOG.stmt(d_module, d_progress, 'x_auth_checks_to_do.check_doc_totals', x_auth_checks_to_do.check_doc_totals);
    END IF;

    l_ret_sts := 'S';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF ((l_ret_sts = 'U') and (PO_LOG.d_exc)) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;
      IF (l_ret_sts = 'E') THEN
        PO_LOG.stmt(d_module, d_progress, 'Error: ' || d_msg);
      END IF;
  END;

  x_return_status := l_ret_sts;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
    PO_LOG.proc_end(d_module, 'x_auth_check_ids.object_id', x_auth_check_ids.object_id);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN others THEN
    x_return_status := 'U';
    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'x_return_status', x_return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END authority_checks_setup;
    
    
/********************************************************************************/
PROCEDURE authority_check(
   p_action_ctl_rec  IN OUT NOCOPY  PO_DOCUMENT_ACTION_PVT.doc_action_call_rec_type
)
IS

d_progress       NUMBER;
d_module         VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.authority_check';

l_authority_verified   VARCHAR2(1);
l_action_to_verify     VARCHAR2(30) := PO_DOCUMENT_ACTION_PVT.g_doc_action_APPROVE;
l_auth_checks_to_do    AUTH_CHECK_TYPES_REC;
l_auth_check_ids       AUTH_CHECK_IDS_REC;
l_using_positions      BOOLEAN;

l_session_gt_key       NUMBER;

l_ret_sts  VARCHAR2(1);
d_msg      VARCHAR2(200);

l_authorized_yn  VARCHAR2(1);

BEGIN

  d_progress := 0;
  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_begin(d_module);
    PO_LOG.proc_begin(d_module, 'p_action_ctl_rec.document_id', p_action_ctl_rec.document_id);
    PO_LOG.proc_begin(d_module, 'p_action_ctl_rec.document_type', p_action_ctl_rec.document_type);
    PO_LOG.proc_begin(d_module, 'p_action_ctl_rec.document_subtype', p_action_ctl_rec.document_subtype);
    PO_LOG.proc_begin(d_module, 'p_action_ctl_rec.action', p_action_ctl_rec.action);
    PO_LOG.proc_begin(d_module, 'p_action_ctl_rec.employee_id', p_action_ctl_rec.employee_id);
  END IF;

  BEGIN

    d_progress := 10;

    authority_checks_setup(
       p_action_to_verify  => l_action_to_verify
    ,  p_document_id       => p_action_ctl_rec.document_id
    ,  p_document_type     => p_action_ctl_rec.document_type
    ,  p_document_subtype  => p_action_ctl_rec.document_subtype
    ,  p_employee_id       => p_action_ctl_rec.employee_id
    ,  x_auth_checks_to_do => l_auth_checks_to_do
    ,  x_auth_check_ids    => l_auth_check_ids
    ,  x_using_positions   => l_using_positions
    ,  x_return_status     => l_ret_sts
    ,  x_functional_error  => p_action_ctl_rec.functional_error
    );

    IF (l_ret_sts = 'U')
    THEN
      d_progress := 20;
      d_msg := 'unexpected error in authority_checks_setup';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;

    IF (l_ret_sts = 'E')
    THEN
      d_progress := 30;
      d_msg := 'functional error in authority_checks_setup';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;

    /* Ne pas inserer dans une table car cette procedure est utilisee dans un select*/
    /*  
    d_progress := 40;

    populate_session_gt(
       p_document_id       => p_action_ctl_rec.document_id
    ,  p_document_type     => p_action_ctl_rec.document_type
    ,  p_document_subtype  => p_action_ctl_rec.document_subtype
    ,  x_session_gt_key    => l_session_gt_key
    ,  x_return_status     => l_ret_sts
    );

    IF (l_ret_sts <> 'S')
    THEN
      d_progress := 50;
      l_ret_sts := 'U';
      d_msg := 'populate_session_gt not successful';
      RAISE PO_CORE_S.g_early_return_exc;
    END IF;
    */


    d_progress := 60;

    IF (l_auth_checks_to_do.check_doc_totals) THEN

      d_progress := 70;

      check_doc_total_limit(
         p_document_id        => p_action_ctl_rec.document_id
      ,  p_document_type      => p_action_ctl_rec.document_type
      ,  p_document_subtype   => p_action_ctl_rec.document_subtype
      ,  p_session_gt_key     => l_session_gt_key
      ,  p_auth_check_ids     => l_auth_check_ids
      ,  x_return_status      => l_ret_sts
      ,  x_authorized_yn      => l_authorized_yn
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 80;
        d_msg := 'check_doc_total_limit not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (l_authorized_yn <> 'Y')
      THEN
        d_progress := 90;
        d_msg := 'functional error in check_doc_total_limit';
        p_action_ctl_rec.functional_error := fnd_message.get_string('PO', 'PO_AUT_DOC_TOT_FAIL');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;
      
      d_progress := 100;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Passed document total check.');
      END IF;

     END IF;  -- IF check_doc_totals

     IF (l_auth_checks_to_do.check_accounts) THEN

      d_progress := 110;

      check_account_exists(
         p_document_id        => p_action_ctl_rec.document_id
      ,  p_document_type      => p_action_ctl_rec.document_type
      ,  p_document_subtype   => p_action_ctl_rec.document_subtype
      ,  p_session_gt_key     => l_session_gt_key
      ,  p_auth_check_ids     => l_auth_check_ids
      ,  x_return_status      => l_ret_sts
      ,  x_authorized_yn      => l_authorized_yn
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 120;
        d_msg := 'check_account_exists not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (l_authorized_yn <> 'Y')
      THEN
        d_progress := 130;
        d_msg := 'functional error in check_account_exists';
        p_action_ctl_rec.functional_error := fnd_message.get_string('PO', 'PO_AUT_ACCOUNT_NOT_EXISTS');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      d_progress := 140;
      IF (PO_LOG.d_stmt) THEN
         PO_LOG.stmt(d_module, d_progress, 'Passed account exists check.');
      END IF;

      check_account_limit(
         p_document_id        => p_action_ctl_rec.document_id
      ,  p_document_type      => p_action_ctl_rec.document_type
      ,  p_document_subtype   => p_action_ctl_rec.document_subtype
      ,  p_session_gt_key     => l_session_gt_key
      ,  p_auth_check_ids     => l_auth_check_ids
      ,  x_return_status      => l_ret_sts
      ,  x_authorized_yn      => l_authorized_yn
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 150;
        d_msg := 'check_account_limit not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (l_authorized_yn <> 'Y')
      THEN
        d_progress := 160;
        d_msg := 'functional error in check_account_limit';
        p_action_ctl_rec.functional_error := fnd_message.get_string('PO', 'PO_AUT_ACCOUNT_LIMIT_FAIL');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      d_progress := 170;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Passed account limit check.');
      END IF;

     END IF;  -- IF check_accounts

     IF (l_auth_checks_to_do.check_locations) THEN

      d_progress := 180;

      check_location_limit(
         p_document_id        => p_action_ctl_rec.document_id
      ,  p_document_type      => p_action_ctl_rec.document_type
      ,  p_document_subtype   => p_action_ctl_rec.document_subtype
      ,  p_session_gt_key     => l_session_gt_key
      ,  p_auth_check_ids     => l_auth_check_ids
      ,  x_return_status      => l_ret_sts
      ,  x_authorized_yn      => l_authorized_yn
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 190;
        d_msg := 'check_location_limit not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (l_authorized_yn <> 'Y')
      THEN
        d_progress := 200;
        d_msg := 'functional error in check_location_limit';
        p_action_ctl_rec.functional_error := fnd_message.get_string('PO', 'PO_AUT_LOC_LIMIT_FAIL');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      d_progress := 210;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Passed location limit check.');
      END IF;

    END IF;  -- IF check_locations

    IF (l_auth_checks_to_do.check_items) THEN

       d_progress := 220;

       check_item_limit(
         p_document_id        => p_action_ctl_rec.document_id
      ,  p_document_type      => p_action_ctl_rec.document_type
      ,  p_document_subtype   => p_action_ctl_rec.document_subtype
      ,  p_session_gt_key     => l_session_gt_key
      ,  p_auth_check_ids     => l_auth_check_ids
      ,  x_return_status      => l_ret_sts
      ,  x_authorized_yn      => l_authorized_yn
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 230;
        d_msg := 'check_item_limit not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (l_authorized_yn <> 'Y')
      THEN
        d_progress := 240;
        d_msg := 'functional error in check_item_limit';
        p_action_ctl_rec.functional_error := fnd_message.get_string('PO', 'PO_AUT_ITEM_LIMIT_FAIL');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      d_progress := 250;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Passed item limit check.');
      END IF;

    END IF;  -- IF check_items

    IF (l_auth_checks_to_do.check_item_categories) THEN

      d_progress := 260;

      check_category_limit(
         p_document_id        => p_action_ctl_rec.document_id
      ,  p_document_type      => p_action_ctl_rec.document_type
      ,  p_document_subtype   => p_action_ctl_rec.document_subtype
      ,  p_session_gt_key     => l_session_gt_key
      ,  p_auth_check_ids     => l_auth_check_ids
      ,  x_return_status      => l_ret_sts
      ,  x_authorized_yn      => l_authorized_yn
      );

      IF (l_ret_sts <> 'S')
      THEN
        d_progress := 270;
        d_msg := 'check_category_limit not successful';
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      IF (l_authorized_yn <> 'Y')
      THEN
        d_progress := 280;
        d_msg := 'functional error in check_category_limit';
        p_action_ctl_rec.functional_error := fnd_message.get_string('PO', 'PO_AUT_CATEGORY_LIMIT_FAIL');
        RAISE PO_CORE_S.g_early_return_exc;
      END IF;

      d_progress := 290;
      IF (PO_LOG.d_stmt) THEN
        PO_LOG.stmt(d_module, d_progress, 'Passed category limit check.');
      END IF;

    END IF;  -- IF check_locations

    d_progress := 300;
    l_authority_verified := 'Y';

  EXCEPTION
    WHEN PO_CORE_S.g_early_return_exc THEN
      PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, d_msg);
      IF ((l_ret_sts = 'U') and (PO_LOG.d_exc)) THEN
        PO_LOG.exc(d_module, d_progress, d_msg);
      END IF;

      IF (l_ret_sts = 'E' OR (NVL(l_authorized_yn, 'N') <> 'Y')) THEN
        PO_LOG.stmt(d_module, d_progress, 'Error: ' || d_msg);
        l_authority_verified := 'N';
      END IF;
  END;

  IF (NVL(l_authority_verified,'X') = 'N')
  THEN
    p_action_ctl_rec.return_code := 'AUTHORIZATION_FAILED';
  ELSE
    p_action_ctl_rec.return_code := NULL;
  END IF;

  p_action_ctl_rec.return_status := l_ret_sts;
  IF (p_action_ctl_rec.return_status = 'E') THEN
    p_action_ctl_rec.return_status := 'S';
  END IF;

  IF (PO_LOG.d_proc) THEN
    PO_LOG.proc_end(d_module, 'p_action_ctl_rec.return_status', p_action_ctl_rec.return_status);
    PO_LOG.proc_end(d_module, 'p_action_ctl_rec.return_code', p_action_ctl_rec.return_code);
    PO_LOG.proc_end(d_module, 'p_action_ctl_rec.functional_error', p_action_ctl_rec.functional_error);
    PO_LOG.proc_end(d_module);
  END IF;

  RETURN;

EXCEPTION
  WHEN OTHERS THEN
    p_action_ctl_rec.return_status := 'U';

    PO_DOCUMENT_ACTION_PVT.error_msg_append(d_module, d_progress, SQLCODE, SQLERRM);
    IF (PO_LOG.d_exc) THEN
      PO_LOG.exc(d_module, d_progress, SQLCODE || SQLERRM);
      PO_LOG.proc_end(d_module, 'p_action_ctl_rec.return_status', p_action_ctl_rec.return_status);
      PO_LOG.proc_end(d_module);
    END IF;

    RETURN;

END authority_check;

--------------------------------------------------------------------------------------
 --  Nom           : init_env
 --  Description   : Procedure pour initialiser l'envir avec unite operationnelle de la DA.
 --
 --  PARAMETRES :
 --    PN_TRANSACTION_ID   : Id de la DA
 --
 ----------------------------------------------------------------------------------------
PROCEDURE init_env (PN_TRANSACTION_ID  IN  NUMBER)
is
--PRAGMA AUTONOMOUS_TRANSACTION;
v_org_id NUMBER;
BEGIN

    SELECT org_id
    INTO v_org_id
    FROM po_requisition_headers_all
    WHERE requisition_header_id = PN_TRANSACTION_ID;
    
    MO_GLOBAL.SET_POLICY_CONTEXT('S',v_org_id);

END init_env;
--------------------------------------------------------------------------------------
 --  Nom           : GET_NB_APPROVER
 --  Description   : Fonction qui retourne le nombre des approbateurs d'une DA
 --
 --  PARAMETRES :
 --    PN_TRANSACTION_ID   : Id de la DA
 --
 --  VALEUR RETOURNEE :
 --     Nombre des approbateurs DA
 --
 ----------------------------------------------------------------------------------------
    FUNCTION GET_NB_APPROVER (
                                PN_TRANSACTION_ID  IN  NUMBER
                              ) RETURN NUMBER
    IS 
    v_approbateur_id    NUMBER;
    v_montant_DA        NUMBER;
    v_continue          BOOLEAN:= TRUE;
    v_dir_general       NUMBER;
    nb_approver         NUMBER:=0;
    
    V_REC_TYPE PO_DOCUMENT_ACTION_PVT.doc_action_call_rec_type;
    
    d_progress          NUMBER;
    d_module            VARCHAR2(70) := 'DKA_SPO_REQAPPRV_PKG.get_nb_approver';
    
    BEGIN
        
        d_progress := 0;
        -- Init envir avec org_id de la DA
        init_env(PN_TRANSACTION_ID);

        IF (PO_LOG.d_stmt) THEN
            PO_LOG.stmt(d_module, d_progress, 'Passed init envir.');
        END IF;
            
        d_progress := 10;
        -- infos DA
        BEGIN
            SELECT prha.preparer_id , sum(prla.unit_price * prla.quantity)
            INTO v_approbateur_id,v_montant_DA
            FROM PO_REQUISITION_HEADERS_ALL prha,
                 po_requisition_lines_all   prla
            WHERE prha.requisition_header_id = pn_transaction_id
            AND  prha.requisition_header_id  = prla.requisition_header_id
            AND  NVL(PRLA.CANCEL_FLAG, 'N') = 'N' 
            AND  NVL(PRLA.MODIFIED_BY_AGENT_FLAG, 'N') = 'N' 
            GROUP BY prha.preparer_id
            ;
        EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        END;
        
        d_progress := 20;
        -- Directeur General
        BEGIN
            SELECT PERSON_ID
            INTO v_dir_general
            from per_jobs pj, per_assignments_f paf
            where pj.job_id = paf.job_id 
            and TRUNC(sysdate) between TRUNC(paf.effective_start_date) and TRUNC(NVL(paf.effective_end_date,sysdate)) --RBE artf2965197
            AND substr(pj.name, instr(pj.NAME, '.')+1) = 'DIR_GENERAL'
            ;

        EXCEPTION
        WHEN OTHERS THEN
            RETURN NULL;
        END;
        
        d_progress := 30;
        -- Verification des droits d'approbation
        WHILE v_continue LOOP

            V_REC_TYPE.ACTION                         := 'APPROVE';
            V_REC_TYPE.LOCK_DOCUMENT                  := FALSE;        
            V_REC_TYPE.DOCUMENT_TYPE                  := 'REQUISITION';
            V_REC_TYPE.DOCUMENT_SUBTYPE               := 'PURCHASE';
            V_REC_TYPE.DOCUMENT_ID                    := pn_transaction_id;
            V_REC_TYPE.EMPLOYEE_ID                    := v_approbateur_id;

            d_progress := 40;
            -- Appel fonction de la fonction inspiré de PO_DOCUMENT_ACTION_CHECK
            AUTHORITY_CHECK(V_REC_TYPE);
            
            IF (PO_LOG.d_stmt) THEN
                PO_LOG.stmt(d_module, d_progress, 'Passed authority check.');
                PO_LOG.stmt(d_module, d_progress, 'Transaction id : ' || pn_transaction_id);
                PO_LOG.stmt(d_module, d_progress, 'Approver id    : ' || v_approbateur_id);
                PO_LOG.stmt(d_module, d_progress, 'Return status  : ' || V_REC_TYPE.return_status);
                PO_LOG.stmt(d_module, d_progress, 'Return code    : ' || V_REC_TYPE.return_code);
                PO_LOG.stmt(d_module, d_progress, 'Error msg    : ' || V_REC_TYPE.error_msg);
            END IF;

            IF V_REC_TYPE.return_status = 'S' AND V_REC_TYPE.return_code IS NULL THEN
                v_continue := FALSE;
            ELSE
                
                BEGIN
                    SELECT SUPERVISOR_ID
                    INTO  v_approbateur_id
                    FROM  PER_JOBS PJ, PER_ASSIGNMENTS_F PAF
                    WHERE PJ.JOB_ID     = PAF.JOB_ID
                    AND   paf.PERSON_ID = v_approbateur_id
                    AND   TRUNC(SYSDATE) BETWEEN TRUNC(paf.effective_start_date) AND TRUNC(NVL(paf.effective_end_date,SYSDATE)) --RBE  artf2965197
                    AND   ROWNUM = 1
                    ;
                    
                    IF v_approbateur_id IS NULL THEN
                        v_continue := FALSE;
                    END IF;
                    
                    IF NOT (v_approbateur_id = v_dir_general AND v_montant_DA > 3000000)  THEN -- RBE artf2522185
                        nb_approver := nb_approver + 1;
                    END IF;
                    
                EXCEPTION
                WHEN OTHERS THEN
                    RETURN NULL;
                END;
                
            END IF;
            
        END LOOP;
        
        RETURN nb_approver;
    EXCEPTION
    WHEN OTHERS THEN
        IF (PO_LOG.d_stmt) THEN
            PO_LOG.stmt(d_module, d_progress, sqlerrm);
        END IF;
        
    END GET_NB_APPROVER;

/*********************************************************************************/

END DKA_SPO_REQAPPRV_PKG;
/
SHOW ERRORS
EXIT
