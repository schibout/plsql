----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_IAPFAC_DEBLOC_INTERFACE.tab                                                            
-- DESCRIPTION      : Création de la table DKA_IAPFAC_DEBLOC_INTERFACE
-- AUTEUR           : SEL                                                              
-- DATE DE CREATION : 26/10/2020                                                                       
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                      
--                    en lui passant 3 paramètres :                                                 
--                           1) Password DKA                                                        
--                           2) Password APPS                                                       
--                           3) Tablespace des données pour schéma DKA                              
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
--
--------------------------------------------------------------------------------------------        
                                                                                                    
CONNECT &&3/&&4                                                                                   
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT DROP DE LA TABLE DKA_IAPFAC_DEBLOC_INTERFACE                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP TABLE DKA_IAPFAC_DEBLOC_INTERFACE ;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE LA TABLE DKA_IAPFAC_DEBLOC_INTERFACE                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE TABLE DKA_IAPFAC_DEBLOC_INTERFACE (
                                   INVOICE_ID	             NUMBER(15),
                                   IVALUA_PO_LINE_ID         VARCHAR(30),
                                   HOLD_ID	                 NUMBER(15),
                                   HOLD_CODE                 VARCHAR(25),
                                   RESPONSE_CODE             VARCHAR(25),
                                   RESPONSE_DATE             DATE,
                                   COMMENTAIRE               VARCHAR(2000),
                                   CREATION_DATE	         Date,
                                   CREATED_BY	             Number,
                                   LAST_UPDATE_DATE	         Date,
                                   LAST_UPDATED_BY	         Number,
                                   STATUT	                 Varchar2(25),
                                   FILE_NAME	             Varchar2(100),
                                   LINE_NUM	                 Number,
                                   RECORD_ID	             Number,
                                   REQUEST_ID	             Number,
                                   LOADER_REQUEST_ID	     Number							   
) ;      
--TABLESPACE &5;                                                   


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE LA SEQUENCE DKA_IAPFAC_DEBLOC_INTERFACE_S
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                                                                    
                                                                           
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES GRANTS                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
GRANT ALL ON DKA_IAPFAC_DEBLOC_INTERFACE TO &&1;   

                                                                     

                                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DU SYNONYME                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES INDEXS                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
--CREATE INDEX DKA.DKA_RCV_HEADERS_NU1 IN DKA.DKA_IAPFAC_DEBLOC_INTERFACE(RECEIPT_NUM);
  
CONNECT &&1/&&2                                                                              
 
CREATE SEQUENCE DKA_IAPFAC_DEBLOC_INTER_S INCREMENT BY 1
START WITH 1;       
 GRANT ALL ON DKA_IAPFAC_DEBLOC_INTER_S TO &&3; 
 
DROP SYNONYM DKA_IAPFAC_DEBLOC_INTERFACE;                                                                                 
                                                                                                    
CREATE SYNONYM DKA_IAPFAC_DEBLOC_INTERFACE FOR DKA.DKA_IAPFAC_DEBLOC_INTERFACE;                                                                 
                                                                                                    
EXIT;
