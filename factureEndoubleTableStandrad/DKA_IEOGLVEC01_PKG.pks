CREATE OR REPLACE PACKAGE BODY DKA_REP_TRANSCO_PKG AS
----------------------------------------------------------------------------------------------
-- $Id$
--
-- NOM               : DKA_REP_TRANSCO_PKG.pkb
-- DESCRIPTION       : DKA_REP_TRANSCO_PKG package body : Transco pour la reprise
---
--- AUTEUR           : J.JARDEZ
--- DATE DE CREATION : 16/03/2016
--- DOC. ASSOCIEE    :
---
----------------------------------------------------------------------------------------------
--- NOM DU PROGRAMME :
--- PARAMETRES       :
---
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 22/03/2017 YWA artf2125207 : RUN4 ETI - Génération CCF lors de la reprise de données
--------------------------------------------------------------------------------------------
-----------------------------------------------------------------
--  Variables globales
-----------------------------------------------------------------
    gv_debug_mode        VARCHAR2 (1);

  
-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--     pv_out_07        SORTIE
--     pv_out_08        SORTIE
--     pv_out_09        SORTIE
--     pv_out_10        SORTIE
--     pv_out_11        SORTIE
--     pv_out_12        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2,
                            pv_out_07        OUT  VARCHAR2,
                            pv_out_08        OUT  VARCHAR2,
                            pv_out_09        OUT  VARCHAR2,
                            pv_out_10        OUT  VARCHAR2,
                            pv_out_11        OUT  VARCHAR2,
                            pv_out_12        OUT  VARCHAR2
                        ) IS
                        
    BEGIN
    
      SELECT
        OUT_01,
        OUT_02,
        OUT_03,
        OUT_04,
        OUT_05,
        OUT_06,
        OUT_07,
        OUT_08,
        OUT_09,
        OUT_10,
        OUT_11,
        OUT_12      
      INTO
        pv_out_01,
        pv_out_02,
        pv_out_03,
        pv_out_04,
        pv_out_05,
        pv_out_06,
        pv_out_07,
        pv_out_08,
        pv_out_09,
        pv_out_10,
        pv_out_11,
        pv_out_12
      FROM
       DKA_REP_TRANSCO_LINES  drtl
      WHERE
       drtl.TRANSCO_NAME           = pv_transco_name
       AND drtl.COLUMN_01          = nvl(pv_column_01,'#')
       AND nvl(drtl.COLUMN_02,'#') LIKE nvl(pv_column_02,'%')
       AND nvl(drtl.COLUMN_03,'#') LIKE nvl(pv_column_03,'%')
       AND nvl(drtl.COLUMN_04,'#') LIKE nvl(pv_column_04,'%')
       AND nvl(drtl.COLUMN_05,'#') LIKE nvl(pv_column_05,'%')
       AND nvl(drtl.COLUMN_06,'#') LIKE nvl(pv_column_06,'%')
       AND nvl(drtl.COLUMN_07,'#') LIKE nvl(pv_column_07,'%')
       AND nvl(drtl.COLUMN_08,'#') LIKE nvl(pv_column_08,'%')
       AND nvl(drtl.COLUMN_09,'#') LIKE nvl(pv_column_09,'%')
       AND nvl(drtl.COLUMN_10,'#') LIKE nvl(pv_column_10,'%')
       AND nvl(drtl.COLUMN_11,'#') LIKE nvl(pv_column_11,'%')
       AND nvl(drtl.COLUMN_12,'#') LIKE nvl(pv_column_12,'%')
       and drtl.ENABLED_FLAG       = 'Y'
       AND sysdate between nvl(drtl.start_date_active,sysdate) 
                       and nvl(drtl.end_date_active,sysdate);      
      
    EXCEPTION
     WHEN NO_DATA_FOUND THEN
      pv_out_01 := pv_column_01;
      pv_out_02 := pv_column_02;
      pv_out_03 := pv_column_03;
      pv_out_04 := pv_column_04;
      pv_out_05 := pv_column_05;
      pv_out_06 := pv_column_06;
      pv_out_07 := pv_column_07;
      pv_out_08 := pv_column_08;
      pv_out_09 := pv_column_09;
      pv_out_10 := pv_column_10;
      pv_out_11 := pv_column_11;
      pv_out_12 := pv_column_12;
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2                            
                        ) IS
      
      pv_out_02        VARCHAR2(500);
      pv_out_03        VARCHAR2(500);
      pv_out_04        VARCHAR2(500);
      pv_out_05        VARCHAR2(500);
      pv_out_06        VARCHAR2(500);
      pv_out_07        VARCHAR2(500);
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
     
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );     
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2
                        ) IS
    
      pv_out_03        VARCHAR2(500);
      pv_out_04        VARCHAR2(500);
      pv_out_05        VARCHAR2(500);
      pv_out_06        VARCHAR2(500);
      pv_out_07        VARCHAR2(500);
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );     
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2
                        ) IS
    
      pv_out_04        VARCHAR2(500);
      pv_out_05        VARCHAR2(500);
      pv_out_06        VARCHAR2(500);
      pv_out_07        VARCHAR2(500);
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );    
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2
                        ) IS
    
      pv_out_05        VARCHAR2(500);
      pv_out_06        VARCHAR2(500);
      pv_out_07        VARCHAR2(500);
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );     
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

    -----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2
                        ) IS
    
      pv_out_06        VARCHAR2(500);
      pv_out_07        VARCHAR2(500);
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );       
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2
                        ) IS
    
      pv_out_07        VARCHAR2(500);
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );    
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--     pv_out_07        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2,
                            pv_out_07        OUT  VARCHAR2
                        ) IS
    
      pv_out_08        VARCHAR2(500);
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );     
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--     pv_out_07        SORTIE
--     pv_out_08        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2,
                            pv_out_07        OUT  VARCHAR2,
                            pv_out_08        OUT  VARCHAR2
                        ) IS
    
      pv_out_09        VARCHAR2(500);
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );    
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--     pv_out_07        SORTIE
--     pv_out_08        SORTIE
--     pv_out_09        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2,
                            pv_out_07        OUT  VARCHAR2,
                            pv_out_08        OUT  VARCHAR2,
                            pv_out_09        OUT  VARCHAR2
                        ) IS
    
      pv_out_10        VARCHAR2(500);
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );       
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

    -----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--     pv_out_07        SORTIE
--     pv_out_08        SORTIE
--     pv_out_09        SORTIE
--     pv_out_10        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2,
                            pv_out_07        OUT  VARCHAR2,
                            pv_out_08        OUT  VARCHAR2,
                            pv_out_09        OUT  VARCHAR2,
                            pv_out_10        OUT  VARCHAR2
                        ) IS
    
      pv_out_11        VARCHAR2(500);
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );      
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;

-----------------------------------------------------------------
--  Nom           : get_transco
--  Description   : Procédure permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--
--  PARAMETRES :
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--     pv_out_01        SORTIE
--     pv_out_02        SORTIE
--     pv_out_03        SORTIE
--     pv_out_04        SORTIE
--     pv_out_05        SORTIE
--     pv_out_06        SORTIE
--     pv_out_07        SORTIE
--     pv_out_08        SORTIE
--     pv_out_09        SORTIE
--     pv_out_10        SORTIE
--     pv_out_11        SORTIE
--
-----------------------------------------------------------------
    PROCEDURE get_transco ( pv_transco_name  IN   VARCHAR2,
                            pv_column_01     IN   VARCHAR2,
                            pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                            pv_column_12     IN   VARCHAR2 DEFAULT NULL,
                            pv_out_01        OUT  VARCHAR2,
                            pv_out_02        OUT  VARCHAR2,
                            pv_out_03        OUT  VARCHAR2,
                            pv_out_04        OUT  VARCHAR2,
                            pv_out_05        OUT  VARCHAR2,
                            pv_out_06        OUT  VARCHAR2,
                            pv_out_07        OUT  VARCHAR2,
                            pv_out_08        OUT  VARCHAR2,
                            pv_out_09        OUT  VARCHAR2,
                            pv_out_10        OUT  VARCHAR2,
                            pv_out_11        OUT  VARCHAR2
                        ) IS
    
      pv_out_12        VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>pv_out_01      ,
                    pv_out_02        =>pv_out_02      ,
                    pv_out_03        =>pv_out_03      ,
                    pv_out_04        =>pv_out_04      ,
                    pv_out_05        =>pv_out_05      ,
                    pv_out_06        =>pv_out_06      ,
                    pv_out_07        =>pv_out_07      ,
                    pv_out_08        =>pv_out_08      ,
                    pv_out_09        =>pv_out_09      ,
                    pv_out_10        =>pv_out_10      ,
                    pv_out_11        =>pv_out_11      ,
                    pv_out_12        =>pv_out_12      
                        );    
      
    EXCEPTION
     WHEN OTHERS THEN
      RAISE;      
    END get_transco;
                                    
-----------------------------------------------------------------
--  Nom           : get_transco_f
--  Description   : Fonction permettant suivant un nom de jeu de transco et  
--                  les colonnes en entrée d'obtenir les valeurs transcodées
--                  avec un séparateur
--
--  PARAMETRES :
--     pv_transco_name  ENTREE
--     pv_separator     ENTREE
--     pv_column_01     ENTREE
--     pv_column_02     ENTREE
--     pv_column_03     ENTREE
--     pv_column_04     ENTREE
--     pv_column_05     ENTREE
--     pv_column_06     ENTREE
--     pv_column_07     ENTREE
--     pv_column_08     ENTREE
--     pv_column_09     ENTREE
--     pv_column_10     ENTREE
--     pv_column_11     ENTREE
--     pv_column_12     ENTREE
--
--  VALEUR RETOURNEE :
--     Description       :  Transcodification
--     Valeurs possibles :
-----------------------------------------------------------------
    
    FUNCTION get_transco_f (  pv_transco_name  IN   VARCHAR2,
                              pv_separator     IN   VARCHAR2 DEFAULT ';',
                              pv_column_01     IN   VARCHAR2,
                              pv_column_02     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_03     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_04     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_05     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_06     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_07     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_08     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_09     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_10     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_11     IN   VARCHAR2 DEFAULT NULL,
                              pv_column_12     IN   VARCHAR2 DEFAULT NULL                              
                        ) RETURN VARCHAR2 IS
     
     vv_out    VARCHAR2(6000);
     vv_out_01 VARCHAR2(500);
     vv_out_02 VARCHAR2(500);
     vv_out_03 VARCHAR2(500);
     vv_out_04 VARCHAR2(500);
     vv_out_05 VARCHAR2(500);
     vv_out_06 VARCHAR2(500);
     vv_out_07 VARCHAR2(500);
     vv_out_08 VARCHAR2(500);
     vv_out_09 VARCHAR2(500);
     vv_out_10 VARCHAR2(500);
     vv_out_11 VARCHAR2(500);
     vv_out_12 VARCHAR2(500);
                        
    BEGIN
    
      get_transco ( pv_transco_name  =>pv_transco_name,
                    pv_column_01     =>pv_column_01   ,
                    pv_column_02     =>pv_column_02   ,
                    pv_column_03     =>pv_column_03   ,
                    pv_column_04     =>pv_column_04   ,
                    pv_column_05     =>pv_column_05   ,
                    pv_column_06     =>pv_column_06   ,
                    pv_column_07     =>pv_column_07   ,
                    pv_column_08     =>pv_column_08   ,
                    pv_column_09     =>pv_column_09   ,
                    pv_column_10     =>pv_column_10   ,
                    pv_column_11     =>pv_column_11   ,
                    pv_column_12     =>pv_column_12   ,
                    pv_out_01        =>vv_out_01      ,
                    pv_out_02        =>vv_out_02      ,
                    pv_out_03        =>vv_out_03      ,
                    pv_out_04        =>vv_out_04      ,
                    pv_out_05        =>vv_out_05      ,
                    pv_out_06        =>vv_out_06      ,
                    pv_out_07        =>vv_out_07      ,
                    pv_out_08        =>vv_out_08      ,
                    pv_out_09        =>vv_out_09      ,
                    pv_out_10        =>vv_out_10      ,
                    pv_out_11        =>vv_out_11      ,
                    pv_out_12        =>vv_out_12      
                        );      
       
       vv_out := vv_out_01||pv_separator||
                 vv_out_02||pv_separator||
                 vv_out_03||pv_separator||
                 vv_out_04||pv_separator||
                 vv_out_05||pv_separator||
                 vv_out_06||pv_separator||
                 vv_out_07||pv_separator||
                 vv_out_08||pv_separator||
                 vv_out_09||pv_separator||
                 vv_out_10||pv_separator||
                 vv_out_11||pv_separator||
                 vv_out_12||pv_separator;
                 
        vv_out := rtrim(vv_out,pv_separator);
        
        return vv_out;         
       
    EXCEPTION
     WHEN OTHERS THEN
      return NULL;      
    END get_transco_f;

-----------------------------------------------------------------
--  Nom           : get_cle_transco_f
--  Description   : Fonction permettant suivant les segments de la clé d'obtenir
--                  une clé transcodée valide
--
--  PARAMETRES :
--     pv_segment_01     ENTREE
--     pv_segment_02     ENTREE
--     pv_segment_03     ENTREE
--     pv_segment_04     ENTREE
--     pv_segment_05     ENTREE
--     pv_code_projet    ENTREE
--     pv_segment_08     ENTREE
--     pv_segment_09     ENTREE
--     pv_segment_10     ENTREE
--
--  VALEUR RETOURNEE :
--     Description       :  Transcodification
--     Valeurs possibles :
-----------------------------------------------------------------
    
    FUNCTION get_cle_transco_f (  pv_segment_01     IN   VARCHAR2,
                                  pv_segment_02     IN   VARCHAR2,
                                  pv_segment_03     IN   VARCHAR2,
                                  pv_segment_04     IN   VARCHAR2,
                                  pv_segment_05     IN   VARCHAR2,
                                  pv_code_projet    IN   VARCHAR2,
                                  pv_segment_08     IN   VARCHAR2,
                                  pv_segment_09     IN   VARCHAR2,
                                  pv_segment_10     IN   VARCHAR2 ) RETURN VARCHAR2 IS
     
     vv_SEGMENT1   GL_CODE_COMBINATIONS.SEGMENT1%TYPE;
     vv_SEGMENT2   GL_CODE_COMBINATIONS.SEGMENT2%TYPE;
     vv_SEGMENT3   GL_CODE_COMBINATIONS.SEGMENT3%TYPE;
     vv_SEGMENT4   GL_CODE_COMBINATIONS.SEGMENT4%TYPE;
     vv_SEGMENT5   GL_CODE_COMBINATIONS.SEGMENT5%TYPE;
     vv_SEGMENT6   GL_CODE_COMBINATIONS.SEGMENT6%TYPE;
     vv_SEGMENT7   GL_CODE_COMBINATIONS.SEGMENT7%TYPE;
     vv_SEGMENT8   GL_CODE_COMBINATIONS.SEGMENT8%TYPE;
     vv_SEGMENT9   GL_CODE_COMBINATIONS.SEGMENT9%TYPE;
     vv_SEGMENT10  GL_CODE_COMBINATIONS.SEGMENT10%TYPE;
     vv_SEGMENT11  GL_CODE_COMBINATIONS.SEGMENT11%TYPE;
     vv_SEGMENT12  GL_CODE_COMBINATIONS.SEGMENT12%TYPE;
     
     vv_code_projet_12 VARCHAR2(500);
     vv_segment67      VARCHAR2(500);
     
     vv_errbuf              VARCHAR2(500);
     vn_retcode             NUMBER;
     vn_code_combination_id GL_CODE_COMBINATIONS.CODE_COMBINATION_ID%TYPE;
     
     vv_out                 VARCHAR2(500);
                                  
    BEGIN
    
       get_cle_transco( pv_segment_01,
                        pv_segment_02,
                        pv_segment_03,
                        pv_segment_04,
                        pv_segment_05,
                        pv_code_projet,
                        pv_segment_08,
                        pv_segment_09,
                        pv_segment_10,
                        vv_SEGMENT1, 
                        vv_SEGMENT2, 
                        vv_SEGMENT3, 
                        vv_SEGMENT4, 
                        vv_SEGMENT5, 
                        vv_SEGMENT6, 
                        vv_SEGMENT7, 
                        vv_SEGMENT8, 
                        vv_SEGMENT9, 
                        vv_SEGMENT10,
                        vv_SEGMENT11,
                        vv_SEGMENT12);    
      
       --Recherche de la clé
       Dka_Tools_Pkg.get_code_combination_id (
        pv_segment1              => vv_SEGMENT1,
        pv_segment2              => vv_SEGMENT2,
        pv_segment3              => vv_SEGMENT3,
        pv_segment4              => vv_SEGMENT4,
        pv_segment5              => vv_SEGMENT5,
        pv_segment6              => vv_SEGMENT6,
        pv_segment7              => vv_SEGMENT7,
        pv_segment8              => vv_SEGMENT8,
        pv_segment9              => vv_SEGMENT9,
        pv_segment10             => vv_SEGMENT10,
        pv_segment11             => vv_SEGMENT12,
        pv_segment12             => vv_SEGMENT12,
        pn_code_combination_id   => vn_code_combination_id,
        pv_errbuf                => vv_errbuf,
        pn_retcode               => vn_retcode);
    
      --Si OK on sort avec l4ID de la clé comptable
      --sinon on sort avec le message
      IF vn_retcode != 0 THEN 
         vv_out := vv_errbuf;
      ELSE
         vv_out := vn_code_combination_id;
      END IF;
      
      RETURN vv_out;
      
    EXCEPTION
     WHEN OTHERS THEN
      return SQLERRM;
    END get_cle_transco_f;

-----------------------------------------------------------------
--  Nom           : get_complement_compte
--  Description   : Fonction permettant suivant le complément de compte 11 
--                  d'obtenir le complément de compte 12
--
--  PARAMETRES :
--     pv_complement_cpte ENTREE
--
--  VALEUR RETOURNEE :
--     Description       :  Transcodification
--     Valeurs possibles :
-----------------------------------------------------------------
    
    FUNCTION get_complement_compte (  pv_complement_cpte IN   VARCHAR2 ) RETURN VARCHAR2 IS
    
     ln_exist      pls_integer; 
     vv_complt_cpt gl_code_combinations.segment5%TYPE;
                                       
    BEGIN
    
      --Existe comme Unité opérationnelle
      IF length(pv_complement_cpte) = 7 THEN
       
       BEGIN
         
         SELECT 1
         INTO ln_exist
         FROM hr_all_organization_units haou,
              hr_organization_information hoi
         WHERE haou.NAME = pv_complement_cpte
          AND nvl(haou.TYPE,'*') != 'SOCIETE'
          AND hoi.ORGANIZATION_ID = haou.ORGANIZATION_ID
          AND org_information1 = 'OPERATING_UNIT'
          AND org_information2 = 'Y'; 
         
         vv_complt_cpt :=  pv_complement_cpte;
          
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_complt_cpt := '0';
       END;
        
      ELSIF length(pv_complement_cpte) = 4 AND dka_tools_pkg.numeric_check(pv_complement_cpte) = '0' THEN
       BEGIN
         
         /*SELECT 1
         INTO ln_exist
		 FROM FND_FLEX_VALUES_VL FFVV, FND_FLEX_VALUESET_V FFVSV
		 WHERE FFVV.FLEX_VALUE_SET_ID  = FFVSV.FLEX_VALUE_SET_ID
		 AND FFVSV.FLEX_VALUE_SET_NAME = 'DAOPCCF_STE'
		 AND FFVV.FLEX_VALUE = pv_complement_cpte;*/--YWA artf2125207
         
         vv_complt_cpt :=  'XXX'||pv_complement_cpte;
          
         SELECT 1
         INTO ln_exist 
         FROM FND_FLEX_VALUES_VL FFVV, FND_FLEX_VALUESET_V FFVSV
		 WHERE FFVV.FLEX_VALUE_SET_ID  = FFVSV.FLEX_VALUE_SET_ID
		 AND FFVSV.FLEX_VALUE_SET_NAME = 'DAOPCCF_INTERCO'
		 AND FFVV.FLEX_VALUE = vv_complt_cpt;--YWA  artf2125207
          
       EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vv_complt_cpt := '0';
       END;  
         
      ELSE      
        vv_complt_cpt :=  '0';      
      END IF; 
      
      RETURN vv_complt_cpt;
      
    EXCEPTION
     WHEN OTHERS THEN
      return '0';
    END get_complement_compte;

-----------------------------------------------------------------
--  Nom           : get_cle_transco
--  Description   : Procédure permettant suivant les segments de la clé d'obtenir
--                  les segments de la clé
--
--  PARAMETRES :
--     pv_segment_in_01      ENTREE
--     pv_segment_in_02      ENTREE
--     pv_segment_in_03      ENTREE
--     pv_segment_in_04      ENTREE
--     pv_segment_in_05      ENTREE
--     pv_code_projet        ENTREE
--     pv_segment_in_08      ENTREE
--     pv_segment_in_09      ENTREE
--     pv_segment_in_10      ENTREE
--     pv_segment_out_01     SORTIE
--     pv_segment_out_02     SORTIE
--     pv_segment_out_03     SORTIE
--     pv_segment_out_04     SORTIE
--     pv_segment_out_05     SORTIE
--     pv_segment_out_06     SORTIE
--     pv_segment_out_07     SORTIE
--     pv_segment_out_08     SORTIE
--     pv_segment_out_09     SORTIE
--     pv_segment_out_10     SORTIE
--     pv_segment_out_11     SORTIE
--     pv_segment_out_12     SORTIE
--
--  VALEUR RETOURNEE :
--     Description       :  
--     Valeurs possibles :
-----------------------------------------------------------------
    
    PROCEDURE get_cle_transco ( pv_segment_01     IN   VARCHAR2,
                                pv_segment_02     IN   VARCHAR2,
                                pv_segment_03     IN   VARCHAR2,
                                pv_segment_04     IN   VARCHAR2,
                                pv_segment_05     IN   VARCHAR2,
                                pv_code_projet    IN   VARCHAR2,
                                pv_segment_08     IN   VARCHAR2,
                                pv_segment_09     IN   VARCHAR2,
                                pv_segment_10     IN   VARCHAR2,
                                pv_segment_out_01 OUT  VARCHAR2,
                                pv_segment_out_02 OUT  VARCHAR2,
                                pv_segment_out_03 OUT  VARCHAR2,
                                pv_segment_out_04 OUT  VARCHAR2,
                                pv_segment_out_05 OUT  VARCHAR2,
                                pv_segment_out_06 OUT  VARCHAR2,
                                pv_segment_out_07 OUT  VARCHAR2,
                                pv_segment_out_08 OUT  VARCHAR2,
                                pv_segment_out_09 OUT  VARCHAR2,
                                pv_segment_out_10 OUT  VARCHAR2,
                                pv_segment_out_11 OUT  VARCHAR2,
                                pv_segment_out_12 OUT  VARCHAR2 ) IS
     
     vv_code_projet_12 VARCHAR2(500);
                                
    BEGIN
    
       --SEGMENT1 : pas de transco
       pv_segment_out_01 := pv_segment_01;
      
       --SEGMENT2 : pas de transco
       --pv_segment_out_02 := pv_segment_02;
	   get_transco(pv_transco_name => '008_REGIONS', 
										pv_column_01    =>pv_segment_02,
										pv_out_01       => pv_segment_out_02
										); 
      
       --SEGMENT3 : TRANSCO : 005_COMPTE_LOCAL
       pv_segment_out_03 := DKA_REP_TRANSCO_PKG.get_transco_f(pv_transco_name => '005_COMPTE_LOCAL',
                                                                   pv_column_01    => pv_segment_03);
                                                         
       --SEGMENT4 : TRANSCO : 006_COMPTE_GROUPE
       pv_segment_out_04 := DKA_REP_TRANSCO_PKG.get_transco_f(pv_transco_name => '006_COMPTE_GROUPE',
                                                                  pv_column_01    => pv_segment_04);                                                        
      
       --SEGMENT5 : Complement groupe
       pv_segment_out_05 := get_complement_compte(pv_segment_05);
       
       --SEGMENT6-7 : Centre Financier et Affaire
       vv_code_projet_12 := DKA_REP_TRANSCO_PKG.get_transco_f(pv_transco_name => '014_PROJETS',
                                                              pv_column_01    => pv_code_projet);
       vv_code_projet_12 := nvl(substr(vv_code_projet_12,1,instr(vv_code_projet_12,';')-1),'0');
       
       DKA_REP_TRANSCO_PKG.get_transco( pv_transco_name  => '019_PROJET_CP_AFFAIRE',
                                        pv_column_01     => vv_code_projet_12,
                                        pv_out_01        => pv_segment_out_07,
                                        pv_out_02        => pv_segment_out_06);
                                        
       IF pv_segment_out_06 is null then
         pv_segment_out_06 := '0';
         pv_segment_out_07 := '0';
       END IF;
       
       --SEGMENT8 : Code projet finance 
       pv_segment_out_08 := vv_code_projet_12;
       
       --SEGMENT9 : pas de transco
       pv_segment_out_09 := pv_segment_09;
       
       --SEGMENT10-11-12 : Par Défaut
       pv_segment_out_10 := '0';
       pv_segment_out_11 := '0';
       pv_segment_out_12 := '0';
    
    EXCEPTION
     WHEN OTHERS THEN
       pv_segment_out_01 := NULL;
       pv_segment_out_02 := NULL;
       pv_segment_out_03 := NULL;
       pv_segment_out_04 := NULL;
       pv_segment_out_05 := NULL;
       pv_segment_out_06 := NULL;
       pv_segment_out_07 := NULL;
       pv_segment_out_08 := NULL;
       pv_segment_out_09 := NULL;
       pv_segment_out_10 := NULL;
       pv_segment_out_11 := NULL;
       pv_segment_out_12 := NULL;
    END get_cle_transco;
    
END DKA_REP_TRANSCO_PKG; -- Corps du package
/

SHOW ERRORS
EXIT;

