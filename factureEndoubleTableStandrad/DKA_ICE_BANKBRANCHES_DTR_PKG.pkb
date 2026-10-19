CREATE OR REPLACE PACKAGE dka_iapfacxgs_pkg
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
/

SHOW ERRORS PACKAGE dka_iapfacxgs_pkg;
EXIT
