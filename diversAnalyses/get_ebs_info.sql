SELECT release_name FROM fnd_product_groups;
SELECT * FROM v$version;
SELECT owner, count(*) FROM all_tables WHERE owner IN ('GL', 'AP', 'AR', 'PO', 'FA', 'FND', 'XLA') OR owner LIKE 'DKA%' GROUP BY owner;
