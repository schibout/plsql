/* Lignes de commande rejetées CAP */
select DSE.SOC_CAP "Sté CAP"
      ,DSE.CDG_CAP "Région CAP"
      ,DSE.SOC_COMMANDE "Sté Cde"
      ,DSE.NUM_COMMANDE "Cde"
      ,DSE.NUM_LIGNE_COMMANDE "Ligne Cde"
      ,DSE.PROJECT_CODE "Projet"
      ,PT.TASK_NUMBER "Num tâche"
      ,case when PT.attribute2 is not null
           then TO_DATE(SUBSTR(PT.attribute2,1,10),'YYYY/MM/DD')
           else Null
       end "Date clôture tâche"
      ,PT.COMPLETION_DATE "Date fermeture tâche"     
      ,DSE.TYPE_DEPENSE "Type dépense"
      ,DSE.CONCATENATED_SEGMENTS "Compte imputation"
      ,ASU.VENDOR_NAME "Fournisseur"
      ,PDA.QUANTITY_ORDERED-PDA.QUANTITY_CANCELLED "Qté Cde." 
      ,PDA.QUANTITY_DELIVERED "Qté reçue"
      ,PDA.QUANTITY_BILLED "Qté Fact. Rapprochée" 
      ,pla.UNIT_PRICE "Prix U." 
      ,(PDA.QUANTITY_DELIVERED-PDA.QUANTITY_BILLED)*pla.UNIT_PRICE "Montant Prov."
      ,DSE.REJECTION_REASON "Motif rejet"
      ,PLA.ITEM_DESCRIPTION "Description article"
from DKA_SPOCHARGE_ERRORS DSE
    inner join PO_DISTRIBUTIONS_ALL PDA on PDA.PO_DISTRIBUTION_ID = DSE.PO_DISTRIBUTION_ID
    inner join PO_LINES_ALL PLA on PLA.PO_LINE_ID = PDA.PO_LINE_ID
    inner join PA.PA_TASKS PT on PT.TASK_ID = PDA.TASK_ID
    inner join PO.PO_HEADERS_ALL PHA on PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
    inner join AP.AP_SUPPLIERS ASU on ASU.VENDOR_ID = PHA.VENDOR_ID
;