----------------------------------------------------------------------------------------------      
-- $Id$                                                                                              
-- Capgemini                                                                     
-- PROJET           : DALKIA Oracle Applications                                                    
-- NOM              : RECREATION_INDEXES.sql                                          
-- DESCRIPTION      : Creation des index dans le cadre de l'optimisation du specifique                                                                                                           
-- AUTEUR           : Nicolas BOUSSEKEYT                                                             
-- DATE DE CREATION : 17/04/2019                                                                     
-- DOC. ASSOCIEE    :                                                                               
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user DKA                                      
--                    en lui passant 3 paramètres :                                                                                                     
--                           1) Password APPS                                                                                  
--                                                       
--------------------------------------------------------------------------------------------        
-- HISTORIQUE DES MODIFICATIONS                                                                     
-- Date       Qui Description                                                                       
-- ---------- --- -------------------------------------------------------------------------         
--------------------------------------------------------------------------------------------        
                                                                                                    
CONNECT APPS/&1;    

drop index AR.DKA_RA_CUSTOMER_TRX_ALL_N1;

create unique index AR.DKA_RA_CUSTOMER_TRX_ALL_U1
 on AR.RA_CUSTOMER_TRX_ALL (INTERFACE_HEADER_CONTEXT, INTERFACE_HEADER_ATTRIBUTE1, INTERFACE_HEADER_ATTRIBUTE2, INTERFACE_HEADER_ATTRIBUTE3, INTERFACE_HEADER_ATTRIBUTE4, INTERFACE_HEADER_ATTRIBUTE5)
  tablespace APPS_TS_TX_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

drop index AR.DKA_RA_CUST_TRX_LINES_ALL_N1;

create unique index AR.DKA_RA_CUST_TRX_LINES_ALL_U1 on AR.RA_CUSTOMER_TRX_LINES_ALL (INTERFACE_LINE_CONTEXT, INTERFACE_LINE_ATTRIBUTE1, INTERFACE_LINE_ATTRIBUTE2, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4, INTERFACE_LINE_ATTRIBUTE5)
  tablespace APPS_TS_TX_DATA
  pctfree 10
  initrans 2
  maxtrans 255
  storage
  (
    initial 128K
    next 128K
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
  
drop index AR.DKA_RA_INTERFACE_LINES_N1;

create unique index AR.DKA_RA_INTERFACE_LINES_U1 on AR.RA_INTERFACE_LINES_ALL (INTERFACE_LINE_CONTEXT, INTERFACE_LINE_ATTRIBUTE1, INTERFACE_LINE_ATTRIBUTE2, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4, INTERFACE_LINE_ATTRIBUTE5, REQUEST_ID)
  tablespace APPS_TS_TX_DATA
  pctfree 10
  initrans 11
  maxtrans 255
  storage
  (
    initial 8M
    next 8M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );
  
drop index AR.DKA_RA_INTERFACE_DIST_ALL_N1;

create unique index AR.DKA_RA_INTERFACE_DIST_ALL_U1 on AR.RA_INTERFACE_DISTRIBUTIONS_ALL (INTERFACE_LINE_CONTEXT, INTERFACE_LINE_ATTRIBUTE1, INTERFACE_LINE_ATTRIBUTE2, INTERFACE_LINE_ATTRIBUTE3, INTERFACE_LINE_ATTRIBUTE4, INTERFACE_LINE_ATTRIBUTE5)
  tablespace APPS_TS_TX_DATA
  pctfree 10
  initrans 11
  maxtrans 255
  storage
  (
    initial 8M
    next 8M
    minextents 1
    maxextents unlimited
    pctincrease 0
  );

EXIT;