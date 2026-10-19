CREATE OR REPLACE TRIGGER DKA_PO_HEADERS_AIU
  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAP GEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_PO_HEADERS_AIU.trg
  -- DESCRIPTION       : Trigger sur la table PO_HEADERS_ALL
  ---
  --- AUTEUR           : Maxime EGOT (Capgemini)
  --- DATE DE CREATION : 04/04/2017
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- ---------------------------------------------------------------------------
  --- 04/04/2017 MEG artf2131632 : Dysfonctionnement de la gestion des frais de port
  ----------------------------------------------------------------------------------------------

   AFTER
   INSERT
   OR
   UPDATE 
   ON po.po_headers_all

DECLARE
  vv_errbuf  VARCHAR2(500);
  vn_retcode NUMBER;

BEGIN

  FOR i IN 1 .. DKA_SPOFRAIS_PORT_PKG.g_index_tab LOOP

    DKA_SPOFRAIS_PORT_PKG.Inserer_ligne(DKA_SPOFRAIS_PORT_PKG.g_header_id_tab(i),
                                        DKA_SPOFRAIS_PORT_PKG.g_vendor_id_tab(i),
                                        vv_errbuf,
                                        vn_retcode);

  END LOOP;

  DKA_SPOFRAIS_PORT_PKG.g_index_tab := 0;

EXCEPTION
  WHEN OTHERS THEN
    app_exception.raise_exception(NULL, NULL, SQLCODE || '=' || substr(SQLERRM, 1, 80) || ' // ' || vv_errbuf);
END;
/
SHOW ERRORS;
EXIT
