----------------------------------------------------------------------------------------------      
-- $Id$                                                                                              
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : DKA_PO_LINES_ALL_N1.sql                                          
-- DESCRIPTION      : Creation des index dans le cadre de l'optimisation du specifique                                                                                                           
-- AUTEUR           : Asma AMENKOUR                                                             
-- DATE DE CREATION : 28/07/2020                                                                    
-- DOC. ASSOCIEE    :                                                                               
                                                                                
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
--------------------------------------------------------------------------------------------        


 
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LINDEX DKA_PO_LINES_ALL_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP INDEX PO.DKA_PO_LINES_ALL_N1;

PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LINDEX DKA_PO_LINES_ALL_N1
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE INDEX PO.DKA_PO_LINES_ALL_N1 
ON PO.PO_LINES_ALL (ATTRIBUTE8
                           );

EXIT