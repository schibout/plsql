Comparaison des données d’Oracle R12 et BO – Finance Achats concernant : 
les factures impayées

1 - Extractions des factures payées dans Oracle R12 :
Requête :
SELECT    
aia.invoice_id as ID_FACTURE,
aia.invoice_num,
aia.payment_status_flag,
aia.last_update_date
FROM ap_invoices_all aia        
WHERE 1=1      
AND aia.PAYMENT_STATUS_FLAG = 'Y'
AND nvl(AMOUNT_PAID,0) != 0
AND invoice_amount != 0
AND trunc(aia.last_update_date) = trunc(sysdate-1)
AND exists (
select 1
            from AP_INVOICE_PAYMENTS_all AIP,  AP_CHECKS_ALL AC
            where aia.INVOICE_ID = AIP.INVOICE_ID
            and AIP.CHECK_ID = AC.CHECK_ID
            and ac.status_lookup_code!='VOIDED'
            and trunc(aip.last_update_date) = trunc(sysdate-1)
         )
ORDER BY aia.last_update_date desc;

Remarque : Hind de l’équipe Oracle R12 nous envoi chaque jour par mail le résultat de son extraction

 
 








2 - Extraction depuis la base BO des factures en écart entre Oracle R12 et BO :
Requête :
SELECT ID_FACTURE, num_facture, statut_paiement, statut_facture
FROM DWH_ECHEANCIER_AP 
WHERE statut_paiement <> 'PAYEE'
AND DWH_ECHEANCIER_AP.ID_FACTURE IN (
<<<liste des  ID_FACTURE résultants de la requête Oracle R12, colonne invoice_id >>>);

Exécuter la requête dans BO puis faire un retour au mail de Hind si l’on a ou pas un écart
Si on a un écart, il faudra envoyer le delta à Hind de l’équipe Oracle R12 pour qu’elle renvoie une màj des factures dans le dump et qu’elle mette à jour de son côté la date update.
Il faudra demander à notre TMA d’analyser les écart le jour même.

 
 

Remarque : On peut intégrer les données d’oracle R12 dans une table temporaire en base BO puis l’utiliser dans la requête BO.

Requêtes :
--Création d’une table temporaire
CREATE TABLE "FINANCE"."TRAVAIL_FACTURE_ORACLER12_PAYEES" (	
	"ID_FACTURE" NUMBER(*,0), 
	"NUM_FACTURE" VARCHAR2(500 BYTE)
) ;
--Insertion des données de l’extract Oracle R12 dans la table temporaire
INSERT INTO FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES (ID_FACTURE, NUM_FACTURE) values (8207135,'4104099064');--valeur de l’extract Oracle R12

Remarque : vous pouvez intégrer les données du fichier en utilisant dans SQL Developer l’Import Data
https://www.youtube.com/watch?v=TbDSfF5qz3E

-- Extraction des factures en écart entre Oracle R12 et BO  utiliser plutôt la seconde requête
SELECT ID_FACTURE, num_facture, statut_paiement, statut_facture
FROM DWH_ECHEANCIER_AP 
WHERE statut_paiement <> 'PAYEE'
AND DWH_ECHEANCIER_AP.ID_FACTURE IN (
SELECT ID_FACTURE  FROM FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES
);
--Autre requête d’extraction des factures en écart entre Oracle R12 et BO  
SELECT 
TRAVAIL_FACTURE_ORACLER12_PAYEES.ID_FACTURE, TRAVAIL_FACTURE_ORACLER12_PAYEES.num_facture, DWH_ECHEANCIER_AP.statut_paiement, 
DWH_ECHEANCIER_AP.statut_facture 
FROM
FINANCE.TRAVAIL_FACTURE_ORACLER12_PAYEES
LEFT OUTER JOIN FINANCE.DWH_ECHEANCIER_AP 
ON   TRAVAIL_FACTURE_ORACLER12_PAYEES.ID_FACTURE = DWH_ECHEANCIER_AP.ID_FACTURE
AND TRAVAIL_FACTURE_ORACLER12_PAYEES.NUM_FACTURE = DWH_ECHEANCIER_AP.NUM_FACTURE
WHERE 
DWH_ECHEANCIER_AP.statut_paiement <> 'PAYEE'
OR 
DWH_ECHEANCIER_AP.ID_FACTURE IS NULL;



SQL pour ressortir toutes les factures impayées dans BO avec filtre sur type_facture = 'STANDARD' 
	A utiliser pour les extract des factures impayées par années et a envoyer a Hind pour un update

SELECT ID_FACTURE, num_facture, statut_paiement, statut_facture, type_facture, DATE_FACTURE, DATE_CREATION_FACTURE
FROM DWH_ECHEANCIER_AP
WHERE statut_paiement <> 'PAYEE'
AND type_facture = 'STANDARD'
AND EXTRACT(YEAR FROM DATE_FACTURE) = '2024'
AND statut_facture not in ( 'Annulé')
--AND ID_FACTURE IN ('7851346')
order by DATE_FACTURE  asc --order by  date_creation_facture  asc


Autre :
select distinct type_de_facture from FINANCE.DWH_FACTURE_FOURNISSEUR
select * from FINANCE.DWH_FACTURE_FOURNISSEUR where type_de_facture = 'STANDARD'
