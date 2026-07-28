create or replace PACKAGE dka_iapfacxgs_pkg
AS
--------------------------------------------------------------------------------
-- $Id: DKA_IAPFACXGS_PKG.pks 1969 2009-06-09 13:35:05Z CORP\pcailluy $
-- Capgemini
-- Projet           : VEOLIA Oracle Applications
-- Nom              : DKA_IAPFACXGS_PKG.pks
-- Description      : Spécification du package dka_iapfacxgs_pkg
-- Auteur           : Thomas Bonduaeux
-- Date de création : 27/02/2008
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------
-- 30/09/2009 FMI ajout de la procédure "populate_xgs_tables" pour l'insertion des
--                données de la table DKA_IAPFACXGS_TMP dans les tables de l'application
-- ---------- --- --------------------------------------------------------------
-- 08/09/2011 JB  artf770438: EDIFIS_Interface_XEROX_Prise_en_compte_de_ZCI
--
-- ---------- --- --------------------------------------------------------------
--- 2016/09/02 JJA Portage Helios R12
--- 2020/11/17 MTIA EDB264 - Mise à jour spécifique
--------------------------------------------------------------------------------

/*
 * Récupere l'identifiant du bon de réception associé a l'identifiant de la
 * ligne de commande passée en parametre.
 *
 * Retourne : NULL si la ligne de commande n'est pas associée a un bon de
 *              réception ou si elle est associée a plusieurs bons de réception
 *            Sinon l'identifiant du bon de réception
 */
FUNCTION get_id_br(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
RETURN rcv_shipment_headers.shipment_header_id%TYPE;
PRAGMA RESTRICT_REFERENCES (get_id_br, WNDS, WNPS, RNPS);


/*
 * Récupere le numéro du bon de réception associé a l'identifiant de la
 * ligne de commande passée en parametre.
 *
 * Retourne : NULL si la ligne de commande n'est pas associée a un bon de
 *              réception ou si elle est associée a plusieurs bons de réception
 *            Sinon le numéro du bon de réception
 */
FUNCTION get_num_br(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
RETURN rcv_shipment_headers.receipt_num%TYPE;
PRAGMA RESTRICT_REFERENCES (get_num_br, WNDS, WNPS, RNPS);


/*
 * Récupere le packing slip du bon de réception associé a l'identifiant de la
 * ligne de commande passée en parametre.
 *
 * Retourne : NULL si la ligne de commande n'est pas associée a un bon de
 *              réception ou si elle est associée a plusieurs bons de réception
 *            Sinon le packing slip du bon de réception
 */
FUNCTION get_packing_slip(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
RETURN rcv_shipment_headers.packing_slip%TYPE;
PRAGMA RESTRICT_REFERENCES (get_packing_slip, WNDS, WNPS, RNPS);


/*
 * Récupere le numéro de ligne du bon de réception associé a l'identifiant de la
 * ligne de commande passée en parametre.
 *
 * Retourne : NULL si la ligne de commande n'est pas associée a un bon de
 *              réception ou si elle est associée a plusieurs bons de réception
 *            Sinon le numéro de ligne du bon de réception
 */
FUNCTION get_num_ligne_br(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
RETURN rcv_shipment_lines.line_num%TYPE;
PRAGMA RESTRICT_REFERENCES (get_num_ligne_br, WNDS, WNPS, RNPS);


/*
 * Vérifie que la transaction est de type refac.
 *
 * Parametre :
 *  pv_transaction_type   le type de transaction
 *
 * Valeur de retour :
 *  'REFAC' si la transaction est soumis a refac,
 *  'OTHER' sinon
 */
FUNCTION transaction_type(pv_transaction_type IN VARCHAR2)
RETURN VARCHAR2;


/*
 * Point d'entrée du traitement.
 * Lance la procedure d'import pour chaque responsabilite detectee dans la
 * table d'interface.
 */
PROCEDURE import(
  pv_errbuf   OUT VARCHAR2,
  pn_retcode  OUT NUMBER);


/*
 * Vérifie qu'il n'y a pas de faux doublons
 */
PROCEDURE control_double (  pn_org_id IN VARCHAR2,
                            pv_errbuf   OUT VARCHAR2,
                            pn_retcode  OUT NUMBER);


PROCEDURE populate_xgs_tables( pv_errbuf   OUT VARCHAR2,
                               pn_retcode  OUT NUMBER);

PROCEDURE populate_zci_tables( pv_errbuf   OUT VARCHAR2,
                               pn_retcode  OUT NUMBER);

PROCEDURE populate_dsp_tables(pv_errbuf  OUT VARCHAR2,
                                pn_retcode OUT NUMBER);
END dka_iapfacxgs_pkg;

create or replace PACKAGE BODY                dka_iapfacxgs_pkg AS
  --------------------------------------------------------------------------------mont_rappro
  -- Description      : Corps du package dka_iapfacxgs_pkg
  -- Auteur           : Thomas Bonduaeux
  -- Date de creation : 27/02/2008
  -- Commentaires     : A executer sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  --- Historique
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------
  --- 2016/09/02 JJA Portage Helios R12
  --------------------------------------------------------------------------------
  --- 2017/04/18 OBE artf2141124 : INT047 - Recherche de la categorie - defect Bout_en_Bout_Helios_Ref #575
  --------------------------------------------------------------------------------
  --- 2017/05/09 NBO artf2150386 - INT047 - Factures aÃ?Â aÃ?Â  recycler - Defect Bout_en_Bout_Helios_Ref #648Ac
  --- 30/05/2017 YWA artf2163145
  --- 05/02/2018 MEG artf2356939 : Correction INT047 - Interface des factures numerisees Xerox
  --- 14/02/2018 MEG artf2374976 : Correction INT047 - Interface des factures numerisees Xerox - Ecart minime
  --- 28/02/2018 NBO artf2404586 : Correction INT047 - Interface des factures numerisees Xerox - Ecart minime
  --- 21/03/2018 OBE artf2438563 : INT047 - Interface XEROX - Non rapprochement des commandes cas de refac
  --- 04/04/2018 NBO artf2483384 : INC0204462 - INT047 - Interface XEROx
  --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
  --- 2018/09/03 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
  --- 2019/01/31 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
  --- 2019/08/30 SEL artf07147602 : EDB223 - Rapprochement des commandes
  --- 2019/08/30 SEL artf07176478 : EDB235 - TVA IC
  --- 2020/02/18 MTIA : INC0402570 : Initialisation variable pour eviter division aÃ?Â aÃ?Â  zero
  --- 2020/04/30 AAM  artf07219745 : enlever le critore unite operationnelle lors du controle de doublon
  --- 2020/07/15 MTIA INC0319253 : Quickmatch sur tache projet ferme
  --  2020/08/15 MTIA EDB260 Gestion de la TVA sur immobilisation
  --- 2020/09/22 MTIA EDB260b - Gestion quickmatch sur tache fermee
  --- 2020/10/21 MTIA Correction sur Ã?Â©cart sur ligne avec projet de refacturation
  --- 2020/11/04 MTIA EDB264 - Gestion des factures DSP (IVALUA)
  --- 2021/07/09 CDE EDB264 - Ajout lancement de la fonction pour la TVA autoliquidee pour DSP
  --- 2022/03/24 SELO EDB235B
  --- 2022/10/25 IBA  EDB350
  --- 2022/10/28 IBA  EDB349
  --- 2023/07/21 IBA  EDB355  INTERFACE DES FACTURES XEROX Ã¢Â¿Â¿ GESTION DES CODES TVA Ã¢Â¿Â¿ICÃ¢Â¿Â¿ Ã¢Â¿Â¿ EVOLUTION REGLE DE GESTION CAS 2
  --- 2023/03/29 BNZ  EDB376  Rapprochement automatique de lÂ¿interface Xerox
  --- 2024/12/12 KHH  EDB396 - Projet SSTR IVALUA - Evolution sur l'interface XEROX pour prise en compte du Type de Commande SSTR IVALUA
  --- 2025/03/04 KHH  KAFI-1039 ;Recette KAFI-838 - Intégration XEROX  : si Cd SSTR le type est de 0003_SSTRT.
  --------------------------------------------------------------------------------

  /* constantes privees */
  cv_appl_short_name CONSTANT fnd_application.application_short_name%TYPE := 'SQLGL';
  cv_flex_code       CONSTANT fnd_id_flex_segments.id_flex_code%TYPE := 'GL#';
  cv_program_code    CONSTANT dka_parameters.program_code%TYPE := 'IAPFACXGS';
  cv_parameter_name  CONSTANT dka_parameters.parameter_name%TYPE := 'GLOBAL_ATTRIBUTE_CATEGORY';
  cv_error_message   CONSTANT VARCHAR2(100) := ' (voir le fichier journal pour ' ||
                                               'plus d''informations)';
  cn_round           CONSTANT NUMBER := 2;
  cv_resp_key        CONSTANT VARCHAR2(100) := '_AP_ADMINISTRATEUR';

  /* variables globales */
  --gn_chart_of_accounts_id       gl_sets_of_books.chart_of_accounts_id%TYPE;
  gv_global_attribute_category ap_invoices_interface.global_attribute_category%TYPE;
  gn_org_id                    hr_all_organization_units.organization_id%TYPE;
  gv_org_name                  hr_all_organization_units.name%TYPE;
  gn_ledger_id                 gl_ledgers.ledger_id%TYPE;
  gv_code                      fnd_flex_values.flex_value%TYPE;
  gn_term_id                   ap_terms.term_id%TYPE;

  /* exceptions */
  e_generic EXCEPTION;
  e_no_data EXCEPTION;

  /*
  * Initialise la variable gv_code.
  */
  PROCEDURE init_gv_code IS
  BEGIN
    SELECT ffv.flex_value
      INTO gv_code
      FROM fnd_flex_value_sets ffvs, fnd_flex_values ffv
     WHERE ffvs.flex_value_set_name = 'DKA_CODES_XEROX'
       AND ffvs.flex_value_set_id = ffv.flex_value_set_id
       AND attribute2 = 'Y';
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                    ' - Erreur lors de la recuperation du code de rejet parametre');
      RAISE e_generic;
  END init_gv_code;

  /*
  * Initialise la variable gv_global_attribute_category.
  */
  PROCEDURE init_global_attribute_category IS
  BEGIN
    SELECT dp.varchar2_value
      INTO gv_global_attribute_category
      FROM dka_parameters dp
     WHERE dp.program_code = cv_program_code
       AND dp.parameter_name = cv_parameter_name;
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                    ' - Erreur lors de la recuperation du ' ||
                                    'parametre ' || cv_parameter_name ||
                                    ' pour le programme ' ||
                                    cv_program_code);
      RAISE e_generic;
  END init_global_attribute_category;

  /*
  * Initialise la variable gn_term_id.
  */
  PROCEDURE init_gn_term_id IS
  BEGIN
    SELECT at.term_id
      INTO gn_term_id
      FROM ap_terms at
     WHERE at.name = 'Comptant'
       AND at.enabled_flag = 'Y'
       AND SYSDATE BETWEEN at.start_date_active AND
           nvl(at.end_date_active, SYSDATE);
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                    ' - Erreur lors de la recuperation d''id ' ||
                                    'de la condition de paiement Comptant');
      RAISE e_generic;
  END init_gn_term_id;

  /*
  * Verifie que la transaction est de type refac.
  *
  * Parametre :
  *  pv_transaction_type   le type de transaction
  *
  * Valeur de retour :
  *  'REFAC' si la transaction est soumis a refac,
  *  'OTHER' sinon
  */
  FUNCTION transaction_type(pv_transaction_type IN VARCHAR2) RETURN VARCHAR2 IS
  BEGIN
    IF dka_sarrefac_pkg.is_transaction_type_refac(pv_transaction_type) THEN
      RETURN 'REFAC';
    ELSE
      RETURN 'OTHER';
    END IF;
  END;

--< BNZ EDB376
/*
  * Verifie nomber des lignes.
  *
  * Parametre :
  *  no_commande   numero de la commande
  *
  * Valeur de retour :
  *  1 si il y a une line ,
  *  0 +line
  */

  FUNCTION Number_lines(no_commande IN VARCHAR2) RETURN number IS
    nb_line number := 0;
  BEGIN

  select count(1) into nb_line
    from po_headers_all A
    where segment1 = no_commande
      and 1 = (select count(*)
                      from po_lines_all B
            where A.PO_HEADER_ID = B.PO_HEADER_ID);
    IF nb_line = 1 THEN
      RETURN 1;
    ELSE
      RETURN 0;
    END IF;
  END;
--> EDB376

  /*
  * Recupere des informations d'entete et de ligne de reception pour un
  * po_line_id donne.
  *
  * Si le po_line_id n'est present dans aucune ligne de reception ou s'il est
  * present dans plusieurs lignes de reception, retourne NULL dans toutes les
  * variables de sortie.
  */
  PROCEDURE shipments(pn_po_line_id         IN rcv_shipment_lines.po_line_id%TYPE,
                      pn_shipment_header_id OUT NOCOPY rcv_shipment_headers.shipment_header_id%TYPE,
                      pv_receipt_num        OUT NOCOPY rcv_shipment_headers.receipt_num%TYPE,
                      pv_packing_slip       OUT NOCOPY rcv_shipment_headers.packing_slip%TYPE,
                      pn_line_num           OUT NOCOPY rcv_shipment_lines.line_num%TYPE) IS
  BEGIN
    SELECT rsh.shipment_header_id,
           rsh.receipt_num,
           rsh.packing_slip,
           rsl.line_num
      INTO pn_shipment_header_id,
           pv_receipt_num,
           pv_packing_slip,
           pn_line_num
      FROM rcv_shipment_headers rsh, rcv_shipment_lines rsl
     WHERE rsh.shipment_header_id = rsl.shipment_header_id
       AND rsl.po_line_id = pn_po_line_id;
  EXCEPTION
    WHEN no_data_found OR too_many_rows THEN
      pn_shipment_header_id := NULL;
      pv_receipt_num        := NULL;
      pv_packing_slip       := NULL;
      pn_line_num           := NULL;
  END shipments;

  /*
  * Recupere l'identifiant du bon de reception associe a l'identifiant de la
  * ligne de commande passee en parametre.
  *
  * Retourne : NULL si la ligne de commande n'est pas associee a un bon de
  *              reception ou si elle est associee a plusieurs bons de reception
  *            Sinon l'identifiant du bon de reception
  */
  FUNCTION get_id_br(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
    RETURN rcv_shipment_headers.shipment_header_id%TYPE IS
    vn_shipment_header_id rcv_shipment_headers.shipment_header_id%TYPE;
    vv_receipt_num        rcv_shipment_headers.receipt_num%TYPE;
    vv_packing_slip       rcv_shipment_headers.packing_slip%TYPE;
    vn_line_num           rcv_shipment_lines.line_num%TYPE;
  BEGIN
    shipments(pn_po_line_id,
              vn_shipment_header_id,
              vv_receipt_num,
              vv_packing_slip,
              vn_line_num);
    RETURN vn_shipment_header_id;
  END get_id_br;

  /*
  * Recupere le numero du bon de reception associe a l'identifiant de la
  * ligne de commande passee en parametre.
  *
  * Retourne : NULL si la ligne de commande n'est pas associee a un bon de
  *              reception ou si elle est associee a plusieurs bons de reception
  *            Sinon le numero du bon de reception
  */
  FUNCTION get_num_br(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
    RETURN rcv_shipment_headers.receipt_num%TYPE IS
    vn_shipment_header_id rcv_shipment_headers.shipment_header_id%TYPE;
    vv_receipt_num        rcv_shipment_headers.receipt_num%TYPE;
    vv_packing_slip       rcv_shipment_headers.packing_slip%TYPE;
    vn_line_num           rcv_shipment_lines.line_num%TYPE;
  BEGIN
    shipments(pn_po_line_id,
              vn_shipment_header_id,
              vv_receipt_num,
              vv_packing_slip,
              vn_line_num);
    RETURN vv_receipt_num;
  END get_num_br;

  /*
  * Recupere le packing slip du bon de reception associe a l'identifiant de la
  * ligne de commande passee en parametre.
  *
  * Retourne : NULL si la ligne de commande n'est pas associee a un bon de
  *              reception ou si elle est associee a plusieurs bons de reception
  *            Sinon le packing slip du bon de reception
  */
  FUNCTION get_packing_slip(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
    RETURN rcv_shipment_headers.packing_slip%TYPE IS
    vn_shipment_header_id rcv_shipment_headers.shipment_header_id%TYPE;
    vv_receipt_num        rcv_shipment_headers.receipt_num%TYPE;
    vv_packing_slip       rcv_shipment_headers.packing_slip%TYPE;
    vn_line_num           rcv_shipment_lines.line_num%TYPE;
  BEGIN
    shipments(pn_po_line_id,
              vn_shipment_header_id,
              vv_receipt_num,
              vv_packing_slip,
              vn_line_num);
    RETURN vv_packing_slip;
  END get_packing_slip;

  /*
  * Recupere le numero de ligne du bon de reception associe a l'identifiant de la
  * ligne de commande passee en parametre.
  *
  * Retourne : NULL si la ligne de commande n'est pas associee a un bon de
  *              reception ou si elle est associee a plusieurs bons de reception
  *            Sinon le numero de ligne du bon de reception
  */
  FUNCTION get_num_ligne_br(pn_po_line_id IN rcv_shipment_lines.po_line_id%TYPE)
    RETURN rcv_shipment_lines.line_num%TYPE IS
    vn_shipment_header_id rcv_shipment_headers.shipment_header_id%TYPE;
    vv_receipt_num        rcv_shipment_headers.receipt_num%TYPE;
    vv_packing_slip       rcv_shipment_headers.packing_slip%TYPE;
    vn_line_num           rcv_shipment_lines.line_num%TYPE;
  BEGIN
    shipments(pn_po_line_id,
              vn_shipment_header_id,
              vv_receipt_num,
              vv_packing_slip,
              vn_line_num);
    RETURN vn_line_num;
  END get_num_ligne_br;

  /*
  * Calcule le code tva.
  *
  * Parametres :
  *  pv_type_tva       type TVA
  *  pn_taux_tva       taux TVA
  */
  FUNCTION get_code_tva(pv_type_tva IN dka_iapfacxgs_interface.type_tva%TYPE,
                        pn_taux_tva IN dka_iapfacxgs_interface.taux_tva%TYPE)
    RETURN ap_tax_codes_all.name%TYPE IS
    vv_code_tva ap_tax_codes_all.name%TYPE;
  BEGIN
    vv_code_tva := 'DED_';
    --IF pv_type_tva = 'IC' THEN
    -- vv_code_tva := vv_code_tva || 'INTRACOM_';
    -- ELSE
    vv_code_tva := vv_code_tva || substr(pn_taux_tva, 1, 2) || '.' ||
                   substr(pn_taux_tva, -2, 2);
    IF pv_type_tva = 'EN' THEN
      vv_code_tva := vv_code_tva || 'E';
    ELSIF nvl(pv_type_tva, 'DE') IN ('DE', 'EX', 'IC') THEN
      vv_code_tva := vv_code_tva || 'D';
    END IF;
    -- END IF;
    RETURN vv_code_tva;
  END get_code_tva;

  /*
  * Verifie si l'ensemble de codes rejets passes contient au moins un code rejet
  * de type 2, 3 ou 4.
  *
  * Parametres :
  *  pv_code_rejet         codes rejet concatenes par un '.'
  *  pb_code_rejet2_found  vrai si au moins un des codes rejet concerne une
  *                        anomalie multi commande
  *  pb_code_rejet3_found  vrai si au moins un des codes rejet concerne une
  *                        anomalie fournisseur
  *  pb_code_rejet4_found  vrai si au moins un des codes rejet concerne une
  *                        anomalie multi BL
  */
  PROCEDURE check_code_rejet(pv_code_rejet        IN dka_iapfacxgs_interface.code_rejet%TYPE,
                             pb_code_rejet1_found OUT NOCOPY BOOLEAN,
                             pb_code_rejet2_found OUT NOCOPY BOOLEAN,
                             pb_code_rejet3_found OUT NOCOPY BOOLEAN,
                             pb_code_rejet4_found OUT NOCOPY BOOLEAN) IS
    cv_separator CONSTANT CHAR := '.';
    vn_length NUMBER;
    vv_char   CHAR;
    vv_buf    fnd_flex_values.flex_value%TYPE := NULL;
    vn_value  NUMBER;
    vb_try    BOOLEAN := FALSE;
  BEGIN
    pb_code_rejet1_found := FALSE;
    pb_code_rejet2_found := FALSE;
    pb_code_rejet3_found := FALSE;
    pb_code_rejet4_found := FALSE;

    vn_length := length(pv_code_rejet);

    IF vn_length IS NULL THEN
      RETURN;
    END IF;

    -- parser
    FOR i IN 1 .. vn_length LOOP
      vv_char := substr(pv_code_rejet, i, 1);

      IF vv_char = cv_separator THEN
        vb_try := TRUE;
      ELSIF i = vn_length THEN
        vv_buf := vv_buf || vv_char;
        vb_try := TRUE;
      END IF;

      IF vb_try THEN
        if vv_buf is not null then
          begin
            select ffv.attribute1
              into vn_value
              from fnd_flex_value_sets ffvs, fnd_flex_values ffv
             where ffvs.flex_value_set_id = ffv.flex_value_set_id
               and ffvs.flex_value_set_name = 'DKA_CODES_XEROX'
               and ffv.flex_value = vv_buf;

            case vn_value
              WHEN '1' THEN
                pb_code_rejet1_found := TRUE;
              when '2' then
                pb_code_rejet2_found := true;
              when '3' then
                pb_code_rejet3_found := true;
              when '4' then
                pb_code_rejet4_found := true;
              else
                null;
            end case;
            -- si chaque code rejet a deja ete trouve la procedure s'arrete la
            if pb_code_rejet1_found AND pb_code_rejet2_found and
               pb_code_rejet3_found and pb_code_rejet4_found then
              return;
            end if;
          exception
            when no_data_found then
              null;
            WHEN OTHERS THEN
              dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                            ' - Erreur ' || SQLERRM);
              dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                            ' - Erreur lors de la recuperation ' ||
                                            'des codes rejets');
              RAISE e_generic;
          end;
          vv_buf := null;
        end if;
        vb_try := false;
      else
        vv_buf := vv_buf || vv_char;
      end if;
    end loop;
  end check_code_rejet;

  /*
  * Ajoute le "faux" code rejet 99 au code rejet existant (M4)
  *
  * Parametres :
  *  pv_code_rejet         codes rejet concatenes par un '.'
  *
  */
  PROCEDURE ajout_code_99(pv_code_rejet IN OUT dka_iapfacxgs_interface.code_rejet%TYPE) IS
    vn_length NUMBER;
    vv_code   fnd_flex_values.flex_value%TYPE := gv_code;
  BEGIN

    vn_length := length(pv_code_rejet);

    -- si le code rejet etait vide alors maintenant il doit contenir 99
    IF vn_length IS NULL THEN
      pv_code_rejet := vv_code;
      RETURN;
    END IF;

    IF instr(pv_code_rejet, vv_code) = 0 THEN
      pv_code_rejet := pv_code_rejet || '.' || vv_code;
    END IF;

  END ajout_code_99;

  /*
  * Supprime les lignes traitees de la table d'interface
  *
  * Retourne : le nombre de lignes supprimees
  */
  FUNCTION delete_processed_lines RETURN PLS_INTEGER IS
  BEGIN
    DELETE FROM dka_iapfacxgs_interface
     WHERE code_region || code_societe =
           (SELECT description
              FROM dka_organisation_v
             WHERE value = gn_org_id)
       AND flag_trt = 1;
    RETURN SQL%ROWCOUNT;
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                    ' - Erreur lors de la suppression ' ||
                                    'des lignes traitees de la table d''interface');
      RAISE e_generic;
  END delete_processed_lines;

  PROCEDURE reporte_erreur(vv_row_id rowid, vv_erreur_log varchar2) IS
    PRAGMA AUTONOMOUS_TRANSACTION;
  BEGIN
    BEGIN

      -- dka_Tools_Pkg.put_log_message('reporte_erreur : rowid = ' ||vv_row_id || 'vv_erreur_log =' || vv_erreur_log );

      update dka_iapfacxgs_reporting_all
         set --STATUT_INTERFACE  = 'KO',
             DESCRIPTION_ANO_INTERFACE = substr(vv_erreur_log, 1, 260),
             date_traitement           = sysdate,
             org_id                    = gn_org_id
       where (type, code_societe, code_division, code_region, type_piece,
              num_fact, mht_devise, date_numerisation, batchno, batchidx,
              nvl(code_frs, '#VIDE#'), nvl(site_frs, '#VIDE#')) =
             (select type,
                     code_societe,
                     code_division,
                     code_region,
                     type_piece,
                     num_fact,
                     mht_devise,
                     date_numerisation,
                     batchno,
                     batchidx,
                     nvl(code_frs, '#VIDE#'),
                     nvl(site_frs, '#VIDE#')
                from dka_iapfacxgs_interface
               where rowid = vv_row_id);

      commit;
    EXCEPTION
      WHEN OTHERS THEN
        dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                      ' - Erreur ' || SQLERRM);
        dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                      ' - Erreur lors du report d''une erreur  dans dka_iapfacxgs_reporting_all');
        RAISE e_generic;
    END;
  END reporte_erreur;

  /*
  * Insere une ligne dans la table ap_invoices_all.
  *
  * Parametres : valeurs des differents champs
  *
  * Exception : e_generic en cas d'erreur
  */
  FUNCTION insert_header(pv_invoice_num                IN ap_invoices_interface.invoice_num%TYPE,
                         pv_invoice_type_lookup_code   IN ap_invoices_interface.invoice_type_lookup_code%TYPE,
                         pd_invoice_date               IN ap_invoices_interface.invoice_date%TYPE,
                         pv_group_id                   IN ap_invoices_interface.group_id%TYPE,
                         pn_org_id                     IN ap_invoices_interface.org_id%TYPE,
                         pd_gl_date                    IN ap_invoices_interface.gl_date%TYPE,
                         pv_vendor_num                 IN ap_invoices_interface.vendor_num%TYPE,
                         pn_vendor_site_id             IN ap_invoices_interface.vendor_site_id%TYPE,
                         pv_vendor_site_code           IN ap_invoices_interface.vendor_site_code%TYPE,
                         pn_invoice_amount             IN ap_invoices_interface.invoice_amount%TYPE,
                         pv_invoice_currency_code      IN ap_invoices_interface.invoice_currency_code%TYPE,
                         pn_terms_id                   IN ap_invoices_interface.terms_id%TYPE,
                         pv_attribute1                 IN ap_invoices_interface.attribute1%TYPE,
                         pv_attribute3                 IN ap_invoices_interface.attribute3%TYPE,
                         pv_attribute8                 IN ap_invoices_interface.attribute8%TYPE,
                         pv_attribute9                 IN ap_invoices_interface.attribute9%TYPE,
                         pv_attribute10                IN ap_invoices_interface.attribute10%TYPE,
                         pv_attribute13                IN ap_invoices_interface.attribute13%TYPE,
                         pv_attribute14                IN ap_invoices_interface.attribute14%TYPE,
                         pv_attribute15                IN ap_invoices_interface.attribute15%TYPE,
                         pv_doc_category_code          IN ap_invoices_interface.doc_category_code%TYPE,
                         pn_accts_pay_ccid             IN ap_invoices_interface.accts_pay_code_combination_id%TYPE,
                         pv_pay_group_lookup_code      IN ap_invoices_interface.pay_group_lookup_code%TYPE,
                         pv_payment_method_lookup_code IN ap_invoices_interface.payment_method_lookup_code%TYPE,
                         pv_description                IN ap_invoices_interface.description%TYPE,
                         pv_global_attribute_category  IN ap_invoices_interface.global_attribute_category%TYPE,
                         pv_global_attribute1          IN ap_invoices_interface.global_attribute1%TYPE,
                         pd_terms_date                 IN ap_invoices_interface.terms_date%TYPE)
    RETURN ap_invoices_interface.invoice_id%TYPE IS
    vn_invoice_id ap_invoices_all.invoice_id%TYPE;
  BEGIN
    INSERT INTO ap_invoices_interface
      (INVOICE_ID,
       INVOICE_NUM,
       INVOICE_TYPE_LOOKUP_CODE,
       INVOICE_DATE,
       PO_NUMBER,
       VENDOR_ID,
       VENDOR_NUM,
       VENDOR_NAME,
       VENDOR_SITE_ID,
       VENDOR_SITE_CODE,
       INVOICE_AMOUNT,
       INVOICE_CURRENCY_CODE,
       EXCHANGE_RATE,
       EXCHANGE_RATE_TYPE,
       EXCHANGE_DATE,
       TERMS_ID,
       TERMS_NAME,
       DESCRIPTION,
       AWT_GROUP_ID,
       AWT_GROUP_NAME,
       LAST_UPDATE_DATE,
       LAST_UPDATED_BY,
       LAST_UPDATE_LOGIN,
       CREATION_DATE,
       CREATED_BY,
       ATTRIBUTE_CATEGORY,
       ATTRIBUTE1,
       ATTRIBUTE2,
       ATTRIBUTE3,
       ATTRIBUTE4,
       ATTRIBUTE5,
       ATTRIBUTE6,
       ATTRIBUTE7,
       ATTRIBUTE8,
       ATTRIBUTE9,
       ATTRIBUTE10,
       ATTRIBUTE11,
       ATTRIBUTE12,
       ATTRIBUTE13,
       ATTRIBUTE14,
       ATTRIBUTE15,
       GLOBAL_ATTRIBUTE_CATEGORY,
       GLOBAL_ATTRIBUTE1,
       GLOBAL_ATTRIBUTE2,
       GLOBAL_ATTRIBUTE3,
       GLOBAL_ATTRIBUTE4,
       GLOBAL_ATTRIBUTE5,
       GLOBAL_ATTRIBUTE6,
       GLOBAL_ATTRIBUTE7,
       GLOBAL_ATTRIBUTE8,
       GLOBAL_ATTRIBUTE9,
       GLOBAL_ATTRIBUTE10,
       GLOBAL_ATTRIBUTE11,
       GLOBAL_ATTRIBUTE12,
       GLOBAL_ATTRIBUTE13,
       GLOBAL_ATTRIBUTE14,
       GLOBAL_ATTRIBUTE15,
       GLOBAL_ATTRIBUTE16,
       GLOBAL_ATTRIBUTE17,
       GLOBAL_ATTRIBUTE18,
       GLOBAL_ATTRIBUTE19,
       GLOBAL_ATTRIBUTE20,
       STATUS,
       SOURCE,
       GROUP_ID,
       REQUEST_ID,
       PAYMENT_CROSS_RATE_TYPE,
       PAYMENT_CROSS_RATE_DATE,
       PAYMENT_CROSS_RATE,
       PAYMENT_CURRENCY_CODE,
       WORKFLOW_FLAG,
       DOC_CATEGORY_CODE,
       VOUCHER_NUM,
       PAYMENT_METHOD_LOOKUP_CODE,
       PAY_GROUP_LOOKUP_CODE,
       GOODS_RECEIVED_DATE,
       INVOICE_RECEIVED_DATE,
       GL_DATE,
       ACCTS_PAY_CODE_COMBINATION_ID,
       USSGL_TRANSACTION_CODE,
       EXCLUSIVE_PAYMENT_FLAG,
       ORG_ID,
       AMOUNT_APPLICABLE_TO_DISCOUNT,
       PREPAY_NUM,
       PREPAY_DIST_NUM,
       PREPAY_APPLY_AMOUNT,
       PREPAY_GL_DATE,
       INVOICE_INCLUDES_PREPAY_FLAG,
       NO_XRATE_BASE_AMOUNT,
       VENDOR_EMAIL_ADDRESS,
       TERMS_DATE,
       REQUESTER_ID,
       SHIP_TO_LOCATION,
       EXTERNAL_DOC_REF,
       PREPAY_LINE_NUM,
       REQUESTER_FIRST_NAME,
       REQUESTER_LAST_NAME,
       APPLICATION_ID,
       PRODUCT_TABLE,
       REFERENCE_KEY1,
       REFERENCE_KEY2,
       REFERENCE_KEY3,
       REFERENCE_KEY4,
       REFERENCE_KEY5,
       APPLY_ADVANCES_FLAG,
       CALC_TAX_DURING_IMPORT_FLAG,
       CONTROL_AMOUNT,
       ADD_TAX_TO_INV_AMT_FLAG,
       TAX_RELATED_INVOICE_ID,
       TAXATION_COUNTRY,
       DOCUMENT_SUB_TYPE,
       SUPPLIER_TAX_INVOICE_NUMBER,
       SUPPLIER_TAX_INVOICE_DATE,
       SUPPLIER_TAX_EXCHANGE_RATE,
       TAX_INVOICE_RECORDING_DATE,
       TAX_INVOICE_INTERNAL_SEQ,
       LEGAL_ENTITY_ID,
       LEGAL_ENTITY_NAME,
       REFERENCE_1,
       REFERENCE_2,
       OPERATING_UNIT,
       BANK_CHARGE_BEARER,
       REMITTANCE_MESSAGE1,
       REMITTANCE_MESSAGE2,
       REMITTANCE_MESSAGE3,
       UNIQUE_REMITTANCE_IDENTIFIER,
       URI_CHECK_DIGIT,
       SETTLEMENT_PRIORITY,
       PAYMENT_REASON_CODE,
       PAYMENT_REASON_COMMENTS,
       PAYMENT_METHOD_CODE,
       DELIVERY_CHANNEL_CODE,
       PAID_ON_BEHALF_EMPLOYEE_ID,
       NET_OF_RETAINAGE_FLAG,
       REQUESTER_EMPLOYEE_NUM,
       CUST_REGISTRATION_CODE,
       CUST_REGISTRATION_NUMBER,
       PARTY_ID,
       PARTY_SITE_ID,
       PAY_PROC_TRXN_TYPE_CODE,
       PAYMENT_FUNCTION,
       PAYMENT_PRIORITY,
       PORT_OF_ENTRY_CODE,
       EXTERNAL_BANK_ACCOUNT_ID,
       ACCTS_PAY_CODE_CONCATENATED,
       PAY_AWT_GROUP_ID,
       PAY_AWT_GROUP_NAME,
       ORIGINAL_INVOICE_AMOUNT,
       DISPUTE_REASON,
       REMIT_TO_SUPPLIER_NAME,
       REMIT_TO_SUPPLIER_ID,
       REMIT_TO_SUPPLIER_SITE,
       REMIT_TO_SUPPLIER_SITE_ID,
       RELATIONSHIP_ID,
       REMIT_TO_SUPPLIER_NUM)
    VALUES
      (ap_invoices_interface_s.NEXTVAL --INVOICE_ID
      ,
       pv_invoice_num --INVOICE_NUM
      ,
       pv_invoice_type_lookup_code --INVOICE_TYPE_LOOKUP_CODE
      ,
       pd_invoice_date --INVOICE_DATE
      ,
       NULL --PO_NUMBER
      ,
       NULL --VENDOR_ID
      ,
       pv_vendor_num --VENDOR_NUM
      ,
       NULL --VENDOR_NAME
      ,
       pn_vendor_site_id --VENDOR_SITE_ID
      ,
       pv_vendor_site_code --VENDOR_SITE_CODE
      ,
       pn_invoice_amount --INVOICE_AMOUNT
      ,
       pv_invoice_currency_code --INVOICE_CURRENCY_CODE
      ,
       NULL --EXCHANGE_RATE
      ,
       NULL --EXCHANGE_RATE_TYPE
      ,
       NULL --EXCHANGE_DATE
      ,
       pn_terms_id --TERMS_ID
      ,
       NULL --TERMS_NAME
      ,
       pv_description --DESCRIPTION
      ,
       NULL --AWT_GROUP_ID
      ,
       NULL --AWT_GROUP_NAME
      ,
       SYSDATE --LAST_UPDATE_DATE
      ,
       fnd_global.user_id --LAST_UPDATED_BY
      ,
       fnd_global.login_id --LAST_UPDATE_LOGIN
      ,
       SYSDATE --CREATION_DATE
      ,
       fnd_global.user_id --CREATED_BY
      ,
       pv_attribute9 --ATTRIBUTE_CATEGORY
      ,
       pv_attribute1 --ATTRIBUTE1
      ,
       NULL --ATTRIBUTE2
      ,
       pv_attribute3 --ATTRIBUTE3
      ,
       NULL --ATTRIBUTE4
      ,
       NULL --ATTRIBUTE5
      ,
       NULL --ATTRIBUTE6
      ,
       NULL --ATTRIBUTE7
      ,
       pv_attribute8 --ATTRIBUTE8
      ,
       pv_attribute9 --ATTRIBUTE9
      ,
       pv_attribute10 --ATTRIBUTE10
      ,
       NULL --ATTRIBUTE11
      ,
       NULL --ATTRIBUTE12
      ,
       pv_attribute13 --ATTRIBUTE13
      ,
       pv_attribute14 --ATTRIBUTE14
      ,
       pv_attribute15 --ATTRIBUTE15
      ,
       pv_global_attribute_category --GLOBAL_ATTRIBUTE_CATEGORY
      ,
       pv_global_attribute1 --GLOBAL_ATTRIBUTE1
      ,
       NULL --GLOBAL_ATTRIBUTE2
      ,
       NULL --GLOBAL_ATTRIBUTE3
      ,
       NULL --GLOBAL_ATTRIBUTE4
      ,
       NULL --GLOBAL_ATTRIBUTE5
      ,
       NULL --GLOBAL_ATTRIBUTE6
      ,
       NULL --GLOBAL_ATTRIBUTE7
      ,
       NULL --GLOBAL_ATTRIBUTE8
      ,
       NULL --GLOBAL_ATTRIBUTE9
      ,
       NULL --GLOBAL_ATTRIBUTE10
      ,
       NULL --GLOBAL_ATTRIBUTE11
      ,
       NULL --GLOBAL_ATTRIBUTE12
      ,
       NULL --GLOBAL_ATTRIBUTE13
      ,
       NULL --GLOBAL_ATTRIBUTE14
      ,
       NULL --GLOBAL_ATTRIBUTE15
      ,
       NULL --GLOBAL_ATTRIBUTE16
      ,
       NULL --GLOBAL_ATTRIBUTE17
      ,
       NULL --GLOBAL_ATTRIBUTE18
      ,
       NULL --GLOBAL_ATTRIBUTE19
      ,
       NULL --GLOBAL_ATTRIBUTE20
      ,
       NULL --STATUS
      ,
       'SCAN_XGS' --SOURCE
      ,
       pv_group_id --GROUP_ID
      ,
       NULL --REQUEST_ID
      ,
       NULL --PAYMENT_CROSS_RATE_TYPE
      ,
       NULL --PAYMENT_CROSS_RATE_DATE
      ,
       NULL --PAYMENT_CROSS_RATE
      ,
       NULL --PAYMENT_CURRENCY_CODE
      ,
       NULL --WORKFLOW_FLAG
      ,
       pv_doc_category_code --DOC_CATEGORY_CODE
      ,
       NULL --VOUCHER_NUM
      ,
       pv_payment_method_lookup_code --PAYMENT_METHOD_LOOKUP_CODE
      ,
       pv_pay_group_lookup_code --PAY_GROUP_LOOKUP_CODE
      ,
       NULL --GOODS_RECEIVED_DATE
      ,
       NULL --INVOICE_RECEIVED_DATE
      ,
       pd_gl_date --GL_DATE
      ,
       pn_accts_pay_ccid --ACCTS_PAY_CODE_COMBINATION_ID
      ,
       NULL --USSGL_TRANSACTION_CODE
      ,
       NULL --EXCLUSIVE_PAYMENT_FLAG
      ,
       pn_org_id --ORG_ID
      ,
       NULL --AMOUNT_APPLICABLE_TO_DISCOUNT
      ,
       NULL --PREPAY_NUM
      ,
       NULL --PREPAY_DIST_NUM
      ,
       NULL --PREPAY_APPLY_AMOUNT
      ,
       NULL --PREPAY_GL_DATE
      ,
       NULL --INVOICE_INCLUDES_PREPAY_FLAG
      ,
       NULL --NO_XRATE_BASE_AMOUNT
      ,
       NULL --VENDOR_EMAIL_ADDRESS
      ,
       pd_terms_date --TERMS_DATE
      ,
       NULL --REQUESTER_ID
      ,
       NULL --SHIP_TO_LOCATION
      ,
       NULL --EXTERNAL_DOC_REF
      ,
       NULL --PREPAY_LINE_NUM
      ,
       NULL --REQUESTER_FIRST_NAME
      ,
       NULL --REQUESTER_LAST_NAME
      ,
       NULL --APPLICATION_ID
      ,
       NULL --PRODUCT_TABLE
      ,
       NULL --REFERENCE_KEY1
      ,
       NULL --REFERENCE_KEY2
      ,
       NULL --REFERENCE_KEY3
      ,
       NULL --REFERENCE_KEY4
      ,
       NULL --REFERENCE_KEY5
      ,
       NULL --APPLY_ADVANCES_FLAG
      ,
       NULL --CALC_TAX_DURING_IMPORT_FLAG
      ,
       NULL --CONTROL_AMOUNT
      ,
       NULL --ADD_TAX_TO_INV_AMT_FLAG
      ,
       NULL --TAX_RELATED_INVOICE_ID
      ,
       NULL --TAXATION_COUNTRY
      ,
       NULL --DOCUMENT_SUB_TYPE
      ,
       NULL --SUPPLIER_TAX_INVOICE_NUMBER
      ,
       NULL --SUPPLIER_TAX_INVOICE_DATE
      ,
       NULL --SUPPLIER_TAX_EXCHANGE_RATE
      ,
       NULL --TAX_INVOICE_RECORDING_DATE
      ,
       NULL --TAX_INVOICE_INTERNAL_SEQ
      ,
       NULL --LEGAL_ENTITY_ID
      ,
       NULL --LEGAL_ENTITY_NAME
      ,
       NULL --REFERENCE_1
      ,
       NULL --REFERENCE_2
      ,
       NULL --OPERATING_UNIT
      ,
       NULL --BANK_CHARGE_BEARER
      ,
       NULL --REMITTANCE_MESSAGE1
      ,
       NULL --REMITTANCE_MESSAGE2
      ,
       NULL --REMITTANCE_MESSAGE3
      ,
       NULL --UNIQUE_REMITTANCE_IDENTIFIER
      ,
       NULL --URI_CHECK_DIGIT
      ,
       NULL --SETTLEMENT_PRIORITY
      ,
       NULL --PAYMENT_REASON_CODE
      ,
       NULL --PAYMENT_REASON_COMMENTS
      ,
       NULL --PAYMENT_METHOD_CODE
      ,
       NULL --DELIVERY_CHANNEL_CODE
      ,
       NULL --PAID_ON_BEHALF_EMPLOYEE_ID
      ,
       NULL --NET_OF_RETAINAGE_FLAG
      ,
       NULL --REQUESTER_EMPLOYEE_NUM
      ,
       NULL --CUST_REGISTRATION_CODE
      ,
       NULL --CUST_REGISTRATION_NUMBER
      ,
       NULL --PARTY_ID
      ,
       NULL --PARTY_SITE_ID
      ,
       NULL --PAY_PROC_TRXN_TYPE_CODE
      ,
       NULL --PAYMENT_FUNCTION
      ,
       NULL --PAYMENT_PRIORITY
      ,
       NULL --PORT_OF_ENTRY_CODE
      ,
       NULL --EXTERNAL_BANK_ACCOUNT_ID
      ,
       NULL --ACCTS_PAY_CODE_CONCATENATED
      ,
       NULL --PAY_AWT_GROUP_ID
      ,
       NULL --PAY_AWT_GROUP_NAME
      ,
       NULL --ORIGINAL_INVOICE_AMOUNT
      ,
       NULL --DISPUTE_REASON
      ,
       NULL --REMIT_TO_SUPPLIER_NAME
      ,
       NULL --REMIT_TO_SUPPLIER_ID
      ,
       NULL --REMIT_TO_SUPPLIER_SITE
      ,
       NULL --REMIT_TO_SUPPLIER_SITE_ID
      ,
       NULL --RELATIONSHIP_ID
      ,
       NULL --REMIT_TO_SUPPLIER_NUM
       )
    RETURNING invoice_id INTO vn_invoice_id;
    RETURN vn_invoice_id;
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' FACT :' ||
                                    pv_invoice_num || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' FACT :' ||
                                    pv_invoice_num ||
                                    ' - Erreur lors de l''insertion d''une ' ||
                                    'ligne d''entete dans la table d''Open Interface');
      RAISE e_generic;
  END insert_header;

  /*
  * Insere une ligne dans la table ap_invoice_lines_interface
  *
  * Parametres : valeurs des differents champs
  *
  * Exception : e_generic en cas d'erreur
  */
  PROCEDURE insert_line(pn_invoice_id                  IN ap_invoice_lines_interface.invoice_id%TYPE,
                        pn_line_number                 IN ap_invoice_lines_interface.line_number%TYPE,
                        pv_line_type_lookup_code       IN ap_invoice_lines_interface.line_type_lookup_code%TYPE,
                        pn_amount                      IN ap_invoice_lines_interface.amount%TYPE,
                        pv_tax_code                    IN ap_invoice_lines_interface.tax_code%TYPE,
                        pn_po_header_id                IN ap_invoice_lines_interface.po_header_id%TYPE,
                        pv_po_number                   IN ap_invoice_lines_interface.po_number%TYPE,
                        pn_po_line_id                  IN ap_invoice_lines_interface.po_line_id%TYPE,
                        pn_po_line_number              IN ap_invoice_lines_interface.po_line_number%TYPE,
                        pn_po_line_location_id         IN ap_invoice_lines_interface.po_line_location_id%TYPE,
                        pn_po_distribution_id          IN ap_invoice_lines_interface.po_distribution_id%TYPE,
                        pn_po_distribution_num         IN ap_invoice_lines_interface.po_distribution_num%TYPE,
                        pn_dist_code_combination_id    IN ap_invoice_lines_interface.dist_code_combination_id%TYPE,
                        pv_attribute_category          IN ap_invoice_lines_interface.attribute_category%TYPE, -- Modif EMA du 04/01/2012
                        pv_attribute1                  IN ap_invoice_lines_interface.attribute1%TYPE, -- Modif EMA du 04/01/2012
                        pv_attribute2                  IN ap_invoice_lines_interface.attribute2%TYPE,
                        pv_attribute3                  IN ap_invoice_lines_interface.attribute3%TYPE,
                        pv_attribute4                  IN ap_invoice_lines_interface.attribute4%TYPE,
                        pv_attribute7                  IN ap_invoice_lines_interface.attribute7%TYPE,
                        pn_tax_recovery_rate           IN ap_invoice_lines_interface.tax_recovery_rate%TYPE,
                        pv_tax_recoverable_flag        IN ap_invoice_lines_interface.tax_recoverable_flag%TYPE,
                        pn_project_id                  IN ap_invoice_lines_interface.project_id%TYPE,
                        pn_task_id                     IN ap_invoice_lines_interface.task_id%TYPE,
                        pv_expenditure_type            IN ap_invoice_lines_interface.expenditure_type%TYPE,
                        pd_expenditure_item_date       IN ap_invoice_lines_interface.expenditure_item_date%TYPE,
                        pn_expenditure_organization_id IN ap_invoice_lines_interface.expenditure_organization_id%TYPE,
                        pv_description                 IN ap_invoice_lines_interface.description%TYPE,
                        --Ajout R12
                        pn_line_group_number     IN ap_invoice_lines_interface.line_group_number%TYPE,
                        pv_tax_rate_code         IN ap_invoice_lines_interface.tax_rate_code%TYPE,
                        pv_tax_regime_code       IN ap_invoice_lines_interface.tax_regime_code%TYPE,
                        pv_tax                   IN ap_invoice_lines_interface.tax%TYPE,
                        pv_tax_jurisdiction_code IN ap_invoice_lines_interface.tax_jurisdiction_code%TYPE,
                        pv_tax_status_code       IN ap_invoice_lines_interface.tax_status_code%TYPE,
                        pv_prorate_across_flag   IN ap_invoice_lines_interface.prorate_across_flag%TYPE) IS
    vn_invoice_line_id ap_invoice_lines_interface.invoice_line_id%TYPE;
    vn_region_commande VARCHAR2(3);
    vn_region_facture  VARCHAR2(3);
    vc_po_number       VARCHAR2(150);

    vc_invoice_num  AP_Invoices_interface.invoice_num%TYPE;
    vc_attribute_13 AP_Invoices_interface.Attribute13%TYPE;
    vc_description  AP_Invoices_interface.description%TYPE; -- Ajout - MSL Artf534772

  BEGIN
    INSERT INTO ap_invoice_lines_interface
      (INVOICE_ID,
       INVOICE_LINE_ID,
       LINE_NUMBER,
       LINE_TYPE_LOOKUP_CODE,
       LINE_GROUP_NUMBER,
       AMOUNT,
       ACCOUNTING_DATE,
       DESCRIPTION,
       AMOUNT_INCLUDES_TAX_FLAG,
       PRORATE_ACROSS_FLAG,
       TAX_CODE,
       FINAL_MATCH_FLAG,
       PO_HEADER_ID,
       PO_NUMBER,
       PO_LINE_ID,
       PO_LINE_NUMBER,
       PO_LINE_LOCATION_ID,
       PO_SHIPMENT_NUM,
       PO_DISTRIBUTION_ID,
       PO_DISTRIBUTION_NUM,
       PO_UNIT_OF_MEASURE,
       INVENTORY_ITEM_ID,
       ITEM_DESCRIPTION,
       QUANTITY_INVOICED,
       SHIP_TO_LOCATION_CODE,
       UNIT_PRICE,
       DISTRIBUTION_SET_ID,
       DISTRIBUTION_SET_NAME,
       DIST_CODE_CONCATENATED,
       DIST_CODE_COMBINATION_ID,
       AWT_GROUP_ID,
       AWT_GROUP_NAME,
       LAST_UPDATED_BY,
       LAST_UPDATE_DATE,
       LAST_UPDATE_LOGIN,
       CREATED_BY,
       CREATION_DATE,
       ATTRIBUTE_CATEGORY,
       ATTRIBUTE1,
       ATTRIBUTE2,
       ATTRIBUTE3,
       ATTRIBUTE4,
       ATTRIBUTE5,
       ATTRIBUTE6,
       ATTRIBUTE7,
       ATTRIBUTE8,
       ATTRIBUTE9,
       ATTRIBUTE10,
       ATTRIBUTE11,
       ATTRIBUTE12,
       ATTRIBUTE13,
       ATTRIBUTE14,
       ATTRIBUTE15,
       GLOBAL_ATTRIBUTE_CATEGORY,
       GLOBAL_ATTRIBUTE1,
       GLOBAL_ATTRIBUTE2,
       GLOBAL_ATTRIBUTE3,
       GLOBAL_ATTRIBUTE4,
       GLOBAL_ATTRIBUTE5,
       GLOBAL_ATTRIBUTE6,
       GLOBAL_ATTRIBUTE7,
       GLOBAL_ATTRIBUTE8,
       GLOBAL_ATTRIBUTE9,
       GLOBAL_ATTRIBUTE10,
       GLOBAL_ATTRIBUTE11,
       GLOBAL_ATTRIBUTE12,
       GLOBAL_ATTRIBUTE13,
       GLOBAL_ATTRIBUTE14,
       GLOBAL_ATTRIBUTE15,
       GLOBAL_ATTRIBUTE16,
       GLOBAL_ATTRIBUTE17,
       GLOBAL_ATTRIBUTE18,
       GLOBAL_ATTRIBUTE19,
       GLOBAL_ATTRIBUTE20,
       PO_RELEASE_ID,
       RELEASE_NUM,
       ACCOUNT_SEGMENT,
       BALANCING_SEGMENT,
       COST_CENTER_SEGMENT,
       PROJECT_ID,
       TASK_ID,
       EXPENDITURE_TYPE,
       EXPENDITURE_ITEM_DATE,
       EXPENDITURE_ORGANIZATION_ID,
       PROJECT_ACCOUNTING_CONTEXT,
       PA_ADDITION_FLAG,
       PA_QUANTITY,
       USSGL_TRANSACTION_CODE,
       STAT_AMOUNT,
       TYPE_1099,
       INCOME_TAX_REGION,
       ASSETS_TRACKING_FLAG,
       PRICE_CORRECTION_FLAG,
       ORG_ID,
       RECEIPT_NUMBER,
       RECEIPT_LINE_NUMBER,
       MATCH_OPTION,
       PACKING_SLIP,
       RCV_TRANSACTION_ID,
       PA_CC_AR_INVOICE_ID,
       PA_CC_AR_INVOICE_LINE_NUM,
       REFERENCE_1,
       REFERENCE_2,
       PA_CC_PROCESSED_CODE,
       TAX_RECOVERY_RATE,
       TAX_RECOVERY_OVERRIDE_FLAG,
       TAX_RECOVERABLE_FLAG,
       TAX_CODE_OVERRIDE_FLAG,
       TAX_CODE_ID,
       CREDIT_CARD_TRX_ID,
       AWARD_ID,
       VENDOR_ITEM_NUM,
       TAXABLE_FLAG,
       PRICE_CORRECT_INV_NUM,
       EXTERNAL_DOC_LINE_REF,
       SERIAL_NUMBER,
       MANUFACTURER,
       MODEL_NUMBER,
       WARRANTY_NUMBER,
       DEFERRED_ACCTG_FLAG,
       DEF_ACCTG_START_DATE,
       DEF_ACCTG_END_DATE,
       DEF_ACCTG_NUMBER_OF_PERIODS,
       DEF_ACCTG_PERIOD_TYPE,
       UNIT_OF_MEAS_LOOKUP_CODE,
       PRICE_CORRECT_INV_LINE_NUM,
       ASSET_BOOK_TYPE_CODE,
       ASSET_CATEGORY_ID,
       REQUESTER_ID,
       REQUESTER_FIRST_NAME,
       REQUESTER_LAST_NAME,
       REQUESTER_EMPLOYEE_NUM,
       APPLICATION_ID,
       PRODUCT_TABLE,
       REFERENCE_KEY1,
       REFERENCE_KEY2,
       REFERENCE_KEY3,
       REFERENCE_KEY4,
       REFERENCE_KEY5,
       PURCHASING_CATEGORY,
       PURCHASING_CATEGORY_ID,
       COST_FACTOR_ID,
       COST_FACTOR_NAME,
       CONTROL_AMOUNT,
       ASSESSABLE_VALUE,
       DEFAULT_DIST_CCID,
       PRIMARY_INTENDED_USE,
       SHIP_TO_LOCATION_ID,
       PRODUCT_TYPE,
       PRODUCT_CATEGORY,
       PRODUCT_FISC_CLASSIFICATION,
       USER_DEFINED_FISC_CLASS,
       TRX_BUSINESS_CATEGORY,
       TAX_REGIME_CODE,
       TAX,
       TAX_JURISDICTION_CODE,
       TAX_STATUS_CODE,
       TAX_RATE_ID,
       TAX_RATE_CODE,
       TAX_RATE,
       INCL_IN_TAXABLE_LINE_FLAG,
       SOURCE_APPLICATION_ID,
       SOURCE_ENTITY_CODE,
       SOURCE_EVENT_CLASS_CODE,
       SOURCE_TRX_ID,
       SOURCE_LINE_ID,
       SOURCE_TRX_LEVEL_TYPE,
       TAX_CLASSIFICATION_CODE,
       CC_REVERSAL_FLAG,
       COMPANY_PREPAID_INVOICE_ID,
       EXPENSE_GROUP,
       JUSTIFICATION,
       MERCHANT_DOCUMENT_NUMBER,
       MERCHANT_NAME,
       MERCHANT_REFERENCE,
       MERCHANT_TAX_REG_NUMBER,
       MERCHANT_TAXPAYER_ID,
       RECEIPT_CURRENCY_CODE,
       RECEIPT_CONVERSION_RATE,
       RECEIPT_CURRENCY_AMOUNT,
       COUNTRY_OF_SUPPLY,
       PAY_AWT_GROUP_ID,
       PAY_AWT_GROUP_NAME,
       EXPENSE_START_DATE,
       EXPENSE_END_DATE)
    VALUES
      (pn_invoice_id --INVOICE_ID
      ,
       ap_invoice_lines_interface_s.NEXTVAL --INVOICE_LINE_ID
      ,
       pn_line_number --LINE_NUMBER
      ,
       pv_line_type_lookup_code --LINE_TYPE_LOOKUP_CODE
      ,
       pn_line_group_number --LINE_GROUP_NUMBER
      ,
       pn_amount --AMOUNT
      ,
       NULL --ACCOUNTING_DATE
      ,
       pv_description --DESCRIPTION
      ,
       NULL --AMOUNT_INCLUDES_TAX_FLAG
      ,
       pv_prorate_across_flag --PRORATE_ACROSS_FLAG
      ,
       pv_tax_code --TAX_CODE
      ,
       NULL --FINAL_MATCH_FLAG
      ,
       pn_po_header_id --PO_HEADER_ID
      ,
       pv_po_number --PO_NUMBER
      ,
       pn_po_line_id --PO_LINE_ID
      ,
       pn_po_line_number --PO_LINE_NUMBER
      ,
       pn_po_line_location_id --PO_LINE_LOCATION_ID
      ,
       NULL --PO_SHIPMENT_NUM
      ,
       pn_po_distribution_id --PO_DISTRIBUTION_ID
      ,
       pn_po_distribution_num --PO_DISTRIBUTION_NUM
      ,
       NULL --PO_UNIT_OF_MEASURE
      ,
       NULL --INVENTORY_ITEM_ID
      ,
       NULL --ITEM_DESCRIPTION
      ,
       NULL --QUANTITY_INVOICED
      ,
       NULL --SHIP_TO_LOCATION_CODE
      ,
       NULL --UNIT_PRICE
      ,
       NULL --DISTRIBUTION_SET_ID
      ,
       NULL --DISTRIBUTION_SET_NAME
      ,
       NULL --DIST_CODE_CONCATENATED
      ,
       pn_dist_code_combination_id --DIST_CODE_COMBINATION_ID
      ,
       NULL --AWT_GROUP_ID
      ,
       NULL --AWT_GROUP_NAME
      ,
       fnd_global.user_id --LAST_UPDATED_BY
      ,
       SYSDATE --LAST_UPDATE_DATE
      ,
       fnd_global.login_id --LAST_UPDATE_LOGIN
      ,
       fnd_global.user_id --CREATED_BY
      ,
       SYSDATE --CREATION_DATE
      ,
       pv_attribute_category --ATTRIBUTE_CATEGORY
      ,
       pv_attribute1 --ATTRIBUTE1
      ,
       pv_attribute2 --ATTRIBUTE2
      ,
       pv_attribute3 --ATTRIBUTE3
      ,
       pv_attribute4 --ATTRIBUTE4
      ,
       NULL --ATTRIBUTE5
      ,
       NULL --ATTRIBUTE6
      ,
       pv_attribute7 --ATTRIBUTE7
      ,
       NULL --ATTRIBUTE8
      ,
       NULL --ATTRIBUTE9
      ,
       NULL --ATTRIBUTE10
      ,
       NULL --ATTRIBUTE11
      ,
       NULL --ATTRIBUTE12
      ,
       NULL --ATTRIBUTE13
      ,
       NULL --ATTRIBUTE14
      ,
       NULL --ATTRIBUTE15
      ,
       NULL --GLOBAL_ATTRIBUTE_CATEGORY
      ,
       NULL --GLOBAL_ATTRIBUTE1
      ,
       NULL --GLOBAL_ATTRIBUTE2
      ,
       NULL --GLOBAL_ATTRIBUTE3
      ,
       NULL --GLOBAL_ATTRIBUTE4
      ,
       NULL --GLOBAL_ATTRIBUTE5
      ,
       NULL --GLOBAL_ATTRIBUTE6
      ,
       NULL --GLOBAL_ATTRIBUTE7
      ,
       NULL --GLOBAL_ATTRIBUTE8
      ,
       NULL --GLOBAL_ATTRIBUTE9
      ,
       NULL --GLOBAL_ATTRIBUTE10
      ,
       NULL --GLOBAL_ATTRIBUTE11
      ,
       NULL --GLOBAL_ATTRIBUTE12
      ,
       NULL --GLOBAL_ATTRIBUTE13
      ,
       NULL --GLOBAL_ATTRIBUTE14
      ,
       NULL --GLOBAL_ATTRIBUTE15
      ,
       NULL --GLOBAL_ATTRIBUTE16
      ,
       NULL --GLOBAL_ATTRIBUTE17
      ,
       NULL --GLOBAL_ATTRIBUTE18
      ,
       NULL --GLOBAL_ATTRIBUTE19
      ,
       NULL --GLOBAL_ATTRIBUTE20
      ,
       NULL --PO_RELEASE_ID
      ,
       NULL --RELEASE_NUM
      ,
       NULL --ACCOUNT_SEGMENT
      ,
       NULL --BALANCING_SEGMENT
      ,
       NULL --COST_CENTER_SEGMENT
      ,
       pn_project_id --PROJECT_ID
      ,
       pn_task_id --TASK_ID
      ,
       pv_expenditure_type --EXPENDITURE_TYPE
      ,
       pd_expenditure_item_date --EXPENDITURE_ITEM_DATE
      ,
       pn_expenditure_organization_id --EXPENDITURE_ORGANIZATION_ID
      ,
       NULL --PROJECT_ACCOUNTING_CONTEXT
      ,
       NULL --PA_ADDITION_FLAG
      ,
       NULL --PA_QUANTITY
      ,
       NULL --USSGL_TRANSACTION_CODE
      ,
       NULL --STAT_AMOUNT
      ,
       NULL --TYPE_1099
      ,
       NULL --INCOME_TAX_REGION
      ,
       NULL --ASSETS_TRACKING_FLAG
      ,
       NULL --PRICE_CORRECTION_FLAG
      ,
       NULL --ORG_ID
      ,
       NULL --RECEIPT_NUMBER
      ,
       NULL --RECEIPT_LINE_NUMBER
      ,
       'P' --MATCH_OPTION
      ,
       NULL --PACKING_SLIP
      ,
       NULL --RCV_TRANSACTION_ID
      ,
       NULL --PA_CC_AR_INVOICE_ID
      ,
       NULL --PA_CC_AR_INVOICE_LINE_NUM
      ,
       NULL --REFERENCE_1
      ,
       NULL --REFERENCE_2
      ,
       NULL --PA_CC_PROCESSED_CODE
      ,
       pn_tax_recovery_rate --TAX_RECOVERY_RATE
      ,
       'Y' --TAX_RECOVERY_OVERRIDE_FLAG
      ,
       pv_tax_recoverable_flag --TAX_RECOVERABLE_FLAG
      ,
       'Y' --TAX_CODE_OVERRIDE_FLAG
      ,
       NULL --TAX_CODE_ID
      ,
       NULL --CREDIT_CARD_TRX_ID
      ,
       NULL --AWARD_ID
      ,
       NULL --VENDOR_ITEM_NUM
      ,
       NULL --TAXABLE_FLAG
      ,
       NULL --PRICE_CORRECT_INV_NUM
      ,
       NULL --EXTERNAL_DOC_LINE_REF
      ,
       NULL --SERIAL_NUMBER
      ,
       NULL --MANUFACTURER
      ,
       NULL --MODEL_NUMBER
      ,
       NULL --WARRANTY_NUMBER
      ,
       NULL --DEFERRED_ACCTG_FLAG
      ,
       NULL --DEF_ACCTG_START_DATE
      ,
       NULL --DEF_ACCTG_END_DATE
      ,
       NULL --DEF_ACCTG_NUMBER_OF_PERIODS
      ,
       NULL --DEF_ACCTG_PERIOD_TYPE
      ,
       NULL --UNIT_OF_MEAS_LOOKUP_CODE
      ,
       NULL --PRICE_CORRECT_INV_LINE_NUM
      ,
       NULL --ASSET_BOOK_TYPE_CODE
      ,
       NULL --ASSET_CATEGORY_ID
      ,
       NULL --REQUESTER_ID
      ,
       NULL --REQUESTER_FIRST_NAME
      ,
       NULL --REQUESTER_LAST_NAME
      ,
       NULL --REQUESTER_EMPLOYEE_NUM
      ,
       NULL --APPLICATION_ID
      ,
       NULL --PRODUCT_TABLE
      ,
       NULL --REFERENCE_KEY1
      ,
       NULL --REFERENCE_KEY2
      ,
       NULL --REFERENCE_KEY3
      ,
       NULL --REFERENCE_KEY4
      ,
       NULL --REFERENCE_KEY5
      ,
       NULL --PURCHASING_CATEGORY
      ,
       NULL --PURCHASING_CATEGORY_ID
      ,
       NULL --COST_FACTOR_ID
      ,
       NULL --COST_FACTOR_NAME
      ,
       NULL --CONTROL_AMOUNT
      ,
       NULL --ASSESSABLE_VALUE
      ,
       NULL --DEFAULT_DIST_CCID
      ,
       NULL --PRIMARY_INTENDED_USE
      ,
       NULL --SHIP_TO_LOCATION_ID
      ,
       NULL --PRODUCT_TYPE
      ,
       NULL --PRODUCT_CATEGORY
      ,
       NULL --PRODUCT_FISC_CLASSIFICATION
      ,
       NULL --USER_DEFINED_FISC_CLASS
      ,
       NULL --TRX_BUSINESS_CATEGORY
      ,
       pv_tax_regime_code --TAX_REGIME_CODE
      ,
       pv_tax --TAX
      ,
       pv_tax_jurisdiction_code --TAX_JURISDICTION_CODE
      ,
       pv_tax_status_code --TAX_STATUS_CODE
      ,
       NULL --TAX_RATE_ID
      ,
       pv_tax_rate_code --TAX_RATE_CODE
      ,
       NULL --TAX_RATE
      ,
       NULL --INCL_IN_TAXABLE_LINE_FLAG
      ,
       NULL --SOURCE_APPLICATION_ID
      ,
       NULL --SOURCE_ENTITY_CODE
      ,
       NULL --SOURCE_EVENT_CLASS_CODE
      ,
       NULL --SOURCE_TRX_ID
      ,
       NULL --SOURCE_LINE_ID
      ,
       NULL --SOURCE_TRX_LEVEL_TYPE
      ,
       NULL --TAX_CLASSIFICATION_CODE
      ,
       NULL --CC_REVERSAL_FLAG
      ,
       NULL --COMPANY_PREPAID_INVOICE_ID
      ,
       NULL --EXPENSE_GROUP
      ,
       NULL --JUSTIFICATION
      ,
       NULL --MERCHANT_DOCUMENT_NUMBER
      ,
       NULL --MERCHANT_NAME
      ,
       NULL --MERCHANT_REFERENCE
      ,
       NULL --MERCHANT_TAX_REG_NUMBER
      ,
       NULL --MERCHANT_TAXPAYER_ID
      ,
       NULL --RECEIPT_CURRENCY_CODE
      ,
       NULL --RECEIPT_CONVERSION_RATE
      ,
       NULL --RECEIPT_CURRENCY_AMOUNT
      ,
       NULL --COUNTRY_OF_SUPPLY
      ,
       NULL --PAY_AWT_GROUP_ID
      ,
       NULL --PAY_AWT_GROUP_NAME
      ,
       NULL --EXPENSE_START_DATE
      ,
       NULL --EXPENSE_END_DATE
       )
    RETURNING invoice_line_id INTO vn_invoice_line_id;

    -- Verification que la commande est valide
    dka_Tools_Pkg.put_log_message('Verification que la commande est valide');
    dka_Tools_Pkg.put_log_message('pn_invoice_id : ' || pn_invoice_id);

    SELECT aii.invoice_num, aii.attribute13
      INTO vc_invoice_num, vc_attribute_13
      FROM AP_Invoices_interface aii
     WHERE aii.invoice_id = pn_invoice_id;

    dka_Tools_Pkg.put_log_message('vc_invoice_num : ' || vc_invoice_num);
    dka_Tools_Pkg.put_log_message('vc_attribute_13 : ' || vc_attribute_13);

    BEGIN
      -- Verification par rapport aux lignes
      SELECT ail.po_number
        INTO vc_po_number
        FROM ap_invoice_lines_interface ail, AP_Invoices_interface aii
       WHERE ail.invoice_id = aii.invoice_id
         AND nvl(aii.attribute1, 'OK') NOT LIKE '%37%'
         AND nvl(aii.attribute1, 'OK') NOT LIKE '%38%'
         AND ail.invoice_id = pn_invoice_id
         AND ail.po_number IS NOT NULL
         AND ROWNUM = 1;

    EXCEPTION
      WHEN NO_DATA_FOUND THEN
        BEGIN
          -- Si aucune valeur n'est retournee, on recherche dans le cuf
          SELECT aii.attribute13
            INTO vc_po_number
            FROM AP_Invoices_interface aii
           WHERE nvl(aii.attribute1, 'OK') NOT LIKE '%37%'
             AND nvl(aii.attribute1, 'OK') NOT LIKE '%38%'
             AND aii.invoice_id = pn_invoice_id;

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vc_po_number := NULL;
            dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                          ' FACT :' || vc_invoice_num ||
                                          ' - La commande n''est pas valide');
          WHEN OTHERS THEN
            dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                          ' FACT :' || vc_invoice_num ||
                                          ' - Erreur ' || SQLERRM);
            dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                          ' FACT :' || vc_invoice_num ||
                                          ' - Erreur lors de la verification de la validite de la commande');
            RAISE e_generic;
        END;

      WHEN OTHERS THEN
        dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' FACT :' ||
                                      vc_invoice_num || ' - Erreur ' ||
                                      SQLERRM);
        dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' FACT :' ||
                                      vc_invoice_num ||
                                      ' - Erreur lors de la verification de la validite de la commande');
        RAISE e_generic;
    END;

    dka_Tools_Pkg.put_log_message('po_number = ' || vc_po_number);
    IF vc_po_number IS NOT NULL THEN
      -- Si la commande est valide, on compare les regions
      BEGIN
        -- Region de la commande
        SELECT gcc.segment2
          INTO vn_region_commande
          FROM po_distributions_all pda,
               gl_code_combinations gcc,
               po_headers_all       pha
         WHERE pda.code_combination_id = gcc.code_combination_id
           AND pda.po_header_id = pha.po_header_id
           AND pha.segment1 = vc_po_number
           AND pda.org_id = gn_org_id
           AND ROWNUM = 1; -- premiere ligne d'imputation

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vn_region_commande := 'ZZZ';
        WHEN OTHERS THEN
          dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                        ' FACT :' || vc_invoice_num ||
                                        ' - Erreur ' || SQLERRM);
          dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                        ' FACT :' || vc_invoice_num ||
                                        ' - Erreur lors du controle de la region de la commande');
          RAISE e_generic;
      END;

      dka_Tools_Pkg.put_log_message('Region de la commande : ' ||
                                    vn_region_commande);

      BEGIN
        -- Region de la facture
        SELECT substr(haou.name, 1, 3)
          INTO vn_region_facture
          FROM ap_invoices_interface aii, hr_all_organization_units haou
         WHERE aii.org_id = haou.organization_id
           AND aii.invoice_id = pn_invoice_id;

      EXCEPTION
        WHEN NO_DATA_FOUND THEN
          vn_region_facture := '***';
        WHEN OTHERS THEN
          dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                        ' FACT :' || vc_invoice_num ||
                                        ' - Erreur ' || SQLERRM);
          dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                        ' FACT :' || vc_invoice_num ||
                                        ' - Erreur lors du controle de la region de la facture');
          RAISE e_generic;
      END;

      dka_Tools_Pkg.put_log_message('Region de la facture : ' ||
                                    vn_region_facture);

      -- Si les deux requetes ont retournes un resultat.
      -- On compare les regions.
      IF vn_region_commande <> vn_region_facture THEN
        -- Debut ajout - MSL Artf534772
        -- Verification que la ligne n'est pas deja considere comme en erreur
        SELECT substr(aii.description, 1, 14)
          INTO vc_description
          FROM ap_invoices_interface aii
         WHERE aii.invoice_id = pn_invoice_id;

        IF vc_description <> '*ERREUR REGION' THEN
          -- Fin ajout - MSL Artf534772
          dka_Tools_Pkg.put_log_message('Region differente => update de ap_invoices_interface');
          dka_Tools_Pkg.put_log_message('pn_invoice_id = ' ||
                                        pn_invoice_id);
          -- Si les regions sont differentes, on met a jour l'entete de la facture
          UPDATE ap_invoices_interface aii
             SET aii.description           = '*ERREUR REGION ' ||
                                             aii.description,
                 aii.vendor_site_id        = -999,
                 aii.vendor_site_code      = NULL,
                 aii.pay_group_lookup_code = NULL
           WHERE aii.invoice_id = pn_invoice_id;
        END IF; -- Ajout - MSL Artf534772
      END IF;
    END IF;

    RETURN;
  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' FACT_ID :' ||
                                    pn_invoice_id || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' FACT_ID :' ||
                                    pn_invoice_id ||
                                    ' - Erreur lors de l''insertion d''une ' ||
                                    'ligne de facture dans la table d''Open Interface');
      RAISE e_generic;
  END insert_line;

  /*
  * Importe les factures pour une organisation donnee.
  *
  * Parametres :
  *  pv_errbuf   message d'erreur
  *  pn_retcode  code de retour (0 : ok, 1 : warning, 2 : erreur)
  */
  PROCEDURE child_import(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    CURSOR cur_factures IS
      SELECT xii.rowid,
             xii.type,
             xii.code_societe,
             xii.code_division,
             xii.code_region,
             xii.no_commande,
             xii.affacte,
             xii.reglement,
             xii.edi,
             xii.type_piece,
             xii.code_frs,
             xii.site_frs,
             xii.code_dossier,
             xii.packing_slip,
             xii.rib,
             xii.code_devise,
             xii.num_fact,
             xii.mht_devise,
             xii.mtva_devise,
             xii.mttc_devise,
             xii.taux_tva,
             xii.date_piece,
             xii.date_echeance,
             xii.reference_lad,
             xii.date_numerisation,
             xii.code_rejet,
             xii.date_creation,
             xii.type_tva,
             xii.s_type,
             xii.pretypelot,
             xii.prenbfac,
             xii.predate,
             xii.batchprefix,
             xii.batchno,
             xii.batchidx,
             xii.cdrejp,
             xii.cdrejs,
             xii.imagefile,
             xii.imagefile2,
             xii.nom_fichier,
             haou.organization_id
        FROM dka_iapfacxgs_interface xii, hr_all_organization_units haou
       WHERE xii.code_region || xii.code_societe = haou.name
         AND haou.organization_id = gn_org_id;

    CURSOR cur_lines1(pv_no_commande  VARCHAR2,
                      pd_gl_date      DATE,
                      pd_start_date   DATE,
                      pv_code_societe VARCHAR2) IS
      SELECT xiv.id_cde,
             xiv.num_cde,
             xiv.id_lig,
             xiv.num_lig,
             xiv.id_location,
             xiv.id_distribution,
             xiv.num_distribution,
             xiv.qte_cde,
             xiv.qte_fact,
             xiv.prix_unit,
             xiv.id_br,
             xiv.num_br,
             xiv.packing_slip,
             xiv.num_ligne_br,
             xiv.societe_projet,
             xiv.id_projet,
             xiv.id_tache,
             xiv.type_depense,
             xiv.date_depense,
             xiv.orgid_depense,
             xiv.class_code,
             xiv.date_ferm_projet,
             xiv.date_ferm_tache, --MTIA INC0319253
             xiv.type_tache, --MTIA EDB260 Ajout du type de Tache
             SUM(xiv.qte_fact * xiv.prix_unit) OVER() mont_rappro --> Ajout GV20100222
        FROM dka_iapfacxgs_cde_valid_lig_v xiv
       WHERE xiv.num_cde = pv_no_commande
         AND (nvl(xiv.date_ferm_projet, pd_gl_date) >= pd_gl_date or
             xiv.date_ferm_projet between pd_start_date and pd_gl_date)
         AND (nvl(xiv.date_ferm_tache, pd_gl_date) >= pd_gl_date or
             xiv.date_ferm_tache between pd_start_date and pd_gl_date) --MTIA INC0319253
         AND (xiv.societe_projet = pv_code_societe -- suite RG17
             OR transaction_type(xiv.type_depense) = 'REFAC')
         AND xiv.org_id = gn_org_id;

    CURSOR cur_lines2(pv_no_commande  VARCHAR2,
                      pv_packing_slip VARCHAR2,
                      pd_gl_date      DATE,
                      pd_start_date   DATE,
                      pv_code_societe VARCHAR2) IS
      SELECT xiv.id_cde,
             xiv.num_cde,
             xiv.id_lig,
             xiv.num_lig,
             xiv.id_location,
             xiv.id_distribution,
             xiv.num_distribution,
             xiv.qte_cde,
             xiv.qte_fact,
             xiv.prix_unit,
             xiv.id_br,
             xiv.num_br,
             xiv.packing_slip,
             xiv.num_ligne_br,
             xiv.societe_projet,
             xiv.id_projet,
             xiv.id_tache,
             xiv.type_depense,
             xiv.date_depense,
             xiv.orgid_depense,
             xiv.class_code,
             xiv.date_ferm_projet,
             xiv.date_ferm_tache --MTIA INC0319253
        FROM dka_iapfacxgs_cde_valid_lig_v xiv
       WHERE xiv.num_cde = pv_no_commande
         AND lower(TRIM(xiv.packing_slip)) = lower(TRIM(pv_packing_slip))
         AND (nvl(xiv.date_ferm_projet, pd_gl_date) >= pd_gl_date or
             xiv.date_ferm_projet between pd_start_date and pd_gl_date)
         AND (nvl(xiv.date_ferm_tache, pd_gl_date) >= pd_gl_date or
             xiv.date_ferm_tache between pd_start_date and pd_gl_date) --MTIA INC0319253
         AND (xiv.societe_projet = pv_code_societe -- suite RG17
             OR transaction_type(xiv.type_depense) = 'REFAC')
         AND xiv.org_id = gn_org_id;
    --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
    --- 2018/09/03 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
    CURSOR cur_error IS
      select invoice_id, invoice_num
        from ap_invoices_interface aii
       where aii.vendor_num like '%DOUBLON'
         and aii.vendor_site_id = -999
         and aii.status = 'REJECTED'
         AND aii.source = 'SCAN_XGS'
         and NOT EXISTS
       (select 'x'
                from ap_interface_rejections air
               where air.parent_id = aii.invoice_id
                 and air.reject_lookup_code = 'DUPLICATE INVOICE NUMBER');

    --- 2019/01/31 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
    CURSOR cur_ap_interface IS
      SELECT AII.INVOICE_ID,
             AII.GL_DATE,
             AII.ATTRIBUTE9 ORIGINE,
             substr(AII.DOC_CATEGORY_CODE, 1, 4) SOCIETE,
             substr(AII.PAY_GROUP_LOOKUP_CODE, 8) TYPE_FOURNISSEUR,
             AII.VENDOR_ID,
             AII.STATUS,
             AII.GROUP_ID,
             AII.SOURCE,
             AII.ORG_ID organization,
             AII.invoice_num,
             AII.vendor_site_code,
             AII.vendor_site_id,
             AII.invoice_date,
             AII.invoice_amount,
             AII.vendor_num,
             AII.rowid rid
        FROM AP_INVOICES_INTERFACE AII
       WHERE AII.SOURCE = 'SCAN_XGS'
         AND (AII.STATUS != 'PROCESSED' OR AII.STATUS IS NULL)
         AND AII.ORG_ID = gn_org_id
       ORDER BY AII.ATTRIBUTE9,
                substr(AII.DOC_CATEGORY_CODE, 1, 4),
                --AII.ORG_ID,
                substr(AII.PAY_GROUP_LOOKUP_CODE, 8);

    -- timestamp pour la mesure du temps d'execution des fonctions/procedures
    vd_function_starttime TIMESTAMP;
    -- timestamp pour le temps d'execution total
    vd_process_starttime TIMESTAMP;

    -- identification des lignes traitees
    TYPE t_code_frs IS TABLE OF dka_iapfacxgs_interface.code_frs%TYPE;
    TYPE t_site_frs IS TABLE OF dka_iapfacxgs_interface.site_frs%TYPE;
    TYPE t_num_fact IS TABLE OF dka_iapfacxgs_interface.num_fact%TYPE;
    TYPE t_date_piece IS TABLE OF dka_iapfacxgs_interface.date_piece%TYPE;
    TYPE t_code_societe IS TABLE OF dka_iapfacxgs_interface.code_societe%TYPE;
    TYPE t_code_region IS TABLE OF dka_iapfacxgs_interface.code_region%TYPE;
    va_code_frs     t_code_frs := t_code_frs();
    va_site_frs     t_site_frs := t_site_frs();
    va_num_fact     t_num_fact := t_num_fact();
    va_date_piece   t_date_piece := t_date_piece();
    va_code_societe t_code_societe := t_code_societe();
    va_code_region  t_code_region := t_code_region();

    -- compteur nombre d'insertions
    vn_header_count           PLS_INTEGER := 0;
    vn_line_count             PLS_INTEGER := 0;
    vn_ventilation_line_count PLS_INTEGER := 0;
    vn_tva_line_count         PLS_INTEGER := 0;
    vn_tva_ic_line_count      PLS_INTEGER := 0;
    --- 2019/01/31 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
    vn_count_doublon PLS_INTEGER := 0;

    -- variables temporaires/intermediaires
    vn_pv_vendor_id                ap_suppliers.vendor_id%TYPE;
    vv_pv_segment1                 ap_suppliers.segment1%type;
    vv_pv_pmnt_method_lookup_code  IBY_EXT_PARTY_PMT_MTHDS.PAYMENT_METHOD_CODE%type;
    vn_pvs_vendor_id               ap_supplier_sites_all.vendor_id%type;
    vn_pvs_vendor_site_id          ap_supplier_sites_all.vendor_site_id%type;
    vv_pvs_accts_pay_ccid          ap_supplier_sites_all.accts_pay_code_combination_id%type;
    vv_pvs_pay_group_lookup_code   ap_supplier_sites_all.pay_group_lookup_code%type;
    vv_pvs_pmnt_method_lookup_code ap_supplier_sites_all.payment_method_lookup_code%type;
    vn_party_id                    ap_suppliers.party_id%TYPE;
    vn_party_site_id               ap_supplier_sites_all.party_site_id%TYPE;
    vb_code_rejet1_found           BOOLEAN;
    vb_code_rejet2_found           BOOLEAN;
    vb_code_rejet3_found           BOOLEAN;
    vb_code_rejet4_found           BOOLEAN;
    vv_closing_status              gl_period_statuses.closing_status%TYPE;
    vb_is_prelevement              BOOLEAN;
    vv_attribute8                  ap_invoices_interface.attribute8%TYPE;
    vv_attribute9                  ap_invoices_interface.attribute9%TYPE;
    vd_gl_date                     date := null;
    vd_start_date                  date := null; -- MTIA le 22/09/2020 - INC0319253 - RG quickmatch sur tache fermee
    vv_accts_pay_ccid              gl_code_combinations.code_combination_id%type;
    vv_attribute13                 ap_invoices_interface.attribute13%TYPE;
    vv_attribute14                 ap_invoices_interface.attribute14%TYPE;
    vv_hold_name                   VARCHAR2(100);
    vv_invoice_type_lookup_code    ap_invoices_interface.invoice_type_lookup_code%TYPE;
    vn_invoice_amount              ap_invoices_interface.invoice_amount%TYPE;
    vv_doc_category_code           ap_invoices_interface.doc_category_code%TYPE;
    vn_invoice_id                  ap_invoices_interface.invoice_id%TYPE;
    vn_type_facture                PLS_INTEGER;
    vn_dummy                       NUMBER;
    vv_type_lig                    VARCHAR2(200);
    vn_montant_total               NUMBER;
    vn_dummy2                      NUMBER;
    vn_line_number                 ap_invoice_lines_interface.line_number%TYPE;
    vv_name                        ap_tax_codes_all.name%TYPE;
    vn_tax_id                      ap_tax_codes_all.tax_id%TYPE;
    vn_tax_ccid                    ap_tax_codes_all.tax_code_combination_id%TYPE;
    vn_tax_recovery_rate           ap_tax_codes_all.tax_recovery_rate%TYPE;
    vn_offset_tax_code_id          ap_tax_codes_all.offset_tax_code_id%TYPE;
    vn_amount                      ap_invoice_lines_interface.amount%TYPE;
    --MTIA : INC0402570 : Creation variable pour eviter division aÃ?Â aÃ?Â  zero
    vn_prix_unit_avoir       ap_invoice_lines_interface.UNIT_PRICE%Type;
    vn_ic_tax_id             ap_tax_codes_all.tax_id%TYPE;
    vv_ic_name               ap_tax_codes_all.name%TYPE;
    vn_ic_tax_ccid           ap_tax_codes_all.tax_code_combination_id%TYPE;
    vn_ic_tax_recovery_rate  ap_tax_codes_all.tax_recovery_rate%TYPE;
    vn_ic_tax_rate           ZX_RATES_B.percentage_rate%TYPE;
    vv_attribute2            ap_invoice_lines_interface.attribute2%TYPE;
    vv_attribute3            ap_invoice_lines_interface.attribute3%TYPE;
    vv_attribute4            ap_invoice_lines_interface.attribute4%TYPE;
    vv_group_id              ap_invoices_interface.group_id%TYPE;
    vv_pay_group_lookup_code ap_invoices_interface.pay_group_lookup_code%TYPE;
    vn_terms_id              ap_invoices_interface.terms_id%TYPE;
    vd_terms_date            ap_invoices_interface.terms_date%TYPE;

    vv_po_number           ap_invoice_lines_interface.po_number%TYPE;
    vn_po_line_id          ap_invoice_lines_interface.po_line_id%TYPE;
    vn_po_line_number      ap_invoice_lines_interface.po_line_number%TYPE;
    vn_po_line_location_id ap_invoice_lines_interface.po_line_location_id%TYPE;
    vn_po_distribution_id  ap_invoice_lines_interface.po_distribution_id%TYPE;
    vn_po_distribution_num ap_invoice_lines_interface.po_distribution_num%TYPE;

    --eTax
    vn_line_group_number ap_invoice_lines_interface.line_group_number%TYPE;

    vv_tax_rate_code         ZX_RATES_B.tax_rate_code%TYPE;
    vv_tax_regime_code       ZX_RATES_B.tax_regime_code%TYPE;
    vv_tax                   ZX_RATES_B.tax%TYPE;
    vv_tax_jurisdiction_code ZX_RATES_B.tax_jurisdiction_code%TYPE;
    vv_tax_status_code       ZX_RATES_B.tax_status_code%TYPE;
    vv_offset_status_code    ZX_RATES_B.offset_status_code%TYPE;

    vv_ic_tax_rate_code         ZX_RATES_B.tax_rate_code%TYPE;
    vv_ic_tax_regime_code       ZX_RATES_B.tax_regime_code%TYPE;
    vv_ic_tax                   ZX_RATES_B.tax%TYPE;
    vv_ic_tax_jurisdiction_code ZX_RATES_B.tax_jurisdiction_code%TYPE;
    vv_ic_tax_status_code       ZX_RATES_B.tax_status_code%TYPE;

  -- SELO EDB235B DEBUT
    v_id_cde        NUMBER;
  v_num_cde       NUMBER;
  v_id_lig        NUMBER;
  v_num_lig       NUMBER;
  v_id_location     NUMBER;
  v_id_distribution   NUMBER;
  v_num_distribution    NUMBER;
  -- SELO EDB235B FIN



    -- tableau associatif utilise pour conserver les group_id et le code
    -- blocage associe
    TYPE t_group_id IS TABLE OF VARCHAR2(100) INDEX BY VARCHAR2(100);
    va_group_id t_group_id;

    -- identifiant du traitement lance
    vn_request_id PLS_INTEGER;
    vv_order_type VARCHAR2(10); -- MT
    vv_order_type_sstr VARCHAR2(10); -- EDB396
    --TVA Autoliquidee - JJA - 13/01/2015
    vv_errbuf  VARCHAR2(500);
    vn_retcode NUMBER;

    --Ecart Minimes
    CURSOR cur_factures_ec IS
      SELECT aii.*
        FROM ap_invoices_interface aii
       WHERE aii.source = 'SCAN_XGS'
         AND attribute13 IS NOT NULL
         AND EXISTS (SELECT 'X'
                FROM ap_invoice_lines_interface aili
               WHERE aili.invoice_id = aii.invoice_id
                 AND aili.line_type_lookup_code = 'ITEM'
                 AND aili.po_header_id IS NOT NULL)
         AND aii.org_id = gn_org_id;

    vn_somme_lignes                ap_invoice_lines_interface.amount%TYPE;
    vn_nombre_lignes               NUMBER;
    vn_numero_ligne_max            ap_invoice_lines_interface.line_number%TYPE;
    vn_ecart_max_facture           NUMBER; --IBA EDB349
  vn_ecart_minime_facture        NUMBER;
    vn_ecart_facture               ap_invoice_lines_interface.amount%TYPE;
    vc_tax_code                    ap_invoice_lines_interface.tax_code%TYPE;
    vn_tax_code_id                 ap_invoice_lines_interface.tax_code_id%TYPE;
    vn_project_id                  ap_invoice_lines_interface.project_id%TYPE;
    vn_task_id                     ap_invoice_lines_interface.task_id%TYPE;
    vc_expenditure_type            ap_invoice_lines_interface.expenditure_type%TYPE;
    vd_expenditure_item_date       ap_invoice_lines_interface.expenditure_item_date%TYPE;
    vn_expenditure_organization_id ap_invoice_lines_interface.expenditure_organization_id%TYPE;
    vc_description                 ap_invoice_lines_interface.description%TYPE;
    vc_vendor_name                 ap_suppliers.vendor_name%TYPE;
    Vr_Data                        Dka_Parameters%ROWTYPE;
    vv_centre_gestion              VARCHAR2(3);
    vv_project_company_code        VARCHAR2(4);
    vv_invoice_company_code        VARCHAR2(4);
    vv_attribute_category          ap_invoice_lines_interface.attribute_category%TYPE;
    vv_attribute1                  ap_invoice_lines_interface.attribute1%TYPE;
    vv_attribute7                  ap_invoice_lines_interface.attribute7%TYPE;
    vv_project_type                pa_projects_all.project_type%TYPE;
    vn_old_project_id              pa_projects_all.project_id%TYPE;
    vn_old_task_id                 pa_tasks.task_id%TYPE;
    vv_project_code                pa_projects_all.segment1%TYPE;
    vv_project_name                pa_projects_all.name%TYPE;
    vd_date_piece                  ap_invoices_interface.invoice_date%TYPE;
    vb_data_ok                     BOOLEAN;
    v_count                    number;
  v_mht_dispo                number;
    vv_fournisseur_service ap_suppliers.Attribute1%type; -- MTIA EDB260
    vv_vendor_site_code    ap_supplier_sites.vendor_site_code%TYPE;
    vb_code_rejet98_found  BOOLEAN;
    l_multiple_GY          NUMBER; -- MTIA EDB260
    --SNK EDB235
    v_cmd_status         VARCHAR2(200);
    v_total_article      NUMBER;
    V_TOTAL_ARTICLE_CAS7 NUMBER;
    v_total_article_lig  NUMBER;
    v_montant_ligne_fact NUMBER;
    v_num_ic_frs         VARCHAR2(200);

    v_avoir_rapproche NUMBER;
    l_cas1            NUMBER; --MTIABL
    l_cas4            NUMBER; --MTIABL
    l_cas2            NUMBER; --SELO EDB235B
  l_cas2A           NUMBER; --IBA EDB355
    l_cas3            NUMBER; --SELO EDB235B
  l_cas5            NUMBER; --SELO EDB235B
    l_cas6            NUMBER; --SELO EDB235B
    l_cas7            NUMBER; --SELO EDB235B
    l_cas8            NUMBER; --SELO EDB235B
  l_cas9            NUMBER; --SELO EDB235B
    --SNK EDB235
  VN_NB_LIGNES_112_BLOCAGE NUMBER; ---IBA EDB350
  BEGIN
    vd_process_starttime := LOCALTIMESTAMP;

    pv_errbuf  := '';
    pn_retcode := 0;

    dka_Tools_Pkg.put_log_message('child_import');
    dka_Tools_Pkg.put_log_message('**********');

    init_global_attribute_category();
    init_gv_code();
    init_gn_term_id();

    -- affichage des informations sur les parametres
    dka_Tools_Pkg.put_log_message('> global_attribute_cat : ' ||
                                  gv_global_attribute_category);
    dka_Tools_Pkg.put_log_message('> terms_id ''Comptant'' : ' ||
                                  gn_term_id);
    dka_Tools_Pkg.put_log_message('--------------------------------------------------');

    dka_Tools_Pkg.put_log_message('Insertion dans les tables d''Open Interface');
    vd_function_starttime := LOCALTIMESTAMP;

    -- debut reel du traitement
    FOR rec_fact in cur_factures LOOP
      BEGIN
        -- rg01
        BEGIN
          SELECT pv.vendor_id,
                 pv.segment1,
                 pvs.vendor_id,
                 pvs.vendor_site_id,
                 pvs.accts_pay_code_combination_id,
                 pvs.pay_group_lookup_code,
                 pvs.payment_method_lookup_code,
                 pv.party_id,
                 pvs.party_site_id,
                 pv.attribute1 --MTIA - EDB260
            INTO vn_pv_vendor_id,
                 vv_pv_segment1,
                 vn_pvs_vendor_id,
                 vn_pvs_vendor_site_id, -- utilise
                 vv_pvs_accts_pay_ccid, -- utilise
                 vv_pvs_pay_group_lookup_code, -- utilise
                 vv_pvs_pmnt_method_lookup_code,
                 vn_party_id,
                 vn_party_site_id,
                 vv_fournisseur_service --MTIA - EDB260
            FROM ap_suppliers pv, ap_supplier_sites_all pvs
           WHERE pv.vendor_id = pvs.vendor_id
             AND pv.segment1 = rec_fact.code_frs
             AND pvs.vendor_site_code = rec_fact.site_frs
             AND pvs.org_id = gn_org_id;

        EXCEPTION
          WHEN no_data_found THEN
            vn_pv_vendor_id                := NULL;
            vv_pv_segment1                 := NULL;
            vn_pvs_vendor_id               := NULL;
            vn_pvs_vendor_site_id          := NULL;
            vv_pvs_accts_pay_ccid          := NULL;
            vv_pvs_pay_group_lookup_code   := NULL;
            vv_pvs_pmnt_method_lookup_code := NULL;
            vv_fournisseur_service         := NULL; -- MTIA EDB260
          WHEN too_many_rows THEN
            pn_retcode := 1;
            pv_errbuf  := 'Erreur sur la recuperation des informations fournisseurs : ' ||
                          SQLERRM;
            dka_Tools_Pkg.put_log_message(pv_errbuf);

            reporte_erreur(rec_fact.rowid, pv_errbuf);
            vn_pv_vendor_id                := NULL;
            vv_pv_segment1                 := NULL;
            vn_pvs_vendor_id               := NULL;
            vn_pvs_vendor_site_id          := NULL;
            vv_pvs_accts_pay_ccid          := NULL;
            vv_pvs_pay_group_lookup_code   := NULL;
            vv_pvs_pmnt_method_lookup_code := NULL;
            vv_fournisseur_service         := NULL; -- MTIA EDB260
        END;
        BEGIN

          SELECT REPLACE(IEPPM.PAYMENT_METHOD_CODE, ';', '')
            INTO vv_pv_pmnt_method_lookup_code
            FROM HZ_PARTY_SITES          SITE_SUPP,
                 HZ_PARTIES              HZP,
                 IBY_EXTERNAL_PAYEES_ALL IEP,
                 IBY_EXT_PARTY_PMT_MTHDS IEPPM
           WHERE HZP.PARTY_ID = vn_party_id
             AND HZP.PARTY_ID = SITE_SUPP.PARTY_ID
             AND SITE_SUPP.PARTY_SITE_ID = vn_party_site_id
             AND IEP.PAYEE_PARTY_ID = HZP.PARTY_ID
             AND IEP.PARTY_SITE_ID = SITE_SUPP.PARTY_SITE_ID
             AND IEP.SUPPLIER_SITE_ID = vn_pvs_vendor_site_id
             AND IEP.EXT_PAYEE_ID = IEPPM.EXT_PMT_PARTY_ID
             AND IEPPM.primary_flag = 'Y'
             AND IEP.ORG_TYPE IS NOT NULL
             AND SYSDATE >= NVL(IEPPM.inactive_date, SYSDATE);

        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vv_pv_pmnt_method_lookup_code := NULL;
          WHEN OTHERS THEN
            pn_retcode := 1;
            pv_errbuf  := 'Erreur sur la recuperation des informations fournisseurs (payment_method):' ||
                          SQLERRM;
            dka_Tools_Pkg.put_log_message(pv_errbuf);

            vv_pv_pmnt_method_lookup_code := NULL;
        END;

        -- rg11: recuperation de la date comptable
        --MTIA INC0319253 - le 22/09/2020 - RG sur le quickmatch sur tache fermee
        IF vd_gl_date IS NULL THEN
          BEGIN
            SELECT gps.start_date, gps.end_date, gps.closing_status
              INTO vd_start_date, vd_gl_date, vv_closing_status
              FROM gl_period_statuses gps
             WHERE gps.application_id = 200
               AND gps.set_of_books_id = gn_ledger_id
               AND trunc(SYSDATE) BETWEEN trunc(gps.start_date) AND
                   trunc(gps.end_date);
          EXCEPTION
            WHEN OTHERS THEN
              dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                            ' - Erreur ' || SQLERRM);
              dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                            ' - Erreur lors de la recuperation de la date comptable');
              reporte_erreur(rec_fact.rowid,
                             'Erreur sur la recuperation de la date comptable');
              RAISE e_generic;
          END;
          IF vv_closing_status != 'O' THEN
            dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                          ' - La date comptable de la facture ' ||
                                          rec_fact.num_fact || ' (' ||
                                          vd_gl_date || ') n''est pas ' ||
                                          'dans une periode ouverte');
            reporte_erreur(rec_fact.rowid,
                           'La date comptable de la facture (' ||
                           vd_gl_date ||
                           ') n''est pas dans une periode ouverte');
            RAISE e_generic;
          END IF;
        END IF;
        -- DÃ?Â©termination origine de la facture MTIA - EDB264 - Modification IVALUA
        IF rec_fact.batchno like '%DSP%' THEN
          vv_attribute9 := 'DSP';
        ELSE
          vv_attribute9 := 'XGS';
        END IF;

        -- rg24
        vn_terms_id       := NULL;
        vd_terms_date     := NULL;
        vb_is_prelevement := FALSE;
        IF rec_fact.reglement = 1 or
           vv_pvs_pmnt_method_lookup_code = 'WIRE' THEN
          -- dans le cas d'une facture avec prelevement, entrer la date d'echeance
          vb_is_prelevement := TRUE;
          vn_terms_id       := gn_term_id;
          vd_terms_date     := TO_DATE(rec_fact.date_echeance, 'YYYYMMDD');
        END IF;

        -- rechercher les codes rejets "interessants"
        check_code_rejet(rec_fact.code_rejet,
                         vb_code_rejet1_found,
                         vb_code_rejet2_found,
                         vb_code_rejet3_found,
                         vb_code_rejet4_found);

        -- rg13
        vv_attribute13 := rec_fact.no_commande;

        IF rec_fact.no_commande IS NOT NULL THEN
          vv_order_type := Substr(rec_fact.no_commande, -6, 2);
          ---EDB396 KHH
          vv_order_type_sstr := Substr(rec_fact.no_commande, 0, 2);
        END IF;

        -- rg02/rg04/rg06
        IF (rec_fact.no_commande IS NULL OR vb_code_rejet1_found) THEN
          -- si il existe un code rejet 1 la facture est consideree sans commande
          -- facture sans commande
          vv_hold_name := 'Imputation en attente';
          vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
        ELSE
          -- facture avec commande
          --M5 considerer la facture comme facture avec commande uniquemement si aucun code rejet 1
          IF NOT vb_code_rejet1_found THEN
            IF vb_code_rejet2_found THEN
              -- facture multi commande
              vv_hold_name := 'Multi-commandes';
              vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                              ' MULTI-COMMANDES';
            ELSE
              vv_hold_name := NULL;
              vv_group_id  := rec_fact.code_region || rec_fact.code_societe;
            END IF;
          END IF;
        END IF;

        IF rec_fact.type_piece = '0001' THEN
          vv_invoice_type_lookup_code := 'STANDARD';
          vn_invoice_amount           := round(abs(rec_fact.mttc_devise) / 100,
                                               cn_round);
        ELSE
          vv_invoice_type_lookup_code := 'CREDIT';
          vn_invoice_amount           := -round(abs(rec_fact.mttc_devise) / 100,
                                                cn_round);

          vn_terms_id   := gn_term_id;
          vd_terms_date := NULL;
        END IF;

        -- rg14
        ---EDB396 KHH
        IF (rec_fact.no_commande IS NULL OR vb_code_rejet1_found OR
           vv_order_type = 'ST' or vv_order_type_SSTR ='ST') --  M5 si il existe un code rejet 1 la facture est consideree sans commande
           AND NOT vb_is_prelevement THEN
          --RG2
          vv_attribute14 := 'En attente';
        ELSE
          vv_attribute14 := NULL;
        END IF;

        -- rg07 - Modification pour IVALUA: MTIA EDB264
        if vv_attribute9 = 'XGS' THEN
        BEGIN
          SELECT fdsa.category_code
            INTO vv_doc_category_code
            FROM fnd_doc_sequence_assignments fdsa
           WHERE fdsa.category_code = rec_fact.code_societe || '_SCAN_XGS'
             AND fdsa.method_code = 'A'
             AND fdsa.set_of_books_id = gn_ledger_id
             AND trunc(vd_gl_date) BETWEEN trunc(fdsa.start_date)
                --AND trunc(nvl(fdsa.end_date, SYSDATE))                       -- OBE artf2141124
                 AND
                 trunc(nvl(fdsa.end_date, GREATEST(SYSDATE, vd_gl_date))) -- OBE artf2141124
          ;
        EXCEPTION
          WHEN OTHERS THEN
            pv_errbuf := 'Erreur lors de la recuperation de la categorie ' ||
                         rec_fact.code_societe || '_SCAN_XGS' ||
                         ' (ledger_id = ' || gn_ledger_id ||
                         ') pour la facture' || rec_fact.num_fact || ' : ' ||
                         SQLERRM;
            dka_Tools_Pkg.put_log_message(pv_errbuf);
            pn_retcode           := 1;
            vv_doc_category_code := NULL;
        END;
       END IF;
      IF vv_attribute9 = 'DSP' THEN
        BEGIN
          SELECT fdsa.category_code
            INTO vv_doc_category_code
            FROM fnd_doc_sequence_assignments fdsa
           WHERE fdsa.category_code = rec_fact.code_societe || '_IVALUA'
             AND fdsa.method_code = 'A'
             AND fdsa.set_of_books_id = gn_ledger_id
             AND trunc(vd_gl_date) BETWEEN trunc(fdsa.start_date)
                --AND trunc(nvl(fdsa.end_date, SYSDATE))                       -- OBE artf2141124
                 AND
                 trunc(nvl(fdsa.end_date, GREATEST(SYSDATE, vd_gl_date))) -- OBE artf2141124
          ;
        EXCEPTION
          WHEN OTHERS THEN
            pv_errbuf := 'Erreur lors de la rÃ?Â©cupÃ?Â©ration de la catÃ?Â©gorie ' ||
                         rec_fact.code_societe || '_IVALUA' ||
                         ' (ledger_id = ' || gn_ledger_id ||
                         ') pour la facture' || rec_fact.num_fact || ' : ' ||
                         SQLERRM;
            dka_Tools_Pkg.put_log_message(pv_errbuf);
            pn_retcode           := 1;
            vv_doc_category_code := NULL;
        END;
      END IF;
        -- rg10
        IF vv_pvs_accts_pay_ccid IS NULL THEN
          vv_accts_pay_ccid := NULL;
        ELSE
          vv_accts_pay_ccid := vv_pvs_accts_pay_ccid;
        END IF;
        l_multiple_GY := 0;
        --Determination si Commande sur Tache GY pour TVA IMMO -- MTIA EDB260 -- 12/08/2020
        BEGIN
          select count(distinct dicv.type_tache)
            into l_multiple_GY
            from dka_iapfacxgs_cde_valid_lig_v dicv,
                 hr_all_organization_units     houa
           where dicv.num_cde = rec_fact.no_commande
             and dicv.org_id = houa.organization_id
             and rec_fact.code_region || rec_fact.code_societe = houa.name
             AND EXISTS (select 'X'
                    from dka_iapfacxgs_cde_valid_lig_v dicv1
                   where dicv.id_cde = dicv1.id_cde
                     and dicv1.type_tache = 'GY');
        EXCEPTION
          wHEN NO_DATA_FOUND THEN
            l_multiple_GY := 0;
        END;
        -- rg17: determination du type de facture
        vn_type_facture := 4;

        IF rec_fact.no_commande IS NOT NULL AND NOT vb_code_rejet1_found THEN
          -- M5
          BEGIN
            SELECT 1
              INTO vn_dummy
              FROM dual
             WHERE EXISTS
             (SELECT 1
                      FROM dka_iapfacxgs_cde_valid_lig_v xiv
                     WHERE xiv.num_cde = rec_fact.no_commande
                       AND (nvl(xiv.date_ferm_projet, vd_gl_date) >=
                           vd_gl_date or xiv.date_ferm_projet between
                           vd_start_date and vd_gl_date)
                       AND (nvl(xiv.date_ferm_tache, vd_gl_date) >=
                           vd_gl_date or xiv.date_ferm_tache between
                           vd_start_date and vd_gl_date) --MTIA INC0319253
                       AND xiv.societe_projet = rec_fact.code_societe
                          --- 04/04/2018 NBO artf2483384 : INC0204462 - INT047 - Interface XEROx
                       AND xiv.org_id = gn_org_id
                    UNION ALL
                    SELECT 1
                      FROM dka_iapfacxgs_cde_valid_lig_v xiv
                     WHERE xiv.num_cde = rec_fact.no_commande
                          --- 04/04/2018 NBO artf2483384 : INC0204462 - INT047 - Interface XEROx
                       AND xiv.org_id = gn_org_id
                       AND (nvl(xiv.date_ferm_projet, vd_gl_date) >=
                           vd_gl_date or xiv.date_ferm_projet between
                           vd_start_date and vd_gl_date)
                       AND (nvl(xiv.date_ferm_tache, vd_gl_date) >=
                           vd_gl_date or xiv.date_ferm_tache between
                           vd_start_date and vd_gl_date) --MTIA INC0319253
                       AND xiv.societe_projet != rec_fact.code_societe
                       AND transaction_type(xiv.type_depense) = 'REFAC');             vn_type_facture := 3;

          EXCEPTION
            WHEN no_data_found THEN
              null; -- SELO
          END;
        END IF; 


        -- rg18: regles de rapprochement
        IF vn_type_facture = 3 THEN       --- KAFI-1039 ;Recette KAFI-838 - Intégration XEROX 
                                           --- rec_fact.no_commande LIKE 'ST%' 
          IF rec_fact.no_commande LIKE '%ST____' Or  rec_fact.no_commande LIKE 'ST%' THEN
            -- Modification - MSL artf535507
            vv_type_lig := '0003_SSTRT';



          ELSE
            BEGIN

              SELECT SUM(round(xiv.qte_cde * xiv.prix_unit, cn_round))
                INTO vn_montant_total
                FROM dka_iapfacxgs_cde_valid_lig_v xiv
               WHERE xiv.num_cde = rec_fact.no_commande
                    --- 04/04/2018 NBO artf2483384 : INC0204462 - INT047 - Interface XEROx
                 AND xiv.org_id = gn_org_id
                 AND (nvl(xiv.date_ferm_projet, vd_gl_date) >= vd_gl_date or
                     xiv.date_ferm_projet between vd_start_date and
                     vd_gl_date)
                 AND (nvl(xiv.date_ferm_tache, vd_gl_date) >= vd_gl_date or
                     xiv.date_ferm_tache between vd_start_date and
                     vd_gl_date) --MTIA INC0319253
                 AND (xiv.societe_projet = rec_fact.code_societe OR
                     transaction_type(xiv.type_depense) = 'REFAC');

            EXCEPTION
              WHEN OTHERS THEN

                dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                              ' - Erreur ' || SQLERRM);
                dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                              ' - Erreur lors du calcul du ' ||
                                              'montant total de la commande ' ||
                                              rec_fact.no_commande);
                reporte_erreur(rec_fact.rowid,
                               'Erreur lors du calcul du ' ||
                               'montant total de la commande ' ||
                               rec_fact.no_commande);
                RAISE e_generic;
            END;
            IF round((rec_fact.mht_devise / 100), cn_round) =
               vn_montant_total THEN
              vv_type_lig := '0003_ALLCDE';

            ELSE
              -- on est force de tester deux fois, cf 3eme point de la regle 18
              -- vn_dummy2

              IF rec_fact.packing_slip IS NOT NULL THEN
                BEGIN

                  SELECT 1
                    INTO vn_dummy2
                    FROM dual
                   WHERE exists
                   (SELECT 1
                            FROM dka_iapfacxgs_cde_valid_lig_v xiv
                           WHERE xiv.num_cde = rec_fact.no_commande
                                --- 04/04/2018 NBO artf2483384 : INC0204462 - INT047 - Interface XEROx
                             AND xiv.org_id = gn_org_id
                             AND lower(TRIM(xiv.packing_slip)) =
                                 lower(TRIM(rec_fact.packing_slip)));
                EXCEPTION
                  WHEN no_data_found THEN
                    vn_dummy2 := 0;

                END;
              END IF;
        IF rec_fact.packing_slip IS NOT NULL AND vn_dummy2 = 1 THEN
                vv_type_lig := '0003_BL';
        ELSE
                BEGIN
            SELECT COUNT(*)
                    INTO vn_dummy2
                    FROM dka_iapfacxgs_cde_valid_lig_v xiv
                  --- 04/04/2018 NBO artf2483384 : INC0204462 - INT047 - Interface XEROx
                   WHERE xiv.num_cde = rec_fact.no_commande
                     AND xiv.org_id = gn_org_id;
                EXCEPTION
                  WHEN OTHERS THEN
                    dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                                  ' - Erreur ' || SQLERRM);
                    dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                                  ' - Erreur lors du calcul du ' ||
                                                  'nombre de ligne de la commande ' ||
                                                  rec_fact.no_commande);
                    reporte_erreur(rec_fact.rowid,
                                   'Erreur lors du calcul du ' ||
                                   'nombre de ligne de la commande ' ||
                                   rec_fact.no_commande);
                    RAISE e_generic;
                END;
        ---<DEBUT IBA EDB350
  Dka_Tools_Pkg.Get_Parameter(cv_program_code,
                                'NB_LIGNES_112_BLOCAGE',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      VN_NB_LIGNES_112_BLOCAGE := 0;
    ELSE
      VN_NB_LIGNES_112_BLOCAGE := vr_data.number_value;
    END IF;
     dka_Tools_Pkg.put_log_message('VN_NB_LIGNES_112_BLOCAGE : ' ||
                                      VN_NB_LIGNES_112_BLOCAGE);
     dka_Tools_Pkg.put_log_message('vn_dummy2 : ' ||
                                     vn_dummy2);
                IF vn_dummy2 <= VN_NB_LIGNES_112_BLOCAGE THEN
        --FIN IBA EDB350>
                  vv_type_lig := '0003_GENERAL';
                ELSE
                  vn_type_facture := 4;

                  ajout_code_99(rec_fact.code_rejet);
                END IF;
              END IF;
            END IF;
          END IF;
        END IF;

        IF vn_type_facture = 4 THEN
          -- rg04
          vv_hold_name := 'Imputation en attente';
          vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';

          -- rg14
          IF NOT vb_is_prelevement THEN
            vv_attribute14 := 'En attente';
          ELSE
            vv_attribute14 := NULL;
          END IF;
        END IF;

        -- Les valeurs de group_id et hold_name sont maintenant determinees.
        -- On les met dans un tableau pour les lancements du traitement
        -- standard d'import des commandes
        dka_tools_pkg.put_log_message('vv_hold_name :' || vv_hold_name);
        dka_tools_pkg.put_log_message('vv_group_id  :' || vv_group_id);
        IF NOT va_group_id.exists(vv_group_id) THEN
          va_group_id(vv_group_id) := vv_hold_name;
        END IF;

        --rg 08
        vv_pay_group_lookup_code := vv_pvs_pay_group_lookup_code;

        --rg 25
        IF rec_fact.code_frs is not null and vn_pvs_vendor_site_id is null THEN
          vn_pvs_vendor_site_id := -999;
        END IF;

        --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
        vv_vendor_site_code   := rec_fact.site_frs;
        vb_code_rejet98_found := FALSE;
        IF rec_fact.code_rejet like '%98%' THEN
          vn_pvs_vendor_site_id := -999;
          vv_vendor_site_code   := NULL;
          vb_code_rejet98_found := TRUE;

        END IF;

        -- on peut maintenant inserer l'entete
        -- insertion de l'entete
        vn_invoice_id := insert_header(REPLACE(rec_fact.num_fact, ' '),
                                       vv_invoice_type_lookup_code,
                                       to_date(rec_fact.date_piece, 'YYYYMMDD'),
                                       vv_group_id,
                                       gn_org_id,
                                       vd_gl_date,
                                       CASE
                                         WHEN vb_code_rejet3_found THEN
                                          rec_fact.code_frs || ' - A VERIFIER'
                                       -- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
                                         WHEN vb_code_rejet98_found THEN
                                          rec_fact.code_frs || ' - DOUBLON'
                                         ELSE
                                          rec_fact.code_frs
                                       END,
                                       vn_pvs_vendor_site_id,
                                       --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
                                       --rec_fact.site_frs,
                                       vv_vendor_site_code,
                                       vn_invoice_amount,
                                       rec_fact.code_devise,
                                       vn_terms_id,
                                       CASE rec_fact.code_rejet
                                         WHEN '00' THEN
                                          NULL
                                         ELSE
                                          rec_fact.code_rejet
                                       END,
                                       rec_fact.reference_lad,
                                       vv_attribute8,
                                       vv_attribute9, --EDB264 - IVALUA - MTIA le 14/10/2020
                                       rec_fact.reference_lad,
                                       vv_attribute13,
                                       vv_attribute14,
                                       rec_fact.code_societe,
                                       vv_doc_category_code,
                                       vv_accts_pay_ccid,
                                       vv_pay_group_lookup_code,
                                       CASE
                                         WHEN vb_is_prelevement THEN
                                          'WIRE'
                                         ELSE
                                          NULL
                                       END,
                                       rec_fact.code_region ||
                                       rec_fact.code_societe ||
                                       LPAD(rec_fact.batchno, 4, '0') ||
                                       LPAD(rec_fact.batchidx, 3, '0') ||
                                       to_char(SYSDATE, 'DDMMYY'),
                                       gv_global_attribute_category,
                                       CASE rec_fact.type_tva
                                         WHEN 'EN' THEN
                                          'CRE/M'
                                         ELSE
                                          'DEB/M'
                                       END,
                                       vd_terms_date);

        vn_header_count      := vn_header_count + 1;
        vn_line_group_number := 1;

        --MTIA - Determination type de TVA - EDB260 le 12/08/2020

        If l_multiple_GY = 0 THEN
          -- gestion des lignes
          -- rg19: recuperation des infos de tva
      BEGIN
            if rec_fact.type_tva = 'EN' THEN
              vv_name := 'DED_' || substr(rec_fact.taux_tva, 1, 2) || '.' ||
                         substr(rec_fact.taux_tva, -2, 2) || 'E';
            ELSIF nvl(rec_fact.type_tva, 'DE') IN ('DE', 'EX') THEN  --EDB325B enlevÃ?Â© 'IC
              vv_name := 'DED_' || substr(rec_fact.taux_tva, 1, 2) || '.' ||
                         substr(rec_fact.taux_tva, -2, 2) || 'D';
      ELSIF nvl(rec_fact.type_tva, 'DE') IN ('IC') THEN --EDB325B
        IF vv_fournisseur_service = 'N' then
           vv_name := 'DED_' || substr(rec_fact.taux_tva, 1, 2) || '.' ||
                         substr(rec_fact.taux_tva, -2, 2) || 'D';
        ELSE
            vv_name := 'DED_' || substr(rec_fact.taux_tva, 1, 2) || '.' ||
                    substr(rec_fact.taux_tva, -2, 2) || 'E';
                END IF;
            END IF;

            SELECT tax_rate_code,
                   tax_regime_code,
                   tax,
                   tax_jurisdiction_code,
                   tax_status_code,
                   offset_status_code
              INTO vv_tax_rate_code,
                   vv_tax_regime_code,
                   vv_tax,
                   vv_tax_jurisdiction_code,
                   vv_tax_status_code,
                   vv_offset_status_code
              FROM ZX_RATES_B
             WHERE tax_rate_code = vv_name
                  --AND SYSDATE > effective_from
               AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
                   NVL(effective_to, sysdate)
               AND active_flag = 'Y'
               AND tax_jurisdiction_code = 'FR_JURIDICTION';

          EXCEPTION
            WHEN OTHERS THEN
              pv_errbuf := 'Erreur lors de la recuperation ' ||
                           'des informations de tva pour le code TVA ' ||
                           vv_name || 'de la facture ' || rec_fact.num_fact ||
                           ' : ' || SQLERRM;
              dka_Tools_Pkg.put_log_message(pv_errbuf);
              reporte_erreur(rec_fact.rowid, pv_errbuf);

              pn_retcode            := 1;
              vn_tax_id             := NULL;
              vn_tax_ccid           := NULL;
              vn_tax_recovery_rate  := NULL;
              vn_offset_tax_code_id := NULL;

          END;
          -- si tva intra communautaire, recuperer les infos relatives
          IF rec_fact.type_tva = 'IC' THEN
            BEGIN
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     percentage_rate
                INTO vv_ic_tax_rate_code,
                     vv_ic_tax_regime_code,
                     vv_ic_tax,
                     vv_ic_tax_jurisdiction_code,
                     vv_ic_tax_status_code,
                     vn_ic_tax_rate
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_offset_status_code -- SNK
                 AND SYSDATE > effective_from
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva (intra communautaire) pour le code ' ||
                             vn_tax_id || ' (offset: ' ||
                             vn_offset_tax_code_id || ') : ' || SQLERRM;
                dka_Tools_Pkg.put_log_message(pv_errbuf);
                reporte_erreur(rec_fact.rowid, pv_errbuf);
                -- pn_retcode              := 1;
                vn_ic_tax_id            := NULL;
                vv_ic_name              := NULL;
                vn_ic_tax_ccid          := NULL;
                vn_ic_tax_recovery_rate := NULL;
                vn_ic_tax_rate          := NULL;
            END;
          END IF;
        ELSIF l_multiple_GY = 1 THEN
          --Que des GY sur la commande on gore la TVA IMMO
          --MTIA - EDB260 - TVA Immo ?
          IF vv_fournisseur_service = 'N' then
            BEGIN
              vv_name := 'DED_' || substr(rec_fact.taux_tva, 1, 2) || '.' ||
                         substr(rec_fact.taux_tva, -2, 2) || 'ID';
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     offset_status_code
                INTO vv_tax_rate_code,
                     vv_tax_regime_code,
                     vv_tax,
                     vv_tax_jurisdiction_code,
                     vv_tax_status_code,
                     vv_offset_status_code
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_name
                    --AND SYSDATE > effective_from
                 AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
                     NVL(effective_to, sysdate)
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva immo pour le code TVA ' ||
                             vv_name || 'de la facture ' ||
                             rec_fact.num_fact || ' : ' || SQLERRM;
                dka_Tools_Pkg.put_log_message(pv_errbuf);
                reporte_erreur(rec_fact.rowid, pv_errbuf);
                pn_retcode            := 1;
                vn_tax_id             := NULL;
                vn_tax_ccid           := NULL;
                vn_tax_recovery_rate  := NULL;
                vn_offset_tax_code_id := NULL;

            END;
          ELse
            --vv_fournisseur_service = 'N' then

            BEGIN
              vv_name := 'DED_' || substr(rec_fact.taux_tva, 1, 2) || '.' ||
                         substr(rec_fact.taux_tva, -2, 2) || 'IE';
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     offset_status_code
                INTO vv_tax_rate_code,
                     vv_tax_regime_code,
                     vv_tax,
                     vv_tax_jurisdiction_code,
                     vv_tax_status_code,
                     vv_offset_status_code
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_name
                    --AND SYSDATE > effective_from
                 AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
                     NVL(effective_to, sysdate)
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva immo pour le code TVA ' ||
                             vv_name || 'de la facture ' ||
                             rec_fact.num_fact || ' : ' || SQLERRM;
                dka_Tools_Pkg.put_log_message(pv_errbuf);
                reporte_erreur(rec_fact.rowid, pv_errbuf);

                pn_retcode            := 1;
                vn_tax_id             := NULL;
                vn_tax_ccid           := NULL;
                vn_tax_recovery_rate  := NULL;
                vn_offset_tax_code_id := NULL;
            end;
          end if;
          IF rec_fact.type_tva = 'IC' THEN
            BEGIN
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     percentage_rate
                INTO vv_ic_tax_rate_code,
                     vv_ic_tax_regime_code,
                     vv_ic_tax,
                     vv_ic_tax_jurisdiction_code,
                     vv_ic_tax_status_code,
                     vn_ic_tax_rate
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_offset_status_code -- SNK
                 AND SYSDATE > effective_from
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva (intra communautaire) pour le code ' ||
                             vn_tax_id || ' (offset: ' ||
                             vn_offset_tax_code_id || ') : ' || SQLERRM;
                dka_Tools_Pkg.put_log_message(pv_errbuf);
                reporte_erreur(rec_fact.rowid, pv_errbuf);
                --    pn_retcode              := 1;
                vn_ic_tax_id            := NULL;
                vv_ic_name              := NULL;
                vn_ic_tax_ccid          := NULL;
                vn_ic_tax_recovery_rate := NULL;
                vn_ic_tax_rate          := NULL;
            END;
          END IF;
        ELSE
          IF vv_fournisseur_service = 'N' then
        BEGIN
              vv_name := 'DED_00.00D';
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     offset_status_code
                INTO vv_tax_rate_code,
                     vv_tax_regime_code,
                     vv_tax,
                     vv_tax_jurisdiction_code,
                     vv_tax_status_code,
                     vv_offset_status_code
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_name
                    --AND SYSDATE > effective_from
                 AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
                     NVL(effective_to, sysdate)
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva immo pour le code TVA ' ||
                             vv_name || 'de la facture ' ||
                             rec_fact.num_fact || ' : ' || SQLERRM;
                dka_Tools_Pkg.put_log_message(pv_errbuf);
                reporte_erreur(rec_fact.rowid, pv_errbuf);

                pn_retcode            := 1;
                vn_tax_id             := NULL;
                vn_tax_ccid           := NULL;
                vn_tax_recovery_rate  := NULL;
                vn_offset_tax_code_id := NULL;

            END;
          ELse
            --vv_fournisseur_service = 'N' then
        BEGIN
              vv_name := 'DED_00.00E';
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     offset_status_code
                INTO vv_tax_rate_code,
                     vv_tax_regime_code,
                     vv_tax,
                     vv_tax_jurisdiction_code,
                     vv_tax_status_code,
                     vv_offset_status_code
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_name
                    --AND SYSDATE > effective_from
                 AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
                     NVL(effective_to, sysdate)
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva immo pour le code TVA ' ||
                             vv_name || 'de la facture ' ||
                             rec_fact.num_fact || ' : ' || SQLERRM;
                dka_Tools_Pkg.put_log_message(pv_errbuf);
                reporte_erreur(rec_fact.rowid, pv_errbuf);

                pn_retcode            := 1;
                vn_tax_id             := NULL;
                vn_tax_ccid           := NULL;
                vn_tax_recovery_rate  := NULL;
                vn_offset_tax_code_id := NULL;
            end;
          end if;
          IF rec_fact.type_tva = 'IC' THEN
            BEGIN
              SELECT tax_rate_code,
                     tax_regime_code,
                     tax,
                     tax_jurisdiction_code,
                     tax_status_code,
                     percentage_rate
                INTO vv_ic_tax_rate_code,
                     vv_ic_tax_regime_code,
                     vv_ic_tax,
                     vv_ic_tax_jurisdiction_code,
                     vv_ic_tax_status_code,
                     vn_ic_tax_rate
                FROM ZX_RATES_B
               WHERE tax_rate_code = vv_offset_status_code -- SNK
                 AND SYSDATE > effective_from
                 AND active_flag = 'Y'
                 AND tax_jurisdiction_code = 'FR_JURIDICTION';

            EXCEPTION
              WHEN OTHERS THEN
                pv_errbuf := 'Erreur lors de la recuperation ' ||
                             'des informations de tva (intra communautaire) pour le code ' ||
                             vn_tax_id || ' (offset: ' ||
                             vn_offset_tax_code_id || ') : ' || SQLERRM;
                reporte_erreur(rec_fact.rowid, pv_errbuf);
                --        pn_retcode              := 1;
                vn_ic_tax_id            := NULL;
                vv_ic_name              := NULL;
                vn_ic_tax_ccid          := NULL;
                vn_ic_tax_recovery_rate := NULL;
                vn_ic_tax_rate          := NULL;
            END;
          END IF;
        END IF;

        -- attribute2 (commun a toutes les lignes pour une meme facture)
        vv_attribute2 := LPAD(rec_fact.batchidx, 3);

        -- initialisation du compteur de lignes
        vn_line_number := 0;

        dka_Tools_Pkg.put_log_message('vn_type_facture : ' ||
                                      vn_type_facture);
        dka_Tools_Pkg.put_log_message('vv_type_lig : ' || vv_type_lig);

        v_avoir_rapproche := 0;
        --  IF rec_fact.type_tva <> 'IC' THEN   - MTIABL
        --SNK EDB235 30/04/19

        v_total_article := 0;
        l_cas1          := 0;
        l_cas4          := 0;
    l_cas2          := 0; --SELO EDB235B
    l_cas2A         := 0; --IBA EDB355
    l_cas3          := 0; --SELO EDB235B
    l_cas5          := 0; --SELO EDB235B
    l_cas6          := 0; --SELO EDB235B
    l_cas7          := 0; --SELO EDB235B
    l_cas8          := 0; --SELO EDB235B
    l_cas9          := 0; --SELO EDB235B

        -- Verification des factures recues avec un code IC
        IF rec_fact.type_tva = 'IC' THEN
  --  dka_Tools_Pkg.put_log_message('type_tva = IC'  );

          BEGIN
            SELECT authorization_status
              INTO v_cmd_status
              FROM po_headers_all
             WHERE segment1 = rec_fact.no_commande
               AND org_id = rec_fact.organization_id;
          EXCEPTION
            WHEN OTHERS THEN
              v_cmd_status := NULL;
          END;

          BEGIN
            SELECT vat_registration_num
              INTO v_num_ic_frs
              FROM po_vendors
             WHERE segment1 = rec_fact.code_frs;
          EXCEPTION
            WHEN OTHERS THEN
              v_num_ic_frs := NULL;
          END;
          IF vn_type_facture = 3 THEN
            IF vv_type_lig = '0003_SSTRT' THEN
              -- gestion des lignes de validation
              FOR rec_line IN cur_lines1(rec_fact.no_commande,
                                         vd_gl_date,
                                         vd_start_date,
                                         rec_fact.code_societe) LOOP

                IF (((rec_fact.type_piece = '0001') and
                   (rec_line.qte_fact < rec_line.qte_cde)) or
                   (rec_fact.type_piece != '0001')) then
                  --EDB223 - SELO
                  vn_amount :=  -- Quantite Projet
                   (rec_line.qte_cde * rec_line.prix_unit)
                              -- Mutipliee par le quotient de la somme du montant de la facture ht et des montant deja rapproches de la commande
                              -- par le montant total de la commande
                               * ((rec_fact.mht_devise / 100) +
                               rec_line.mont_rappro) /
                               po_headers_pkg_s2.po_total(rec_line.id_cde)
                              -- moins le montant deja facture pour le projet
                               - (rec_line.qte_fact * rec_line.prix_unit);
                  IF ((vn_amount < 0) and (rec_fact.type_piece = '0001')) THEN
                    vn_amount := 0;
                  ELSE
                    vn_amount := round(vn_amount, cn_round);
                  END IF;

                  IF (rec_fact.type_piece != '0001') and (vn_amount > 0) then
                    vn_amount := -vn_amount;
                  END IF;
                end if;
                v_total_article := v_total_article + vn_amount;

              END LOOP;
            ELSIF vv_type_lig IN ('0003_ALLCDE', '0003_GENERAL') THEN
              -- gestion des lignes de validation
              FOR rec_line IN cur_lines1(rec_fact.no_commande,
                                         vd_gl_date,
                                         vd_start_date,
                                         rec_fact.code_societe) LOOP

                IF (((rec_fact.type_piece = '0001') and
                   (rec_line.qte_fact < rec_line.qte_cde)) or
                   (rec_fact.type_piece != '0001')) then

                  -- rg20: montant de la ligne
                  vn_amount := round(abs((rec_line.qte_cde -
                                         rec_line.qte_fact) *
                                         rec_line.prix_unit),
                                     cn_round);


    --< BNZ EDB376
  dka_Tools_Pkg.put_log_message(' BNZ !=  vn_type_facture = 3 AND l_multiple_GY < 2 ( Partie 1 ) '  );

    if (Number_lines(rec_line.num_cde) = 1 AND vv_type_lig = '0003_GENERAL') then

  dka_Tools_Pkg.put_log_message('Facture Type :  ' || vv_type_lig );

         select count(*) into v_count from dka_iapfacxgs_interface where no_commande = rec_line.num_cde and flag_trt is null;
      if v_count > 1 then
      dka_Tools_Pkg.put_log_message('==== > Commande avec plusieur Facture  NÂ° :  ' || v_count || 'Factures' );
         begin
         select Mht_dispo
         into v_Mht_dispo
         from DKA_IAPFACXGS_MTDISP where no_commande = rec_line.num_cde and org_id = gn_org_id ;
     exception WHEN OTHERS then
     v_Mht_dispo := NULL ;

     end;

       dka_Tools_Pkg.put_log_message('===== > 1: Montant dispo :  ' || v_Mht_dispo );

        if v_Mht_dispo IS NULL then

      v_Mht_dispo := vn_amount;
      dka_Tools_Pkg.put_log_message('====== > 2: Montant dispo Null :  ' || v_Mht_dispo );
        else
      vn_amount := v_Mht_dispo;
      dka_Tools_Pkg.put_log_message('====== > 3: New Montant dispo  :  ' || vn_amount );
        end if ;



            if vn_amount >= round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round) then
                    vn_amount := round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round);
              dka_Tools_Pkg.put_log_message('===== > Dispo < Montant XEROX = ' || vn_amount );
        v_mht_dispo :=  v_mht_dispo - vn_amount ;
      else
      vn_amount   := v_Mht_dispo;
      v_Mht_dispo := 0 ;
      dka_Tools_Pkg.put_log_message('===== > Last Montant Dispo  = ' || vn_amount );
      end if;

    dka_Tools_Pkg.put_log_message('Commande avec 1 ligne . Montant dispo :  ' || v_Mht_dispo );


    else
             dka_Tools_Pkg.put_log_message('==== > Seule Facture , Montant Dispo  = ' || vn_amount );

                   if vn_amount >= round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round) then
                    vn_amount := round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round);

          end if;
     end if ;


    end if;

  --> BNZ EDB376

                  IF (rec_fact.type_piece != '0001') and (vn_amount > 0) then
                    vn_amount := -vn_amount;
                  END IF;
                end if;
                v_total_article := v_total_article + vn_amount;


              END LOOP;
            ELSIF vv_type_lig = '0003_BL' THEN
              -- gestion des lignes de validation
              FOR rec_line IN cur_lines2(rec_fact.no_commande,
                                         rec_fact.packing_slip,
                                         vd_gl_date,
                                         vd_start_date,
                                         rec_fact.code_societe) LOOP

                IF (((rec_fact.type_piece = '0001') and
                   (rec_line.qte_fact < rec_line.qte_cde)) or
                   (rec_fact.type_piece != '0001')) then
                  --EDB223 - SELO
                  -- rg20: montant de la ligne
                  vn_amount := round(abs((rec_line.qte_cde -
                                         rec_line.qte_fact) *
                                         rec_line.prix_unit),
                                     cn_round);

                  IF (rec_fact.type_piece != '0001') and (vn_amount > 0) then
                    vn_amount := -vn_amount;
                  END IF;
                end IF;
                v_total_article := v_total_article + vn_amount;
              END LOOP;
            END IF;
          END IF;

          --Verification si CAS 1
          IF v_cmd_status = 'APPROVED' AND rec_fact.taux_tva = '0000' -- SOUF
             AND rec_fact.no_commande IS NOT NULL -- SOUF
             AND round(v_total_article, cn_round) = vn_invoice_amount AND
             v_num_ic_frs IS NOT NULL THEN  -- original
            l_cas1 := 1;
      --    dka_Tools_Pkg.put_log_message('cas 1');
          END IF;

        --  dka_Tools_Pkg.put_log_message('no_commande = ' || rec_fact.no_commande);
        --  dka_Tools_Pkg.put_log_message('taux_tva = ' || rec_fact.taux_tva);
        --  dka_Tools_Pkg.put_log_message('vn_invoice_amount = ' || round(vn_invoice_amount, 0));
        --  dka_Tools_Pkg.put_log_message('v_total_article =' || round(nvl(v_total_article, 0) , 0));


          IF rec_fact.no_commande IS NOT NULL AND
             rec_fact.taux_tva = '2000' AND
             round(vn_invoice_amount, 0) =
             round(nvl(v_total_article, 0) * 1.2, 0)
            THEN
            --Verification si CAS 4
            l_cas4 := 1;
      --    dka_Tools_Pkg.put_log_message('cas 4');
          END IF;


      -- SELO EDB235B DEBUT
          IF rec_fact.no_commande IS NOT NULL AND
             rec_fact.taux_tva = '0000' AND
             round(v_total_article, cn_round) <> vn_invoice_amount THEN

        ---<DEBUT IBA EDB355
        Dka_Tools_Pkg.Get_Parameter(cv_program_code,
                      'ECART_ENERGIE_MAX',
                      Vr_Data,
                      Vn_Retcode,
                      Vv_Errbuf);

        IF Vn_Retcode != 0 THEN
          vn_ecart_max_facture := 0;
        ELSE
          vn_ecart_max_facture := vr_data.number_value;
        END IF;
        dka_Tools_Pkg.put_log_message('Ecart maximum  : ' ||
                        vn_ecart_max_facture);

        Dka_Tools_Pkg.Get_Parameter(cv_program_code,
                      'ECART_ENERGIE_MIN',
                      Vr_Data,
                      Vn_Retcode,
                      Vv_Errbuf);

        IF Vn_Retcode != 0 THEN
          vn_ecart_minime_facture := 0;
        ELSE
          vn_ecart_minime_facture := vr_data.number_value;
        END IF;
        dka_Tools_Pkg.put_log_message('Ecart minime : ' ||
                        vn_ecart_minime_facture);

          vn_ecart_facture := vn_invoice_amount - round(v_total_article, cn_round);
          --IF ABS(vn_ecart_facture) <= vn_ecart_minime_facture AND
            IF vn_ecart_facture <= vn_ecart_max_facture AND vn_ecart_facture >= vn_ecart_minime_facture
            THEN
             l_cas2A := 1;
            else
          ---FIN IBA EDB355>
                       l_cas2 := 1;
                 vv_hold_name := 'Imputation en attente';
                       vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
                    --    dka_Tools_Pkg.put_log_message('cas 2');
                        IF NOT va_group_id.exists(vv_group_id) THEN
                           va_group_id(vv_group_id) := vv_hold_name;
                        END IF;
                    END IF;   ---IBA EDB355
          END IF;

          IF rec_fact.no_commande IS NULL AND
             rec_fact.taux_tva = '0000' THEN
            l_cas3 := 1;
      vv_hold_name := 'Imputation en attente';
            vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
      --    dka_Tools_Pkg.put_log_message('cas 3');
          END IF;

          IF rec_fact.no_commande IS NOT NULL AND
             rec_fact.taux_tva <> '0000' AND
             round(vn_invoice_amount, 0) <>
             round(nvl(v_total_article, 0) * (1+ (to_number(rec_fact.taux_tva)/10000)), 0) THEN
            l_cas5 := 1;
      --    dka_Tools_Pkg.put_log_message('cas 5');
          END IF;

          IF rec_fact.no_commande IS NULL AND
             rec_fact.taux_tva = '2000' THEN
            l_cas6 := 1;
      vv_hold_name := 'Imputation en attente';
            vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
      --    dka_Tools_Pkg.put_log_message('cas 6');
          END IF;

          IF rec_fact.no_commande IS NOT NULL AND
             rec_fact.taux_tva <> '2000' AND rec_fact.taux_tva <> '0000' AND
             round(vn_invoice_amount, 0) =
             round(nvl(v_total_article, 0) * (1+ (to_number(rec_fact.taux_tva)/10000)), 0)
             THEN
            l_cas7 := 1;
      --    dka_Tools_Pkg.put_log_message('cas 7');
          END IF;

          IF rec_fact.no_commande IS NULL AND
             rec_fact.taux_tva <> '2000' AND rec_fact.taux_tva <> '0000' THEN
            l_cas8 := 1;
      vv_hold_name := 'Imputation en attente';
            vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
      --    dka_Tools_Pkg.put_log_message('cas 8');
          END IF;

      --    dka_Tools_Pkg.put_log_message('no_commande = ' || rec_fact.no_commande);
      --    dka_Tools_Pkg.put_log_message('taux_tva = ' || rec_fact.taux_tva);
      --    dka_Tools_Pkg.put_log_message('vn_invoice_amount = ' || round(vn_invoice_amount, 0));
      --    dka_Tools_Pkg.put_log_message('v_total_article =' || round(nvl(v_total_article, 0) , 0));

       IF v_cmd_status = 'APPROVED' AND rec_fact.taux_tva = '0000' -- SOUF
             AND rec_fact.no_commande IS NOT NULL -- SOUF
             AND round(v_total_article, cn_round) = vn_invoice_amount AND
             v_num_ic_frs IS  NULL THEN



             l_cas9 := 1;
      --          dka_Tools_Pkg.put_log_message('cas 9');
      IF vv_fournisseur_service = 'N' then
        BEGIN
          vv_name := 'DED_00.00D';
          SELECT tax_rate_code,
             tax_regime_code,
             tax,
             tax_jurisdiction_code,
             tax_status_code,
             offset_status_code
          INTO vv_tax_rate_code,
             vv_tax_regime_code,
             vv_tax,
             vv_tax_jurisdiction_code,
             vv_tax_status_code,
             vv_offset_status_code
          FROM ZX_RATES_B
           WHERE tax_rate_code = vv_name
            --AND SYSDATE > effective_from
           AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
             NVL(effective_to, sysdate)
           AND active_flag = 'Y'
           AND tax_jurisdiction_code = 'FR_JURIDICTION';

        EXCEPTION
          WHEN OTHERS THEN
          pv_errbuf := 'Erreur lors de la recuperation ' ||
                 'des informations de tva immo pour le code TVA ' ||
                 vv_name || 'de la facture ' ||
                 rec_fact.num_fact || ' : ' || SQLERRM;
          dka_Tools_Pkg.put_log_message(pv_errbuf);
          reporte_erreur(rec_fact.rowid, pv_errbuf);

          pn_retcode            := 1;
          vn_tax_id             := NULL;
          vn_tax_ccid           := NULL;
          vn_tax_recovery_rate  := NULL;
          vn_offset_tax_code_id := NULL;

        END;
        ELse
        --vv_fournisseur_service = 'N' then
        BEGIN
          vv_name := 'DED_00.00E';
          SELECT tax_rate_code,
             tax_regime_code,
             tax,
             tax_jurisdiction_code,
             tax_status_code,
             offset_status_code
          INTO vv_tax_rate_code,
             vv_tax_regime_code,
             vv_tax,
             vv_tax_jurisdiction_code,
             vv_tax_status_code,
             vv_offset_status_code
          FROM ZX_RATES_B
           WHERE tax_rate_code = vv_name
            --AND SYSDATE > effective_from
           AND SYSDATE BETWEEN NVL(effective_from, sysdate) AND
             NVL(effective_to, sysdate)
           AND active_flag = 'Y'
           AND tax_jurisdiction_code = 'FR_JURIDICTION';

        EXCEPTION
          WHEN OTHERS THEN
          pv_errbuf := 'Erreur lors de la recuperation ' ||
                 'des informations de tva immo pour le code TVA ' ||
                 vv_name || 'de la facture ' ||
                 rec_fact.num_fact || ' : ' || SQLERRM;
          dka_Tools_Pkg.put_log_message(pv_errbuf);
          reporte_erreur(rec_fact.rowid, pv_errbuf);

          pn_retcode            := 1;
          vn_tax_id             := NULL;
          vn_tax_ccid           := NULL;
          vn_tax_recovery_rate  := NULL;
          vn_offset_tax_code_id := NULL;
        end;
        end if;
      /*  IF rec_fact.type_tva = 'IC' THEN
        BEGIN

          SELECT tax_rate_code,
             tax_regime_code,
             tax,
             tax_jurisdiction_code,
             tax_status_code,
             percentage_rate
          INTO vv_ic_tax_rate_code,
             vv_ic_tax_regime_code,
             vv_ic_tax,
             vv_ic_tax_jurisdiction_code,
             vv_ic_tax_status_code,
             vn_ic_tax_rate
          FROM ZX_RATES_B
           WHERE tax_rate_code = vv_offset_status_code -- SNK
           AND SYSDATE > effective_from
           AND active_flag = 'Y'
           AND tax_jurisdiction_code = 'FR_JURIDICTION';

        EXCEPTION
          WHEN OTHERS THEN
          pv_errbuf := 'Erreur lors de la recuperation ' ||
                 'des informations de tva (intra communautaire) pour le code ' ||
                 vn_tax_id || ' (offset: ' ||
                 vn_offset_tax_code_id || ') : ' || SQLERRM;
          reporte_erreur(rec_fact.rowid, pv_errbuf);
          --        pn_retcode              := 1;
          vn_ic_tax_id            := NULL;
          vv_ic_name              := NULL;
          vn_ic_tax_ccid          := NULL;
          vn_ic_tax_recovery_rate := NULL;
          vn_ic_tax_rate          := NULL;
        END;
        END IF;
        */
            END IF;
          -- SELO EDB235B FIN
        END IF;

    --    dka_Tools_Pkg.put_log_message('l_cas1'  || l_cas1);
        --    dka_Tools_Pkg.put_log_message('l_cas2 ' || l_cas2 );
    --    dka_Tools_Pkg.put_log_message('l_cas2A ' || l_cas2A ); --IBA EDB355
    --    dka_Tools_Pkg.put_log_message('l_cas3 ' || l_cas3 );
    --    dka_Tools_Pkg.put_log_message('l_cas4 ' || l_cas4 );
    --    dka_Tools_Pkg.put_log_message('l_cas5 ' || l_cas5 );
    --    dka_Tools_Pkg.put_log_message('l_cas6 ' || l_cas6 );
    --    dka_Tools_Pkg.put_log_message('l_cas7 ' || l_cas7 );
        --    dka_Tools_Pkg.put_log_message('l_cas8 ' || l_cas8);
        --    dka_Tools_Pkg.put_log_message('l_cas9 ' || l_cas9);
        --    dka_Tools_Pkg.put_log_message('rec_fact.type_tva ' || rec_fact.type_tva);
    IF (rec_fact.type_tva = 'IC' and (l_cas1 = 1 or  l_cas2A = 1 or l_cas4 = 1 or l_cas5 = 1 or l_cas7 = 1 or l_cas9 = 1)) or nvl(rec_fact.type_tva,'A') <> 'IC' THEN --IBA EDB355
            dka_Tools_Pkg.put_log_message('Avec Rapprochement');
        IF vn_type_facture = 3 AND l_multiple_GY < 2 THEN
          IF vv_type_lig = '0003_SSTRT' THEN
            -- gestion des lignes de validation
            FOR rec_line IN cur_lines1(rec_fact.no_commande,
                                       vd_gl_date,
                                       vd_start_date,
                                       rec_fact.code_societe) LOOP
            -- SELO EDB235B DEBUT
/*      IF rec_fact.type_tva = 'IC' and l_cas2 = 1 then
            v_id_cde        := null;
        v_num_cde       := null;
        v_id_lig        := null;
        v_num_lig       := null;
        v_id_location     := null;
        v_id_distribution   := null;
        v_num_distribution    := null;
        dka_Tools_Pkg.put_log_message('A supprimer  ' || '2.2');
        else
          v_id_cde        := rec_line.id_cde;
        v_num_cde       := rec_line.num_cde;
        v_id_lig        := rec_line.id_lig;
        v_num_lig       := rec_line.num_lig;
        v_id_location     := rec_line.id_location;
        v_id_distribution   := rec_line.id_distribution;
        v_num_distribution    := rec_line.num_distribution;
          dka_Tools_Pkg.put_log_message('A supprimer  ' || '2.3');
      END if;*/
      -- SELO EDB235B FIN


              IF (((rec_fact.type_piece = '0001') and
                 (rec_line.qte_fact < rec_line.qte_cde)) or
                 (rec_fact.type_piece != '0001')) then
                --EDB223 - SELO

                vn_line_number := vn_line_number + 1;

                -- rg20: montant de la ligne

                vn_amount :=  -- Quantite Projet
                 (rec_line.qte_cde * rec_line.prix_unit)
                            -- Mutipliee par le quotient de la somme du montant de la facture ht et des montant deja rapproches de la commande
                            -- par le montant total de la commande
                             * ((rec_fact.mht_devise / 100) +
                             rec_line.mont_rappro) /
                             po_headers_pkg_s2.po_total(rec_line.id_cde)
                            -- moins le montant deja facture pour le projet
                             - (rec_line.qte_fact * rec_line.prix_unit);

                IF ((vn_amount < 0) and (rec_fact.type_piece = '0001')) THEN
                  vn_amount := 0;
                ELSE
                  vn_amount := round(vn_amount, cn_round);
                END IF;

                --MTIA : INC0402570 : Initialisation variable pour eviter division aÃ?Â aÃ?Â  zero
                IF rec_line.prix_unit = 0 Then
                  vn_prix_unit_avoir := 1;
                Else
                  vn_prix_unit_avoir := rec_line.prix_unit;
                end if;

                IF ((rec_fact.type_piece = '0001') or
                   ((rec_fact.type_piece != '0001') and
                   (rec_line.qte_fact >=
                   abs(vn_amount) / vn_prix_unit_avoir))) then

                  IF (rec_fact.type_piece != '0001') and (vn_amount > 0) then
                    vn_amount := -vn_amount;
                  END IF;

        dka_Tools_Pkg.put_log_message('Insertion Item' );
                  v_avoir_rapproche := 1;
                  insert_line(pn_invoice_id                  => vn_invoice_id,
                              pn_line_number                 => vn_line_number,
                              pv_line_type_lookup_code       => 'ITEM',
                              pn_amount                      => vn_amount,
                              pv_tax_code                    => vv_name,
                              pn_po_header_id                => rec_line.id_cde,          --v_id_cde,                 -- SELO EDB235B
                              pv_po_number                   => rec_line.num_cde,         --v_num_cde,                -- SELO EDB235B
                              pn_po_line_id                  => rec_line.id_lig,      --v_id_lig,                 -- SELO EDB235B
                              pn_po_line_number              => rec_line.num_lig,     --v_num_lig,                -- SELO EDB235B
                              pn_po_line_location_id         => rec_line.id_location,   --v_id_location,            -- SELO EDB235B
                              pn_po_distribution_id          => rec_line.id_distribution, --v_id_distribution,        -- SELO EDB235B
                              pn_po_distribution_num         => rec_line.num_distribution,  --v_num_distribution,       -- SELO EDB235B
                              pn_dist_code_combination_id    => NULL,
                              pv_attribute_category          => NULL, -- attribute_category  Modif EMA du 04/01/2012
                              pv_attribute1                  => NULL, -- attribute1          Modif EMA du 04/01/2012
                              pv_attribute2                  => vv_attribute2,
                              pv_attribute3                  => NULL, --vv_attribute3,
                              pv_attribute4                  => NULL, --vv_attribute4,
                              pv_attribute7                  => NULL, --vv_attribute7,
                              pn_tax_recovery_rate           => vn_tax_recovery_rate,
                              pv_tax_recoverable_flag        => NULL,
                              pn_project_id                  => NULL, --rec_line.id_projet,
                              pn_task_id                     => NULL, --rec_line.id_tache,
                              pv_expenditure_type            => NULL, --rec_line.type_depense,
                              pd_expenditure_item_date       => NULL, --rec_line.date_depense,
                              pn_expenditure_organization_id => NULL, --rec_line.orgid_depense,
                              pv_description                 => NULL,
                              --R12
                              pn_line_group_number     => vn_line_group_number,
                              pv_tax_rate_code         => NULL,
                              pv_tax_regime_code       => NULL,
                              pv_tax                   => NULL,
                              pv_tax_jurisdiction_code => NULL,
                              pv_tax_status_code       => NULL,
                              pv_prorate_across_flag   => NULL);

                  vn_ventilation_line_count := vn_ventilation_line_count + 1;
                  vn_line_count             := vn_line_count + 1;
                END IF;
              end if;
            END LOOP;
          ELSIF vv_type_lig IN ('0003_ALLCDE', '0003_GENERAL') THEN

            -- gestion des lignes de validation
            FOR rec_line IN cur_lines1(rec_fact.no_commande,
                                       vd_gl_date,
                                       vd_start_date,
                                       rec_fact.code_societe) LOOP

            -- SELO EDB235B DEBUT
/*      IF rec_fact.type_tva = 'IC' and l_cas2 = 1 then
            v_id_cde        := null;
        v_num_cde       := null;
        v_id_lig        := null;
        v_num_lig       := null;
        v_id_location     := null;
        v_id_distribution   := null;
        v_num_distribution    := null;
        dka_Tools_Pkg.put_log_message('A supprimer  ' || '2.4');
        else
          v_id_cde        := rec_line.id_cde;
        v_num_cde       := rec_line.num_cde;
        v_id_lig        := rec_line.id_lig;
        v_num_lig       := rec_line.num_lig;
        v_id_location     := rec_line.id_location;
        v_id_distribution   := rec_line.id_distribution;
        v_num_distribution    := rec_line.num_distribution;
          dka_Tools_Pkg.put_log_message('A supprimer  ' || '2.5');
      END if;
      */
      -- SELO EDB235B FIN
              IF (((rec_fact.type_piece = '0001') and
                 (rec_line.qte_fact < rec_line.qte_cde)) or
                 (rec_fact.type_piece != '0001')) then
                --EDB223 - SELO

                vn_line_number := vn_line_number + 1;

                -- rg20: montant de la ligne
                vn_amount := round(abs((rec_line.qte_cde -
                                       rec_line.qte_fact) *
                                       rec_line.prix_unit),
                                   cn_round);
    --< BNZ EDB376

  dka_Tools_Pkg.put_log_message(' ==== > La partie 2 < ====== ');
    if (Number_lines(rec_line.num_cde) = 1 AND vv_type_lig = '0003_GENERAL') then

  dka_Tools_Pkg.put_log_message('Facture Type :  ' || vv_type_lig );
  dka_Tools_Pkg.put_log_message('---------------- > Facture NÂ°  :  ' || rec_fact.num_fact );

         select count(*) into v_count from dka_iapfacxgs_interface where no_commande = rec_line.num_cde and flag_trt is null;
      if v_count > 1 then
      dka_Tools_Pkg.put_log_message('====== > Commande avec plusieur Facture  NÂ° :  ' || v_count );
         begin
         select Mht_dispo
         into v_Mht_dispo
         from DKA_IAPFACXGS_MTDISP where no_commande = rec_line.num_cde and org_id = gn_org_id ;
     exception WHEN OTHERS then
     v_Mht_dispo := NULL ;
     end;
       dka_Tools_Pkg.put_log_message('===== > 1: Montant dispo :  ' || v_Mht_dispo );

        if v_Mht_dispo is NULL then
    dka_Tools_Pkg.put_log_message('====== > 2: Montant dispo Null :  ' || v_Mht_dispo );
      insert INTO DKA_IAPFACXGS_MTDISP
      (no_commande , org_id , mht_commande , mht_fact , mht_dispo , num_fact)
      values (rec_line.num_cde , gn_org_id ,null, rec_fact.mttc_devise   ,vn_amount, rec_fact.num_fact  ) ;
      commit;
      v_Mht_dispo := vn_amount;
      dka_Tools_Pkg.put_log_message('===== >  New Montant dispo :  ' || v_Mht_dispo );
        else
      vn_amount := v_Mht_dispo;
      dka_Tools_Pkg.put_log_message('====== > 3:  Montant dispo Not NUll :  ' || vn_amount );
        end if ;



            if vn_amount >= round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round) then
                    vn_amount := round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round);
              dka_Tools_Pkg.put_log_message('===== > Dispo < Montant XEROX = ' || vn_amount );
        v_mht_dispo :=  v_mht_dispo - vn_amount ;
      else
      vn_amount := v_Mht_dispo;
      v_Mht_dispo := 0 ;
      dka_Tools_Pkg.put_log_message('======= > Last Montant Dispo  = ' || vn_amount );
      end if;

    dka_Tools_Pkg.put_log_message('==== > Commande avec 1 ligne . Montant dispo :  ' || v_Mht_dispo );
        update  DKA_IAPFACXGS_MTDISP
        set mht_dispo = v_mht_dispo
        where org_id = gn_org_id
        and no_commande = rec_line.num_cde ;


        commit;




    else
             dka_Tools_Pkg.put_log_message(' ====== > Commande Avec Seule Facture  ' );

                   if vn_amount >= round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round) then
                    vn_amount := round(abs((rec_fact.mht_devise)/
                                       100),
                                   cn_round);
                   dka_Tools_Pkg.put_log_message('Seule Facture , Montant XEROX = ' || vn_amount );

        end if;
     end if ;


    end if;

  --> BNZ EDB376


                --MTIA : INC0402570 : Initialisation variable pour eviter division aÃ?Â aÃ?Â  zero
                IF rec_line.prix_unit = 0 Then
                  vn_prix_unit_avoir := 1;
                else
                  vn_prix_unit_avoir := rec_line.prix_unit;
                end if;

                IF ((rec_fact.type_piece = '0001') or
                   ((rec_fact.type_piece != '0001') and
                   (rec_line.qte_fact >=
                   abs(vn_amount) / vn_prix_unit_avoir))) then

                  IF (rec_fact.type_piece != '0001') and (vn_amount > 0) then
                    vn_amount := -vn_amount;
                  END IF;
                  v_avoir_rapproche := 1;
                  if vn_amount = 0  and (Number_lines(rec_line.num_cde) = 1 AND vv_type_lig = '0003_GENERAL') then -- BNZ376
                    dka_Tools_Pkg.put_log_message('Insertion Item Null' );
                  else
                    dka_Tools_Pkg.put_log_message('Insertion Item' );
                  insert_line(pn_invoice_id                  => vn_invoice_id,
                              pn_line_number                 => vn_line_number,
                              pv_line_type_lookup_code       => 'ITEM',
                              pn_amount                      => vn_amount,
                              pv_tax_code                    => vv_name,
                              pn_po_header_id                => rec_line.id_cde,
                              pv_po_number                   => rec_line.num_cde,
                              pn_po_line_id                  => rec_line.id_lig,
                              pn_po_line_number              => rec_line.num_lig,
                              pn_po_line_location_id         => rec_line.id_location,
                              pn_po_distribution_id          => rec_line.id_distribution,
                              pn_po_distribution_num         => rec_line.num_distribution,
                              pn_dist_code_combination_id    => NULL,
                              pv_attribute_category          => NULL, -- attribute_category Modif EMA du 04/01/2012
                              pv_attribute1                  => NULL, -- attribute1         Modif EMA du 04/01/2012
                              pv_attribute2                  => vv_attribute2,
                              pv_attribute3                  => NULL, --vv_attribute3,
                              pv_attribute4                  => NULL, --vv_attribute4,
                              pv_attribute7                  => NULL, --vv_attribute7,
                              pn_tax_recovery_rate           => vn_tax_recovery_rate,
                              pv_tax_recoverable_flag        => NULL,
                              pn_project_id                  => NULL, --rec_line.id_projet,
                              pn_task_id                     => NULL, --rec_line.id_tache,
                              pv_expenditure_type            => NULL, --rec_line.type_depense,
                              pd_expenditure_item_date       => NULL, --rec_line.date_depense,
                              pn_expenditure_organization_id => NULL, --rec_line.orgid_depense,
                              pv_description                 => NULL,
                              --R12
                              pn_line_group_number     => vn_line_group_number,
                              pv_tax_rate_code         => NULL,
                              pv_tax_regime_code       => NULL,
                              pv_tax                   => NULL,
                              pv_tax_jurisdiction_code => NULL,
                              pv_tax_status_code       => NULL,
                              pv_prorate_across_flag   => NULL);

                  vn_ventilation_line_count := vn_ventilation_line_count + 1;
                  vn_line_count             := vn_line_count + 1;
                  END IF; --BNZ376
                END IF;
              end if;
            END LOOP;
          ELSIF vv_type_lig = '0003_BL' THEN

            -- gestion des lignes de validation
            FOR rec_line IN cur_lines2(rec_fact.no_commande,
                                       rec_fact.packing_slip,
                                       vd_gl_date,
                                       vd_start_date,
                                       rec_fact.code_societe) LOOP
            -- SELO EDB235B DEBUT
  /*    IF rec_fact.type_tva = 'IC' and l_cas2 = 1 then
            v_id_cde        := null;
        v_num_cde       := null;
        v_id_lig        := null;
        v_num_lig       := null;
        v_id_location     := null;
        v_id_distribution   := null;
        v_num_distribution    := null;
        dka_Tools_Pkg.put_log_message('A supprimer  ' || '2.6');
        else
          v_id_cde        := rec_line.id_cde;
        v_num_cde       := rec_line.num_cde;
        v_id_lig        := rec_line.id_lig;
        v_num_lig       := rec_line.num_lig;
        v_id_location     := rec_line.id_location;
        v_id_distribution   := rec_line.id_distribution;
        v_num_distribution    := rec_line.num_distribution;
          dka_Tools_Pkg.put_log_message('A supprimer  ' || '2.7');
      END if;
      */
      -- SELO EDB235B FIN
              IF (((rec_fact.type_piece = '0001') and
                 (rec_line.qte_fact < rec_line.qte_cde)) or
                 (rec_fact.type_piece != '0001')) then
                --EDB223 - SELO

                vn_line_number := vn_line_number + 1;

                -- rg20: montant de la ligne
                vn_amount := round(abs((rec_line.qte_cde -
                                       rec_line.qte_fact) *
                                       rec_line.prix_unit),
                                   cn_round);



                --MTIA : INC0402570 : Initialisation variable pour eviter division aÃ?Â aÃ?Â  zero
                IF rec_line.prix_unit = 0 Then
                  vn_prix_unit_avoir := 1;
                else
                  vn_prix_unit_avoir := rec_line.prix_unit;
                end if;
                IF ((rec_fact.type_piece = '0001') or
                   ((rec_fact.type_piece != '0001') and
                   (rec_line.qte_fact >=
                   abs(vn_amount) / vn_prix_unit_avoir))) then
                  IF (rec_fact.type_piece != '0001') and (vn_amount > 0) then
                    vn_amount := -vn_amount;
                  END IF;
                  v_avoir_rapproche := 1;
        dka_Tools_Pkg.put_log_message('Insertion Item' );
                  insert_line(pn_invoice_id                  => vn_invoice_id,
                              pn_line_number                 => vn_line_number,
                              pv_line_type_lookup_code       => 'ITEM',
                              pn_amount                      => vn_amount,
                              pv_tax_code                    => vv_name,
                              pn_po_header_id                => rec_line.id_cde,
                              pv_po_number                   => rec_line.num_cde,
                              pn_po_line_id                  => rec_line.id_lig,
                              pn_po_line_number              => rec_line.num_lig,
                              pn_po_line_location_id         => rec_line.id_location,
                              pn_po_distribution_id          => rec_line.id_distribution,
                              pn_po_distribution_num         => rec_line.num_distribution,
                              pn_dist_code_combination_id    => NULL,
                              pv_attribute_category          => NULL, -- attribute_category Modif EMA du 04/01/2012
                              pv_attribute1                  => NULL, -- attribute1         Modif EMA du 04/01/2012
                              pv_attribute2                  => vv_attribute2,
                              pv_attribute3                  => NULL, --vv_attribute3,
                              pv_attribute4                  => NULL, --vv_attribute4,
                              pv_attribute7                  => NULL, --vv_attribute7,
                              pn_tax_recovery_rate           => vn_tax_recovery_rate,
                              pv_tax_recoverable_flag        => NULL,
                              pn_project_id                  => NULL, --rec_line.id_projet,
                              pn_task_id                     => NULL, --rec_line.id_tache,
                              pv_expenditure_type            => NULL, --rec_line.type_depense,
                              pd_expenditure_item_date       => NULL, --rec_line.date_depense,
                              pn_expenditure_organization_id => NULL, --rec_line.orgid_depense,
                              pv_description                 => NULL,
                              --R12
                              pn_line_group_number     => vn_line_group_number,
                              pv_tax_rate_code         => NULL,
                              pv_tax_regime_code       => NULL,
                              pv_tax                   => NULL,
                              pv_tax_jurisdiction_code => NULL,
                              pv_tax_status_code       => NULL,
                              pv_prorate_across_flag   => NULL);
                  vn_ventilation_line_count := vn_ventilation_line_count + 1;
                  vn_line_count             := vn_line_count + 1;
                END IF;
              end if;
            END LOOP;
          END IF;
        END IF;
        END IF;
        IF (rec_fact.type_piece != '0001' and rec_fact.mtva_devise > 0) then
          vn_amount := -1 * round(rec_fact.mtva_devise / 100, cn_round);

        ELSE
          vn_amount := round(rec_fact.mtva_devise / 100, cn_round);

        END IF;

        -- SELO
        -- SELO
        if (v_avoir_rapproche = 0) and (rec_fact.type_piece != '0001') then
          vv_hold_name := 'Imputation en attente';
          vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
          IF NOT va_group_id.exists(vv_group_id) THEN
            va_group_id(vv_group_id) := vv_hold_name;
          END IF;
          update ap_invoices_interface
             set group_id = vv_group_id
           where invoice_id = vn_invoice_id;

        end if;
        -- SELO EDB235B DEBUT
        if (l_cas2 = 1) or (l_cas3 = 1) or (l_cas6 = 1) or (l_cas8 = 1) then
          vv_hold_name := 'Imputation en attente';
          vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
          IF NOT va_group_id.exists(vv_group_id) THEN
            va_group_id(vv_group_id) := vv_hold_name;
          END IF;
          update ap_invoices_interface
             set group_id = vv_group_id
           where invoice_id = vn_invoice_id;

        end if;
        -- SELO EDB235B FIN
        if l_multiple_GY > 1 then
          vn_amount    := 0;
          vv_hold_name := 'Imputation en attente';
          vv_group_id  := rec_fact.code_region || rec_fact.code_societe ||
                          ' IMPUTATION EN ATTENTE';
          IF NOT va_group_id.exists(vv_group_id) THEN
            va_group_id(vv_group_id) := vv_hold_name;
          END IF;
          update ap_invoices_interface
             set group_id = vv_group_id
           where invoice_id = vn_invoice_id;

        end if;
        -- ligne de tva
        dka_Tools_Pkg.put_log_message('Insertion Tax' );
        vn_line_number := vn_line_number + 1;
        insert_line(pn_invoice_id                  => vn_invoice_id,
                    pn_line_number                 => vn_line_number,
                    pv_line_type_lookup_code       => 'TAX',
                    pn_amount                      => vn_amount,
                    pv_tax_code                    => vv_name,
                    pn_po_header_id                => NULL,
                    pv_po_number                   => NULL,
                    pn_po_line_id                  => NULL,
                    pn_po_line_number              => NULL,
                    pn_po_line_location_id         => NULL,
                    pn_po_distribution_id          => NULL,
                    pn_po_distribution_num         => NULL,
                    pn_dist_code_combination_id    => vn_tax_ccid,
                    pv_attribute_category          => NULL, -- attribute_category Modif EMA du 04/01/2012
                    pv_attribute1                  => NULL, -- attribute11        Modif EMA du 04/01/2012
                    pv_attribute2                  => vv_attribute2,
                    pv_attribute3                  => NULL, --vv_attribute3,
                    pv_attribute4                  => NULL, --vv_attribute4,
                    pv_attribute7                  => NULL, --vv_attribute7,
                    pn_tax_recovery_rate           => NULL,
                    pv_tax_recoverable_flag        => 'Y',
                    pn_project_id                  => NULL, --rec_line.id_projet,
                    pn_task_id                     => NULL, --rec_line.id_tache,
                    pv_expenditure_type            => NULL, --rec_line.type_depense,
                    pd_expenditure_item_date       => NULL, --rec_line.date_depense,
                    pn_expenditure_organization_id => NULL, --rec_line.orgid_depense,
                    pv_description                 => NULL,
                    --R12
                    pn_line_group_number     => vn_line_group_number,
                    pv_tax_rate_code         => vv_tax_rate_code, --vv_ic_tax_rate_code,
                    pv_tax_regime_code       => vv_tax_regime_code, --vv_ic_tax_regime_code,
                    pv_tax                   => vv_tax, --vv_ic_tax,
                    pv_tax_jurisdiction_code => vv_tax_jurisdiction_code, --vv_ic_tax_jurisdiction_code,
                    pv_tax_status_code       => vv_tax_status_code, --vv_ic_tax_status_code,
                    pv_prorate_across_flag   => 'Y'

                    );

        vn_tva_line_count := vn_tva_line_count + 1;
        vn_line_count     := vn_line_count + 1;
        -- si tva intra communautaire alors inserer une seconde ligne de tva

        -- si tva intra communautaire alors inserer une seconde ligne de tva
        IF rec_fact.type_tva = 'IC' and  l_cas1 = 0 and  l_cas2 = 0 and  l_cas2A = 0 and  l_cas3 = 0 and  l_cas4 = 0 and  l_cas5 = 0 and  l_cas6 = 0 and  l_cas7 = 0 --IBA EDB355
          and  l_cas8 = 0 and  l_cas9 = 0   THEN
          vn_amount      := round(rec_fact.mtva_devise * vn_ic_tax_rate / 100,
                                  cn_round);
          vn_line_number := vn_line_number + 1;

          IF rec_fact.type_piece != '0001' then
            vn_amount := -vn_amount;
          END IF;
    dka_Tools_Pkg.put_log_message('Insertion Tax' );
          insert_line(pn_invoice_id                  => vn_invoice_id,
                      pn_line_number                 => vn_line_number,
                      pv_line_type_lookup_code       => 'TAX',
                      pn_amount                      => vn_amount,
                      pv_tax_code                    => vv_name,
                      pn_po_header_id                => NULL,
                      pv_po_number                   => NULL,
                      pn_po_line_id                  => NULL,
                      pn_po_line_number              => NULL,
                      pn_po_line_location_id         => NULL,
                      pn_po_distribution_id          => NULL,
                      pn_po_distribution_num         => NULL,
                      pn_dist_code_combination_id    => vn_ic_tax_ccid,
                      pv_attribute_category          => NULL, -- attribute_category Modif EMA du 04/01/2012
                      pv_attribute1                  => NULL, -- attribute1         Modif EMA du 04/01/2012
                      pv_attribute2                  => vv_attribute2,
                      pv_attribute3                  => NULL, --vv_attribute3,
                      pv_attribute4                  => NULL, --vv_attribute4,
                      pv_attribute7                  => NULL, --vv_attribute7,
                      pn_tax_recovery_rate           => NULL,
                      pv_tax_recoverable_flag        => 'Y',
                      pn_project_id                  => NULL,
                      pn_task_id                     => NULL,
                      pv_expenditure_type            => NULL,
                      pd_expenditure_item_date       => NULL,
                      pn_expenditure_organization_id => NULL,
                      pv_description                 => NULL,
                      --R12
                      pn_line_group_number     => vn_line_group_number,
                      pv_tax_rate_code         => vv_ic_tax_rate_code,
                      pv_tax_regime_code       => vv_ic_tax_regime_code,
                      pv_tax                   => vv_ic_tax,
                      pv_tax_jurisdiction_code => vv_ic_tax_jurisdiction_code,
                      pv_tax_status_code       => vv_ic_tax_status_code,
                      pv_prorate_across_flag   => 'Y');

          vn_tva_ic_line_count := vn_tva_ic_line_count + 1;
          vn_line_count        := vn_line_count + 1;
        END IF;

        -- sauvegarde de la ligne traitee dans un tableau pour mise a jour
        -- ulterieure du champ flag_trt dans la table d'interface
        va_code_frs.extend;
        va_site_frs.extend;
        va_num_fact.extend;
        va_date_piece.extend;
        va_code_societe.extend;
        va_code_region.extend;

        va_code_frs(va_code_frs.last) := rec_fact.code_frs;
        va_site_frs(va_site_frs.last) := rec_fact.site_frs;
        va_num_fact(va_num_fact.last) := rec_fact.num_fact;
        va_date_piece(va_date_piece.last) := rec_fact.date_piece;
        va_code_societe(va_code_societe.last) := rec_fact.code_societe;
        va_code_region(va_code_region.last) := rec_fact.code_region;

      EXCEPTION
        WHEN OTHERS THEN
          pv_errbuf := 'Erreur sur la facture ' || rec_fact.num_fact || ':' ||
                       SQLERRM;
          dka_Tools_Pkg.put_log_message(pv_errbuf);
          reporte_erreur(rec_fact.rowid, pv_errbuf);
          pn_retcode := 1;
          RAISE;
      END;
    END LOOP;

    -- on commite quand on a vraiment tout insere
    COMMIT;

    dka_Tools_Pkg.put_log_message('  ' || vn_header_count ||
                                  ' entete(s) de facture inseree(s)');
    dka_Tools_Pkg.put_log_message('  ' || vn_line_count ||
                                  ' ligne(s) de facture inseree(s) dont');
    dka_Tools_Pkg.put_log_message('    ' || vn_ventilation_line_count ||
                                  ' ligne(s) de ventilation');
    dka_Tools_Pkg.put_log_message('    ' || vn_tva_line_count ||
                                  ' ligne(s) de tva (non ic)');
    dka_Tools_Pkg.put_log_message('    ' || vn_tva_ic_line_count ||
                                  ' ligne(s) de tva ic');

    dka_Tools_Pkg.put_log_message('  [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_function_starttime) || ']');

    ----------------------------------------------------------------
    ---------- Traitement des ecarts minimes
    ----------------------------------------------------------------

    ---------------------------------------
    -- Recherche de la valeur de l'ecart --
    ---------------------------------------
    ---<DEBUT IBA EDB349
   Dka_Tools_Pkg.Get_Parameter(cv_program_code,
                                'ECART_ENERGIE_MAX',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      vn_ecart_max_facture := 0;
    ELSE
      vn_ecart_max_facture := vr_data.number_value;
    END IF;
    dka_Tools_Pkg.put_log_message('Ecart maximum  : ' ||
                                  vn_ecart_max_facture);

    Dka_Tools_Pkg.Get_Parameter(cv_program_code,
                                'ECART_ENERGIE_MIN',
                                Vr_Data,
                                Vn_Retcode,
                                Vv_Errbuf);

    IF Vn_Retcode != 0 THEN
      vn_ecart_minime_facture := 0;
    ELSE
      vn_ecart_minime_facture := vr_data.number_value;
    END IF;
    dka_Tools_Pkg.put_log_message('Ecart minime : ' ||
                                  vn_ecart_minime_facture);

  ---FIN IBA EDB349>
    ----
    FOR head_facture IN cur_factures_ec LOOP
      -- Recuperation de la somme des lignes de la facture dans vn_somme_lignes
      SELECT sum(aili.amount), count(*), MAX(aili.line_number)
        INTO vn_somme_lignes, vn_nombre_lignes, vn_numero_ligne_max
        FROM ap_invoice_lines_interface aili
       WHERE aili.invoice_id = head_facture.invoice_id;

      -- Comparaison du montant de la facture et de la somme des lignes par rapport a l'ecart minime
      vn_ecart_facture := head_facture.invoice_amount - vn_somme_lignes;
     -- IF ABS(vn_ecart_facture) <= vn_ecart_minime_facture AND
        IF vn_ecart_facture <= vn_ecart_max_facture AND vn_ecart_facture >= vn_ecart_minime_facture and --IBA EDB349
          head_facture.invoice_amount <> vn_somme_lignes -- On ne compte pas les comptes ronds
       THEN
        -- La facture correspond aux criteres
        -- Debut des traitements pour inserer une nouvelle ligne
        vn_invoice_id := head_facture.invoice_id;

        dka_Tools_Pkg.put_log_message('Il faut inserer une ligne pour la Commande noaÃ?Â°' ||
                                      head_facture.attribute13 ||
                                      ' et Invoice_Id noaÃ?Â°' ||
                                      vn_invoice_id || ' de ' ||
                                      vn_ecart_facture || '?');
        --MTIA Correction sur Ã?Â©cart sur ligne avec projet de refacturation
        ---------------------------------------------------------
        -- Recuperation des informations de la ligne a ajouter --
        ---------------------------------------------------------
        SELECT aili.tax_code,
               aili.tax_code_id,
               aili.tax_recovery_rate,
               --
               aili.line_group_number,
               aili.tax_rate_code,
               aili.tax_regime_code,
               aili.tax,
               aili.tax_jurisdiction_code,
               aili.tax_status_code,
               aili.po_number,
               aili.po_line_id,
               aili.po_line_number,
               aili.po_line_location_id,
               aili.po_distribution_id,
               aili.po_distribution_num,
               --
               pda.project_id,
               pda.task_id,
               pda.expenditure_type,
               SUBSTR(houa.name, 1, 3),
               aii.invoice_date
          INTO vc_tax_code,
               vn_tax_code_id,
               vn_tax_recovery_rate,
               --
               vn_line_group_number,
               vv_tax_rate_code,
               vv_tax_regime_code,
               vv_tax,
               vv_tax_jurisdiction_code,
               vv_tax_status_code,
               vv_po_number,
               vn_po_line_id,
               vn_po_line_number,
               vn_po_line_location_id,
               vn_po_distribution_id,
               vn_po_distribution_num,
               --
               vn_project_id,
               vn_task_id,
               vc_expenditure_type,
               vv_centre_gestion,
               vd_date_piece
          FROM ap_invoices_interface      aii,
               hr_all_organization_units  houa,
               ap_invoice_lines_interface aili,
               po_distributions_all       pda,
               po_headers_all             pha,
               ap_supplier_sites_all      pvsa
         WHERE aii.invoice_id = vn_invoice_id
           AND aii.invoice_id = aili.invoice_id
           AND aili.line_type_lookup_code = 'ITEM'
           and aii.org_id = houa.organization_id
              --- 28/02/2018 NBO artf2404586 : Correction INT047 - Interface des factures numerisees Xerox - Ecart minime
           AND rownum = 1
              /*AND   aili.po_line_number = (SELECT MIN(aili2.po_line_number)
                                             FROM ap_invoice_lines_interface aili2
                                            WHERE aili.invoice_id = aili2.invoice_id)
              AND pda.po_distribution_id = (SELECT MIN(pda2.po_distribution_id)
                                              FROM po_distributions_all pda2
                                             WHERE pda.po_header_id = pda2.po_header_id)*/
           AND aili.po_line_id = pda.po_line_id
           AND aili.po_line_location_id = pda.line_location_id
           AND pda.po_header_id = pha.po_header_id
           AND pha.vendor_site_id = pvsa.vendor_site_id
         ORDER BY aili.line_number;

        -----------------------------------------------------------------------------
        -- On a reussi a recuperer tous les elements pour generer la ligne d'ecart --
        -----------------------------------------------------------------------------
        -- Ajout 1 au numero de la ligne qui va etre ajoutee
        vn_numero_ligne_max := vn_numero_ligne_max + 1;

        -- Recuperation de la date GL pour expenditure_item_date
        vd_expenditure_item_date := head_facture.gl_date;

        -- Modif EMA du 26/01/2012 : on gere le cas ou on ne trouve pas le nom du fournisseur
        ----------------------------------------
        -- Recuperation du nom du fournisseur --
        ----------------------------------------
        BEGIN
          vb_data_ok := TRUE;

          SELECT pv.vendor_name
            INTO vc_vendor_name
            FROM ap_suppliers pv
           WHERE (head_facture.vendor_id IS NOT NULL AND
                 pv.vendor_id = head_facture.vendor_id)
              OR (head_facture.vendor_num IS NOT NULL AND
                 pv.segment1 = head_facture.vendor_num);

        EXCEPTION
          WHEN OTHERS THEN
            dka_Tools_Pkg.put_log_message('Le nom du fournisseur (vendor_num = ' ||
                                          head_facture.vendor_num ||
                                          ') n''a pas ete trouve');
            vc_vendor_name := 'Fournisseur inconnu';
            vb_data_ok     := FALSE;
        END;

        -------------------------------------------------------------------------
        -- Le nom du fournisseur a ete trouve, on peut genere la ligne d'ecart --
        -------------------------------------------------------------------------
        IF vb_data_ok THEN

          -- Debut modif EMA du 06/01/2012
          ------------------------------------------------
          -- Recherche des informations liees au projet --
          ------------------------------------------------
          dka_pa_tools_pkg.get_project_info(pv_errbuf       => vv_errbuf,
                                            pn_retcode      => vn_retcode,
                                            pn_project_id   => vn_project_id,
                                            pv_project_soc  => vv_project_company_code,
                                            pv_project_type => vv_project_type);

          ----------------------------------------------
          -- Recuperation de la societe de la facture --
          ----------------------------------------------
          vv_invoice_company_code := head_facture.attribute15;

          vv_attribute1         := NULL;
          vv_attribute7         := NULL;
          vv_attribute_category := NULL;

          -----------------------------------------
          -- Dans le cas de refacturation sur PO --
          -----------------------------------------
          IF vv_project_company_code != vv_invoice_company_code THEN

            vn_old_project_id := vn_project_id;
            vn_old_task_id    := vn_task_id;

            ------------------------------------------------------------
            -- Recuperation du projet et de la tache de refacturation --
            ------------------------------------------------------------
            dka_pa_tools_pkg.pa_get_code_z_refac(pv_societe        => vv_invoice_company_code,
                                                 pv_centre_gestion => vv_centre_gestion,
                                                 pv_segment1       => vv_project_code,
                                                 pn_project_id     => vn_project_id,
                                                 pv_project_name   => vv_project_name,
                                                 pv_errbuf         => vv_errbuf,
                                                 pn_retcode        => vn_retcode);

            ---------------------------------------
            -- Recuperation du task_id du projet --
            ---------------------------------------
            SELECT pt.task_id , pt.CARRYING_OUT_ORGANIZATION_ID
              INTO vn_task_id , vn_expenditure_organization_id
              FROM pa_tasks pt
             WHERE pt.project_id = vn_project_id
               AND pt.task_number = '1'
               AND rownum = 1;

            vv_attribute1         := vn_old_project_id;
            vv_attribute_category := gn_ledger_id;
            vv_attribute7         := vn_old_task_id;
            --Suppression info cde
            vv_po_number           := NULL;
            vn_po_line_id          := NULL;
            vn_po_line_number      := NULL;
            vn_po_line_location_id := NULL;
            vn_po_distribution_id  := NULL;
            vn_po_distribution_num := NULL;

            /*                ELSE
            --suppression info projet
            vn_project_id                   := NULL;
            vn_task_id                      := NULL;
            vc_expenditure_type             := NULL;
            vd_expenditure_item_date        := NULL;
            vn_expenditure_organization_id  := NULL;*/
          END IF;

           IF vv_project_company_code = vv_invoice_company_code THEN
          -----------------------------------------------
          -- Recherche de l'organisation de la depense --
          -----------------------------------------------
          BEGIN
            SELECT pcdo.override_from_organization_id
              INTO vn_expenditure_organization_id
              FROM pa_cost_dist_overrides pcdo
             WHERE pcdo.project_id = vn_project_id
               AND TRUNC(vd_date_piece) BETWEEN
                   TRUNC(pcdo.start_date_active) AND
                   TRUNC(NVL(pcdo.end_date_active, vd_date_piece));
          EXCEPTION
            WHEN OTHERS THEN
              vn_expenditure_organization_id := NULL;
          END;
          END IF;
          -- Fin modif EMA du 06/01/2012

          -- Mise a jour de la ligne pour inserer dans le champs description
          -- la valeur "ECART AUTO-<numero de facture>-<numero de fournisseur>-<date facture>"
          vc_description    := 'ECART AUTO-' || head_facture.invoice_num || '-' ||
                               vc_vendor_name || '-' ||
                               TO_CHAR(head_facture.invoice_date,
                                       'DD/MM/YYYY');
          v_avoir_rapproche := 1; --------------
          -- On insert la ligne
          insert_line(pn_invoice_id                  => vn_invoice_id,
                      pn_line_number                 => vn_numero_ligne_max,
                      pv_line_type_lookup_code       => 'ITEM',
                      pn_amount                      => vn_ecart_facture,
                      pv_tax_code                    => vc_tax_code,
                      pn_po_header_id                => NULL,
                      pv_po_number                   => NULL, --vv_po_number,
                      pn_po_line_id                  => NULL, --vn_po_line_id,
                      pn_po_line_number              => NULL, --vn_po_line_number,
                      pn_po_line_location_id         => NULL, --vn_po_line_location_id,
                      pn_po_distribution_id          => NULL, --vn_po_distribution_id,
                      pn_po_distribution_num         => NULL, --vn_po_distribution_num,
                      pn_dist_code_combination_id    => NULL,
                      pv_attribute_category          => vv_attribute_category,
                      pv_attribute1                  => vv_attribute1,
                      pv_attribute2                  => NULL,
                      pv_attribute3                  => NULL,
                      pv_attribute4                  => NULL,
                      pv_attribute7                  => vv_attribute7,
                      pn_tax_recovery_rate           => vn_tax_recovery_rate,
                      pv_tax_recoverable_flag        => NULL,
                      pn_project_id                  => vn_project_id,
                      pn_task_id                     => vn_task_id,
                      pv_expenditure_type            => vc_expenditure_type,
                      pd_expenditure_item_date       => vd_expenditure_item_date,
                      pn_expenditure_organization_id => vn_expenditure_organization_id,
                      pv_description                 => vc_description,
                      --R12
                      pn_line_group_number     => vn_line_group_number,
                      pv_tax_rate_code         => NULL,
                      pv_tax_regime_code       => NULL,
                      pv_tax                   => NULL,
                      pv_tax_jurisdiction_code => NULL,
                      pv_tax_status_code       => NULL,
                      pv_prorate_across_flag   => NULL);

          dka_Tools_Pkg.put_log_message('Une ligne invoice_id = ' ||
                                        vn_invoice_id ||

                                        ' a ete inseree. (amount : ' ||
                                        vn_ecart_facture || ')');
        END IF;
      END IF;
    END LOOP;

    --- 2019/01/31 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
    FOR rec_ap_interface IN cur_ap_interface LOOP

      SELECT count(*)
        INTO vn_count_doublon
        FROM ap_invoices_all api, ap_suppliers pv, ap_supplier_sites pvs
       WHERE api.org_id = gn_org_id
         AND api.invoice_num = rec_ap_interface.invoice_num
         AND api.vendor_id = pv.vendor_id
         AND (pvs.vendor_site_code !=
             NVL(rec_ap_interface.vendor_site_code, 'NULL') OR
             pvs.vendor_site_id != rec_ap_interface.vendor_site_id)
         AND pvs.vendor_id = pv.vendor_id
            --AND pv.segment1 = rec_ap_interface.vendor_num
         AND pv.vendor_id = rec_ap_interface.vendor_id
         AND api.invoice_date = rec_ap_interface.invoice_date
         AND api.invoice_amount = rec_ap_interface.invoice_amount;

      IF vn_count_doublon > 0 THEN
        UPDATE AP_INVOICES_INTERFACE AII
           SET AII.vendor_site_id   = -999,
               AII.vendor_site_code = NULL,
               AII.vendor_num       = AII.vendor_num ||
                                      decode(instr(vendor_num, 'DOUBLON'),
                                             0,
                                             ' - DOUBLON',
                                             '')
         WHERE AII.rowid = rec_ap_interface.rid;
      END IF;
    END LOOP;

    -- on commite quand on a vraiment tout insere
    COMMIT;

    -- mise a jour des lignes traitees
    dka_Tools_Pkg.put_log_message('Marquage des lignes traitees');
    vd_function_starttime := localtimestamp;
    DECLARE
      vn_count PLS_INTEGER;
    BEGIN
      IF va_code_frs.first IS NULL THEN
        vn_count := 0;
      ELSE
        FORALL i IN va_code_frs.first .. va_code_frs.last
          UPDATE dka_iapfacxgs_interface
             SET flag_trt = 1
           WHERE nvl(code_frs, '-1') = nvl(va_code_frs(i), '-1')
             AND nvl(site_frs, '-1') = nvl(va_site_frs(i), '-1')
             AND nvl(num_fact, '-1') = nvl(va_num_fact(i), '-1')
             AND nvl(date_piece, '-1') = nvl(va_date_piece(i), '-1')
             AND nvl(code_societe, '-1') = nvl(va_code_societe(i), '-1')
             AND nvl(code_region, '-1') = nvl(va_code_region(i), '-1');
        vn_count := SQL%ROWCOUNT;
        COMMIT;
      END IF;
      dka_Tools_Pkg.put_log_message('  ' || vn_count ||
                                    ' ligne(s) marquee(s) ' ||
                                    'comme traitees');
    END;
    dka_Tools_Pkg.put_log_message('  [' ||
                                  to_char(localtimestamp -
                                          vd_function_starttime) || ']');

    -- copie des lignes traitees dans la table de reporting
    dka_Tools_Pkg.put_log_message('Recopie des donnees traitees dans la table ' ||
                                  'de reporting');
    vd_function_starttime := LOCALTIMESTAMP;
    DECLARE
      vn_reporting_count PLS_INTEGER;
    BEGIN
      IF va_code_frs.first IS NULL THEN
        vn_reporting_count := 0;
      ELSE

        update dka_iapfacxgs_reporting_all xira
           set STATUT_INTERFACE = 'OK',
               date_traitement  = sysdate,
               org_id           = gn_org_id
         where exists
         (select 1
                  from dka_iapfacxgs_interface   xii,
                       hr_all_organization_units haou
                 where xii.num_fact = xira.num_fact
                   and nvl(xira.site_frs, '#VIDE#') =
                       nvl(xii.site_frs, '#VIDE#')
                   and xira.date_numerisation = xii.date_numerisation
                   and xira.type_piece = xii.type_piece
                   and xira.type = xii.type
                   and xira.batchno = xii.batchno
                   and xira.batchidx = xii.batchidx
                   and xira.mht_devise = xii.mht_devise
                   and xii.flag_trt = 1
                   AND xii.code_region || xii.code_societe = haou.name
                   AND haou.organization_id = gn_org_id);

        vn_reporting_count := SQL%ROWCOUNT;
        COMMIT;
      END IF;

      --- 2017/05/09 NBO artf2150386 - INT047 - Factures aÃ?Â aÃ?Â  recycler - Defect Bout_en_Bout_Helios_Ref #648
      dka_Tools_Pkg.put_log_message('Recyclage des factures');

      FOR facture_recyclee in (select distinct group_id
                                 from ap_invoices_interface aii
                                where aii.status = 'REJECTED'
                                  and source = 'SCAN_XGS'
                                  and org_id = gn_org_id) LOOP
        -- Les valeurs de group_id et hold_name sont maintenant determinees.
        -- On les met dans un tableau pour les lancements du traitement
        -- standard d'import des commandes
        IF NOT va_group_id.exists(facture_recyclee.group_id) THEN
          vv_hold_name := null;
          IF INSTR(facture_recyclee.group_id, 'IMPUTATION EN ATTENTE') > 0 THEN
            vv_hold_name := 'Imputation en attente';
          ELSIF INSTR(facture_recyclee.group_id, 'MULTI-COMMANDES') > 0 THEN
            vv_hold_name := 'Multi-commandes';

          END IF;

          va_group_id(facture_recyclee.group_id) := vv_hold_name;
          vn_header_count := vn_header_count + 1;
        END IF;
      END LOOP;

      IF vn_header_count = 0 THEN
        RAISE e_no_data;
      END IF;

      dka_Tools_Pkg.put_log_message('  [temps de recopie des donnees ' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_function_starttime) || ']');

      --> Traitement des factures eligibles a la TVA autoliquidee

      vv_group_id := va_group_id.first;
      WHILE vv_group_id IS NOT NULL LOOP

        -- Lancement de la fonction pour les factures XGS
        vv_errbuf  := '';
        vn_retcode := 0;

        DKA_AP_TOOLS_PKG.apply_fonction(vv_errbuf,
                                        vn_retcode,
                                        'XEROX',
                                        'SCAN_XGS',
                                        'XGS',
                                        vv_group_id,
                                        gn_org_id);

        IF vn_retcode != 0 THEN
          dka_Tools_Pkg.put_log_message('Erreur lors de l''ajout des lignes de TVA Autoliquidee Origine XGS / Group_id: SCAN_XGS / ' ||
                                        vv_group_id || ' : ' || vv_errbuf);
        ELSE
          dka_Tools_Pkg.put_log_message('Ajout des lignes de TVA Autoliquidee avec succes : Origine XGS / Group_id: SCAN_XGS / ' ||
                                        vv_group_id || ' : ' || vv_errbuf);
        END IF;

        -- Lancement de la fonction pour les factures DSP
        vv_errbuf  := '';
        vn_retcode := 0;

        DKA_AP_TOOLS_PKG.apply_fonction(vv_errbuf,
                                        vn_retcode,
                                        'XEROX',
                                        'SCAN_XGS',
                                        'DSP',
                                        vv_group_id,
                                        gn_org_id);

        IF vn_retcode != 0 THEN
          dka_Tools_Pkg.put_log_message('Erreur lors de l''ajout des lignes de TVA Autoliquidee Origine DSP / Group_id: SCAN_XGS / ' ||
                                        vv_group_id || ' : ' || vv_errbuf);
        ELSE
          dka_Tools_Pkg.put_log_message('Ajout des lignes de TVA Autoliquidee avec succes : Origine DSP / Group_id: SCAN_XGS / ' ||
                                        vv_group_id || ' : ' || vv_errbuf);
        END IF;


        -- suivant
        vv_group_id := va_group_id.next(vv_group_id);
      END LOOP;
      --<

      -- lancement du traitement d'import (boucle)
      dka_Tools_Pkg.put_log_message('Lancement du traitement d''import pour ' ||
                                    va_group_id.count || 'groupe(s)');
      vd_function_starttime := LOCALTIMESTAMP;

      DECLARE
        TYPE t_request_id IS TABLE OF PLS_INTEGER;
        va_request_id     t_request_id := t_request_id();
        vn_nb_traitements PLS_INTEGER := 0;

        vv_phase      VARCHAR2(100);
        vv_status     VARCHAR2(100);
        vv_dev_phase  VARCHAR2(100);
        vv_dev_status VARCHAR2(100);
        vv_message    VARCHAR2(255);
      BEGIN
        vv_group_id := va_group_id.first;
        WHILE vv_group_id IS NOT NULL LOOP
          vv_hold_name := va_group_id(vv_group_id);

          vn_request_id := fnd_request.submit_request('SQLAP', -- application
                                                      'APXIIMPT', -- program
                                                      NULL, -- program_name
                                                      NULL, -- start_time
                                                      FALSE, -- sub_request
                                                      gn_org_id, --org_id
                                                      'SCAN_XGS', -- origine
                                                      vv_group_id, -- group
                                                      'N/A', -- nom lot de facture
                                                      vv_hold_name, -- code bloquage
                                                      NULL, -- motif de blocage
                                                      NULL, -- date GL
                                                      'Y', -- purger
                                                      'Y', -- trace switch
                                                      'Y', -- debug switch
                                                      'N', -- synthetiser l'etat
                                                      '1000', -- point de validation
                                                      to_char(fnd_global.user_id), -- user_id
                                                      to_char(fnd_global.login_id) -- login_id
                                                      );

          IF nvl(vn_request_id, 0) = 0 THEN
            pv_errbuf := 'Erreur lors du lancement du' ||
                         'traitement APXIIMPT (group_id: ' || vv_group_id ||
                         ', hold_name: ' || vv_hold_name || ') : ' ||
                         fnd_message.get();
            dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
            pn_retcode := 1;
          ELSE
            COMMIT;
            va_request_id.extend;
            vn_nb_traitements := vn_nb_traitements + 1;
            va_request_id(vn_nb_traitements) := vn_request_id;
          END IF;

          -- suivant
          vv_group_id := va_group_id.next(vv_group_id);
        END LOOP;

        -- attente fin traitement
        FOR i IN 1 .. vn_nb_traitements LOOP
          IF NOT fnd_concurrent.wait_for_request(va_request_id(i),
                                                 15,
                                                 0,
                                                 vv_phase,
                                                 vv_status,
                                                 vv_dev_phase,
                                                 vv_dev_status,
                                                 vv_message) THEN
            ROLLBACK;
            pv_errbuf := 'Erreur lors de l''attente de fin ' ||
                         'd''execution du traitement APXIIMPT (request_id: ' ||
                         va_request_id(i) || ') :' || fnd_message.get();
            dka_Tools_Pkg.put_log_message(pv_errbuf);
            pn_retcode := 1;
          ELSIF vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL' THEN
            dka_Tools_Pkg.put_log_message('execution traitement OK');
          ELSE
            ROLLBACK;
            pv_errbuf := 'Erreur lors de l''execution du ' ||
                         'traitement APXIIMPT (request_id: ' ||
                         va_request_id(i) || ') :';

            dka_Tools_Pkg.put_log_message('  phase   : ' || vv_dev_phase || ' (' ||
                                          vv_phase || ')');
            dka_Tools_Pkg.put_log_message('  status  : ' || vv_dev_status || ' (' ||
                                          vv_status || ')');
            dka_Tools_Pkg.put_log_message('  message : ' || vv_message);
            pn_retcode := 1;
          END IF;
        END LOOP;
      EXCEPTION
        WHEN OTHERS THEN
          pv_errbuf := 'Erreur Traitement';
          dka_Tools_Pkg.put_log_message(pv_errbuf);
          pn_retcode := 1;
      END;

      --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
      FOR rec_error IN cur_error LOOP

        INSERT INTO ap_interface_rejections
          (parent_table,
           parent_id,
           reject_lookup_code,
           last_updated_by,
           last_update_date,
           last_update_login,
           created_by,
           creation_date)
        VALUES
          ('AP_INVOICES_INTERFACE',
           rec_error.invoice_id,
           'DUPLICATE INVOICE NUMBER',
           fnd_global.user_id,
           SYSDATE,
           fnd_global.login_id,
           fnd_global.user_id,
           SYSDATE);
      END LOOP;

      COMMIT;
      dka_Tools_Pkg.put_log_message('  [' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_function_starttime) || ']');

      dka_Tools_Pkg.put_log_message('  ' || vn_reporting_count ||
                                    ' ligne(s)' ||
                                    ' copiee(s) vers la table de reporting');
    END;
    dka_Tools_Pkg.put_log_message('  [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_function_starttime) || ']');

    -- fin
    dka_Tools_Pkg.put_log_message('[' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_process_starttime) || ']');
  EXCEPTION
    WHEN e_no_data THEN
      COMMIT;
      dka_Tools_Pkg.put_outdebug_message('  Rien a traiter (pas de donnees)');
      dka_Tools_Pkg.put_log_message('[' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_process_starttime) || ']');
      pv_errbuf := 'Pas de donnees a traiter';
    WHEN e_generic THEN
      dka_Tools_Pkg.put_log_message('ERREUR [e_generic]');
      dka_Tools_Pkg.put_log_message('  [' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_function_starttime) || ']');
      dka_Tools_Pkg.put_log_message('[' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_process_starttime) || ']');
      ROLLBACK;
      pn_retcode := 2;
      pv_errbuf  := 'Erreur generique' || cv_error_message;
      dka_tools_pkg.print_error_stack();
      dka_tools_pkg.clear_error_stack();
    WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR [exception dans child_import() ' ||
                                    'non catchee]');
      dka_Tools_Pkg.put_log_message('  [' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_function_starttime) || ']');
      dka_Tools_Pkg.put_log_message('[' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_process_starttime) || ']');
      pn_retcode := 2;
      pv_errbuf  := 'Erreur ' || SQLERRM || cv_error_message;
      dka_Tools_Pkg.put_log_message('# ' || SQLERRM);
      ROLLBACK;
  END child_import;

  /*
  * Point d'entree du traitement.
  * Lance la procedure d'import pour chaque organisation detectee dans la
  * table d'interface.
  */
  PROCEDURE import(pv_errbuf OUT VARCHAR2, pn_retcode OUT NUMBER) IS
    TYPE t_org_name IS TABLE OF hr_all_organization_units.name%TYPE;
    TYPE t_organization_id IS TABLE OF hr_all_organization_units.organization_id%TYPE;
    TYPE t_ledger_id IS TABLE OF gl_ledgers.ledger_id%TYPE;

    va_org_name        t_org_name;
    va_organization_id t_organization_id;
    va_ledger_id       t_ledger_id;

    vn_interface_count PLS_INTEGER;

    -- timestamp pour la mesure du temps d'execution des fonctions/procedures
    vd_function_starttime TIMESTAMP;
    -- autre timestamp
    vd_local_starttime TIMESTAMP;
    -- timestamp pour le temps d'execution total
    vd_process_starttime TIMESTAMP;

  BEGIN
    vd_process_starttime := LOCALTIMESTAMP;

    pv_errbuf  := '';
    pn_retcode := 0;

    dka_Tools_Pkg.put_log_message('Recherche des organisations a utiliser');
    vd_function_starttime := LOCALTIMESTAMP;

    --- 2017/05/09 NBO artf2150386 - INT047 - Factures aÃ?Â aÃ?Â  recycler - Defect Bout_en_Bout_Helios_Ref #648
    SELECT v.org_name, v.organization_id, v.ledger_id
      BULK COLLECT
      INTO va_org_name, va_organization_id, va_ledger_id
      FROM (SELECT DISTINCT haou.NAME org_name,
                            haou.organization_id,
                            gl.ledger_id
              FROM hr_operating_units haou, --YWA artf2163145
                   --hr_all_organization_units haou,
                   dka_iapfacxgs_interface dii,
                   gl_ledgers              gl
             WHERE haou.NAME = dii.code_region || dii.code_societe
               AND gl.ledger_id = haou.set_of_books_id --YWA artf2163145
                  --AND gl.NAME = mo_utils.get_ledger_name(haou.organization_id)
               AND EXISTS
             (SELECT 1
                      FROM per_security_organizations_v ov
                     WHERE ov.security_profile_id =
                           fnd_profile.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')
                       AND ov.organization_id = haou.organization_id)
            --- 2017/05/09 NBO artf2150386 - INT047 - Factures aÃ?Â aÃ?Â  recycler - Defect Bout_en_Bout_Helios_Ref #648
            UNION
            SELECT DISTINCT haou.NAME org_name, aii.org_id, gl.ledger_id
              FROM ap_invoices_interface aii,
                   hr_operating_units    haou, --YWA artf2163145
                   --hr_all_organization_units haou,
                   gl_ledgers gl
             WHERE aii.source = 'SCAN_XGS'
               AND aii.org_id = haou.organization_id
               AND gl.ledger_id = haou.set_of_books_id) v; -- YWA artf2163145
    --AND gl.NAME = mo_utils.get_ledger_name(haou.organization_id)) v;

    dka_Tools_Pkg.put_log_message('  ' || SQL%ROWCOUNT || ' trouvees');
    dka_Tools_Pkg.put_log_message('  [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_function_starttime) || ']');

    IF va_org_name.count = 0 THEN
      RAISE e_no_data;
    ELSE
      dka_Tools_Pkg.put_log_message('Lancement de la procedure d''import pour chaque organisation trouvee');
      vd_function_starttime := LOCALTIMESTAMP;

      FOR i IN va_org_name.first .. va_org_name.last LOOP
        dka_Tools_Pkg.put_log_message('  Organisation : ' ||
                                      va_org_name(i) || ' (org_id: ' ||
                                      va_organization_id(i) || ')');
        vd_local_starttime := LOCALTIMESTAMP;

        gn_org_id    := va_organization_id(i);
        gv_org_name  := va_org_name(i);
        gn_ledger_id := va_ledger_id(i);

        --mo_global.set_policy_context('S',gn_org_id);
        Fnd_Request.set_org_id(org_id => gn_org_id);

        dka_Tools_Pkg.put_log_message('Suppression des lignes de la table d''interface deja traitees');
        vd_function_starttime := LOCALTIMESTAMP;
        vn_interface_count    := delete_processed_lines();
        COMMIT;
        dka_Tools_Pkg.put_log_message('  ' || vn_interface_count ||
                                      ' ligne(s) effacee(s)');
        dka_Tools_Pkg.put_log_message('  [' ||
                                      TO_CHAR(LOCALTIMESTAMP -
                                              vd_function_starttime) || ']');

        dka_Tools_Pkg.put_log_message('**************************************************');
        DECLARE
          vv_errbuf  VARCHAR2(1000);
          vn_retcode NUMBER;
        BEGIN

          control_double(gn_org_id, vv_errbuf, vn_retcode);

    --< BNZ EDB376
  begin
  dka_Tools_Pkg.put_log_message('Suppression  de la table Temporaire DKA_IAPFACXGS_MTDISP (organisation : ' || gv_org_name );
    DELETE FROM DKA_IAPFACXGS_MTDISP;
  Exception WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR exception dans la table MTDISP (organisation : ' ||
                                          gv_org_name);
    end;
    --< BNZ EDB376

          child_import(vv_errbuf, vn_retcode);

          dka_Tools_Pkg.put_log_message('**************************************************');
          IF vn_retcode != 0 THEN
            -- soit une procedure standard d'import a echoue, soit un message
            -- d'erreur quelconque s'est affiche dans le log (cuf non parametre,
            -- donnee non recuperee, etc.)
            dka_Tools_Pkg.put_log_message('Un probleme dans l''execution a ete ' ||
                                          'detecte (organisation : ' ||
                                          gv_org_name || ', message : ' ||
                                          vv_errbuf || ')');
            pn_retcode := 1;
            pv_errbuf  := 'Un probleme dans l''execution a ete detecte';
          END IF;
        END;

        dka_Tools_Pkg.put_log_message('    [' ||
                                      TO_CHAR(LOCALTIMESTAMP -
                                              vd_local_starttime) || ']');
      END LOOP;

      dka_Tools_Pkg.put_log_message('  [' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_function_starttime) || ']');
    END IF;

    -- fin
    dka_Tools_Pkg.put_log_message('[' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_process_starttime) || ']');
  EXCEPTION
    WHEN e_no_data THEN
      dka_Tools_Pkg.put_log_message('Pas de donnees dans la table d''interface');
      dka_Tools_Pkg.put_log_message('[' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_process_starttime) || ']');
      pn_retcode := 0;
      pv_errbuf  := 'Pas de donnees a traiter';
    WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('ERREUR [exception dans import() ' ||
                                    'non catchee]');
      dka_Tools_Pkg.put_log_message('  [' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_function_starttime) || ']');
      dka_Tools_Pkg.put_log_message('[' ||
                                    TO_CHAR(LOCALTIMESTAMP -
                                            vd_process_starttime) || ']');
      pn_retcode := 2;
      pv_errbuf  := 'Erreur ' || SQLERRM || cv_error_message;
      dka_Tools_Pkg.put_log_message('# ' || SQLERRM);
  END import;

  /*
  *Verification des faux doublons
  */

  PROCEDURE control_double(pn_org_id  IN VARCHAR2,
                           pv_errbuf  OUT VARCHAR2,
                           pn_retcode OUT NUMBER) IS

    CURSOR cur_factures IS
      SELECT xii.rowid,
             xii.type,
             xii.code_societe,
             xii.code_division,
             xii.code_region,
             xii.no_commande,
             xii.affacte,
             xii.reglement,
             xii.edi,
             xii.type_piece,
             xii.code_frs,
             xii.site_frs,
             xii.code_dossier,
             xii.packing_slip,
             xii.rib,
             xii.code_devise,
             xii.num_fact,
             xii.mht_devise,
             xii.mtva_devise,
             xii.mttc_devise,
             xii.taux_tva,
             xii.date_piece,
             xii.date_echeance,
             xii.reference_lad,
             xii.date_numerisation,
             xii.code_rejet,
             xii.date_creation,
             xii.type_tva,
             xii.s_type,
             xii.pretypelot,
             xii.prenbfac,
             xii.predate,
             xii.batchprefix,
             xii.batchno,
             xii.batchidx,
             xii.cdrejp,
             xii.cdrejs,
             xii.imagefile,
             xii.imagefile2,
             --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
             xii.nom_fichier,
             xii.rowid rid
        FROM dka_iapfacxgs_interface xii, hr_all_organization_units haou
       WHERE xii.code_region || xii.code_societe = haou.name
         AND haou.organization_id = pn_org_id
         AND xii.flag_trt IS NULL;

    vn_count_double  NUMBER;
    vn_count_doublon NUMBER;

  BEGIN
    dka_Tools_Pkg.put_log_message('control_double');

    FOR rec_fact in cur_factures LOOP

      BEGIN
        /*Recherche des faux doublons : meme org_id,numero facture,fournisseur
        date_piece et invoice_amount differents*/
        BEGIN
          --dka_Tools_Pkg.put_log_message(to_date(rec_fact.date_piece,'RRRR/MM/DD'));
          SELECT count(*)
            INTO vn_count_double
            FROM ap_invoices_all api,
                 --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
                 ap_suppliers      pv,
                 ap_supplier_sites pvs
           WHERE 1 = 1 --api.org_id = pn_org_id 30/04/2020 AAM artf07219745 enlever le critore unite operationnelle lors du controle de doublon
             AND api.invoice_num = rec_fact.num_fact
             AND api.vendor_id = pv.vendor_id
             AND pvs.vendor_site_code = NVL(rec_fact.site_frs, 'NULL')
             AND pvs.vendor_id = pv.vendor_id
             AND pv.segment1 = rec_fact.code_frs
             AND ((api.invoice_date !=
                 to_date(rec_fact.date_piece, 'RRRR/MM/DD')) OR
                 (LTRIM(to_number(TO_CHAR(abs(api.invoice_amount),
                                           '999999999999D99')) * 100) !=
                 abs(rec_fact.mttc_devise)))
                /*QVA 05/08/09*/
             AND api.INVOICE_TYPE_LOOKUP_CODE =
                 decode(rec_fact.type_piece,
                        '0001',
                        'STANDARD',
                        '0002',
                        'CREDIT');

        EXCEPTION
          WHEN OTHERS THEN
            dka_Tools_Pkg.put_log_message(SQLERRM);
            pn_retcode := 2;
            pv_errbuf  := 'Erreur ' || SQLERRM;
            RAISE e_no_data;
        END;

        IF vn_count_double > 0 THEN
          /*Si un faux doublon existe on met a jour les 3 tables suivantes : dka_iapfacxgs_interface,
          DKA_IAPFACXGS_REPORTING_ALL, DKA.DKA_IAPFACXGS_INT_HIST_HEADS*/
          dka_Tools_Pkg.put_log_message('plus que 1');
          BEGIN
            UPDATE dka_iapfacxgs_interface xii
               SET xii.num_fact = rec_fact.num_fact || '_' ||
                                  substr(rec_fact.date_piece, 1, 6)
             WHERE xii.num_fact = rec_fact.num_fact
               AND XII.CODE_SOCIETE = rec_fact.CODE_SOCIETE
               AND XII.CODE_DIVISION = rec_fact.CODE_DIVISION
               AND XII.CODE_FRS = rec_fact.CODE_FRS
               AND XII.DATE_PIECE = rec_fact.DATE_PIECE
               AND XII.MTTC_DEVISE = rec_fact.MTTC_DEVISE
               AND XII.REFERENCE_LAD = rec_fact.REFERENCE_LAD
               AND XII.DATE_NUMERISATION = rec_fact.DATE_NUMERISATION;

            COMMIT;
          END;

          BEGIN
            UPDATE DKA_IAPFACXGS_REPORTING_ALL xira
               SET xira.num_fact = rec_fact.num_fact || '_' ||
                                   substr(xira.date_piece, 1, 6)
             WHERE xira.num_fact = rec_fact.num_fact
               AND XIRA.CODE_SOCIETE = rec_fact.CODE_SOCIETE
               AND XIRA.CODE_DIVISION = rec_fact.CODE_DIVISION
               AND XIRA.CODE_FRS = rec_fact.CODE_FRS
               AND XIRA.DATE_PIECE = rec_fact.DATE_PIECE
               AND XIRA.MTTC_DEVISE = rec_fact.MTTC_DEVISE
               AND XIRA.REFERENCE_LAD = rec_fact.REFERENCE_LAD
               AND XIRA.DATE_NUMERISATION = rec_fact.DATE_NUMERISATION;
            COMMIT;
          END;

          BEGIN
            UPDATE DKA.DKA_IAPFACXGS_INT_HIST_HEADS xiihh
               SET xiihh.num_fact = rec_fact.num_fact || '_' ||
                                    substr(xiihh.date_piece, 1, 6)
             WHERE xiihh.num_fact = rec_fact.num_fact
               AND XIIHH.CODE_SOCIETE = rec_fact.CODE_SOCIETE
               AND XIIHH.CODE_DIVISION = rec_fact.CODE_DIVISION
               AND XIIHH.CODE_FRS = rec_fact.CODE_FRS
               AND XIIHH.DATE_PIECE = rec_fact.DATE_PIECE
               AND XIIHH.MTTC_DEVISE = rec_fact.MTTC_DEVISE
               AND XIIHH.REFERENCE_LAD = rec_fact.REFERENCE_LAD
               AND XIIHH.DATE_NUMERISATION = rec_fact.DATE_NUMERISATION;
            COMMIT;
          END;
        END IF;

        --- 2018/08/27 NBO artf2877778 : DPE20180026 - EDB094 - Controle doublon facture AP sur site different
        -- Verifie si il y a un doublon facture : maÃ?Â aÃ?Âªme numero / maÃ?Â aÃ?Âªme montant / maÃ?Â aÃ?Âªme date / maÃ?Â aÃ?Âªme region / mais site different
        SELECT count(*)
          INTO vn_count_doublon
          FROM ap_invoices_all api, ap_suppliers pv, ap_supplier_sites pvs
         WHERE 1 = 1 --api.org_id = pn_org_id 30/04/2020 AAM artf07219745 enlever le critore unite operationnelle lors du controle de doublon
           AND api.invoice_num = rec_fact.num_fact
           AND api.vendor_id = pv.vendor_id
           AND pvs.vendor_site_code != NVL(rec_fact.site_frs, 'NULL')
           AND pvs.vendor_id = pv.vendor_id
           AND pv.segment1 = rec_fact.code_frs
           AND api.invoice_date =
               to_date(rec_fact.date_piece, 'RRRR/MM/DD')
           AND LTRIM(to_number(TO_CHAR(abs(api.invoice_amount),
                                       '999999999999D99')) * 100) =
               abs(rec_fact.mttc_devise);

        IF vn_count_doublon > 0 THEN
          UPDATE dka_iapfacxgs_interface xii
             SET code_rejet = code_rejet || '.98'
           WHERE ROWID = rec_fact.rid;
        END IF;

      END;
    END LOOP;

  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name || ' - Erreur ' ||
                                    SQLERRM);
      dka_Tools_Pkg.add_error_stack('ORG :' || gv_org_name ||
                                    ' - Erreur lors de la verification des faux doublons');
      RAISE e_generic;
  END control_double;

  ------------------------------------------------------------------------------------
  --  Nom           : populate_xgs_tables
  --  Description   : point d'entree pour l'insertion des donnees de la DKA_IAPFACXGS_TMP dans
  --                  les tables    DKA.DKA_IAPFACXGS_INTERFACE, XXGE.XXGE_IAPFACXGS_REPORTING_ALL,
  --                  XXGE.XXGE_IAPFACXGS_INT_HIST_HEADS et XXGE.XXGE_IAPFACXGS_INT_HIST_LINES.
  --
  --  PARAMETRES    :
  --      pv_errbuf       message d'erreur
  --      pn_retcode      code de retour
  --      px_param1       type
  --  VALEUR RETOURNEE :
  --     Valeurs possibles : 0: deroulement correct
  --                         1: avertissement
  --                         2: deroulement avec erreur
  ------------------------------------------------------------------------------------
  PROCEDURE populate_xgs_tables(pv_errbuf  OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

    -- timestamp pour la mesure du temps d'execution des fonctions/procedures
    vd_func_starttime TIMESTAMP;
    -- timestamp pour le temps d'execution total
    vd_total_starttime TIMESTAMP;

    vn_interface  NUMBER;
    vn_hist_heads NUMBER;
    vn_hist_lines NUMBER;

    rec_param      dka_parameters%ROWTYPE;
    vv_nom_fichier dka_parameters.varchar2_value%type;

    -------------------------------------------------------------------------------------------
    -- Curseur de lecture de la table temporaire pour alimenter table interface et reporting --
    -------------------------------------------------------------------------------------------
    CURSOR Cur_tmp_i IS
      SELECT e.column1  ec1,
             e.column2  ec2,
             e.column3  ec3,
             e.column4  ec4,
             e.column5  ec5,
             e.column6  ec6,
             e.column7  ec7,
             e.column8  ec8,
             e.column9  ec9,
             e.column10 ec10,
             e.column11 ec11,
             e.column12 ec12,
             e.column13 ec13,
             e.column14 ec14,
             e.column15 ec15,
             e.column16 ec16,
             e.column17 ec17,
             e.column18 ec18,
             e.column19 ec19,
             e.column20 ec20,
             e.column21 ec21,
             e.column22 ec22,
             e.column23 ec23,
             e.column24 ec24,
             e.column25 ec25,
             e.column26 ec26,
             e.column27 ec27,
             s.column1  sc1,
             s.column2  sc2,
             s.column3  sc3,
             s.column4  sc4,
             s.column5  sc5,
             s.column6  sc6,
             s.column7  sc7,
             s.column8  sc8,
             s.column9  sc9,
             s.column10 sc10,
             s.column11 sc11
        FROM dka.dka_iapfacxgs_tmp e, dka.dka_iapfacxgs_tmp s
       WHERE e.column1 <> 'FACTURE_SUIVI'
         AND s.column1 = 'FACTURE_SUIVI'
         AND e.column23 = s.column10;

    Rec_tmp_i Cur_tmp_i%ROWTYPE;

    ----------------------------------------------------------------------
    -- Curseur de lecture de la table temporaire pour tables historique --
    ----------------------------------------------------------------------
    CURSOR Cur_tmp_h IS
      SELECT column1,
             column2,
             column3,
             column4,
             column5,
             column6,
             column7,
             column8,
             column9,
             column10,
             column11,
             column12,
             column13,
             column14,
             column15,
             column16,
             column17,
             column18,
             column19,
             column20,
             column21,
             column22,
             column23,
             column24,
             column25,
             column26,
             column27
        FROM dka.dka_iapfacxgs_tmp;

    Rec_tmp_h Cur_tmp_h%ROWTYPE;

  BEGIN

    -- demarrage du programme et initialisation du timestamp total
    vd_total_starttime := LOCALTIMESTAMP;

    -- initialisation des parametres de sorties
    pv_errbuf  := NULL;
    pn_retcode := 0;

    dka_Tools_Pkg.put_log_message('Demarrage du traitement');

    --initialisation des variables globales

    --Recuperer le nom du fichier
    BEGIN

      dka_tools_pkg.get_parameter('IAPCTRFLUX_XEROX',
                                  'DATE_TRAITEMENT',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      IF pn_retcode != 0 THEN
        vv_nom_fichier := 'VE1_DAL_xxxxxxxx' || '.csv';
      ELSE
        vv_nom_fichier := 'VE1_DAL_' ||
                          substr(rec_param.varchar2_value, 1, 8) || '.csv';
      END IF;

    EXCEPTION
      when others THEN
        dka_tools_pkg.get_parameter('IAPCTRFLUX_XEROX',
                                    'DATE_TRAITEMENT',
                                    rec_param,
                                    pn_retcode,
                                    pv_errbuf);
        IF pn_retcode != 0 THEN
          vv_nom_fichier := 'VE1_xxx_xxxxxxxx' || '.csv';
        ELSE
          vv_nom_fichier := 'VE1_xxx_' ||
                            substr(rec_param.varchar2_value, 1, 8) ||
                            '.csv';
        END IF;
        NULL;
    END;

    -- Insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_INTERFACE et DKA_IAPFACXGS_REPORTING_ALL
    -------------------------------------------------------------------------------------------------------------------
    dka_Tools_Pkg.put_log_message('insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_INTERFACE et XXGE_IAPFACXGS_REPORTING_ALL');
    vd_func_starttime := LOCALTIMESTAMP;

    vn_interface := 0;

    open Cur_tmp_i;
    LOOP
      FETCH Cur_tmp_i
        INTO Rec_tmp_i;
      EXIT WHEN Cur_tmp_i%NOTFOUND;

      vn_interface := vn_interface + 1;

      --Creation enreg DKA_IAPFACXGS_INTERFACE
      INSERT INTO DKA_IAPFACXGS_INTERFACE
        (TYPE,
         CODE_SOCIETE,
         CODE_DIVISION,
         CODE_REGION,
         NO_COMMANDE,
         AFFACTE,
         REGLEMENT,
         EDI,
         TYPE_PIECE,
         CODE_FRS,
         SITE_FRS,
         CODE_DOSSIER,
         PACKING_SLIP,
         RIB,
         CODE_DEVISE,
         NUM_FACT,
         MHT_DEVISE,
         MTVA_DEVISE,
         MTTC_DEVISE,
         TAUX_TVA,
         DATE_PIECE,
         DATE_ECHEANCE,
         REFERENCE_LAD,
         DATE_NUMERISATION,
         CODE_REJET,
         DATE_CREATION,
         TYPE_TVA,
         S_TYPE,
         PRETYPELOT,
         PRENBFAC,
         PREDATE,
         BATCHPREFIX,
         BATCHNO,
         BATCHIDX,
         CDREJP,
         CDREJS,
         IMAGEFILE,
         IMAGEFILE2,
         NOM_FICHIER)
      VALUES
        (Rec_tmp_i.ec1,
         Rec_tmp_i.ec2,
         Rec_tmp_i.ec3,
         Rec_tmp_i.ec4,
         Rec_tmp_i.ec5,
         Rec_tmp_i.ec6,
         Rec_tmp_i.ec7,
         Rec_tmp_i.ec8,
         Rec_tmp_i.ec9,
         Rec_tmp_i.ec10,
         Rec_tmp_i.ec11,
         Rec_tmp_i.ec12,
         Rec_tmp_i.ec13,
         Rec_tmp_i.ec14,
         Rec_tmp_i.ec15,
         Rec_tmp_i.ec16,
         Rec_tmp_i.ec17,
         Rec_tmp_i.ec18,
         Rec_tmp_i.ec19,
         Rec_tmp_i.ec20,
         Rec_tmp_i.ec21,
         Rec_tmp_i.ec22,
         Rec_tmp_i.ec23,
         Rec_tmp_i.ec24,
         Rec_tmp_i.ec25,
         Rec_tmp_i.ec26,
         Rec_tmp_i.ec27,
         Rec_tmp_i.sc1,
         Rec_tmp_i.sc2,
         Rec_tmp_i.sc3,
         Rec_tmp_i.sc4,
         Rec_tmp_i.sc5,
         Rec_tmp_i.sc6,
         Rec_tmp_i.sc7,
         Rec_tmp_i.sc8,
         Rec_tmp_i.sc9,
         Rec_tmp_i.sc10,
         Rec_tmp_i.sc11,
         vv_nom_fichier);

      --Creation enreg DKA_IAPFACXGS_REPORTING_ALL
      INSERT INTO DKA_IAPFACXGS_REPORTING_ALL
        (TYPE,
         CODE_SOCIETE,
         CODE_DIVISION,
         CODE_REGION,
         NO_COMMANDE,
         AFFACTE,
         REGLEMENT,
         EDI,
         TYPE_PIECE,
         CODE_FRS,
         SITE_FRS,
         CODE_DOSSIER,
         PACKING_SLIP,
         RIB,
         CODE_DEVISE,
         NUM_FACT,
         MHT_DEVISE,
         MTVA_DEVISE,
         MTTC_DEVISE,
         TAUX_TVA,
         DATE_PIECE,
         DATE_ECHEANCE,
         REFERENCE_LAD,
         DATE_NUMERISATION,
         CODE_REJET,
         DATE_CREATION,
         TYPE_TVA,
         S_TYPE,
         PRETYPELOT,
         PRENBFAC,
         PREDATE,
         BATCHPREFIX,
         BATCHNO,
         BATCHIDX,
         CDREJP,
         CDREJS,
         IMAGEFILE,
         IMAGEFILE2,
         NOM_FICHIER)
      VALUES
        (Rec_tmp_i.ec1,
         Rec_tmp_i.ec2,
         Rec_tmp_i.ec3,
         Rec_tmp_i.ec4,
         Rec_tmp_i.ec5,
         Rec_tmp_i.ec6,
         Rec_tmp_i.ec7,
         Rec_tmp_i.ec8,
         Rec_tmp_i.ec9,
         Rec_tmp_i.ec10,
         Rec_tmp_i.ec11,
         Rec_tmp_i.ec12,
         Rec_tmp_i.ec13,
         Rec_tmp_i.ec14,
         Rec_tmp_i.ec15,
         Rec_tmp_i.ec16,
         Rec_tmp_i.ec17,
         Rec_tmp_i.ec18,
         Rec_tmp_i.ec19,
         Rec_tmp_i.ec20,
         Rec_tmp_i.ec21,
         Rec_tmp_i.ec22,
         Rec_tmp_i.ec23,
         Rec_tmp_i.ec24,
         Rec_tmp_i.ec25,
         Rec_tmp_i.ec26,
         Rec_tmp_i.ec27,
         Rec_tmp_i.sc1,
         Rec_tmp_i.sc2,
         Rec_tmp_i.sc3,
         Rec_tmp_i.sc4,
         Rec_tmp_i.sc5,
         Rec_tmp_i.sc6,
         Rec_tmp_i.sc7,
         Rec_tmp_i.sc8,
         Rec_tmp_i.sc9,
         Rec_tmp_i.sc10,
         Rec_tmp_i.sc11,
         vv_nom_fichier);

    END LOOP;

    --Comptage
    dka_Tools_Pkg.put_log_message('DKA_IAPFACXGS_TMP vers DKA_IAPFACXGS_INTERFACE et XXGE_IAPFACXGS_REPORTING_ALL, ' ||
                                  vn_interface || ' lignes inserees.');

    -- Insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_HIST_HEADS et DKA_IAPFACXGS_HIST_LINES
    -----------------------------------------------------------------------------------------------------------------
    dka_Tools_Pkg.put_log_message('insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_HIST_HEAD et XXGE_IAPFACXGS_HIST_LINES');
    vd_func_starttime := LOCALTIMESTAMP;

    vn_hist_heads := 0;
    vn_hist_lines := 0;

    open Cur_tmp_h;
    LOOP
      FETCH Cur_tmp_h
        INTO Rec_tmp_h;
      EXIT WHEN Cur_tmp_h%NOTFOUND;

      --Creation enreg
      IF Rec_tmp_h.column1 = 'FACTURE_SUIVI' THEN
        vn_hist_lines := vn_hist_lines + 1;
        -- Insert historique Lines
        INSERT INTO DKA_IAPFACXGS_INT_HIST_LINES
          (S_TYPE,
           PRETYPELOT,
           PRENBFAC,
           PREDATE,
           BATCHPREFIX,
           BATCHNO,
           BATCHIDX,
           CDREJP,
           CDREJS,
           IMAGEFILE,
           IMAGEFILE2,
           NOM_FICHIER,
           FIC_IDENT)
        VALUES
          (Rec_tmp_h.Column1,
           Rec_tmp_h.Column2,
           Rec_tmp_h.Column3,
           Rec_tmp_h.Column4,
           Rec_tmp_h.Column5,
           Rec_tmp_h.Column6,
           Rec_tmp_h.Column7,
           Rec_tmp_h.Column8,
           Rec_tmp_h.Column9,
           Rec_tmp_h.Column10,
           Rec_tmp_h.Column11,
           vv_nom_fichier,
           TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));

      ELSE
        vn_hist_heads := vn_hist_heads + 1;
        -- Insert historique Heads
        INSERT INTO DKA_IAPFACXGS_INT_HIST_HEADS
          (TYPE,
           CODE_SOCIETE,
           CODE_DIVISION,
           CODE_REGION,
           NO_COMMANDE,
           AFFACTE,
           REGLEMENT,
           EDI,
           TYPE_PIECE,
           CODE_FRS,
           SITE_FRS,
           CODE_DOSSIER,
           PACKING_SLIP,
           RIB,
           CODE_DEVISE,
           NUM_FACT,
           MHT_DEVISE,
           MTVA_DEVISE,
           MTTC_DEVISE,
           TAUX_TVA,
           DATE_PIECE,
           DATE_ECHEANCE,
           REFERENCE_LAD,
           DATE_NUMERISATION,
           CODE_REJET,
           DATE_CREATION,
           TYPE_TVA,
           NOM_FICHIER,
           FIC_IDENT)
        VALUES
          (Rec_tmp_h.Column1,
           Rec_tmp_h.Column2,
           Rec_tmp_h.Column3,
           Rec_tmp_h.Column4,
           Rec_tmp_h.Column5,
           Rec_tmp_h.Column6,
           Rec_tmp_h.Column7,
           Rec_tmp_h.Column8,
           Rec_tmp_h.Column9,
           Rec_tmp_h.Column10,
           Rec_tmp_h.Column11,
           Rec_tmp_h.Column12,
           Rec_tmp_h.Column13,
           Rec_tmp_h.Column14,
           Rec_tmp_h.Column15,
           Rec_tmp_h.Column16,
           Rec_tmp_h.Column17,
           Rec_tmp_h.Column18,
           Rec_tmp_h.Column19,
           Rec_tmp_h.Column20,
           Rec_tmp_h.Column21,
           Rec_tmp_h.Column22,
           Rec_tmp_h.Column23,
           Rec_tmp_h.Column24,
           Rec_tmp_h.Column25,
           Rec_tmp_h.Column26,
           Rec_tmp_h.Column27,
           vv_nom_fichier,
           TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));

      END IF;

    END LOOP;

    --Comptage
    dka_Tools_Pkg.put_log_message('DKA_IAPFACXGS_TMP vers DKA_IAPFACXGS_HIST_LINES, ' ||
                                  vn_hist_lines || ' lignes inserees.');
    dka_Tools_Pkg.put_log_message('DKA_IAPFACXGS_TMP vers DKA_IAPFACXGS_HIST_HEADS, ' ||
                                  vn_hist_heads || ' lignes inserees.');

    dka_Tools_Pkg.put_log_message('temps ecoule [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_func_starttime,
                                          'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') || ']');

    dka_Tools_Pkg.put_log_message('Fin du traitement, ' || SQL%ROWCOUNT ||
                                  ' lignes inserees.');

    dka_Tools_Pkg.put_log_message('temps total ecoule : [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_total_starttime,
                                          'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') || ']');

    pn_retcode := 0;
    pv_errbuf  := NULL;

  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('erreur : ' || SQLCODE || ' - ' ||
                                    SQLERRM);
      pn_retcode := 2;
      pv_errbuf  := 'Consultez le fichier de log';
      ROLLBACK;

  END populate_xgs_tables;
  ------------------------------------------------------------------------------------  -- 22/08/2011 JB start
  --  Nom           : populate_zci_tables
  --  Description   : point d'entree pour l'insertion des donnees de la DKA_IAPFACZCI_TMP dans
  --                  les tables    DKA.DKA_IAPFACXGS_INTERFACE, XXGE.XXGE_IAPFACXGS_REPORTING_ALL,
  --                  XXGE.XXGE_IAPFACXGS_INT_HIST_HEADS et XXGE.XXGE_IAPFACXGS_INT_HIST_LINES.
  --
  --  PARAMETRES    :
  --      pv_errbuf       message d'erreur
  --      pn_retcode      code de retour
  --      px_param1       type
  --  VALEUR RETOURNEE :
  --     Valeurs possibles : 0: deroulement correct
  --                         1: avertissement
  --                         2: deroulement avec erreur
  ------------------------------------------------------------------------------------
  PROCEDURE populate_zci_tables(pv_errbuf  OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

    -- timestamp pour la mesure du temps d'execution des fonctions/procedures
    vd_func_starttime TIMESTAMP;
    -- timestamp pour le temps d'execution total
    vd_total_starttime TIMESTAMP;

    vn_interface  NUMBER;
    vn_hist_heads NUMBER;
    vn_hist_lines NUMBER;

    rec_param      dka_parameters%ROWTYPE;
    vv_nom_fichier dka_parameters.varchar2_value%type;

    -------------------------------------------------------------------------------------------
    -- Curseur de lecture de la table temporaire pour alimenter table interface et reporting --
    -------------------------------------------------------------------------------------------
    CURSOR Cur_tmp_i IS
      SELECT e.column1  ec1,
             e.column2  ec2,
             e.column3  ec3,
             e.column4  ec4,
             e.column5  ec5,
             e.column6  ec6,
             e.column7  ec7,
             e.column8  ec8,
             e.column9  ec9,
             e.column10 ec10,
             e.column11 ec11,
             e.column12 ec12,
             e.column13 ec13,
             e.column14 ec14,
             e.column15 ec15,
             e.column16 ec16,
             e.column17 ec17,
             e.column18 ec18,
             e.column19 ec19,
             e.column20 ec20,
             e.column21 ec21,
             e.column22 ec22,
             e.column23 ec23,
             e.column24 ec24,
             e.column25 ec25,
             e.column26 ec26,
             e.column27 ec27,
             s.column1  sc1,
             s.column2  sc2,
             s.column3  sc3,
             s.column4  sc4,
             s.column5  sc5,
             s.column6  sc6,
             s.column7  sc7,
             s.column8  sc8,
             s.column9  sc9,
             s.column10 sc10,
             s.column11 sc11
        FROM dka.dka_iapfaczci_tmp e, dka.dka_iapfaczci_tmp s
       WHERE e.column1 <> 'FACTURE_SUIVI'
         AND s.column1 = 'FACTURE_SUIVI'
         AND e.column23 = s.column10;

    Rec_tmp_i Cur_tmp_i%ROWTYPE;

    ----------------------------------------------------------------------
    -- Curseur de lecture de la table temporaire pour tables historique --
    ----------------------------------------------------------------------
    CURSOR Cur_tmp_h IS
      SELECT column1,
             column2,
             column3,
             column4,
             column5,
             column6,
             column7,
             column8,
             column9,
             column10,
             column11,
             column12,
             column13,
             column14,
             column15,
             column16,
             column17,
             column18,
             column19,
             column20,
             column21,
             column22,
             column23,
             column24,
             column25,
             column26,
             column27
        FROM dka.dka_iapfaczci_tmp;

    Rec_tmp_h Cur_tmp_h%ROWTYPE;

  BEGIN

    vd_total_starttime := LOCALTIMESTAMP;

    -- initialisation des parametres de sorties
    pv_errbuf  := NULL;
    pn_retcode := 0;

    dka_Tools_Pkg.put_log_message('Demarrage du traitement');

    --initialisation des variables globales

    --Recuperer le nom du fichier
    BEGIN

      dka_tools_pkg.get_parameter('IAPCTRFLUX_ZCI',
                                  'DATE_TRAITEMENT',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      IF pn_retcode != 0 THEN
        vv_nom_fichier := 'ZCI_DAL_xxxxxxxx' || '.csv';
      ELSE
        vv_nom_fichier := 'ZCI_DAL_' ||
                          substr(rec_param.varchar2_value, 1, 8) || '.csv';
      END IF;

    EXCEPTION
      when others THEN

        dka_tools_pkg.get_parameter('IAPCTRFLUX_ZCI',
                                    'DATE_TRAITEMENT',
                                    rec_param,
                                    pn_retcode,
                                    pv_errbuf);
        IF pn_retcode != 0 THEN
          vv_nom_fichier := 'ZCI_xxx_xxxxxxxx' || '.csv';
        ELSE
          vv_nom_fichier := 'ZCI_xxx_' ||
                            substr(rec_param.varchar2_value, 1, 8) ||
                            '.csv';
        END IF;
        NULL;
    END;

    -- Insertion des enregistrements de DKA_IAPFACZCI_TMP dans DKA_IAPFACXGS_INTERFACE et DKA_IAPFACXGS_REPORTING_ALL
    -------------------------------------------------------------------------------------------------------------------
    dka_Tools_Pkg.put_log_message('insertion des enregistrements de DKA_IAPFACZCI_TMP dans DKA_IAPFACXGS_INTERFACE et XXGE_IAPFACXGS_REPORTING_ALL');

    vd_func_starttime := LOCALTIMESTAMP;

    vn_interface := 0;

    open Cur_tmp_i;
    LOOP
      FETCH Cur_tmp_i
        INTO Rec_tmp_i;
      EXIT WHEN Cur_tmp_i%NOTFOUND;

      vn_interface := vn_interface + 1;

      --Creation enreg DKA_IAPFACXGS_INTERFACE
      INSERT INTO DKA_IAPFACXGS_INTERFACE
        (TYPE,
         CODE_SOCIETE,
         CODE_DIVISION,
         CODE_REGION,
         NO_COMMANDE,
         AFFACTE,
         REGLEMENT,
         EDI,
         TYPE_PIECE,
         CODE_FRS,
         SITE_FRS,
         CODE_DOSSIER,
         PACKING_SLIP,
         RIB,
         CODE_DEVISE,
         NUM_FACT,
         MHT_DEVISE,
         MTVA_DEVISE,
         MTTC_DEVISE,
         TAUX_TVA,
         DATE_PIECE,
         DATE_ECHEANCE,
         REFERENCE_LAD,
         DATE_NUMERISATION,
         CODE_REJET,
         DATE_CREATION,
         TYPE_TVA,
         S_TYPE,
         PRETYPELOT,
         PRENBFAC,
         PREDATE,
         BATCHPREFIX,
         BATCHNO,
         BATCHIDX,
         CDREJP,
         CDREJS,
         IMAGEFILE,
         IMAGEFILE2,
         NOM_FICHIER)
      VALUES
        (Rec_tmp_i.ec1,
         Rec_tmp_i.ec2,
         Rec_tmp_i.ec3,
         Rec_tmp_i.ec4,
         Rec_tmp_i.ec5,
         Rec_tmp_i.ec6,
         Rec_tmp_i.ec7,
         Rec_tmp_i.ec8,
         Rec_tmp_i.ec9,
         Rec_tmp_i.ec10,
         Rec_tmp_i.ec11,
         Rec_tmp_i.ec12,
         Rec_tmp_i.ec13,
         Rec_tmp_i.ec14,
         Rec_tmp_i.ec15,
         Rec_tmp_i.ec16,
         Rec_tmp_i.ec17,
         Rec_tmp_i.ec18,
         Rec_tmp_i.ec19,
         Rec_tmp_i.ec20,
         Rec_tmp_i.ec21,
         Rec_tmp_i.ec22,
         Rec_tmp_i.ec23,
         Rec_tmp_i.ec24,
         Rec_tmp_i.ec25,
         Rec_tmp_i.ec26,
         Rec_tmp_i.ec27,
         Rec_tmp_i.sc1,
         Rec_tmp_i.sc2,
         Rec_tmp_i.sc3,
         Rec_tmp_i.sc4,
         Rec_tmp_i.sc5,
         Rec_tmp_i.sc6,
         Rec_tmp_i.sc7,
         Rec_tmp_i.sc8,
         Rec_tmp_i.sc9,
         Rec_tmp_i.sc10,
         Rec_tmp_i.sc11,
         vv_nom_fichier);

      --Creation enreg DKA_IAPFACXGS_REPORTING_ALL
      INSERT INTO DKA_IAPFACXGS_REPORTING_ALL
        (TYPE,
         CODE_SOCIETE,
         CODE_DIVISION,
         CODE_REGION,
         NO_COMMANDE,
         AFFACTE,
         REGLEMENT,
         EDI,
         TYPE_PIECE,
         CODE_FRS,
         SITE_FRS,
         CODE_DOSSIER,
         PACKING_SLIP,
         RIB,
         CODE_DEVISE,
         NUM_FACT,
         MHT_DEVISE,
         MTVA_DEVISE,
         MTTC_DEVISE,
         TAUX_TVA,
         DATE_PIECE,
         DATE_ECHEANCE,
         REFERENCE_LAD,
         DATE_NUMERISATION,
         CODE_REJET,
         DATE_CREATION,
         TYPE_TVA,
         S_TYPE,
         PRETYPELOT,
         PRENBFAC,
         PREDATE,
         BATCHPREFIX,
         BATCHNO,
         BATCHIDX,
         CDREJP,
         CDREJS,
         IMAGEFILE,
         IMAGEFILE2,
         NOM_FICHIER)
      VALUES
        (Rec_tmp_i.ec1,
         Rec_tmp_i.ec2,
         Rec_tmp_i.ec3,
         Rec_tmp_i.ec4,
         Rec_tmp_i.ec5,
         Rec_tmp_i.ec6,
         Rec_tmp_i.ec7,
         Rec_tmp_i.ec8,
         Rec_tmp_i.ec9,
         Rec_tmp_i.ec10,
         Rec_tmp_i.ec11,
         Rec_tmp_i.ec12,
         Rec_tmp_i.ec13,
         Rec_tmp_i.ec14,
         Rec_tmp_i.ec15,
         Rec_tmp_i.ec16,
         Rec_tmp_i.ec17,
         Rec_tmp_i.ec18,
         Rec_tmp_i.ec19,
         Rec_tmp_i.ec20,
         Rec_tmp_i.ec21,
         Rec_tmp_i.ec22,
         Rec_tmp_i.ec23,
         Rec_tmp_i.ec24,
         Rec_tmp_i.ec25,
         Rec_tmp_i.ec26,
         Rec_tmp_i.ec27,
         Rec_tmp_i.sc1,
         Rec_tmp_i.sc2,
         Rec_tmp_i.sc3,
         Rec_tmp_i.sc4,
         Rec_tmp_i.sc5,
         Rec_tmp_i.sc6,
         Rec_tmp_i.sc7,
         Rec_tmp_i.sc8,
         Rec_tmp_i.sc9,
         Rec_tmp_i.sc10,
         Rec_tmp_i.sc11,
         vv_nom_fichier);

    END LOOP;

    --Comptage
    dka_Tools_Pkg.put_log_message('DKA_IAPFACZCI_TMP vers DKA_IAPFACXGS_INTERFACE et XXGE_IAPFACXGS_REPORTING_ALL, ' ||
                                  vn_interface || ' lignes inserees.');

    -- Insertion des enregistrements de DKA_IAPFACZCI_TMP dans DKA_IAPFACXGS_HIST_HEADS et DKA_IAPFACXGS_HIST_LINES
    -----------------------------------------------------------------------------------------------------------------
    dka_Tools_Pkg.put_log_message('insertion des enregistrements de DKA_IAPFACZCI_TMP dans DKA_IAPFACXGS_HIST_HEAD et XXGE_IAPFACXGS_HIST_LINES');

    vd_func_starttime := LOCALTIMESTAMP;

    vn_hist_heads := 0;
    vn_hist_lines := 0;

    open Cur_tmp_h;
    LOOP
      FETCH Cur_tmp_h
        INTO Rec_tmp_h;
      EXIT WHEN Cur_tmp_h%NOTFOUND;

      --Creation enreg
      IF Rec_tmp_h.column1 = 'FACTURE_SUIVI' THEN
        vn_hist_lines := vn_hist_lines + 1;
        -- Insert historique Lines
        INSERT INTO DKA_IAPFACXGS_INT_HIST_LINES
          (S_TYPE,
           PRETYPELOT,
           PRENBFAC,
           PREDATE,
           BATCHPREFIX,
           BATCHNO,
           BATCHIDX,
           CDREJP,
           CDREJS,
           IMAGEFILE,
           IMAGEFILE2,
           NOM_FICHIER,
           FIC_IDENT)
        VALUES
          (Rec_tmp_h.Column1,
           Rec_tmp_h.Column2,
           Rec_tmp_h.Column3,
           Rec_tmp_h.Column4,
           Rec_tmp_h.Column5,
           Rec_tmp_h.Column6,
           Rec_tmp_h.Column7,
           Rec_tmp_h.Column8,
           Rec_tmp_h.Column9,
           Rec_tmp_h.Column10,
           Rec_tmp_h.Column11,
           vv_nom_fichier,
           TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));

      ELSE
        vn_hist_heads := vn_hist_heads + 1;
        -- Insert historique Heads
        INSERT INTO DKA_IAPFACXGS_INT_HIST_HEADS
          (TYPE,
           CODE_SOCIETE,
           CODE_DIVISION,
           CODE_REGION,
           NO_COMMANDE,
           AFFACTE,
           REGLEMENT,
           EDI,
           TYPE_PIECE,
           CODE_FRS,
           SITE_FRS,
           CODE_DOSSIER,
           PACKING_SLIP,
           RIB,
           CODE_DEVISE,
           NUM_FACT,
           MHT_DEVISE,
           MTVA_DEVISE,
           MTTC_DEVISE,
           TAUX_TVA,
           DATE_PIECE,
           DATE_ECHEANCE,
           REFERENCE_LAD,
           DATE_NUMERISATION,
           CODE_REJET,
           DATE_CREATION,
           TYPE_TVA,
           NOM_FICHIER,
           FIC_IDENT)
        VALUES
          (Rec_tmp_h.Column1,
           Rec_tmp_h.Column2,
           Rec_tmp_h.Column3,
           Rec_tmp_h.Column4,
           Rec_tmp_h.Column5,
           Rec_tmp_h.Column6,
           Rec_tmp_h.Column7,
           Rec_tmp_h.Column8,
           Rec_tmp_h.Column9,
           Rec_tmp_h.Column10,
           Rec_tmp_h.Column11,
           Rec_tmp_h.Column12,
           Rec_tmp_h.Column13,
           Rec_tmp_h.Column14,
           Rec_tmp_h.Column15,
           Rec_tmp_h.Column16,
           Rec_tmp_h.Column17,
           Rec_tmp_h.Column18,
           Rec_tmp_h.Column19,
           Rec_tmp_h.Column20,
           Rec_tmp_h.Column21,
           Rec_tmp_h.Column22,
           Rec_tmp_h.Column23,
           Rec_tmp_h.Column24,
           Rec_tmp_h.Column25,
           Rec_tmp_h.Column26,
           Rec_tmp_h.Column27,
           vv_nom_fichier,
           TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));

      END IF;

    END LOOP;

    --Comptage
    dka_Tools_Pkg.put_log_message('DKA_IAPFACZCI_TMP vers DKA_IAPFACXGS_HIST_LINES, ' ||
                                  vn_hist_lines || ' lignes inserees.');
    dka_Tools_Pkg.put_log_message('DKA_IAPFACZCI_TMP vers DKA_IAPFACXGS_HIST_HEADS, ' ||
                                  vn_hist_heads || ' lignes inserees.');

    dka_Tools_Pkg.put_log_message('temps ecoule [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_func_starttime,
                                          'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') || ']');

    dka_Tools_Pkg.put_log_message('Fin du traitement, ' || SQL%ROWCOUNT ||
                                  ' lignes inserees.');

    dka_Tools_Pkg.put_log_message('temps total ecoule : [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_total_starttime,
                                          'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') || ']');

    pn_retcode := 0;
    pv_errbuf  := NULL;

  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('erreur : ' || SQLCODE || ' - ' ||
                                    SQLERRM);
      pn_retcode := 2;
      pv_errbuf  := 'Consultez le fichier de log';
      ROLLBACK;

  END populate_zci_tables;
 ------------------------------------------------------------------------------------
  --  Nom           : populate_dsp_tables
  --  Description   : point d'entrÃ?Â©e pour l'insertion des donnÃ?Â©es de la DKA_IAPFACDSP_TMP dans
  --                  les tables    DKA.DKA_IAPFACXGS_INTERFACE, XXGE.XXGE_IAPFACXGS_REPORTING_ALL,
  --                  XXGE.XXGE_IAPFACXGS_INT_HIST_HEADS et XXGE.XXGE_IAPFACXGS_INT_HIST_LINES.
  --
  --  PARAMETRES    :
  --      pv_errbuf       message d'erreur
  --      pn_retcode      code de retour
  --      px_param1       type
  --  VALEUR RETOURNEE :
  --     Valeurs possibles : 0: deroulement correct
  --                         1: avertissement
  --                         2: deroulement avec erreur
  ------------------------------------------------------------------------------------
  PROCEDURE populate_dsp_tables(pv_errbuf  OUT VARCHAR2,
                                pn_retcode OUT NUMBER) IS

    -- timestamp pour la mesure du temps d'exÃ?Â©cution des fonctions/procÃ?Â©dures
    vd_func_starttime TIMESTAMP;
    -- timestamp pour le temps d'exÃ?Â©cution total
    vd_total_starttime TIMESTAMP;

    vn_interface  NUMBER;
    vn_hist_heads NUMBER;
    vn_hist_lines NUMBER;

    rec_param      dka_parameters%ROWTYPE;
    vv_nom_fichier dka_parameters.varchar2_value%type;

    -------------------------------------------------------------------------------------------
    -- Curseur de lecture de la table temporaire pour alimenter table interface et reporting --
    -------------------------------------------------------------------------------------------
    CURSOR Cur_tmp_i IS
      SELECT e.column1  ec1,
             e.column2  ec2,
             e.column3  ec3,
             e.column4  ec4,
             e.column5  ec5,
             e.column6  ec6,
             e.column7  ec7,
             e.column8  ec8,
             e.column9  ec9,
             e.column10 ec10,
             e.column11 ec11,
             e.column12 ec12,
             e.column13 ec13,
             e.column14 ec14,
             e.column15 ec15,
             e.column16 ec16,
             e.column17 ec17,
             e.column18 ec18,
             e.column19 ec19,
             e.column20 ec20,
             e.column21 ec21,
             e.column22 ec22,
             e.column23 ec23,
             e.column24 ec24,
             e.column25 ec25,
             e.column26 ec26,
             e.column27 ec27,
             s.column1  sc1,
             s.column2  sc2,
             s.column3  sc3,
             s.column4  sc4,
             s.column5  sc5,
             s.column6  sc6,
             s.column7  sc7,
             s.column8  sc8,
             s.column9  sc9,
             s.column10 sc10,
             s.column11 sc11
        FROM dka.dka_iapfacdsp_tmp e, dka.dka_iapfacdsp_tmp s
       WHERE e.column1 <> 'FACTURE_SUIVI'
         AND s.column1 = 'FACTURE_SUIVI'
         AND e.column23 = s.column10;

    Rec_tmp_i Cur_tmp_i%ROWTYPE;

    ----------------------------------------------------------------------
    -- Curseur de lecture de la table temporaire pour tables historique --
    ----------------------------------------------------------------------
    CURSOR Cur_tmp_h IS
      SELECT column1,
             column2,
             column3,
             column4,
             column5,
             column6,
             column7,
             column8,
             column9,
             column10,
             column11,
             column12,
             column13,
             column14,
             column15,
             column16,
             column17,
             column18,
             column19,
             column20,
             column21,
             column22,
             column23,
             column24,
             column25,
             column26,
             column27
        FROM dka.dka_iapfacdsp_tmp;

    Rec_tmp_h Cur_tmp_h%ROWTYPE;

  BEGIN

    -- dÃ?Â©marrage du programme et initialisation du timestamp total
    vd_total_starttime := LOCALTIMESTAMP;

    -- initialisation des parametres de sorties
    pv_errbuf  := NULL;
    pn_retcode := 0;

    dka_Tools_Pkg.put_log_message('DÃ?Â©marrage du traitement');

    --initialisation des variables globales

    --Recuperer le nom du fichier
    BEGIN

      dka_tools_pkg.get_parameter('IAPCTRFLUX_IVALUA',
                                  'DATE_TRAITEMENT',
                                  rec_param,
                                  pn_retcode,
                                  pv_errbuf);
      IF pn_retcode != 0 THEN
        vv_nom_fichier := 'DSP_DAL_xxxxxxxx' || '.csv';
      ELSE
        vv_nom_fichier := 'DSP_DAL_' ||
                          substr(rec_param.varchar2_value, 1, 8) || '.csv';
      END IF;

    EXCEPTION
      when others THEN
        dka_tools_pkg.get_parameter('IAPCTRFLUX_IVALUA',
                                    'DATE_TRAITEMENT',
                                    rec_param,
                                    pn_retcode,
                                    pv_errbuf);
        IF pn_retcode != 0 THEN
          vv_nom_fichier := 'DSP_xxx_xxxxxxxx' || '.csv';
        ELSE
          vv_nom_fichier := 'DSP_xxx_' ||
                            substr(rec_param.varchar2_value, 1, 8) ||
                            '.csv';
        END IF;
        NULL;
    END;

    -- Insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_INTERFACE et DKA_IAPFACXGS_REPORTING_ALL
    -------------------------------------------------------------------------------------------------------------------
    dka_Tools_Pkg.put_log_message('insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_INTERFACE et XXGE_IAPFACXGS_REPORTING_ALL');
    vd_func_starttime := LOCALTIMESTAMP;

    vn_interface := 0;

    open Cur_tmp_i;
    LOOP
      FETCH Cur_tmp_i
        INTO Rec_tmp_i;
      EXIT WHEN Cur_tmp_i%NOTFOUND;

      vn_interface := vn_interface + 1;

      --CrÃ?Â©ation enreg DKA_IAPFACXGS_INTERFACE
      INSERT INTO DKA_IAPFACXGS_INTERFACE
        (TYPE,
         CODE_SOCIETE,
         CODE_DIVISION,
         CODE_REGION,
         NO_COMMANDE,
         AFFACTE,
         REGLEMENT,
         EDI,
         TYPE_PIECE,
         CODE_FRS,
         SITE_FRS,
         CODE_DOSSIER,
         PACKING_SLIP,
         RIB,
         CODE_DEVISE,
         NUM_FACT,
         MHT_DEVISE,
         MTVA_DEVISE,
         MTTC_DEVISE,
         TAUX_TVA,
         DATE_PIECE,
         DATE_ECHEANCE,
         REFERENCE_LAD,
         DATE_NUMERISATION,
         CODE_REJET,
         DATE_CREATION,
         TYPE_TVA,
         S_TYPE,
         PRETYPELOT,
         PRENBFAC,
         PREDATE,
         BATCHPREFIX,
         BATCHNO,
         BATCHIDX,
         CDREJP,
         CDREJS,
         IMAGEFILE,
         IMAGEFILE2,
         NOM_FICHIER)
      VALUES
        (Rec_tmp_i.ec1,
         Rec_tmp_i.ec2,
         Rec_tmp_i.ec3,
         Rec_tmp_i.ec4,
         Rec_tmp_i.ec5,
         Rec_tmp_i.ec6,
         Rec_tmp_i.ec7,
         Rec_tmp_i.ec8,
         Rec_tmp_i.ec9,
         Rec_tmp_i.ec10,
         Rec_tmp_i.ec11,
         Rec_tmp_i.ec12,
         Rec_tmp_i.ec13,
         Rec_tmp_i.ec14,
         Rec_tmp_i.ec15,
         Rec_tmp_i.ec16,
         Rec_tmp_i.ec17,
         Rec_tmp_i.ec18,
         Rec_tmp_i.ec19,
         Rec_tmp_i.ec20,
         Rec_tmp_i.ec21,
         Rec_tmp_i.ec22,
         Rec_tmp_i.ec23,
         Rec_tmp_i.ec24,
         Rec_tmp_i.ec25,
         Rec_tmp_i.ec26,
         Rec_tmp_i.ec27,
         Rec_tmp_i.sc1,
         Rec_tmp_i.sc2,
         Rec_tmp_i.sc3,
         Rec_tmp_i.sc4,
         Rec_tmp_i.sc5,
         Rec_tmp_i.sc6,
         Rec_tmp_i.sc7,
         Rec_tmp_i.sc8,
         Rec_tmp_i.sc9,
         Rec_tmp_i.sc10,
         Rec_tmp_i.sc11,
         vv_nom_fichier);

      --CrÃ?Â©ation enreg DKA_IAPFACXGS_REPORTING_ALL
      INSERT INTO DKA_IAPFACXGS_REPORTING_ALL
        (TYPE,
         CODE_SOCIETE,
         CODE_DIVISION,
         CODE_REGION,
         NO_COMMANDE,
         AFFACTE,
         REGLEMENT,
         EDI,
         TYPE_PIECE,
         CODE_FRS,
         SITE_FRS,
         CODE_DOSSIER,
         PACKING_SLIP,
         RIB,
         CODE_DEVISE,
         NUM_FACT,
         MHT_DEVISE,
         MTVA_DEVISE,
         MTTC_DEVISE,
         TAUX_TVA,
         DATE_PIECE,
         DATE_ECHEANCE,
         REFERENCE_LAD,
         DATE_NUMERISATION,
         CODE_REJET,
         DATE_CREATION,
         TYPE_TVA,
         S_TYPE,
         PRETYPELOT,
         PRENBFAC,
         PREDATE,
         BATCHPREFIX,
         BATCHNO,
         BATCHIDX,
         CDREJP,
         CDREJS,
         IMAGEFILE,
         IMAGEFILE2,
         NOM_FICHIER)
      VALUES
        (Rec_tmp_i.ec1,
         Rec_tmp_i.ec2,
         Rec_tmp_i.ec3,
         Rec_tmp_i.ec4,
         Rec_tmp_i.ec5,
         Rec_tmp_i.ec6,
         Rec_tmp_i.ec7,
         Rec_tmp_i.ec8,
         Rec_tmp_i.ec9,
         Rec_tmp_i.ec10,
         Rec_tmp_i.ec11,
         Rec_tmp_i.ec12,
         Rec_tmp_i.ec13,
         Rec_tmp_i.ec14,
         Rec_tmp_i.ec15,
         Rec_tmp_i.ec16,
         Rec_tmp_i.ec17,
         Rec_tmp_i.ec18,
         Rec_tmp_i.ec19,
         Rec_tmp_i.ec20,
         Rec_tmp_i.ec21,
         Rec_tmp_i.ec22,
         Rec_tmp_i.ec23,
         Rec_tmp_i.ec24,
         Rec_tmp_i.ec25,
         Rec_tmp_i.ec26,
         Rec_tmp_i.ec27,
         Rec_tmp_i.sc1,
         Rec_tmp_i.sc2,
         Rec_tmp_i.sc3,
         Rec_tmp_i.sc4,
         Rec_tmp_i.sc5,
         Rec_tmp_i.sc6,
         Rec_tmp_i.sc7,
         Rec_tmp_i.sc8,
         Rec_tmp_i.sc9,
         Rec_tmp_i.sc10,
         Rec_tmp_i.sc11,
         vv_nom_fichier);

    END LOOP;

    --Comptage
    dka_Tools_Pkg.put_log_message('DKA_IAPFACDSP_TMP vers DKA_IAPFACXGS_INTERFACE et XXGE_IAPFACXGS_REPORTING_ALL, ' ||
                                  vn_interface || ' lignes insÃ?Â©rÃ?Â©es.');

    -- Insertion des enregistrements de DKA_IAPFACDSP_TMP dans DKA_IAPFACXGS_HIST_HEADS et DKA_IAPFACXGS_HIST_LINES
    -----------------------------------------------------------------------------------------------------------------
    dka_Tools_Pkg.put_log_message('insertion des enregistrements de DKA_IAPFACXGS_TMP dans DKA_IAPFACXGS_HIST_HEAD et XXGE_IAPFACXGS_HIST_LINES');
    vd_func_starttime := LOCALTIMESTAMP;

    vn_hist_heads := 0;
    vn_hist_lines := 0;

    open Cur_tmp_h;
    LOOP
      FETCH Cur_tmp_h
        INTO Rec_tmp_h;
      EXIT WHEN Cur_tmp_h%NOTFOUND;

      --CrÃ?Â©ation enreg
      IF Rec_tmp_h.column1 = 'FACTURE_SUIVI' THEN
        vn_hist_lines := vn_hist_lines + 1;
        -- Insert historique Lines
        INSERT INTO DKA_IAPFACXGS_INT_HIST_LINES
          (S_TYPE,
           PRETYPELOT,
           PRENBFAC,
           PREDATE,
           BATCHPREFIX,
           BATCHNO,
           BATCHIDX,
           CDREJP,
           CDREJS,
           IMAGEFILE,
           IMAGEFILE2,
           NOM_FICHIER,
           FIC_IDENT)
        VALUES
          (Rec_tmp_h.Column1,
           Rec_tmp_h.Column2,
           Rec_tmp_h.Column3,
           Rec_tmp_h.Column4,
           Rec_tmp_h.Column5,
           Rec_tmp_h.Column6,
           Rec_tmp_h.Column7,
           Rec_tmp_h.Column8,
           Rec_tmp_h.Column9,
           Rec_tmp_h.Column10,
           Rec_tmp_h.Column11,
           vv_nom_fichier,
           TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));

      ELSE
        vn_hist_heads := vn_hist_heads + 1;
        -- Insert historique Heads
        INSERT INTO DKA_IAPFACXGS_INT_HIST_HEADS
          (TYPE,
           CODE_SOCIETE,
           CODE_DIVISION,
           CODE_REGION,
           NO_COMMANDE,
           AFFACTE,
           REGLEMENT,
           EDI,
           TYPE_PIECE,
           CODE_FRS,
           SITE_FRS,
           CODE_DOSSIER,
           PACKING_SLIP,
           RIB,
           CODE_DEVISE,
           NUM_FACT,
           MHT_DEVISE,
           MTVA_DEVISE,
           MTTC_DEVISE,
           TAUX_TVA,
           DATE_PIECE,
           DATE_ECHEANCE,
           REFERENCE_LAD,
           DATE_NUMERISATION,
           CODE_REJET,
           DATE_CREATION,
           TYPE_TVA,
           NOM_FICHIER,
           FIC_IDENT)
        VALUES
          (Rec_tmp_h.Column1,
           Rec_tmp_h.Column2,
           Rec_tmp_h.Column3,
           Rec_tmp_h.Column4,
           Rec_tmp_h.Column5,
           Rec_tmp_h.Column6,
           Rec_tmp_h.Column7,
           Rec_tmp_h.Column8,
           Rec_tmp_h.Column9,
           Rec_tmp_h.Column10,
           Rec_tmp_h.Column11,
           Rec_tmp_h.Column12,
           Rec_tmp_h.Column13,
           Rec_tmp_h.Column14,
           Rec_tmp_h.Column15,
           Rec_tmp_h.Column16,
           Rec_tmp_h.Column17,
           Rec_tmp_h.Column18,
           Rec_tmp_h.Column19,
           Rec_tmp_h.Column20,
           Rec_tmp_h.Column21,
           Rec_tmp_h.Column22,
           Rec_tmp_h.Column23,
           Rec_tmp_h.Column24,
           Rec_tmp_h.Column25,
           Rec_tmp_h.Column26,
           Rec_tmp_h.Column27,
           vv_nom_fichier,
           TO_CHAR(SYSDATE, 'YYYYMMDDHH24MISS'));

      END IF;

    END LOOP;

    --Comptage
    dka_Tools_Pkg.put_log_message('DKA_IAPFACDSP_TMP vers DKA_IAPFACXGS_HIST_LINES, ' ||
                                  vn_hist_lines || ' lignes insÃ?Â©rÃ?Â©es.');
    dka_Tools_Pkg.put_log_message('DKA_IAPFACDSP_TMP vers DKA_IAPFACXGS_HIST_HEADS, ' ||
                                  vn_hist_heads || ' lignes insÃ?Â©rÃ?Â©es.');

    dka_Tools_Pkg.put_log_message('temps Ã?Â©coulÃ?Â© [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_func_starttime,
                                          'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') || ']');

    dka_Tools_Pkg.put_log_message('Fin du traitement, ' || SQL%ROWCOUNT ||
                                  ' lignes insÃ?Â©rÃ?Â©es.');

    dka_Tools_Pkg.put_log_message('temps total Ã?Â©coulÃ?Â© : [' ||
                                  TO_CHAR(LOCALTIMESTAMP -
                                          vd_total_starttime,
                                          'DD-MON-YYYY HH24:MI:SSxFF TZH:TZM') || ']');

    pn_retcode := 0;
    pv_errbuf  := NULL;

  EXCEPTION
    WHEN OTHERS THEN
      dka_Tools_Pkg.put_log_message('erreur : ' || SQLCODE || ' - ' ||
                                    SQLERRM);
      pn_retcode := 2;
      pv_errbuf  := 'Consultez le fichier de log';
      ROLLBACK;

  END populate_dsp_tables;
END dka_iapfacxgs_pkg;
