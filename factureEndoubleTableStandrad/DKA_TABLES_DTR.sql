LOAD DATA
Append
INTO TABLE DKA_PO_CONTRAT_DEPSSTR_TMP
FIELDS TERMINATED BY ';'
TRAILING NULLCOLS
(  REF_CONTRAT_DEPSTTR    "rtrim(:REF_CONTRAT_DEPSTTR                  )"  
 , DESCRIPTION            "rtrim(:DESCRIPTION                          )"
 , REF_CONTRAT_CADRE      "rtrim(:REF_CONTRAT_CADRE                    )"
 , REF_CONTRAT_CADRE_DESC "rtrim(:REF_CONTRAT_CADRE_DESC               )"
 , NUM_FOURNISSEUR        "rtrim(:NUM_FOURNISSEUR                      )" 
 , SITE_CODE              "rtrim(:SITE_CODE                            )"  
 , SHIP_TO				        "rtrim(:SHIP_TO     			                   )"  
 , BILL_TO                "rtrim(:BILL_TO                              )"  
 , NATURE_PRESTATION      "rtrim(:NATURE_PRESTATION                    )"
 , ACHETEUR               "rtrim(:ACHETEUR                             )"
 , MATRICULE              "rtrim(:MATRICULE                            )"
 , DEBUT_CONTRAT          "to_date(rtrim(:DEBUT_CONTRAT),'DD/MM/RRRR'  )"
 , FIN_CONTRAT				    "to_date(rtrim(:FIN_CONTRAT),'DD/MM/RRRR'    )"
 , MONTANT_CONTRAT        "to_number(REPLACE(REPLACE(rtrim(:MONTANT_CONTRAT),',','.'),' ',''))"
 , RECONDUCTION_FLAG      "rtrim(:RECONDUCTION_FLAG                    )"
 , NBR_RECONDUCTION       "to_number(rtrim(:NBR_RECONDUCTION)          )"
 , PREAVIS_RESILIATION    "to_number(rtrim(:PREAVIS_RESILIATION)       )"
 , REVISION_FLAG          "rtrim(:REVISION_FLAG                        )"
 , REVISION_DATE          "to_date(rtrim(:REVISION_DATE),'DD/MM/RRRR'  )"
 , NBR_INTERVENTION       "to_number(rtrim(:NBR_INTERVENTION)          )"
 , PERIODICITE_INT        "rtrim(:PERIODICITE_INT                      )"
 , INTERVENTION_REALISE   "to_number(rtrim(:INTERVENTION_REALISE)      )"
 , TYPE_DEPENSE           "rtrim(:TYPE_DEPENSE                         )"
 , VARIABLE_FLAG          "rtrim(:VARIABLE_FLAG                        )"
 , COMMENTS               "rtrim(:COMMENTS                             )"
 , PERIODICITE_FAC        "to_number(rtrim(:PERIODICITE_FAC)           )"
 , PROJET                 "rtrim(:PROJET                               )"
 , UNITE                  "to_number(rtrim(:UNITE)                     )"
 , TACHE                  "rtrim(:TACHE                                )"
 , ROW_STATUS             CONSTANT 'N'
 , PO_HEADER_ID           CONSTANT ''
)                               
 
