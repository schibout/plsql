CREATE OR REPLACE PACKAGE BODY DKA_IEOMTL_PURGRECH_PKG AS
------------------------------------------------------------------------
-- $Id: dka_ieomtl_purgrech_pkg.pkb
-- Capgemini
-- Nom              : dka_ieomtl_purgrech_pkg.pkb
-- Description      : Spécification du package dka_ieomtl_purgrech_pkg
-- Auteur           : F.Siham
-- Date de création : 26/04/2019
-- Doc. associée    :
-- Commentaires     : A exécuter sous SQLPLUS avec l'utilisateur APPS
------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------

-- ---------- --- ------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


 	------------------------------------------------------------------------------------
	--  Nom           : purge_rech_catalog
	--	Description		:	procedure pour purge de la table temporaire DKA_SICXRECHCAT_HIST

	--
	--  PARAMETRES    :
    --  P_NB_MOIS_SAUV  : le nombre de lignes à 

	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    PROCEDURE PURGE_RECH_CATALOG (
        P_NB_MOIS_SAUV IN NUMBER
    ) AS
        V_NB_TOTAL_LIGNES   NUMBER;
        v_nb_lignes_rest    NUMBER;
		v_nb_lignes_suppr   NUMBER:=0;
 ------------------------------------------------------------------------------------   
    BEGIN
      /*//-------------Calcul du nombre total des lignes dans la table spécifique DKA_SICXRECHCAT_HIST avant purge-----//*/
        BEGIN
            SELECT
                COUNT(*)
            INTO V_NB_TOTAL_LIGNES
            FROM
                DKA.DKA_SICXRECHCAT_HIST;
           
        EXCEPTION
            WHEN NO_DATA_FOUND THEN
                V_NB_TOTAL_LIGNES   := 0;
        END;
        
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Purge de la table spécifique DKA_SICXRECHCAT_HIST                            '||chr(10));
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------'||chr(10));
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre de lignes existantes dans la table DKA_SICXRECHCAT_HIST avant purge est : ' || V_NB_TOTAL_LIGNES ||chr(10));
         /*//-------------purge de la table spécifique DKA_SICXRECHCAT_HIST -----//*/
        
       
			FOR I IN (
				SELECT
					*
				FROM
					 DKA.DKA_SICXRECHCAT_HIST
				WHERE
					TRUNC(CREATION_DATE) <= TRUNC(ADD_MONTHS(SYSDATE,-P_NB_MOIS_SAUV))
			) LOOP
				DELETE FROM  DKA.DKA_SICXRECHCAT_HIST
				WHERE
					ID_RECHERCHE = I.ID_RECHERCHE;

				v_nb_lignes_suppr   := v_nb_lignes_suppr + 1;
			END LOOP;
            COMMIT;
        
          /*//-------------Calcul du nombre total des lignes dans la table spécifique DKA_SICXRECHCAT_HIST aprés purge-----//*/
            
			 V_NB_LIGNES_rest:=nvl(V_NB_TOTAL_LIGNES,0) - nvl(V_NB_LIGNES_SUPPR,0);
        
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Purge de la table spécifique DKA_SICXRECHCAT_HIST                            '||chr(10));
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'------------------------------------------------------------------------------'||chr(10));
			FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre de lignes supprimées de la la table DKA_SICXRECHCAT_HIST est : ' || v_nb_lignes_suppr);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre de lignes restantes  dans la  table DKA_SICXRECHCAT_HIST est : ' || v_nb_lignes_rest); 
    END PURGE_RECH_CATALOG;
	
	PROCEDURE MAIN (
        p_errbuf    OUT NOCOPY VARCHAR2,
        p_retcode   OUT NOCOPY NUMBER,
        P_NB_MOIS_SAUV IN NUMBER
    )
	AS
	
	BEGIN
    /*//--------------appel de la procédure  PURGE_RECH_CATALOG ---/*/
    
	 DKA_IEOMTL_PURGRECH_PKG.PURGE_RECH_CATALOG(P_NB_MOIS_SAUV);
     
	END MAIN;

END DKA_IEOMTL_PURGRECH_PKG;
/

SHOW ERRORS

EXIT;