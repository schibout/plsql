----------------------------------------------------------------------------------------------      
-- $Id$                                                                                               
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_IPOREC_REJECT.tab                                                            
-- DESCRIPTION      : Création de la table DKA_IPOREC_REJECT
-- AUTEUR           : BNZ                                                              
-- DATE DE CREATION : 12/01/2024                                                                      
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
PROMPT DROP DE LA TABLE DKA_IPOREC_REJECT                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
DROP TABLE DKA_IPOREC_REJECT ;
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DE LA TABLE DKA_IPOREC_REJECT                                                                  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
create table DKA_IPOREC_REJECT
        (
          ID_CMD		Number,
          STATUT_CMD	varchar2(20),
          NUM_CMD    	varchar2(20),
          BLOCAGE    	varchar2(20),
          ID_LIGNE   	varchar2(20),
          NEW_STATUT_CMD  varchar2(20),
          RECEIPT_NUM  varchar2(20),
          REQUEST_ID      Number
        );
--TABLESPACE &5;                                                   
                                                               
                                                                                                    
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES GRANTS                                                                          
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
GRANT ALL ON DKA_IPOREC_REJECT TO &&1;   

                                                                     

                                                                                            
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DU SYNONYME                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++    
  
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
PROMPT CREATION DES INDEXS                                                                         
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++   
--CREATE INDEX DKA.DKA_RCV_HEADERS_NU1 IN DKA.DKA_IPOREC_REJECT(RECEIPT_NUM);
  
CONNECT &&1/&&2                                                                              
 

DROP SYNONYM DKA_IPOREC_REJECT;                                                                                 
                                                                                                    
CREATE SYNONYM DKA_IPOREC_REJECT FOR DKA.DKA_IPOREC_REJECT;                                                                 
                                                                                                    
EXIT;
