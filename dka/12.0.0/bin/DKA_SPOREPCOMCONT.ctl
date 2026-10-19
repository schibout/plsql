LOAD DATA
Append
INTO TABLE DKA_PO_COM_CONT_TMP
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(  REF_COMMANDE           "rtrim(:REF_COMMANDE                         )"  
 , DESCRIPTION            "rtrim(:DESCRIPTION                          )"
 , REF_CONTRAT_PARENT     "rtrim(:REF_CONTRAT_PARENT                   )"
 , DESCRIPTION_CONTRAT    "rtrim(:DESCRIPTION_CONTRAT                  )"
 , NUM_FOURNISSEUR        "rtrim(:NUM_FOURNISSEUR                      )" 
 , SITE_CODE              "rtrim(:SITE_CODE                            )"  
 , SHIP_TO				        "rtrim(:SHIP_TO     			                   )"  
 , BILL_TO                "rtrim(:BILL_TO                              )"  
 , NATURE_PRESTATION      "rtrim(:NATURE_PRESTATION                    )"
 , ACHETEUR               "rtrim(:ACHETEUR                             )"
 , MATRICULE              "rtrim(:MATRICULE                            )"
 , MONTANT_COMMANDE       "to_number(REPLACE(REPLACE(rtrim(:MONTANT_COMMANDE),',','.'),' ',''))"
 , TYPE_DEPENSE           "rtrim(:TYPE_DEPENSE                         )"
 , PROJET                 "rtrim(:PROJET                               )"
 , TACHE                  "rtrim(:TACHE                                )"
 , ROW_STATUS             CONSTANT 'N'
 , PO_HEADER_ID           CONSTANT ''
 , PO_LINE_ID             CONSTANT ''
 , PO_DISTRIBUTION_ID     CONSTANT ''
)                               
 
