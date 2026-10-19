-- -----------------------------------------------------------------------------
-- $Id$
-- CapGemini
-- PROJET           : DALKIA Oracle Applications
-- NOM              : DKA_SAPFACT_BLOQ_EDIT.sql
-- DESCRIPTION      : Lancement automatique du traitement DKA_SAPFACT_BLOQ_EDIT
--
-- AUTEUR           : CapGemini
-- DATE DE CREATION : 04/03/2009
-- DOC. ASSOCIEE    :
-- COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
-- -----------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 2016/07/05 JJA Portage Helios R12
-- -----------------------------------------------------------------------------

SET VERIFY OFF
SET SERVEROUTPUT ON SIZE 1000000

VAR ret_code      VARCHAR2(10);

DECLARE
    Vv_Prog_Name                        VARCHAR2(30) := 'DKA_SAPFACT_BLOQ_EDIT';
    Vn_Tempo                            NUMBER := 20;
    Vv_User                             VARCHAR2(80) := '&&1';
    Vv_Resp                             VARCHAR2(80) := '&&2';
    Vv_Errbuf                           VARCHAR2(500) := NULL;
    Vn_Retcode                          NUMBER := 0;
    Vn_Prog_Application_Id              NUMBER(15);
    Vv_Prog_Application_Short_Name      VARCHAR2(50);
    Vn_Program_Id                       NUMBER(15);
    Vn_Responsibility_Id                NUMBER(15);
    Vn_Application_Id                   NUMBER(15);
    vv_application_short_name        VARCHAR2 (50);
    Vn_User_Id                          NUMBER(15);
    Vn_Request_Id                       NUMBER(15);
    Vv_Rphase                           VARCHAR2(80);
    Vv_Rstatus                          VARCHAR2(80);
    Vv_Dphase                           VARCHAR2(30);
    Vv_Dstatus                          VARCHAR2(30);
    Vv_Message                          VARCHAR2(240);
    Vv_Period_Name                      VARCHAR2(50);
    
    E_MYEXCEPTION   EXCEPTION ;
    
    CURSOR cur_csp IS 
      SELECT DISTINCT CSP,return_value as responsibility_Id
      FROM   DKA_SAPREINITBLOCAGE_TMP xst,
             dka_stransco_headers dsh,
            dka_stransco_lines   dsl
      WHERE dsh.set_id = dsl.set_id  
      AND   dsl.param1_value = xst.csp
      AND   dsh.set_name = 'DKA_CSP_RESP'
      AND  xst.NOTIF_CLOSE_DATE between sysdate-7 and sysdate;

BEGIN

  FOR rec_csp IN cur_csp
  LOOP
  
    BEGIN
      Vn_Responsibility_Id := rec_csp.responsibility_Id;
          
      Dbms_Output.Put_Line('=> Traitement du CSP '|| rec_csp.csp ||'et de la responsabilité N°' ||Vn_Responsibility_Id);     
          
      
      

      SELECT Fr.Application_Id,fa.application_short_name
      INTO   Vn_Application_Id,vv_application_short_name
      FROM   Fnd_Responsibility Fr,
           fnd_application fa
      WHERE  Fr.Responsibility_Id = Vn_Responsibility_Id
      AND fr.application_id = fa.application_id;
  
      SELECT User_Id
      INTO   Vn_User_Id
      FROM   Fnd_User
      WHERE  User_Name = Vv_User; 
  
      Dbms_Output.Put_Line(rec_csp.csp||'=> Recuperation des identifiants programme');
      SELECT Fcp.Application_Id,
             Fa.Application_Short_Name,
             Fcp.Concurrent_Program_Id
      INTO   Vn_Prog_Application_Id,
             Vv_Prog_Application_Short_Name,
             Vn_Program_Id
      FROM   Fnd_Concurrent_Programs Fcp,
             Fnd_Application         Fa
      WHERE  Fcp.Concurrent_Program_Name = Vv_Prog_Name 
      AND    Fa.Application_Id           = Fcp.Application_Id;
  
      Dbms_Output.Put_Line(rec_csp.csp||'=> Initialisation dans le contexte O.A.');
      Fnd_Global.Apps_Initialize(Vn_User_Id,
                                 Vn_Responsibility_Id,
                                 Vn_Application_Id);
      MO_GLOBAL.INIT ('SQLAP'); --2016/07/05
                           
      EXECUTE IMMEDIATE 'ALTER SESSION SET NLS_LANGUAGE=''' || Fnd_Profile.VALUE('ICX_LANGUAGE') || '''';
  
      Dbms_Output.Put_Line(rec_csp.csp||'=> Recuperation des parametres');
      Dka_Tools_Pkg.Get_Request_Set_Params(Pv_Errbuf                 => Vv_Errbuf,
                                           Pn_Retcode                => Vn_Retcode,
                                           Pn_Application_Id         => NULL,
                                           Pn_Request_Set_Id         => NULL,
                                           Pn_Request_Set_Program_Id => NULL,
                                           Pn_Prog_Application_Id    => Vn_Prog_Application_Id,
                                           Pn_Program_Id             => Vn_Program_Id);
  
      IF Vn_Retcode != 0 THEN
          Dbms_Output.Put_Line('Impossible de récupérer les parametres :');
          Dbms_Output.Put_Line(Vv_Errbuf);
          :Ret_Code := 'FAILURE';
          RAISE E_MYEXCEPTION;
      END IF;
  
      Dbms_Output.Put_Line(rec_csp.csp||'=> Soumission du traitement');
      Vn_Request_Id := Fnd_Request.Submit_Request(Vv_Prog_Application_Short_Name,       -- APPLICATION PROPRIETAIRE DU TRAITEMENT
                                                  Vv_Prog_Name,                         -- SHORT NAME DU TRAITEMENT
                                                  NULL,                                 -- PROGRAM NAME
                                                  NULL,                                 -- START
                                                  FALSE,                                -- SUB REQUEST
                                                  rec_csp.csp,                          -- ARGUMENT1
                                                  Dka_Tools_Pkg.Tab_Request_Params(2),  -- ARGUMENT2
                                                  Dka_Tools_Pkg.Tab_Request_Params(3),  -- ARGUMENT3
                                                  Dka_Tools_Pkg.Tab_Request_Params(4),  -- ARGUMENT4
                                                  Dka_Tools_Pkg.Tab_Request_Params(5),  -- ARGUMENT5
                                                  Dka_Tools_Pkg.Tab_Request_Params(6),  -- ARGUMENT6
                                                  Dka_Tools_Pkg.Tab_Request_Params(7),  -- ARGUMENT7
                                                  Dka_Tools_Pkg.Tab_Request_Params(8),  -- ARGUMENT8
                                                  Dka_Tools_Pkg.Tab_Request_Params(9),  -- ARGUMENT9
                                                  Dka_Tools_Pkg.Tab_Request_Params(10), -- ARGUMENT10
                                                  Dka_Tools_Pkg.Tab_Request_Params(11), -- ARGUMENT11
                                                  Dka_Tools_Pkg.Tab_Request_Params(12), -- ARGUMENT12
                                                  Dka_Tools_Pkg.Tab_Request_Params(13), -- ARGUMENT13
                                                  Dka_Tools_Pkg.Tab_Request_Params(14), -- ARGUMENT14
                                                  Dka_Tools_Pkg.Tab_Request_Params(15), -- ARGUMENT15
                                                  Dka_Tools_Pkg.Tab_Request_Params(16), -- ARGUMENT16
                                                  Dka_Tools_Pkg.Tab_Request_Params(17), -- ARGUMENT17
                                                  Dka_Tools_Pkg.Tab_Request_Params(18), -- ARGUMENT18
                                                  Dka_Tools_Pkg.Tab_Request_Params(19), -- ARGUMENT19
                                                  Dka_Tools_Pkg.Tab_Request_Params(20), -- ARGUMENT20
                                                  Dka_Tools_Pkg.Tab_Request_Params(21), -- ARGUMENT21
                                                  Dka_Tools_Pkg.Tab_Request_Params(22), -- ARGUMENT22
                                                  Dka_Tools_Pkg.Tab_Request_Params(23), -- ARGUMENT23
                                                  Dka_Tools_Pkg.Tab_Request_Params(24), -- ARGUMENT24
                                                  Dka_Tools_Pkg.Tab_Request_Params(25), -- ARGUMENT25
                                                  Dka_Tools_Pkg.Tab_Request_Params(26), -- ARGUMENT26
                                                  Dka_Tools_Pkg.Tab_Request_Params(27), -- ARGUMENT27
                                                  Dka_Tools_Pkg.Tab_Request_Params(28), -- ARGUMENT28
                                                  Dka_Tools_Pkg.Tab_Request_Params(29), -- ARGUMENT29
                                                  Dka_Tools_Pkg.Tab_Request_Params(30), -- ARGUMENT30
                                                  Dka_Tools_Pkg.Tab_Request_Params(31), -- ARGUMENT31
                                                  Dka_Tools_Pkg.Tab_Request_Params(32), -- ARGUMENT32
                                                  Dka_Tools_Pkg.Tab_Request_Params(33), -- ARGUMENT33
                                                  Dka_Tools_Pkg.Tab_Request_Params(34), -- ARGUMENT34
                                                  Dka_Tools_Pkg.Tab_Request_Params(35), -- ARGUMENT35
                                                  Dka_Tools_Pkg.Tab_Request_Params(36), -- ARGUMENT36
                                                  Dka_Tools_Pkg.Tab_Request_Params(37), -- ARGUMENT37
                                                  Dka_Tools_Pkg.Tab_Request_Params(38), -- ARGUMENT38
                                                  Dka_Tools_Pkg.Tab_Request_Params(39), -- ARGUMENT39
                                                  Dka_Tools_Pkg.Tab_Request_Params(40), -- ARGUMENT40
                                                  Dka_Tools_Pkg.Tab_Request_Params(41), -- ARGUMENT41
                                                  Dka_Tools_Pkg.Tab_Request_Params(42), -- ARGUMENT42
                                                  Dka_Tools_Pkg.Tab_Request_Params(43), -- ARGUMENT43
                                                  Dka_Tools_Pkg.Tab_Request_Params(44), -- ARGUMENT44
                                                  Dka_Tools_Pkg.Tab_Request_Params(45), -- ARGUMENT45
                                                  Dka_Tools_Pkg.Tab_Request_Params(46), -- ARGUMENT46
                                                  Dka_Tools_Pkg.Tab_Request_Params(47), -- ARGUMENT47
                                                  Dka_Tools_Pkg.Tab_Request_Params(48), -- ARGUMENT48
                                                  Dka_Tools_Pkg.Tab_Request_Params(49), -- ARGUMENT49
                                                  Dka_Tools_Pkg.Tab_Request_Params(50), -- ARGUMENT50
                                                  Dka_Tools_Pkg.Tab_Request_Params(51), -- ARGUMENT51
                                                  Dka_Tools_Pkg.Tab_Request_Params(52), -- ARGUMENT52
                                                  Dka_Tools_Pkg.Tab_Request_Params(53), -- ARGUMENT53
                                                  Dka_Tools_Pkg.Tab_Request_Params(54), -- ARGUMENT54
                                                  Dka_Tools_Pkg.Tab_Request_Params(55), -- ARGUMENT55
                                                  Dka_Tools_Pkg.Tab_Request_Params(56), -- ARGUMENT56
                                                  Dka_Tools_Pkg.Tab_Request_Params(57), -- ARGUMENT57
                                                  Dka_Tools_Pkg.Tab_Request_Params(58), -- ARGUMENT58
                                                  Dka_Tools_Pkg.Tab_Request_Params(59), -- ARGUMENT59
                                                  Dka_Tools_Pkg.Tab_Request_Params(60), -- ARGUMENT60
                                                  Dka_Tools_Pkg.Tab_Request_Params(61), -- ARGUMENT61
                                                  Dka_Tools_Pkg.Tab_Request_Params(62), -- ARGUMENT62
                                                  Dka_Tools_Pkg.Tab_Request_Params(63), -- ARGUMENT63
                                                  Dka_Tools_Pkg.Tab_Request_Params(64), -- ARGUMENT64
                                                  Dka_Tools_Pkg.Tab_Request_Params(65), -- ARGUMENT65
                                                  Dka_Tools_Pkg.Tab_Request_Params(66), -- ARGUMENT66
                                                  Dka_Tools_Pkg.Tab_Request_Params(67), -- ARGUMENT67
                                                  Dka_Tools_Pkg.Tab_Request_Params(68), -- ARGUMENT68
                                                  Dka_Tools_Pkg.Tab_Request_Params(69), -- ARGUMENT69
                                                  Dka_Tools_Pkg.Tab_Request_Params(70), -- ARGUMENT70
                                                  Dka_Tools_Pkg.Tab_Request_Params(71), -- ARGUMENT71
                                                  Dka_Tools_Pkg.Tab_Request_Params(72), -- ARGUMENT72
                                                  Dka_Tools_Pkg.Tab_Request_Params(73), -- ARGUMENT73
                                                  Dka_Tools_Pkg.Tab_Request_Params(74), -- ARGUMENT74
                                                  Dka_Tools_Pkg.Tab_Request_Params(75), -- ARGUMENT75
                                                  Dka_Tools_Pkg.Tab_Request_Params(76), -- ARGUMENT76
                                                  Dka_Tools_Pkg.Tab_Request_Params(77), -- ARGUMENT77
                                                  Dka_Tools_Pkg.Tab_Request_Params(78), -- ARGUMENT78
                                                  Dka_Tools_Pkg.Tab_Request_Params(79), -- ARGUMENT79
                                                  Dka_Tools_Pkg.Tab_Request_Params(80), -- ARGUMENT80
                                                  Dka_Tools_Pkg.Tab_Request_Params(81), -- ARGUMENT81
                                                  Dka_Tools_Pkg.Tab_Request_Params(82), -- ARGUMENT82
                                                  Dka_Tools_Pkg.Tab_Request_Params(83), -- ARGUMENT83
                                                  Dka_Tools_Pkg.Tab_Request_Params(84), -- ARGUMENT84
                                                  Dka_Tools_Pkg.Tab_Request_Params(85), -- ARGUMENT85
                                                  Dka_Tools_Pkg.Tab_Request_Params(86), -- ARGUMENT86
                                                  Dka_Tools_Pkg.Tab_Request_Params(87), -- ARGUMENT87
                                                  Dka_Tools_Pkg.Tab_Request_Params(88), -- ARGUMENT88
                                                  Dka_Tools_Pkg.Tab_Request_Params(89), -- ARGUMENT89
                                                  Dka_Tools_Pkg.Tab_Request_Params(90), -- ARGUMENT90
                                                  Dka_Tools_Pkg.Tab_Request_Params(91), -- ARGUMENT91
                                                  Dka_Tools_Pkg.Tab_Request_Params(92), -- ARGUMENT92
                                                  Dka_Tools_Pkg.Tab_Request_Params(93), -- ARGUMENT93
                                                  Dka_Tools_Pkg.Tab_Request_Params(94), -- ARGUMENT94
                                                  Dka_Tools_Pkg.Tab_Request_Params(95), -- ARGUMENT95
                                                  Dka_Tools_Pkg.Tab_Request_Params(96), -- ARGUMENT96
                                                  Dka_Tools_Pkg.Tab_Request_Params(97), -- ARGUMENT97
                                                  Dka_Tools_Pkg.Tab_Request_Params(98), -- ARGUMENT98
                                                  Dka_Tools_Pkg.Tab_Request_Params(99), -- ARGUMENT99
                                                  Dka_Tools_Pkg.Tab_Request_Params(100) -- ARGUMENT100
                                                  );
      Dbms_Output.Put_Line(rec_csp.csp||'=> Validation pour que les GTS puissent prendre la demande');
      COMMIT;
  
      IF Vn_Request_Id = 0 THEN
          Dbms_Output.Put_Line('Impossible de lancer le Traitement ');
          :Ret_Code := 'FAILURE';
          RAISE E_MYEXCEPTION;
      END IF;
  
      Dbms_Output.Put_Line( rec_csp.csp||'=> Traitement numero : ' || To_Char(Vn_Request_Id));
  
      IF NOT Fnd_Concurrent.Wait_For_Request(Vn_Request_Id,
                                             Vn_Tempo,
                                             0,
                                             Vv_Rphase,
                                             Vv_Rstatus,
                                             Vv_Dphase,
                                             Vv_Dstatus,
                                             Vv_Message) THEN
          :Ret_Code := 'FAILURE';
          RAISE E_MYEXCEPTION;
      ELSE
          IF Vv_Dstatus = 'WARNING' THEN
              Dbms_Output.Put_Line(Chr(10) || '>>> Traitement ' || Vn_Request_Id || ' termine en Warning ');
              :Ret_Code := 'WARNING';
              RAISE E_MYEXCEPTION;
          ELSIF Vv_Dstatus != 'NORMAL' THEN
              Dbms_Output.Put_Line(Chr(10) || '>>> Traitement ' || Vn_Request_Id || ' termine en Erreur ');
              :Ret_Code := 'FAILURE';
              RAISE E_MYEXCEPTION;
          END IF;
      END IF;
  
    EXCEPTION
        WHEN E_MYEXCEPTION THEN
          Dbms_Output.Put_Line('=> Erreur pour le CSP '|| rec_csp.csp);
          :Ret_Code := 'WARNING';
        WHEN NO_DATA_FOUND THEN
          Dbms_Output.Put_Line('=> Identifiants user  et responsabilité pour le CSP '|| rec_csp.csp ||' non trouvé');
          :Ret_Code := 'WARNING';
    END;
    
  END LOOP;

    Dbms_Output.Put_Line(Chr(10) || '>>> Traitement ' || Vn_Request_Id || ' termine Normal ');
    :Ret_Code := 'SUCCESS';

EXCEPTION
    WHEN OTHERS THEN
        Dbms_Output.Put_Line(Vv_Prog_Name || ' ==> ERREUR : ' || SQLERRM);
        :Ret_Code := 'FAILURE';
END;
/
COL :ret_code NEW_VALUE ret_code;
SELECT :ret_code
FROM   DUAL;
EXIT &ret_code
