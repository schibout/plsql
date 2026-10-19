DROP TRIGGER DKA_AP_INVOICES_DIST_ALL_ARI;

CREATE OR REPLACE TRIGGER DKA_AP_INVOICES_DIST_ALL_ARI

--------------------------------------------------------------------------------
-- CAP GEMINI
-- Projet       : DALKIA Oracle Applications
-- Auteur       : Quentin VANHOUTE
-- DATE Création    : 16/03/2010
--------------------------------------------------------------------------------
-- NOM                : DKA_AP_INVOICES_DIST_ALL_ARI.trg
-- DESCRIPTION        : Script de création du trigger DKA_AP_INVOICES_DIST_ALL_ARI
--
--------------------------------------------------------------------------------
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             :
-- DATE                :
-- Auteur              :
-- Probleme            :
-- Solution            :
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------
--- 2016/09/02 JJA Portage Helios R12
--------------------------------------------------------------------------------
    AFTER INSERT
    ON "AP"."AP_INVOICE_DISTRIBUTIONS_ALL"
    FOR EACH ROW

DECLARE
    vv_errbuf             VARCHAR2 (255);
    vn_retcode            NUMBER;
    vv_paiement_direct    po_headers_all.attribute13%TYPE;
    
BEGIN
  --------------------------------------------------------
  -- Ajout de la gestion des paiements directs :        --
  -- Mise a jour du champ Pay_Group_Lookup_Code dans le --
  -- cas d'un rapprochement avec une commande en        --
  -- paiement direct                                    --
  --------------------------------------------------------
  IF :NEW.Po_Distribution_Id IS NOT NULL THEN
      -----------------------------------------------
      -- Recherche de l'indicateur paiement direct --
      -----------------------------------------------
      BEGIN
          SELECT NVL(Pha.Attribute13, 'NON')
          INTO   Vv_Paiement_Direct
          FROM   Po_Distributions_All Pda,
                 Po_Headers_All       Pha
          WHERE  Pda.Po_Distribution_Id = :NEW.Po_Distribution_Id
          AND    Pda.Po_Header_Id       = Pha.Po_Header_Id;

      EXCEPTION
          WHEN OTHERS THEN
              Vv_Paiement_Direct := 'NON';
      END;

      -------------------------------------------------------------------
      -- Si la commande est en paiement direct, on met a jour le champ --
      -- Pay_Group_Lookup_Code dans la table Ap_Invoices_All           --
      -------------------------------------------------------------------
      IF Vv_Paiement_Direct = 'OUI' THEN
          -------------------------------------------------------------------------
          -- La classe de reglements est remplacée par 'PMTDIR' --
          -------------------------------------------------------------------------
          UPDATE AP_INVOICES_ALL aia
          SET    Pay_Group_Lookup_Code = 'PMTDIR'
          WHERE  Invoice_Id            = :NEW.Invoice_Id
             AND Pay_Group_Lookup_Code != 'PMTDIR' ;
      END IF;



  END IF;

END;
/
SHOW ERRORS TRIGGER DKA_AP_INVOICES_DIST_ALL_ARI
EXIT

