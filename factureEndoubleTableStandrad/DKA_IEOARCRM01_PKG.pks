set define off


CREATE OR REPLACE PACKAGE BODY DKA_SAPCREATE_BLOCAGES_PKG AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SAPCREATE_BLOCAGES_PKG.pkb  2011-03-29 12:19:28Z CORP\mthunga $
  --
  -- CAPGEMINI
  -- PROJET      : HELIOS
  -- NOM         : DKA_SAPCREATE_BLOCAGES_PKG.pkb
  -- DESCRIPTION : DKA_SAPCREATE_BLOCAGES_PKG package body :
  ---
  --- AUTEUR       : Maheswara THUNGA (CAPGEMINI)
  --- DATE DE CREATION : 29/03/2011
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 13/05/2014 BCO DPE20140029 - Ajout du code blocage 33.Date facture hors période de validité avant la prise en compte AP
  ---------------------------------------------------------------------------------------------------------------
  
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    cv_ano_affact        ap_holds_all.hold_lookup_code%type := 'Blocage Fres Affact';    
    cv_ano_affact_reason ap_holds_all.hold_reason%type :='40.Affacturage non présent';
  
  -- DPE20140029 - Ajout de constante pour le code blocage 33.
  cv_ano_date_fact    ap_holds_all.hold_lookup_code%type := 'Blocage Date Facture';
  cv_ano_date_fact_reason ap_holds_all.hold_reason%type :='33.Date facture hors période de validité';
  
  
 ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : Procédure de l'executable rattache au traitement DKA_SAPCREATE_BLOCAGES_PKG
  --               
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------

  PROCEDURE Main ( pv_errbuf     OUT VARCHAR2,
                   pn_retcode    IN OUT NUMBER) AS
  vv_error_message   VARCHAR2 (200);
  vn_error_code      NUMBER (15);                   
  BEGIN

        
   Dka_Tools_Pkg.put_debug_message ('main +');
   Dka_Tools_Pkg.put_debug_message ('Org ID: '||gn_org_id);
   Dka_Tools_Pkg.put_debug_message ('User  : '||fnd_global.USER_ID);
   vn_error_code    := 0;
   
   IF gn_org_id IS NULL THEN
          dka_tools_pkg.put_log_message('L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée');
          pv_errbuf := 'L''option de profil 1_MO: Unité opérationnelle n''est pas paramétrée';
          pn_retcode := 2;
          RETURN;
   END IF;
   
   DKA_TOOLS_PKG.put_debug_message ('Creation of blocage fres affact');
   Blocage_fres_affact(vv_error_message,vn_error_code);
   IF vn_error_code != 0
   THEN
       pn_retcode    := 2;
       Dka_Tools_Pkg.put_debug_message (vv_error_message);
       RETURN;
    END IF;
    
  -- DPE20140029 - Exécution de la procédure pour le code blocage 33.
  DKA_TOOLS_PKG.put_debug_message ('Creation of blocage date facture');
  Blocage_date_facture(vv_error_message,vn_error_code);
  IF vn_error_code != 0
  THEN
     pn_retcode    := 2;
     Dka_Tools_Pkg.put_debug_message (vv_error_message);
  RETURN;
  END IF;
  
   Dka_Tools_Pkg.put_debug_message ('main -');      
   
  EXCEPTION
  WHEN OTHERS THEN
  pn_retcode    := 2;
  pv_errbuf :=SQLERRM;
  END Main;
 
  ------------------------------------------------------------------------------------
  --  Nom           : Blocage_date_facture
  --  Description   : 
  --               
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------

  PROCEDURE Blocage_date_facture(
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) IS
  cursor c_inv is
  SELECT
    ai.invoice_id, ai.invoice_num
   FROM ap_invoices_all ai
   WHERE    ai.wfapproval_status <> 'NOT REQUIRED'
    AND    ai.wfapproval_status<>'WFAPPROVED'
    AND ai.source in ('SCAN_XGS','ZCI')
    AND instr(ai.attribute1,'33')>0
    and ai.org_id=gn_org_id
    and not exists
    (select 1
      from ap_holds_all aha
     where hold_lookup_code=cv_ano_date_fact
       and ai.invoice_id=aha.invoice_id
     )  
    and exists   
    (SELECT 1
          FROM dka_stransco_headers dsh,
               dka_stransco_lines   dsl,
                gl_code_combinations gcc,
               hr_all_organization_units hou
         WHERE
            ai.accts_pay_code_combination_id = gcc.code_combination_id
            AND dsl.param2_value = gcc.segment2
            AND hou.organization_id = ai.org_id
            AND dsl.param1_value = hou.attribute10
            AND dsh.set_id = dsl.set_id
            AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
            AND dsl.start_date <= trunc (sysdate)
            AND nvl (dsl.end_date, trunc (sysdate)) >= trunc (sysdate)

    );
    
  vn_count number:=0;
  BEGIN
 
    Dka_Tools_Pkg.put_debug_message ('Blocage_date_facture +');  
       
       FOR rec_inv IN c_inv
       LOOP
	   DKA_TOOLS_PKG.put_debug_message ('Boucle atteinte');
       pn_retcode :=0; 
        
       cree_blocage(rec_inv.invoice_id,
                    cv_ano_date_fact,
                    cv_ano_date_fact_reason,
                    fnd_global.USER_ID,
                    pv_errbuf,
                    pn_retcode);
                    
        IF pn_retcode =0 then
         update ap_invoices_all 
           set attribute1=replace(replace(replace(attribute1,'.33',''),'33.',''),'33','')
         where invoice_id=rec_inv.invoice_id;
         vn_count :=vn_count+1;
        else
         DKA_TOOLS_PKG.put_debug_message ('Failed to create blocage date facture for invoice :' || rec_inv.invoice_num||'erreur: '||pv_errbuf);
        end if;
        
       END LOOP;
  
     DKA_TOOLS_PKG.put_debug_message ('Total no of invoices processed :' || vn_count);
             
     Dka_Tools_Pkg.put_debug_message ('Blocage_date_facture -'); 
        
  END Blocage_date_facture;
 
  ------------------------------------------------------------------------------------
  --  Nom           : Blocage_fres_affact
  --  Description   : 
  --               
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --
  -------------------------------------------------------------------------------------

  PROCEDURE Blocage_fres_affact(
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    ) IS
  cursor c_inv is
  SELECT
    ai.invoice_id, ai.invoice_num
   FROM ap_invoices_all ai
   WHERE    ai.wfapproval_status <> 'NOT REQUIRED'
    AND    ai.wfapproval_status<>'WFAPPROVED'
    AND ai.source in ('SCAN_XGS','ZCI')
    AND instr(ai.attribute1,'40')>0
    and ai.org_id=gn_org_id
    and not exists
    (select 1
      from ap_holds_all aha
     where hold_lookup_code=cv_ano_affact
       and ai.invoice_id=aha.invoice_id
     )  
    and exists   
    (SELECT 1
          FROM dka_stransco_headers dsh,
               dka_stransco_lines   dsl,
                gl_code_combinations gcc,
               hr_all_organization_units hou
         WHERE
         -- dsl.return_value = nvl (pv_CSP,dsl.return_value)
           --AND dsl.param1_value = nvl (pv_division,dsl.param1_value)
            --AND 
            ai.accts_pay_code_combination_id = gcc.code_combination_id
            AND dsl.param2_value = gcc.segment2
            AND hou.organization_id = ai.org_id
            AND dsl.param1_value = hou.attribute10
            AND dsh.set_id = dsl.set_id
            AND dsh.set_name = 'CENTRE_SERVICE_PARTAGE'
            AND dsl.start_date <= trunc (sysdate)
            AND nvl (dsl.end_date, trunc (sysdate)) >= trunc (sysdate)

    );
    
  vn_count number:=0;
  BEGIN
 
    Dka_Tools_Pkg.put_debug_message ('Blocage_fres_affact +');  
       
       FOR rec_inv IN c_inv
       LOOP
         DKA_TOOLS_PKG.put_debug_message ('Boucle atteinte');
       pn_retcode :=0; 
        
       cree_blocage(rec_inv.invoice_id,
                    cv_ano_affact,
                    cv_ano_affact_reason,
                    fnd_global.USER_ID,
                    pv_errbuf,
                    pn_retcode);
                    
        IF pn_retcode =0 then
         update ap_invoices_all 
           set attribute1=replace(replace(replace(attribute1,'.40',''),'40.',''),'40','')
         where invoice_id=rec_inv.invoice_id;
         vn_count :=vn_count+1;
        else
         DKA_TOOLS_PKG.put_debug_message ('Failed to create blocage fres affact for invoice :' || rec_inv.invoice_num ||'erreur: '||pv_errbuf);
        end if;
        
       END LOOP;
  
     DKA_TOOLS_PKG.put_debug_message ('Total no of invoices processed :' || vn_count);
             
     Dka_Tools_Pkg.put_debug_message ('Blocage_fres_affact -'); 
        
  END Blocage_fres_affact;

  
   -------------------------------------------------------------------------------------
  --  Nom           : cree_blocage_AP
  --  Description   : Cree le blocage AP sur la facture  pn_invoice_id
  --
  --  PARAMETRES :
  --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE cree_blocage(pn_invoice_id     IN ap_invoices_all.invoice_id%type,
                         pv_blocage        IN ap_holds_all.hold_lookup_code%type,
                         pv_blocage_reason IN ap_holds_all.hold_reason%type,
                         pn_user_id        IN fnd_user.user_id%type,
                         pv_errbuf        OUT NOCOPY VARCHAR2,
                         pn_retcode       OUT NOCOPY NUMBER) IS
    v_blocage_reason ap_lookup_codes.displayed_field%type;
  --X_Rowid             VARCHAR2(100);
 -- x_hold_id       NUMBER;
  v_program_name      VARCHAR2(100);
  BEGIN
    pn_retcode := 0;
  v_program_name:='DKA_SAPCREATE_BLOCAGES_PKG.cree_blocage';
       IF (pv_blocage_reason is null) THEN
        select displayed_field
          into v_blocage_reason
          from ap_lookup_codes aplc
         where aplc.lookup_type = 'HOLD CODE'
           and aplc.lookup_code = pv_blocage;
 
    END IF;
    /*AP_HOLDS_PKG.Insert_Row
    ( 
    X_Rowid                                    =>   X_Rowid,
    x_hold_id                                    =>   x_hold_id,
    X_Invoice_Id                              =>   pn_invoice_id,
    X_Line_Location_Id                   =>   NULL,
    X_Hold_Lookup_Code              =>   pv_blocage,
    X_Last_Update_Date                 =>   SYSDATE,
    X_Last_Updated_By                  =>   pn_user_id,
    X_Held_By                                =>  pn_user_id,
    X_Hold_Date                             =>   SYSDATE,
    X_Hold_Reason                         =>   nvl(ltrim(rtrim(pv_blocage_reason)), v_blocage_reason),
    X_Release_Lookup_Code         =>   NULL,
    X_Release_Reason              =>   NULL,
    X_Status_Flag                     =>   NULL,
    X_Last_Update_Login        =>   fnd_global.login_id,
    X_Creation_Date               =>   SYSDATE,
    X_Created_By                  =>   pn_user_id ,
    X_Responsibility_Id           =>   NULL,
    X_Attribute1                  =>   NULL,
    X_Attribute2                  =>   NULL,
    X_Attribute3                  =>   NULL,
    X_Attribute4                  =>   NULL,
    X_Attribute5                  =>   NULL,
    X_Attribute6                  =>   NULL,
    X_Attribute7                  =>   NULL,
    X_Attribute8                  =>   NULL,
    X_Attribute9                  =>   NULL,
    X_Attribute10                 =>   NULL,
    X_Attribute11                 =>   NULL,
    X_Attribute12                 =>   NULL,
    X_Attribute13                 =>   NULL,
    X_Attribute14                 =>   NULL,
    X_Attribute15                 =>   NULL,
    X_Attribute_Category        =>   NULL,
    X_Org_Id                          =>   gn_org_id,
    X_calling_sequence            =>   NULL
    );*/
    AP_HOLDS_PKG.insert_single_hold  (X_Invoice_Id                              =>   pn_invoice_id,
                                X_Hold_Lookup_Code              =>   pv_blocage,
                                 X_Hold_Reason                         =>   nvl(ltrim(rtrim(pv_blocage_reason)), v_blocage_reason),
                                 X_Held_By                                =>  pn_user_id,
                                 X_calling_sequence =>v_program_name);
   
   
  EXCEPTION 
  WHEN OTHERS THEN
  
  pn_retcode:=2;
  pv_errbuf:=SQLERRM;
       
  END cree_blocage;
  
END DKA_SAPCREATE_BLOCAGES_PKG; -- Corps du package


/
SHOW ERROR PACKAGE BODY DKA_SAPCREATE_BLOCAGES_PKG;
EXIT
