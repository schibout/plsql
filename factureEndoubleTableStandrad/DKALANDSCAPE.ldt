SET VERIFY OFF;
DEFINE package_name = "DKA_SFNDCLOSETP_WF_PKG";

CREATE OR REPLACE PACKAGE BODY &&package_name
AS
----------------------------------------------------------------------------------------------
-- $Id$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SFNDCLOSETP_WF_PKG.pkb
-- DESCRIPTION       : DKA_SFNDCLOSETP_WF_PKG package spec :procedure utiliser dans le workflow
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 02/02/2012
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
-- 27/05/2016  MEG Migration R12
--------------------------------------------------------------------------------------------


--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 -------------------------------------------------------------------------------------------------------------------
 --  Nom           : IS_CLOSE_TP
 --  Description   : Verification de la constante d'ouverture ou fermeture du TP
 --
 --  PARAMETRES    :
 --    itemtype        varchar2
 --    itemkey         varchar2
 --    actid            number
 --    funcmode        varchar2
 --  VALEUR RETOURNEE :
 --     Description       : Resultat de la verification
 --     Valeurs possibles : Yes: TP ferme (0)
 --                         No : TP ouvert (1)
 -------------------------------------------------------------------------------------------------------------------
 PROCEDURE is_close_TP (itemtype    IN       VARCHAR2
                       ,itemkey     IN       VARCHAR2
                       ,actid       IN       NUMBER
                       ,funcmode    IN       VARCHAR2
                       ,resultout   OUT      VARCHAR2
                     ) IS
     tp_is_open number;
     is_running number;
     vr_data    dka_parameters%ROWTYPE;
     vn_retcode PLS_INTEGER;
     vv_err_msg VARCHAR2(500);
     
     --vn_orgid    number;
     
     ee_exception EXCEPTION;

   BEGIN
     
     --INIT
     resultout :='COMPLETE:N';
   
     IF (funcmode = 'RUN') THEN
      
      --vn_orgid := wf_engine.GetItemAttrNumber( itemtype => itemtype,
      --                                         itemkey  => itemkey,
      --                                         aname    => 'ORG_ID');
      
      --IF nvl(vn_orgid,0) = 81 /*DALKIA*/ THEN     
      
        --Verification que le processus d'approbation de commande est en cours
        SELECT fcq.RUNNING_PROCESSES 
        INTO is_running
        FROM 
         FND_CONCURRENT_QUEUES FCQ
        ,FND_CONCURRENT_PROCESSORS FCP
        WHERE 
            FCP.CONCURRENT_PROCESSOR_ID   = FCQ.CONCURRENT_PROCESSOR_ID 
        AND FCP.CONCURRENT_PROCESSOR_NAME = 'POXCON';
        
        --Selection de la variable d'ouverture/fermture du TP
        dka_tools_pkg.get_parameter(pv_program_code   => 'SFND_CLOSE_TP',
                                    pv_parameter_name => 'TP',
                                    pr_data           => vr_data,
                                    pn_retcode        => vn_retcode ,
                                    pv_err_msg        => vv_err_msg);
           
        IF vn_retcode != 0 THEN
           wf_core.CONTEXT('&&package_name', 'is_close_TP',
              itemtype, itemkey, actid, funcmode,vn_retcode,vv_err_msg);
           RAISE ee_exception;
        END IF;
                                    
        IF vr_data.number_value = 0 AND is_running > 0 THEN
             resultout :='COMPLETE:Y';
        ELSE
             resultout :='COMPLETE:N';
        END IF;
     

    --END IF; --DALKIA
   
  END IF;

EXCEPTION
   WHEN OTHERS THEN
     wf_core.CONTEXT('&&package_name', 'is_close_TP',
       itemtype, itemkey, actid, funcmode);
     RAISE;
END is_close_TP; 
   
END &&package_name;
/
SHOW ERRORS;

EXIT;
