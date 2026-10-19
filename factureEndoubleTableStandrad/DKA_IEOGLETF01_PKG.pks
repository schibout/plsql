CREATE OR REPLACE PACKAGE DKA_EXTR_DA_PKG
IS
----------------------------------------------------------------------
-- PROGRAM : DKA_EXTR_DA_PKG.sql                                     -
-- AUTEUR  : S. NIKMAOUI / SOCIETE : CAP GEMINI                      -
-- DATE    : 03/12/2018                                              -
----------------------------------------------------------------------
-- VERSION INITIALE : 1.0                                            -
-- PAR        :                                                      -
-- EVENEMENT  :                                                      -
-- OBJET      :                                                      -
--                                                                   -
----------------------------------------------------------------------
--   Version   Date         Author          Remarks
--   -------   -----------  -----------     --------------------------
--   1.0       03-12-2018   S. NIKMAOUI     Base Version              
----------------------------------------------------------------------

PROCEDURE dka_inserer_element(Doc dbms_xmldom.domdocument,Col VARCHAR2, Col_val VARCHAR2, Target_node dbms_xmldom.domnode);

PROCEDURE MAIN ( P_errbuf                OUT VARCHAR2
               , P_retcode               OUT NUMBER
               , p_region                IN  VARCHAR2
               , p_uo                    IN  VARCHAR2
               , p_type_DA               IN  VARCHAR2
               , p_redacteur             IN  NUMBER 
               , p_demandeur             IN  NUMBER
               , p_tache_fin             IN  VARCHAR2
               , p_statu_DA              IN  VARCHAR2
               , p_tr_cmd                IN  VARCHAR2
               , p_creation_dt_du        IN  VARCHAR2
               , p_creation_dt_au        IN  VARCHAR2
               , p_num_da_du             IN  NUMBER
               , p_num_da_au             IN  NUMBER
               , p_nom_fourn             IN  VARCHAR2
               , p_site_frn              IN  VARCHAR2
               );
END;
/
SHOW ERRORS PACKAGE DKA_EXTR_DA_PKG;
EXIT