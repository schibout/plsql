CREATE OR REPLACE PACKAGE DKA_REPAPIMGIMP_PKG AS
    ----------------------------------------------------------------------
    -- PROGRAM : DKA_REPAPIMGIMP_PKG.sql                                 -
    -- Version : 1.0                                                     -
    -- AUTEUR  : H. Descroizette - Capgemini                             -
    -- DATE    : 09/05/16                                                -
    ----------------------------------------------------------------------
    -- APPELE PAR :                                                      -
    -- FONCTION   : Reprise des images de factures fournisseurs via      -
    --              le database link entre la 11i et la R12              -
    --              Alimentation de FND_DOCUMENTS et tables associées    -
    -- SFD :  HLS-ORA-CONC-LIV-004-Reprise-données-Encours-Fournisseurs.V1.2 --
    --                                                                   -
    ----------------------------------------------------------------------
    -- VERSION              :        1.0                                 -
    -- PROGRAMME MODIFIE LE :                                            -
    -- PAR                  :                                            -
    -- NUM_ANOMALIE         :                                            -
    -- OBJET                :                                            -
    --                                                                   -
    ----------------------------------------------------------------------
    
  PROCEDURE MAIN(p_errbuf                 IN OUT VARCHAR2,
                 p_retcode                IN OUT NUMBER,
                 p_org_id                 IN NUMBER DEFAULT NULL,
                 p_simulation             IN VARCHAR2 DEFAULT 'N'
                );


END DKA_REPAPIMGIMP_PKG;
/
SHOW ERRORS ;
EXIT;
