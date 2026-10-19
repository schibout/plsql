CREATE OR REPLACE PACKAGE BODY DKA_SAPRPT_MVTS_SANS_IMAGE IS

---------------------------------------------------------------------------------------------------------------
  -- $Id: DKA_SAPRPT_MVTS_SANS_IMAGE_PKG.pkb 485 2008-04-16 08:04:21Z CORP\mthunga $
  --
  -- CAPGEMINI
  -- PROJET      : VEOLIA Puissance 4
  -- NOM         :  DKA_SAPRPT_MVTS_SANS_IMAGE.pkb
  -- DESCRIPTION       :  DKA_SAPRPT_MVTS_SANS_IMAGE package body :
  ---           package specifique utilise dans le workflow remplacant le workflow approbation AP
  --- AUTEUR       : Maheswara Thunga (CAPGEMINI)
  --- DATE DE CREATION : 20/05/2010
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A executer sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 2016/07/05 JJA Portage Helios R12
  --- 2017/03/10 EFL Modification suite artf2116842 : Modification requete alimentation de la table tmp.
  --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--------------------------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------
  --  Nom           : clear_tmp_table
  --  Description   : procedure to truncate the temp table.
  --
  --  PARAMETRES :
   --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE clear_tmp_table(pv_csp IN VARCHAR2,
                            pv_division IN VARCHAR2,
                            pv_status IN OUT VARCHAR2) IS
  BEGIN
  delete from DKA_SAPMVTSANSIMAGE_TMP
  where Division=nvl(pv_division,Division)
    and CSP=nvl(pv_csp,CSP) ;
  commit;
  pv_status:='SUCCESS';
  EXCEPTION
  WHEN OTHERS THEN
   pv_status:=substr('Failed to clear data for the division'||pv_division||'. Sql error'||SQLERRM,1,300) ; 
  END clear_tmp_table;

-------------------------------------------------------------------------------------
  --  Nom           : Load_data
  --  Description   : procedure to truncate the temp table.
  --
  --  PARAMETRES :
   --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
  PROCEDURE Load_data(pv_csp IN VARCHAR2,
                      pv_division IN VARCHAR2,
                      pv_status IN OUT VARCHAR2) IS
  BEGIN

  --insert data fron AP_INVOICES_ALL
      INSERT INTO DKA_SAPMVTSANSIMAGE_TMP
      SELECT /*+  INDEX(ai AP_INVOICES_N16)  */
    ai.org_id,
    dsl.return_value CSP,
    hou.attribute10 Division,
    substr(hou.name,1,3) Region,
    'AP' Origine,
    ai.creation_date date_de_creation,
    ceil(sysdate-ai.creation_date) Duree ,
    ai.source Type_de_facture,
    ai.pay_group_lookup_code class_de_reglement ,
    pv.vendor_name nom_du_fournisseur,
    pv.segment1 num_fournisseur,
    pvsa.vendor_site_code code_site_fournisseur,
    ai.invoice_num num_facture,
    ai.invoice_amount Montant,
    ai.attribute3 Code_LAD
   FROM ap_invoices_all ai,
        dka_stransco_lines   dsl,
        hr_all_organization_units hou,
        gl_code_combinations gcc,
        ap_suppliers pv,
        ap_supplier_sites_all pvsa
   WHERE dsl.set_id =  ( SELECT dsh.set_id
                         from   dka_stransco_headers dsh
                         WHERE dsh.set_name = 'CENTRE_SERVICE_PARTAGE' )
        and hou.organization_id =ai.org_id
        and dsl.param1_value = hou.attribute10
        and hou.attribute10=nvl(pv_division,hou.attribute10)
        and dsl.return_value=nvl(pv_csp,dsl.return_value)
        and dsl.params_value = hou.attribute10||gcc.segment2
  	    and dsl.start_date <= trunc(sysdate)                             
        and nvl(dsl.end_date,trunc(sysdate)) >= trunc(sysdate) 
        and ai.accts_pay_code_combination_id = gcc.code_combination_id
        and dsl.param2_value = gcc.segment2 
        and ai.vendor_id=pv.vendor_id
        and ai.vendor_site_id=pvsa.vendor_site_id        and pv.vendor_id=pvsa.vendor_id
        and ( ai.source in ('SCAN_XGS','SCAN','Manual Invoice Entry','EDI')
          OR 
          (ai.source in ('Invoice Gateway','AMONTS') and (ai.attribute9 not in ('HAC','HAF') or ai.attribute9 is null)))
        and ai.invoice_type_lookup_code<>'EXPENSE REPORT'
        and  ai.wfapproval_status not in ('NOT REQUIRED','WFAPPROVED')
        and not exists
        ( select 1 from DKA_STRANSCO_LINES DSL
                  where dsl.set_id =  ( SELECT dsh.set_id
                                       from  DKA_STRANSCO_HEADERS DSH
                                       where dsh.set_name='DKA_STES_EXCLUES' )
                    --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image

                    and ((dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value IS NULL)
                    or (dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value = substr(hou.name,1,3)))
                    --and dsl.params_value=substr(hou.name,4,4)
                    --and dsl.return_value=to_char(ai.org_id) 
         )
        and not exists
         ( select 1 from fnd_attached_documents fad,
                          fnd_documents fd,
                          fnd_document_datatypes fdd,
                          fnd_documents_tl fdt
                    where fad.entity_name='AP_INVOICES'
                      and fad.document_id=fd.document_id
                      and fd.category_id=1
                      and fd.datatype_id=fdd.datatype_id
                      and fdd.language='F'
                      and fdd.user_name='Fichier'
                      and fad.document_id=fdt.document_id
                      and fd.document_id=fdt.document_id
                      and fdt.language='F'
                      and fdt.description='IMAGE FACTURE'
                      and fad.pk1_value=to_char(ai.invoice_id)
         )
    UNION ALL
    --insert data fron AP_INVOICE_INTERFACE
    select aii.org_id,
    dsl.return_value CSP,
    hou.attribute10 Division,
    substr(hou.name,1,3) Region,
    'OI' Origine,
    aii.creation_date date_de_creation,
    ceil(sysdate-aii.creation_date) Duree ,
    aii.source Type_de_facture,
    aii.pay_group_lookup_code class_de_reglement ,
    pv.vendor_name nom_du_fournisseur,
    pv.segment1 num_fournisseur,
    pvsa.vendor_site_code code_site_fournisseur,
    aii.invoice_num num_facture,
    aii.invoice_amount Montant,
    aii.attribute3 Code_LAD
    from ap_invoices_interface aii,
         dka_stransco_lines   dsl,
         ap_suppliers pv,
         ap_supplier_sites_all  pvsa,
         hr_all_organization_units hou
   where aii.status = 'REJECTED'
     and ( aii.source= 'SCAN_XGS' or aii.source= 'SCAN'
           or (aii.source='AMONTS' and (aii.attribute9 not in ('HAC','HAF') or aii.attribute9 is null))
         )
     and  dsl.set_id = ( SELECT dsh.set_id
                         from   dka_stransco_headers dsh
                         WHERE dsh.set_name = 'CENTRE_SERVICE_PARTAGE' )
     and hou.organization_id = aii.org_id
     and dsl.param1_value = hou.attribute10
     and dsl.param2_value = substr(hou.name, 1, 3)  
     and dsl.params_value = hou.attribute10|| substr(hou.name, 1, 3)
	 and hou.attribute10=nvl(pv_division,hou.attribute10)
     and dsl.return_value=nvl(pv_csp,dsl.return_value)
     and dsl.start_date <= trunc(sysdate)                             
     and nvl(dsl.end_date,trunc(sysdate)) >= trunc(sysdate) 
     and aii.vendor_site_id = pvsa.vendor_site_id 
     and pv.vendor_id=aii.vendor_id
     and pv.vendor_id=pvsa.vendor_id
     and not exists-- part of excluded legal entities
      (select 1
         from DKA_STRANSCO_HEADERS DSH,
              DKA_STRANSCO_LINES DSL
       where dsh.set_name='DKA_STES_EXCLUES'
         and dsh.set_id=dsl.set_id
         --- 2017/08/08 NBO artf2068302 - SPE129 - Exclusion des sociétés du controle de l'image
         --and dsl.params_value=nvl(aii.attribute15,substr(hou.name,4,4))		 
         --and dsl.return_value=to_char(aii.org_id)
         and ((dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value IS NULL)
                    or (dsl.param1_value = substr(hou.name,4,4) AND dsl.param2_value = substr(hou.name,1,3)))
		 and dsl.start_date <= trunc(sysdate)                             
         and nvl(dsl.end_date,trunc(sysdate)) >= trunc(sysdate) 
		 )
   and not exists -- exists invoice image 
     ( select 1 
         from fnd_attached_documents fad,
              fnd_documents fd,
              fnd_document_datatypes fdd,
              fnd_documents_tl fdt
       where fad.entity_name='AP_INVOICES_INTERFACE'
          and fad.document_id=fd.document_id
          and fd.category_id=1
          and fd.datatype_id=fdd.datatype_id
          and fdd.language='F'
          and fdd.user_name='Fichier'
          and fdt.language='F'
          and fad.document_id=fdt.document_id
          and fd.document_id=fdt.document_id
          and fdt.description='IMAGE FACTURE'
          and fad.pk1_value=to_char(aii.invoice_id)
   );

  commit;
  pv_status:='SUCCESS';
  EXCEPTION
  WHEN OTHERS THEN
   pv_status:=substr('Failed to load data for the division'||pv_division||'. Sql error'||SQLERRM,1,300);   
    
  END Load_data;
-----------------------------------------------------------------------------------
  --  Nom           : LAUNCH_REPORT
  --  Description   : procedure to write data to output file
  --
  --  PARAMETRES :
   --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------
 
  PROCEDURE Launch_report ( pv_csp        IN VARCHAR2,
                            PV_division   IN VARCHAR2,
                            pv_status IN OUT VARCHAR2) IS
  CURSOR C_DATA IS
  select * 
    FROM DKA_SAPMVTSANSIMAGE_TMP 
    WHERE CSP=nvl(pv_csp,CSP)
    AND DIVISION=nvl(pv_division,division);
   
  BEGIN              
  
  fnd_file.PUT_LINE(fnd_file.OUTPUT,'Liste des mvts sans images (AP '||'&'||' OI)');

  fnd_file.PUT_LINE(fnd_file.OUTPUT,'Org_id;CSP;Division;Region;Origine;Date_de_creation;Duree;Type_de_facture;Classe_de_reglement;Nom_du_fournisseur;Num_fournisseur;Code_site_fournisseur;Num_facture;Montant;Code_lad');
  
  for r_data in C_DATA
  loop
    fnd_file.PUT(fnd_file.output, r_data.org_id||';'||r_data.csp||';'||r_data.division||';'||r_data.region||';'||r_data.origine||';'||r_data.date_de_creation||';');
    fnd_file.PUT(fnd_file.output, r_data.duree||';'||r_data.type_de_facture||';'||r_data.class_de_reglement||';'||r_data.nom_du_fournisseur||';'||r_data.num_fournisseur||';');
    fnd_file.put_line(fnd_file.output, r_data.code_site_fournisseur||';'||r_data.num_facture||';'||r_data.montant||';'||r_data.code_lad);
  end loop;
  pv_status :='SUCCESS';
  EXCEPTION
  WHEN OTHERS THEN
  fnd_file.put_line(fnd_file.LOG,' Error in report execution ' || SQLERRM);
  END Launch_report; 
  ----------------------------------------------------------------------------------
  --  Nom           : Main
  --  Description   : procedure to clear ,load and write data to output file
  --
  --  PARAMETRES :
   --
  --  VALEUR RETOURNEE :
  --     N/A
  -------------------------------------------------------------------------------------

  PROCEDURE Main (pv_errbuf     OUT VARCHAR2,
                pn_retcode    IN OUT NUMBER,
                pv_csp        IN VARCHAR2,
                pv_division   IN VARCHAR2) IS
  vv_status VARCHAR2(400);                
  BEGIN
  
  clear_tmp_table(pv_csp,pv_division,vv_status);
  
  IF vv_status<>'SUCCESS' THEN
     fnd_file.put_line(fnd_file.LOG,vv_status);
     pn_retcode:=2;
     return;
  END IF;
  
  Load_data(pv_csp,pv_division,vv_status);
  
  IF vv_status<>'SUCCESS' THEN
     fnd_file.put_line(fnd_file.LOG,vv_status);
     pn_retcode:=2;
     return;
  END IF;
  
  Launch_report(pv_csp,pv_division,vv_status);
  
  IF vv_status<>'SUCCESS' THEN
     fnd_file.put_line(fnd_file.LOG,vv_status);
     pn_retcode:=2;
     return;
  END IF;
  
  EXCEPTION
  WHEN OTHERS THEN
  pn_retcode:=2;
  END Main;
                
END DKA_SAPRPT_MVTS_SANS_IMAGE;
/
show errors package body DKA_SAPRPT_MVTS_SANS_IMAGE;

EXIT
