-- Script de création d'indexes
-- Auteur: Julien Pelat
-- Date: 17/10/2016
----------------------------------------------------------------------------------------------------

--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++       
--PROMPT CREATION DES INDEX                                                                          
--PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++     
DROP INDEX GL.DKA_GL_CODE_COMBINATIONS_N1;
  
--CREATE INDEX GL.DKA_GL_CODE_COMBINATIONS_N1 ON GL.GL_CODE_COMBINATIONS (CHART_OF_ACCOUNTS_ID, SEGMENT1, SEGMENT2, 
--SEGMENT3, SEGMENT4, SEGMENT5, SEGMENT6, SEGMENT7, SEGMENT8, SEGMENT9, SEGMENT10, SEGMENT11, SEGMENT12)
--TABLESPACE APPS_TS_TX_IDX;
create index GL.DKA_GL_CODE_COMBINATIONS_N1 on GL.GL_CODE_COMBINATIONS (segment8, segment7, SEGMENT3, SEGMENT4, SEGMENT6, SEGMENT5, SEGMENT1)
  tablespace APPS_TS_TX_IDX;

EXIT;
