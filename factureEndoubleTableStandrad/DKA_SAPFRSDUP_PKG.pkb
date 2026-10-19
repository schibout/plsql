CREATE OR REPLACE PACKAGE BODY dka_rapctrlprlvt_pkg AS
  ---------------------------------------------------------------------------------------------------------------
  -- $Id$
  --
  -- CAPGEMINI
  -- PROJET      : 
  -- NOM         : DKA_RAPCTRLPRLVT_PKG.pkb
  -- DESCRIPTION : DKA_RAPCTRLPRLVT_PKG package body :
  ---
  --- AUTEUR       : Nicolas BOUSSEKEYT (CAPGEMINI)
  --- DATE DE CREATION : 26/01/2021
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- 23/06/21   NBO EDB279B - Evol
  --- 26/12/2022 ARA EDB338 - Evol
  --- ---------- --- --------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------------

  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PUBLIQUES
  --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : Main
  --  Description   : Procédure principal
  --
  --  PARAMETRES    :
  --          pv_invoices  varchar2
  --
  --  VALEUR RETOURNEE :
  --      pv_errbuf  varchar2
  --      pv_status  varchar2
  -------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    lv_step VARCHAR2(100);
  
    --XML
    doc       sys.xmldom.domdocument;
    main_node sys.xmldom.domnode;
    root_node sys.xmldom.domnode;
  
    --NODE
    prlvtrapproche_node        sys.xmldom.domnode;
    prlvtrapprocheheader_node  sys.xmldom.domnode;
    prlvtrapprocheline_node    sys.xmldom.domnode;
    prlvtrrestantheader_node   sys.xmldom.domnode;
    prlvtrrestant_node         sys.xmldom.domnode;
    prlvtacontrolerheader_node sys.xmldom.domnode;
    prlvtacontroler_node       sys.xmldom.domnode;
  
    --SYSTEM NODE
    item_node sys.xmldom.domnode;
    root_elmt sys.xmldom.domelement;
    item_elmt sys.xmldom.domelement;
    item_text sys.xmldom.domtext;
    
    l_log varchar2(100);
    l_out varchar2(100);
    lfile VARCHAR2(4000);
    f UTL_FILE.FILE_TYPE;
  
    CURSOR c_select_prlvtrapproche IS
      SELECT identifiant_ligne_rb,
             compte_bancaire,
             oib type_ope,
             to_char(date_operation, 'DD/MM/RRRR') date_operation,
             to_char(date_valeur, 'DD/MM/RRRR') date_valeur,
             montant_rb montant,
             code_devise_rb,
             matching_status_rb status,
             to_char(rapproche_le, 'DD/MM/RRRR') rapproche_le,
             facture_ap,
			 numero_cpt_facturation_rb NumCptFacturationAP,--EDB338
             numero_reglement,
             libelle_long,
             id_modele_reglement,
             id_reglement,
             id_piece_gl
        FROM dka_prel_ap_rb
       WHERE matching_status_rb = 'Y'
       ORDER BY region,
                numero_societe,
                uo_compte_bancaire,
                identifiant_ligne_rb;
  
    CURSOR c_select_prlvtrestant IS
      SELECT identifiant_ligne_rb,
             compte_bancaire,
             oib type_ope,
             to_char(date_operation, 'DD/MM/RRRR') date_operation,
             to_char(date_valeur, 'DD/MM/RRRR') date_valeur,
             montant_rb montant,
             code_devise_rb,
             matching_status_rb status,
             libelle_long,
  			--- 23/06/21   NBO EDB279B - Evol 
            causes_rejet_maj_echeancier
        FROM dka_prel_ap_rb
       WHERE statut_reference = 'P'
       ORDER BY region,
                numero_societe,
                uo_compte_bancaire,
                identifiant_ligne_rb;
  
    CURSOR c_select_prelvt_acontroler IS
      SELECT identifiant_ligne_rb,
             statut_reference,
             compte_bancaire,
             oib type_ope,
             to_char(date_operation, 'DD/MM/RRRR') date_operation,
             to_char(date_valeur, 'DD/MM/RRRR') date_valeur,
             montant_rb montant,
             code_devise_rb,
             matching_status_rb status,
             libelle_long,
             facture_ap,
			 numero_cpt_facturation_rb NumCptFacturationAP,--EDB338
             uo_ap,
             montant montant_ap,
             num_fournisseur_ap,
             fournisseur_ap,
             id_modele_reglement,
             modele_reglement,
             statut_maj_echeancier,
             id_reglement,
             numero_reglement,
             id_demande_reglement,
             statut_etape_reglement,
             statut_centralisation,
             statut_imputation,
             id_piece_gl,
             numero_piece_gl,
             numero_ligne_gl,
             id_ligne_rb_gl,
             libelle_long_gl,
  			 --- 23/06/21   NBO EDB279B - Evol
             causes_rejet_maj_echeancier
        FROM dka_prel_ap_rb
       WHERE nvl(matching_status_rb, 'X') != 'Y'
         AND nvl(statut_reference, 'X') != 'P'
       ORDER BY region,
                numero_societe,
                numero_societe,
                statut_reference,
                identifiant_ligne_rb;
  
    lv_xml_file  VARCHAR2(500);
    lv_directory VARCHAR2(1000);
  
    PROCEDURE log_msg(p_message IN VARCHAR2) IS
      l_message VARCHAR2(1000);
    BEGIN
    
      l_message := substr(p_message, 1, 1000);
    
      IF (l_message IS NULL) THEN
        l_message := to_char(SYSDATE, 'DD/MM/YYYY HH24:MI:SS');
      END IF;
    
      fnd_file.put_line(fnd_file.log, l_message);
      --dbms_output.put_line('LOG : ' || substr(l_message, 1, 253));
    END log_msg;
  
  BEGIN
    lv_step := 'MAIN 001 : debut';
    log_msg(lv_step);
    dbms_session.free_unused_user_memory;
    
    --Init des variables de sortie
    pn_retcode := 0;
    pv_errbuf  := '';
  
    --Création du document
    doc := sys.xmldom.newdomdocument;
    sys.xmldom.setversion(doc, '1.0');
    sys.xmldom.setcharset(doc, 'UTF8');
  
    --NODE ORDER
    main_node := sys.xmldom.makenode(doc);
    root_elmt := sys.xmldom.createelement(doc, 'Prelevmt');
    root_node := sys.xmldom.appendchild(main_node,
                                        sys.xmldom.makenode(root_elmt));
  
    item_elmt                 := sys.xmldom.createelement(doc,
                                                          'PrlvtRapprocheHeader');
    prlvtrapprocheheader_node := sys.xmldom.appendchild(root_node,
                                                        sys.xmldom.makenode(item_elmt));
  
    lv_step := 'MAIN 002 : Prlvt Rapproche';
    log_msg(lv_step);
  
    FOR ligne_prlvtrapproche IN c_select_prlvtrapproche LOOP
    
      lv_step                 := 'XML : PrlvtrapprocheLine'; --log_msg(lv_step);
      item_elmt               := sys.xmldom.createelement(doc,
                                                          'PrlvtRapprocheLine');
      prlvtrapprocheline_node := sys.xmldom.appendchild(prlvtrapprocheheader_node,
                                                        sys.xmldom.makenode(item_elmt));
    
      --IdentifiantLigneRB-----------------------------------------------------------
      lv_step   := 'XML : IdentifiantLigneRB'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdentifiantLigneRB');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.identifiant_ligne_rb);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --UOCompteBancaire-----------------------------------------------------------
      lv_step   := 'XML : UOCompteBancaire'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'UOCompteBancaire');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.compte_bancaire);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --TypeLigneRB-----------------------------------------------------------
      lv_step   := 'XML : TypeLigneRB'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'TypeLigneRB');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.type_ope);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --DateOperation-----------------------------------------------------------
      lv_step   := 'XML : DateOperation'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'DateOperation');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.date_operation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --DateOperation-----------------------------------------------------------
      lv_step   := 'XML : DateValeur'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'DateValeur');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.date_operation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --Montant-----------------------------------------------------------
      lv_step   := 'XML : Montant'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'Montant');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.montant);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --CodeDevise-----------------------------------------------------------
      lv_step   := 'XML : CodeDevise'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'CodeDevise');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.code_devise_rb);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --Status-----------------------------------------------------------
      lv_step   := 'XML : Status'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'Status');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.status);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --RapprocheLe-----------------------------------------------------------
      lv_step   := 'XML : RapprocheLe'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'RapprocheLe');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.rapproche_le);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumFactureAP-----------------------------------------------------------
      lv_step   := 'XML : NumFactureAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumFactureAP');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.facture_ap);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
      
	  --EDB338
	  
	  --NumCptFacturationAP-----------------------------------------------------------
      lv_step   := 'XML : NumCptFacturationAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumCptFacturationAP');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.NumCptFacturationAP);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
										  
	  --END EDB338
	  
	  
	  
      --NumReglement-----------------------------------------------------------
      lv_step   := 'XML : NumReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumReglement');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.numero_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --LibelleReglement-----------------------------------------------------------
      lv_step   := 'XML : LibelleReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'LibelleReglement');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.libelle_long);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdModeleReglement-----------------------------------------------------------
      lv_step   := 'XML : IdModeleReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdModeleReglement');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.id_modele_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdModeleReglement-----------------------------------------------------------
      lv_step   := 'XML : IdReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdReglement');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.id_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdModeleReglement-----------------------------------------------------------
      lv_step   := 'XML : IdPieceGL'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdPieceGL');
      item_node := sys.xmldom.appendchild(prlvtrapprocheline_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             ligne_prlvtrapproche.id_piece_gl);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
    END LOOP;
  
    lv_step := 'MAIN 003 : Prlvt Restant';
    log_msg(lv_step);
  
    item_elmt                := sys.xmldom.createelement(doc,
                                                         'PrlvtRestantHeader');
    prlvtrrestantheader_node := sys.xmldom.appendchild(root_node,
                                                       sys.xmldom.makenode(item_elmt));
  
    FOR rec_prlvtrestant IN c_select_prlvtrestant LOOP
      lv_step            := 'XML : PrlvtRestant'; --log_msg(lv_step);
      item_elmt          := sys.xmldom.createelement(doc,
                                                     'PrlvtRestantLine');
      prlvtrrestant_node := sys.xmldom.appendchild(prlvtrrestantheader_node,
                                                   sys.xmldom.makenode(item_elmt));
    
      --IdentifiantLigneRB-----------------------------------------------------------
      lv_step   := 'XML : IdentifiantLigneRB'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdentifiantLigneRB');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtrestant.identifiant_ligne_rb);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
      --UOCompteBancaire-----------------------------------------------------------
      lv_step   := 'XML : UOCompteBancaire'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'UOCompteBancaire');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtrestant.compte_bancaire);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --TypeLigneRB-----------------------------------------------------------
      lv_step   := 'XML : TypeLigneRB'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'TypeLigneRB');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc, rec_prlvtrestant.type_ope);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --DateOperation-----------------------------------------------------------
      lv_step   := 'XML : DateOperation'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'DateOperation');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtrestant.date_operation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --DateOperation-----------------------------------------------------------
      lv_step   := 'XML : DateValeur'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'DateValeur');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtrestant.date_operation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --Montant-----------------------------------------------------------
      lv_step   := 'XML : Montant'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'Montant');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc, rec_prlvtrestant.montant);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --Montant-----------------------------------------------------------
      lv_step   := 'XML : CodeDevise'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'CodeDevise');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc, rec_prlvtrestant.montant);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --Status-----------------------------------------------------------
      lv_step   := 'XML : Status'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'Status');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc, rec_prlvtrestant.status);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --LibelleLong-----------------------------------------------------------
      lv_step   := 'XML : LibelleLong'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'LibelleLong');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtrestant.libelle_long);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));

      --- 23/06/21   NBO EDB279B - Evol
      --CauseRejet-----------------------------------------------------------
      lv_step   := 'XML : CauseRejet'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'CauseRejet');
      item_node := sys.xmldom.appendchild(prlvtrrestant_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtrestant.causes_rejet_maj_echeancier);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
                                              
    END LOOP;
  
    lv_step := 'MAIN 004 : Prlvt à contrôler';
    log_msg(lv_step);
  
    -- Prélèvements à contrôler
    item_elmt                  := sys.xmldom.createelement(doc,
                                                           'PrlvtAControlerHeader');
    prlvtacontrolerheader_node := sys.xmldom.appendchild(root_node,
                                                         sys.xmldom.makenode(item_elmt));
  
    FOR rec_prlvtacontroler IN c_select_prelvt_acontroler LOOP
      lv_step              := 'XML : PrlvtAControlerLine'; --log_msg(lv_step);
      item_elmt            := sys.xmldom.createelement(doc,
                                                       'PrlvtAControlerLine');
      prlvtacontroler_node := sys.xmldom.appendchild(prlvtacontrolerheader_node,
                                                     sys.xmldom.makenode(item_elmt));
    
      --IdentifiantLigneRB-----------------------------------------------------------
      lv_step   := 'XML : IdentifiantLigneRB'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdentifiantLigneRB');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.identifiant_ligne_rb);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdentifiantLigneRB-----------------------------------------------------------
      lv_step   := 'XML : StatutReference'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'StatutReference');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.statut_reference);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --UOCompteBancaire-----------------------------------------------------------
      lv_step   := 'XML : UOCompteBancaire'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'UOCompteBancaire');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.compte_bancaire);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --TypeLigneRB-----------------------------------------------------------
      lv_step   := 'XML : TypeLigneRB'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'TypeLigneRB');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.type_ope);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --DateOperation-----------------------------------------------------------
      lv_step   := 'XML : DateOperation'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'DateOperation');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.date_operation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --DateOperation-----------------------------------------------------------
      lv_step   := 'XML : DateValeur'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'DateValeur');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.date_operation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --Montant-----------------------------------------------------------
      lv_step   := 'XML : Montant'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'Montant');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.montant);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --CodeDevise-----------------------------------------------------------
      lv_step   := 'XML : CodeDevise'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'CodeDevise');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.code_devise_rb);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --CodeDevise-----------------------------------------------------------
      lv_step   := 'XML : Status'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'Status');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.status);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --LibelleLong-----------------------------------------------------------
      lv_step   := 'XML : LibelleLong'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'LibelleLong');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.libelle_long);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumFactureAP-----------------------------------------------------------
      lv_step   := 'XML : NumFactureAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumFactureAP');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.facture_ap);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
										  
	  --EDB338
	  
	  --NumCptFacturationAP-----------------------------------------------------------
      lv_step   := 'XML : NumCptFacturationAP'; log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumCptFacturationAP');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.NumCptFacturationAP);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
	  	  
	  --END EDB338
    
      --UOFactureAP-----------------------------------------------------------
      lv_step   := 'XML : UOFactureAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'UOFactureAP');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.uo_ap);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --MontantFactureAP-----------------------------------------------------------
      lv_step   := 'XML : MontantFactureAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'MontantFactureAP');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.montant_ap);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumFournisseurAP-----------------------------------------------------------
      lv_step   := 'XML : NumFournisseurAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumFournisseurAP');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.num_fournisseur_ap);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumFournisseurAP-----------------------------------------------------------
      lv_step   := 'XML : FournisseurAP'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'FournisseurAP');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.fournisseur_ap);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdModeleReglement-----------------------------------------------------------
      lv_step   := 'XML : IdModeleReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdModeleReglement');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.id_modele_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --ModeleReglement-----------------------------------------------------------
      lv_step   := 'XML : ModeleReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'ModeleReglement');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.modele_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --StatutMajEcheancier-----------------------------------------------------------
      lv_step   := 'XML : StatutMajEcheancier'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'StatutMajEcheancier');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.statut_maj_echeancier);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdReglement-----------------------------------------------------------
      lv_step   := 'XML : IdReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdReglement');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.id_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumeroReglement-----------------------------------------------------------
      lv_step   := 'XML : NumReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumReglement');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.numero_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdDemandeReglement-----------------------------------------------------------
      lv_step   := 'XML : IdDemandeReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdDemandeReglement');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.id_demande_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --StatutEtapeReglement-----------------------------------------------------------
      lv_step   := 'XML : StatutEtapeReglement'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'StatutEtapeReglement');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.statut_etape_reglement);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --StatutCentralisation-----------------------------------------------------------
      lv_step   := 'XML : StatutCentralisation'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'StatutCentralisation');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.statut_centralisation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --StatutImputation-----------------------------------------------------------
      lv_step   := 'XML : StatutImputation'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'StatutImputation');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.statut_imputation);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdPieceGL-----------------------------------------------------------
      lv_step   := 'XML : IdPieceGL'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdPieceGL');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.id_piece_gl);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumeroPieceGL-----------------------------------------------------------
      lv_step   := 'XML : NumeroPieceGL'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumeroPieceGL');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.numero_piece_gl);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --NumeroLigneGL-----------------------------------------------------------
      lv_step   := 'XML : NumeroLigneGL'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'NumeroLigneGL');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.numero_ligne_gl);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdLigneRbGL-----------------------------------------------------------
      lv_step   := 'XML : IdLigneRbGL'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'IdLigneRbGL');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.id_ligne_rb_gl);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
    
      --IdLigneRbGL-----------------------------------------------------------
      lv_step   := 'XML : LibelleLongGL'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'LibelleLongGL');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.libelle_long_gl);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
      --CauseRejet-----------------------------------------------------------
      lv_step   := 'XML : CauseRejet'; --log_msg(lv_step);
      item_elmt := sys.xmldom.createelement(doc, 'CauseRejet');
      item_node := sys.xmldom.appendchild(prlvtacontroler_node,
                                          sys.xmldom.makenode(item_elmt));
      item_text := sys.xmldom.createtextnode(doc,
                                             rec_prlvtacontroler.causes_rejet_maj_echeancier);
      item_node := sys.xmldom.appendchild(item_node,
                                          sys.xmldom.makenode(item_text));
                                              
    END LOOP;
  
    lv_step := 'MAIN 005 : fin nouvelle ligne';
    log_msg(lv_step);
  
    SELECT directory_path
      INTO lv_directory
      FROM dba_directories
     WHERE directory_name = 'DKA_OUT_DIR';
  
    --Fichier de sortie
    SELECT substr(outfile_name, instr(outfile_name, '/', -1) + 1)
      INTO lv_xml_file
      FROM fnd_concurrent_requests
     WHERE request_id = fnd_global.conc_request_id;
  
    lv_step := 'MAIN 010 : WRITETOFILE : ' || lv_xml_file;
    log_msg(lv_step);
  
    sys.xmldom.writetofile(doc,
                           lv_directory || '/x' ||
                           fnd_global.conc_request_id || '.tmp',
                           'UTF-8');
    sys.xmldom.freedocument(doc);
    /*utl_file.frename('DKA_OUT_DIR',
                     '/x' || fnd_global.conc_request_id || '.tmp',
                     'DKA_OUTPUT',
                     lv_xml_file,
                     TRUE);*/
                     
                     
    /*fnd_file.GET_NAMES(P_LOG => l_log,
                    P_OUT => l_out);
    log_msg(l_out);*/
    --utl_file.fremove('DKA_OUT_DIR', '/x'||Fnd_global.conc_request_id||'.tmp');

    
    lv_step := 'MAIN 010 : LECTURE ';
    log_msg(lv_step);
    
    f := UTL_FILE.FOPEN('DKA_OUT_DIR', 'x' || fnd_global.conc_request_id || '.tmp','R');

    IF UTL_FILE.IS_OPEN(f) THEN
    LOOP

        BEGIN

          UTL_FILE.GET_LINE(f,lfile);

          fnd_file.PUT_LINE(fnd_file.OUTPUT, lfile);
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
          EXIT;
        END;


      END LOOP;
      UTL_FILE.FCLOSE(f);
    END IF;
    utl_file.fremove('DKA_OUT_DIR', 'x'||Fnd_global.conc_request_id||'.tmp');
  
    lv_step := 'MAIN 999 : FIN';
    log_msg(lv_step);
    
	
  
  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf := 'Erreur procedure CONSTRUCTION_XML :' || lv_step ||
                   chr(10) || SQLERRM;
      log_msg(pv_errbuf);
      pn_retcode := 2;
  END main;

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : send_mail
  --  Description   : Procédure d'envoi de mail
  --
  --  PARAMETRES    :
  --
  --  VALEUR RETOURNEE :
  --      pv_errbuf  varchar2
  --      pv_status  varchar2
  -------------------------------------------------------------------------------------------------------------------
  PROCEDURE send_mail(pv_errbuf IN OUT VARCHAR2, pn_retcode OUT NUMBER) IS
  
    CURSOR cur_req IS
      SELECT MAX(request_id) req_id
        FROM fnd_concurrent_requests fcr, fnd_concurrent_programs fcp
       WHERE fcp.concurrent_program_name = 'DKA_RAPCTRLPRLVT'
         AND fcp.concurrent_program_id = fcr.concurrent_program_id;
  
    CURSOR cur_jdv IS
      SELECT ffv.flex_value, ffv.attribute1, ffv.attribute2
        FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
       WHERE ffvs.flex_value_set_name = 'DKA_ENVOI_MAIL_RB'
         AND ffvs.flex_value_set_id = ffv.flex_value_set_id
         AND ffv.enabled_flag = 'Y'
         AND SYSDATE BETWEEN nvl(start_date_active, SYSDATE) AND
             nvl(end_date_active, SYSDATE);
  
    ln_request_id   NUMBER;
    lv_expediteur   VARCHAR2(4000);
    lv_destinataire VARCHAR2(4000);
    lv_objet        VARCHAR2(4000);
    lv_corps        VARCHAR2(4000);
    lv_cc           VARCHAR2(4000);
    lv_filename     VARCHAR2(4000);
    l_step          VARCHAR2(100);
    cn_tempo                          CONSTANT NUMBER         := 20;
    vv_rphase                         VARCHAR2 (80);
    vv_rrphase                        VARCHAR2 (80);
    vv_rstatus                        VARCHAR2 (80);
    vv_rrstatus                       VARCHAR2 (80);
    vv_dphase                         VARCHAR2 (30);
    vv_ddphase                        VARCHAR2 (30);
    vv_dstatus                        VARCHAR2 (30);
    vv_ddstatus                       VARCHAR2 (30);
    vv_message                        VARCHAR2 (240);
  
  BEGIN
  
    FOR rec_req IN cur_req LOOP
    
      FOR rec_jdv IN cur_jdv LOOP
      
        -- Destinataire du mail
        IF rec_jdv.attribute1 = 'Y' THEN
          IF lv_destinataire IS NULL THEN
            lv_destinataire := rec_jdv.flex_value || ';';
          ELSE
            lv_destinataire := lv_destinataire || rec_jdv.flex_value || ';';
          END IF;
        END IF;
      
        -- Copie du mail
        IF rec_jdv.attribute2 = 'Y' THEN
          IF lv_cc IS NULL THEN
            lv_cc := rec_jdv.flex_value;
          ELSE
            lv_cc := lv_cc || ';' || rec_jdv.flex_value;
          END IF;
        END IF;
      END LOOP;
    
      fnd_message.set_name('DKA', 'DKA_RAPCTRLPRLVT_I0001');
      lv_expediteur := fnd_message.get;
    
      fnd_message.set_name('DKA', 'DKA_RAPCTRLPRLVT_I0002');
      lv_objet := fnd_message.get;
    
      fnd_message.set_name('DKA', 'DKA_RAPCTRLPRLVT_I0003');
      fnd_message.set_token('DATE', to_char(SYSDATE, 'DD/MM/RRRR'));
      lv_corps := fnd_message.get;
    
      fnd_message.set_name('DKA', 'DKA_RAPCTRLPRLVT_I0004');
      lv_filename := rec_req.req_id || '_' || fnd_message.get || '_' ||
                     to_char(SYSDATE, 'RRRRMMDD') || '.xls';
    
      DELETE FROM dka.dka_mail_param WHERE req_id = rec_req.req_id;
    
      INSERT INTO dka.dka_mail_param
        (expediteur,
         destinataire,
         objet,
         corps,
         req_id,
         attachement,
         filename,
         cc_mail)
      VALUES
        (lv_expediteur,
         lv_destinataire,
         lv_objet,
         lv_corps,
         rec_req.req_id,
         'O',
         lv_filename,
         lv_cc);
    
      ln_request_id := fnd_request.submit_request('DKA', --APPL
                                                  'DKA_MAIL', --PROG
                                                  NULL, --PROGRAM_NAME
                                                  NULL, --START
                                                  FALSE, --SUB_REQUEST
                                                  rec_req.req_id);
      COMMIT;
      dka_tools_pkg.put_debug_message('send_mail : Lancement du traitement : ' ||
                                      ln_request_id);
      dbms_output.put_line('send_mail : Lancement du traitement : ' ||
                           ln_request_id);
    
      IF ln_request_id = 0 THEN
        dka_tools_pkg.put_debug_message('Impossible de lancer le traitement ');
        dka_tools_pkg.put_debug_message(fnd_message.get);
        dbms_output.put_line('Impossible de lancer le traitement ');
        dbms_output.put_line(fnd_message.get);
        pn_retcode := 2;
      ELSE
        l_step := 'Le Traitement DKA_MAIL N° ' ||
                  ln_request_id || ' a été bien lancé';
                  
        dka_tools_pkg.put_log_message(l_step);
      
        IF NOT fnd_concurrent.wait_for_request(ln_request_id,
                                               cn_tempo,
                                               0,
                                               vv_rphase,
                                               vv_rstatus,
                                               vv_dphase,
                                               vv_dstatus,
                                               vv_message) THEN
          pn_retcode := 2;
        ELSE
          IF vv_dstatus = 'WARNING' THEN
          
            l_step := chr(10) || '>>> Traitement terminé en Warning ';
            dka_tools_pkg.put_log_message(l_step);
            pn_retcode := 1;
          ELSIF vv_dstatus != 'NORMAL' THEN
          
            l_step := chr(10) || '>>> Traitement terminé en Erreur ';
            dka_tools_pkg.put_log_message(l_step);
            pn_retcode := 2;
          END IF;
        END IF;
      END IF;
    
    END LOOP;
  
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
  END send_mail;

END dka_rapctrlprlvt_pkg;
/
SHOW ERRORS;

EXIT
