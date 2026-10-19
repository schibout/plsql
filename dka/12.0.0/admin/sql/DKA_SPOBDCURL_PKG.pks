create or replace package DKA_SPOBDCURL_PKG is

  ----------------------------------------------------------------------------------------------
  --
  -- $Id$
  --
  -- NOM               : DKA_SPOBDCURL_PKG
  -- DESCRIPTION       : Creation du package specifique pour le specifique 068
  --
  -- AUTEUR           : M. EGOT
  -- DATE DE CREATION : 27/09/2016
  -- DOC. ASSOCIEE    : SPECIFICATIONS FONCTIONNELLES :
  --                    SPECIFICATIONS TECHNIQUES     :
  ---
  ----------------------------------------------------------------------------------------------
  -- NOM DU PROGRAMME :
  --- PARAMETRES       :
  --
  -- HISTORIQUE DES MODIFICATIONS
  -- DATE       VERSION QUI           DESCRIPTION
  --
  ----------------------------------------------------------------------------------------------

   FUNCTION url_bdc(p_segment1 IN VARCHAR2) return varchar2;

end DKA_SPOBDCURL_PKG;
/
show error;
exit;
