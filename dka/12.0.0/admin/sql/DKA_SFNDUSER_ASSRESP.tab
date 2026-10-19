----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_SFNDUSER_ASSRESP.tab                                                            
-- DESCRIPTION      : Création de la table DKA_SFNDUSER_ASSRESP
-- AUTEUR           : SEL                                                              
-- DATE DE CREATION : 16/09/2020                                                                       
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
PROMPT DROP DE LA TABLE DKA_SFNDUSER_ASSRESP                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP TABLE DKA_SFNDUSER_ASSRESP ;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE LA TABLE DKA_SFNDUSER_ASSRESP                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
CREATE TABLE DKA_SFNDUSER_ASSRESP (
                                   USER_NAME	          VARCHAR(100),
                                   RESPONSIBILITY         VARCHAR(100),
                                   INACTIVE_DATE	      date,
                                   CREATION_DATE 	      date,
                                   CREATED_BY	          Number,
                                   LAST_UPDATE_DATE	      Date,
                                   LAST_UPDATED_BY	      Number,
                                   STATUT	              Varchar2(25),
                                   RECORD_ID	          Number,
                                   V_USER_ID              Number								   
) ;      
--TABLESPACE &5;                                                   


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE LA SEQUENCE DKA_SFNDUSER_ASSRESP_S
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++                                                                                    
                                                                           
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES GRANTS                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
GRANT ALL ON DKA_SFNDUSER_ASSRESP TO &&1;   

                                                                     

                                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DU SYNONYME                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES INDEXS                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
--CREATE INDEX DKA.DKA_RCV_HEADERS_NU1 IN DKA.DKA_SFNDUSER_ASSRESP(RECEIPT_NUM);
  
CONNECT &&1/&&2                                                                              
 
CREATE SEQUENCE DKA_SFNDUSER_ASSRESP_S INCREMENT BY 1
START WITH 1;       
 GRANT ALL ON DKA_SFNDUSER_ASSRESP_S TO &&3; 
 
DROP SYNONYM DKA_SFNDUSER_ASSRESP;                                                                                 
                                                                                                    
CREATE SYNONYM DKA_SFNDUSER_ASSRESP FOR DKA.DKA_SFNDUSER_ASSRESP;                                                                 
                                                                                                    
EXIT;
