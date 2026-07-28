SELECT
  r.vendor_name,
  r.vendor_number,
  r.invoice_num,
  prepay_remaining_amt,
  invoice_type_lookup_code,
  payment_status_flag,
  distribution_line_number,
  cancelled_date,
  CASE
    WHEN invoice_type_lookup_code = 'PREPAYMENT'
         AND invoice_approval_flag = 'APPROVED'
         AND payment_status_flag IN ( 'P', 'N' ) THEN
      'Unpaid'
    WHEN prepay_remaining_amt = 0                                                       THEN
      'Fully Applied'
    WHEN decode(earliest_settlement_date, NULL, 'PERMANENT', 'TEMPORARY') = 'PERMANENT' THEN
      'Permanent'
    WHEN invoice_approval_status = 'NEVER APPROVED'                                     THEN
      'Unapproved'
    WHEN cancelled_date IS NOT NULL THEN
      'Cancelled'
    WHEN payment_status_flag = 'N'
         AND cancelled_date IS NULL
         AND prepay_remaining_amt != 0 THEN
      'Unpaid'
    ELSE
      'Available'
  END invoice_status
FROM
  (
    SELECT
      q.*,
      CASE
        WHEN encumbrance_flag = 'N'
             AND nvl(invoice_approval_flag, 'X') IN ( 'A', 'T' )
             AND invoice_holds = 0 THEN
          'APPROVED'
        WHEN encumbrance_flag = 'N'
             AND nvl(invoice_approval_flag, 'X') IN ( 'A', 'T' )
             AND invoice_holds > 0
             OR nvl(invoice_approval_flag, 'X') = 'N' THEN
          'NEEDS REAPPROVAL'
        WHEN encumbrance_flag = 'N'
             AND dist_var_hold > 0 THEN
          'NEEDS REAPPROVAL'
        WHEN encumbrance_flag = 'N'
             AND nvl(invoice_approval_flag, 'X') = 'X' THEN
          'NEVER APPROVED'
        ELSE
          NULL
      END invoice_approval_status
    FROM
      (
        SELECT
          idstr.invoice_id,
          inv.invoice_num,
          vend.segment1                             vendor_number,
          vend.vendor_name,
          inv.creation_date,
          inv.invoice_type_lookup_code,
          inv.payment_status_flag,
          CASE
            WHEN match.match_flag_count > 0
                 AND idstr.match_status_flag IS NULL THEN
              NULL
            WHEN match.match_flag_count > 0
                 AND nvl(idstr.match_status_flag, 'N') = 'N' THEN
              'N'
            WHEN match.match_flag_count > 0
                 AND nvl(idstr.match_status_flag, 'N') = 'T' THEN
              'T'
            WHEN match.match_flag_count > 0
                 AND nvl(idstr.match_status_flag, 'N') = 'A' THEN
              'A'
            ELSE
              NULL
          END                                       invoice_approval_flag,
          nvl(holds.hold_count, 0)                  invoice_holds,
          nvl(dis_var_holds.dist_var_hold_count, 0) dist_var_hold,
          inv.cancelled_date,
          match.match_flag_count,
          idstr.line_type_lookup_code,
          idstr.distribution_line_number,
          idstr.match_status_flag,
          inv.earliest_settlement_date,
          round(SUM(nvl(idstr.prepay_amount_remaining, amount)),
                2)                                  prepay_remaining_amt,
          'N'                                       encumbrance_flag
        FROM
               ap_invoices_all inv
          JOIN ap_invoice_distributions_all idstr ON ( inv.invoice_id = idstr.invoice_id )
          JOIN po_vendors                   vend ON ( inv.vendor_id = vend.vendor_id )
          LEFT OUTER JOIN (
            SELECT
              hold.invoice_id,
              COUNT(hold.invoice_id) hold_count
            FROM
              ap_holds_all hold
            WHERE
              hold.release_lookup_code IS NULL
            GROUP BY
              invoice_id
          )                            holds ON ( inv.invoice_id = holds.invoice_id )
          LEFT OUTER JOIN (
            SELECT
              hold_dis.invoice_id,
              COUNT(hold_dis.invoice_id) dist_var_hold_count
            FROM
              ap_holds_all hold_dis
            WHERE
              hold_dis.release_lookup_code IS NULL
              AND hold_dis.hold_lookup_code = 'DIST VARIANCE'
            GROUP BY
              hold_dis.invoice_id
          )                            dis_var_holds ON ( inv.invoice_id = dis_var_holds.invoice_id )
          LEFT OUTER JOIN (
            SELECT
              idstr1.invoice_id,
              COUNT(idstr1.invoice_id) match_flag_count
            FROM
              ap_invoice_distributions_all idstr1
            WHERE
              idstr1.match_status_flag IS NOT NULL
            GROUP BY
              idstr1.invoice_id
          )                            match ON ( inv.invoice_id = match.invoice_id )
        WHERE
          inv.invoice_type_lookup_code = 'PREPAYMENT'
        GROUP BY
          idstr.invoice_id,
          inv.invoice_num,
          vend.segment1,
          inv.creation_date,
          inv.invoice_type_lookup_code,
          inv.approval_status,
          inv.payment_status_flag,
          idstr.line_type_lookup_code,
          idstr.distribution_line_number,
          idstr.match_status_flag,
          inv.earliest_settlement_date,
          nvl(holds.hold_count, 0),
          nvl(dis_var_holds.dist_var_hold_count, 0),
          inv.cancelled_date,
          match.match_flag_count,
          vend.vendor_name,
          'N',
          inv.earliest_settlement_date
        ORDER BY
          inv.creation_date DESC,
          inv.invoice_num,
          idstr.distribution_line_number
      ) q
  ) r;