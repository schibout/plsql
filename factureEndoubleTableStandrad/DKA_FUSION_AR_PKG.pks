CREATE OR REPLACE PACKAGE BODY DKA_SPODISABLE_CALC_CAP_PKG
AS

----------------------------------------------------------------------------
-- $Id: DKA_SPODISABLE_CALC_CAP_PKG.pkb 195 2007-09-14 12:59:35Z NORDEST\jjardez $
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPODISABLE_CALC_CAP_PKG.pks
-- DESCRIPTION       : DKA_SPODISABLE_CALC_CAP_PKG package specifications
---
--- AUTEUR           : J. JARDEZ
--- DATE DE CREATION : 13/09/2007
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date        Qui         Description
--- 11/02/2010  BCOPIN      EARS00008957424 - Suppression du contrôle des statuts
--- 20/06/2017  MEG         artf2173355 : SPE064 - Comptabilisation des charges à payer - Fonctionnement
--- 18/09/2018  RBE         artf2992569 : DPE20180027_EDB208_OracleR12_CAP PO sur commande d'investissement 
----------------------------------------------------------------------------

 --------------------------------------------------------------------------------------
 --  Nom           : DESACTIVE_CALCUL_CAP_SSTR
 --  Description   : Procedure principale de desactivation du calcul des CAP
 --
 --  PARAMETRES :
 --    pv_errbuf                   Entree/Sortie       retour de message eventuel
 --    pn_retcode                  Sortie          status du traitement en sortie
 --
 --  VALEUR RETOURNEE :
 --     Description       : code retour de validite
 --     Valeurs possibles : 0: normal, 1: warning, 2: erreur
 --
 ----------------------------------------------------------------------------------------
    PROCEDURE desactive_calcul_cap_sstr (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) IS
    BEGIN
     pv_errbuf  := '';
     pn_retcode := 0;

     UPDATE PO_DISTRIBUTIONS_ALL pd
     SET pd.accrued_flag = 'Y'
     WHERE pd.po_header_id IN (SELECT po_header_id
                               FROM PO_HEADERS_ALL ph
                               WHERE
                                ph.segment1 LIKE '%ST%'
                                --BCOPIN  EARS00008957424 - Suppression de du contrôle des statuts :
                                --AND ph.authorization_status = 'APPROVED'
                               )
        /*OR EXISTS (SELECT 1 
                     FROM pa_projects_all ppa 
                    WHERE ppa.project_id = pd.project_id
                      AND ppa.project_type = 'Investissement')*/ --RBE  artf2992569
     ;

     COMMIT;

    EXCEPTION
     WHEN OTHERS THEN
      pv_errbuf  := 'Erreur dans la procedure DKA_SPODISABLE_CALC_CAP_PKG.desactive_calcul_cap_sstr : '||SQLERRM;
      pn_retcode := 2;
    END desactive_calcul_cap_sstr;

END DKA_SPODISABLE_CALC_CAP_PKG;
/
SHOW ERROR
EXIT;
