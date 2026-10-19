CREATE OR REPLACE PACKAGE BODY APPS.DKA_SAPDEBAUTOSSTR
  is
  -- -----------------------------------------------------------------------------
  -- $$
  -- Capgemini
  -- PROJET           : Projet Hèlios
  -- NOM              : DKA_SAPDEBAUTOSSTR
 
  -- DESCRIPTION      : DKA_SAPDEBAUTOSSTR
  
  --
  -- AUTEUR           : Sara HOUSSAINI(Capgemini)
  -- DATE DE CREATION : 01/10/2024
  -- COMMENTAIRES     : A exècuter sous SQLPLUS avec le user apps
  -- -----------------------------------------------------------------------------
  --
  -- -----------------------------------------------------------------------------
  -- HISTORIQUE DES MODIFICATIONS
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- -----------------------------------------------------------------------------

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

g_user                    NUMBER        := fnd_profile.value('USER_ID');
g_retproc               NUMBER        := 0;
g_sqlerrm               VARCHAR2(500) := NULL;
    g_package               VARCHAR2(30)  := 'DKA_SAPDEBAUTOSSTR';
    

  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  -- +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  /*
*************************************************************************
* PROCEDURE NAME : Output_Header
*
* DESCRIPTION
*  Procèdure pour insèrer une en-tète dans le fichier de sortie
*
* PARAMETERS
* ==========
* NAME              DESCRIPTION
* ----------------- ------------------------------------------------------
*
*
************************************************************************
*/

        l_err              l_erreur   ;
    l_fac               l_facture;

  PROCEDURE output_header
  IS
        cv_line                     VARCHAR2 (1000);
         BEGIN

        cv_line    := '+-----------------------------------------------------------------------------------------------------------------+';




        Fnd_File.put_line (Fnd_File.output, cv_line );
        Fnd_File.put_line (Fnd_File.output, 'Compte-rendu du traitement : DKA : Automatisation de déblocage BAP factures rapprochées des commandes SSTR en PMTDIR');
        Fnd_File.put_line (Fnd_File.output, 'Traitement : '||fnd_global.conc_request_id);
        Fnd_File.put_line (Fnd_File.output, 'Le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') );
    Fnd_File.put_line (Fnd_File.output, cv_line || CHR(10));
  END output_header;

/*
*************************************************************************
* PROCEDURE NAME : Output_End
*
* DESCRIPTION
*  Procèdure pour insèrer une fin dans le fichier de sortie
*
* PARAMETERS
* ==========
* NAME              DESCRIPTION
* ----------------- ------------------------------------------------------
*
*
************************************************************************
*/

 
  PROCEDURE output_end
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme terminé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_end;
  
   PROCEDURE output_start
  IS
        cv_line                     VARCHAR2 (100);
  BEGIN

        cv_line    := '---------------------------------------------------------------------------';

        Fnd_File.put_line (Fnd_File.output, cv_line);
        Fnd_File.put_line (Fnd_File.output, 'Programme lancé le : ' || TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS'));
        Fnd_File.put_line (Fnd_File.output, cv_line);
  END output_start;
  
   /*============================================================================*/
    -- Procedure         : writeout
    -- Description       : Ecriture dans fichier *.OUT
    -- Parametres entree : P_message IN VARCHAR2 : message a ecrire
    -- Parametres sortie : AUCUN
    -- Auteur            : Saloua HA
    -- Date              : 14/01/2020
    -- Remarques         :
  /*============================================================================*/
  PROCEDURE writeout(P_message IN VARCHAR2) IS
    L_procedure VARCHAR2(30) := 'writeout';
    v_etape   VARCHAR2(100);
  BEGIN

    FND_FILE.PUT_LINE(FND_FILE.OUTPUT, P_message);

  EXCEPTION
    WHEN OTHERS THEN
    G_retproc := 1;
    G_sqlerrm := SUBSTR(SQLERRM, 1, 200);
    Fnd_File.put_line(Fnd_File.LOG,
              '-------------------- ERREUR --------------------');
    Fnd_File.put_line(Fnd_File.LOG, 'Package   : ' || G_package);
    Fnd_File.put_line(Fnd_File.LOG, 'Procedure : ' || L_procedure);
    Fnd_File.put_line(Fnd_File.LOG, 'Exception : OTHERS');
    Fnd_File.put_line(Fnd_File.LOG, 'Message   : ' || v_etape);
    Fnd_File.put_line(Fnd_File.LOG, 'Cause     : ' || G_sqlerrm);
  END writeout;
/*
   *************************************************************************
   * PROCEDURE NAME : Report_Bilan
   *
   * DESCRIPTION
   *  Procédure de génération du bilan du traitement d'interface
   *
   * PARAMETERS
   * ==========
   * NAME                 DESCRIPTION
  .* -------------------- ---------------------------------------------------
   * Pv_Errbuf            Retour de message éventuel
   * Pn_Retcode           Statut du traitement en sortie
   ************************************************************************
   */
  PROCEDURE Report_Bilan(Pv_Errbuf            OUT VARCHAR2,
               Pn_Retcode           OUT NUMBER
               )
  IS
  vv_message varchar2(1000);
  v_counter NUMBER ;
  BEGIN

    Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Début Report_Bilan');

    --------------------
    -- Initialisation --
    --------------------

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;
   v_counter := 0;  

  

      
    IF l_fac.count > 0 
    THEN
      fnd_file.put_line(fnd_file.OUTPUT,' ');
      fnd_file.put_line(fnd_file.OUTPUT,'Liste des factures traitées pour laquelle le blocage a été levé :');
      fnd_file.put_line(fnd_file.OUTPUT,'------------------------------------------------------------------');
      writeout( RPAD('Facture ID',50)||RPAD('N° Facture',20));
      writeout( RPAD('--------',50)||RPAD('-------------',20));
      
       Fnd_File.put_line (Fnd_File.LOG ,RPAD('Facture ID',50)||RPAD('N° Facture',20));
      Fnd_File.put_line (Fnd_File.LOG , RPAD('--------',50)||RPAD('-------------',20));

      FOR i IN l_fac.first..l_fac.last 
      LOOP
        vv_message := RPAD(l_fac(i).FACTURE,50)||RPAD(l_fac(i).NUM_LIGNE,50);
        writeout(vv_message);
        Fnd_File.put_line (Fnd_File.LOG,vv_message);
        v_counter := v_counter + 1;
      END LOOP;

     END IF ;

     fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
     vv_message := 'Nombre total de factures traitées : ' || v_counter;
     Fnd_File.put_line (Fnd_File.LOG,vv_message);
     Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin Report_Bilan');

         IF l_err.count > 0 
    THEN
      fnd_file.put_line(fnd_file.OUTPUT,'Liste des factures en erreurs:');
      fnd_file.put_line(fnd_file.OUTPUT,'------------------------------');
      fnd_file.put_line(fnd_file.OUTPUT,' ');
      writeout( RPAD('Facture',50)||RPAD('N° Facture',20));
      writeout( RPAD('--------',50)||RPAD('---------',20));
      

        FOR i IN l_err.first..l_err.last 
      LOOP
         vv_message := RPAD(l_err(i).FACTURE,50)||RPAD(l_err(i).NUM_LIGNE,20);
         writeout(vv_message);
         Fnd_File.put_line (Fnd_File.LOG,vv_message);
        END LOOP;

      END IF ;
    fnd_file.put_line(fnd_file.OUTPUT,CHR(10));
  EXCEPTION
  WHEN OTHERS
  THEN
      Pn_Retcode   := 2;
      Pv_Errbuf    := 'REPORT_BILAN : ' ||SQLERRM;
      Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'Fin de la procédure Report_Bilan : EXCEPTION OTHERS ');
  END Report_Bilan;

 -------------------------------------------------------------------------------------
    --  Nom           : leve_blocage
    --  Description   :  leve_blocage le blocage de type pv_blocage_AP sur la facture  pn_invoice_id
    --                           avec l'utilisateur pn_user_id
    --  PARAMETRES :
    --
    --  VALEUR RETOURNEE :
    --     N/A
    -------------------------------------------------------------------------------------
    PROCEDURE leve_blocage( Pv_Errbuf                  OUT VARCHAR2
                   ,Pn_Retcode                 OUT NUMBER) IS

        
  Erreur_Programme            EXCEPTION;
  v_errbuf                   VARCHAR2(2500);
  vn_nb_lignes_EC number := 0;
  vv_code_deblocage ap_lookup_codes.lookup_code%type;

    vv_desc_deblocage ap_lookup_codes.description%type;
    
  
  
    CURSOR cur_extract_facture  IS
  select distinct  aia.invoice_id  ,
                   aia.INVOICE_NUM
    from ap_invoice_lines_all e,
     ap_invoice_distributions_all b,
      po_distributions_all c,
      po_headers_all pha, 
      ap_invoices_all aia,
      ap_holds_all aha 
   
     
      WHERE aia.invoice_id = b.invoice_id
      and aia.invoice_id = e.invoice_id
      AND b.po_distribution_id = c.po_distribution_id(+)
      AND c.po_header_id = pha.po_header_id(+)
      AND  aha.invoice_id = aia.invoice_id
      AND aha.hold_lookup_code = 'En attente'
      --AND aha.HOLD_REASON= 'En attente' 
      AND pha.segment1 like '%ST%'
      AND aia.PAY_GROUP_LOOKUP_CODE= 'PMTDIR'
      AND SYSDATE > aia.invoice_date + 15            -- Condition pour ne prendre que les factures dont la date est supérieure à 15 jours
      AND aia.WFAPPROVAL_STATUS != 'APPROVED' 
      AND pha.approved_flag = 'Y'
      AND release_lookup_code is null   ;               -- Condition pour le CUF à 'OUI' (champ à confirmer)


 
        
BEGIN

    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;
    --pn_nb_lignes_ec := 0;
    v_errbuf  := NULL;
    
    
  vv_code_deblocage         := 'Bon à payer';
  vv_desc_deblocage     :='Déblocage facture pour bon à payer';


    dka_tools_pkg.put_debug_message('==> Dèbut du traitement');


      FOR lt_factures IN cur_extract_facture LOOP
   
    
        
      BEGIN
      
             update ap_holds_all
               set last_update_date    = SYSDATE,
                 last_updated_by     = g_user ,
                 release_lookup_code = vv_code_deblocage,
                 release_reason      = vv_desc_deblocage,
                 status_flag         = 'R' /*,
                             attribute1          =  pv_wf_item_type,
                             attribute2          = pv_wf_item_key*/
             where invoice_id = lt_factures.invoice_id AND hold_lookup_code = 'En attente'
                   --  AND HOLD_REASON= 'En attente'
					 AND release_lookup_code is null;
                   COMMIT;
          vn_nb_lignes_EC := vn_nb_lignes_EC + 1;
         l_fac(vn_nb_lignes_EC).FACTURE      := lt_factures.invoice_id;
         l_fac(vn_nb_lignes_EC).NUM_LIGNE      := lt_factures.INVOICE_NUM; 
         
          EXCEPTION
          WHEN Erreur_Programme THEN
            v_errbuf  := 'Erreur : Impossible Déblocage facture pour bon à payer';
            Pn_Retcode   := 2;
            Pv_Errbuf    := v_errbuf;
          l_err(vn_nb_lignes_EC).FACTURE      := lt_factures.invoice_id;
         l_err(vn_nb_lignes_EC).NUM_LIGNE      := lt_factures.INVOICE_NUM; 
          
                

         END;

      END LOOP;
    END leve_blocage;



  

  

/*
*************************************************************************
* PROCEDURE NAME : main
*
* DESCRIPTION
*  Procèdure gènèrale du traitement
*
* PARAMETERS
* ==========
* NAME                 DESCRIPTION
.* -------------------- ---------------------------------------------------
* Pv_Errbuf            Retour de message èventuel
* Pn_Retcode           Statut du traitement en sortie
************************************************************************
*/
PROCEDURE main(Pv_Errbuf    IN OUT VARCHAR2,
                   Pn_Retcode   IN OUT NUMBER
                   )
IS


        v_errbuf                   VARCHAR2(2500);
    v_retcode                  NUMBER;
    Erreur_Programme           EXCEPTION;
    
       -- pn_nb_lignes_ec number := 0;
        

  BEGIN

    v_errbuf  := NULL;
    v_retcode := 0;
    output_header;

    output_start;
    leve_blocage( v_errbuf ,v_retcode);

  

      Fnd_File.put_line (Fnd_File.LOG, v_retcode);
      Fnd_File.put_line (Fnd_File.LOG, v_errbuf);
      Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||v_errbuf||CHR(10));
      Fnd_File.put_line (Fnd_File.LOG, TO_CHAR (SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' || 'FIN DE L''INTERFACE');

       Report_Bilan( v_errbuf ,v_retcode);
       output_end;
    EXCEPTION
      WHEN Erreur_Programme
      THEN
        Pn_Retcode   := 2;
        Pv_Errbuf    := v_errbuf;
        Fnd_File.put_line (Fnd_File.LOG, Pv_Errbuf);
        Fnd_File.put_line (Fnd_File.OUTPUT, CHR(10)||Pv_Errbuf);
       
      WHEN OTHERS
      THEN
         fnd_concurrent.af_rollback;
         Pn_Retcode := 2;
         
         Fnd_File.put_line (Fnd_File.Output ,CHR(10) || '==> Erreur technique (voir journal du traitement)' || CHR(10));
        
         Pv_Errbuf := SQLERRM;
 
        

END main;





END DKA_SAPDEBAUTOSSTR
 ;
/
SHOW ERRORS
EXIT


