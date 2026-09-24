-- FACTURES AR - Rejetees par AutoInvoice
-- Extrait de ControleMatinGenerique/Controle_Quotidien_Complet.sql.
-- Variables fournies par _export.sql : &nb_jours_histo, &heure_fermeture, &heure_ouverture.

SELECT ril.trx_number AS FACTURE, ril.batch_source_name AS SOURCE, ril.interface_line_context AS CONTEXTE,
       TO_CHAR(MIN(ril.creation_date), 'DD/MM HH24:MI') AS EN_INTERFACE_DEPUIS,
       COUNT(*) AS NB_LIGNES, ROUND(SUM(ril.amount)) AS MONTANT,
       NVL((SELECT MAX(rie.message_text) FROM ra_interface_errors_all rie
            WHERE rie.interface_line_id IN (SELECT r2.interface_line_id FROM ra_interface_lines_all r2
                                            WHERE r2.trx_number = ril.trx_number)),
           'Aucun message : en attente du prochain AutoInvoice') AS ERREUR
FROM   ra_interface_lines_all ril
WHERE  ril.trx_number IN (SELECT dii.invoice_number FROM dka_iarpafac_interface dii
                          WHERE dii.creation_date >= SYSDATE - 1)
GROUP BY ril.trx_number, ril.batch_source_name, ril.interface_line_context
ORDER BY MIN(ril.creation_date);
