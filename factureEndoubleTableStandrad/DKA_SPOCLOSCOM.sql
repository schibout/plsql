    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : UPDATE_ATTRIBUTE10.sql
    -- DESCRIPTION      : Ce script permet de mettre à jour l'ATTRIBUTE10 de la 
	--					  table Per_All_People_F lors de l'installation pour ne 
	--					  pas extraire vers Notilus les employés désactivés.
	--					  L'ATTRIBUTE10 des lignes est d'abord initialisé à NULL
	--					  puis l'ATTRIBUTE10 des employés désactivés est mis à
	--					  jour à la date du jour.
    --
    -- AUTEUR           : F.DOUTRIAUX (Capgemini)
    -- DATE DE CREATION : 12/12/2011
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 
    -- -----------------------------------------------------------------------------

SET SERVEROUTPUT ON    
    
DECLARE
    CURSOR Cur_Emp IS
        SELECT *
        FROM   Per_All_People_f Papf
        WHERE  Papf.Person_Type_Id = 6
        AND    Papf.Attribute10 IS NULL
        AND    (EXISTS (SELECT 'x'
                        FROM   Per_All_People_f Papf1
                        WHERE  Papf1.Person_Id = Papf.Person_Id
                        AND    Papf1.Person_Type_Id = 9) 
                --OR Papf.Person_Id IN (2630, 5248, 13997, 1123, 1276, 5377, 2821, 506, 13985, 14002, 5082) --RGH : 19/07/2016 - Migration R12 
				);

    Rec_Emp Cur_Emp%ROWTYPE;
    
    Vn_nbre_maj   NUMBER := 0;

BEGIN
	
	DBMS_OUTPUT.PUT_LINE ('------------------------------------');
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE ('Mise à jour de l''ATTRIBUTE10 à NULL');
	DBMS_OUTPUT.PUT_LINE (' ');
	UPDATE Per_all_people_f SET attribute10 = NULL;
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE ('Mise à jour éffectuée...');
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE ('------------------------------------');
	
	DBMS_OUTPUT.PUT_LINE ('------------------------------------');
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE (' Début du traitement...');
	DBMS_OUTPUT.PUT_LINE (' ');
    OPEN Cur_Emp;
    LOOP
        FETCH Cur_Emp
            INTO Rec_Emp;
        EXIT WHEN Cur_Emp%NOTFOUND;
    
        UPDATE Per_People_f
		-- On ajoute 1 seconde à la date SYSDATE pour ne pas que 
		-- la date LAST_UPDATE_DATE (mise à jour via un trigger)
		-- soit strictement supérieure à la date de l'ATTRIBUTE10
        SET    Attribute10 = To_Char(SYSDATE + 1 / (86400),
                                     'YYYY/MM/DD HH24:MI:SS')
        WHERE  Person_Id = Rec_Emp.Person_Id;
        Vn_nbre_maj := Vn_nbre_maj + 1;
    END LOOP;
    CLOSE Cur_Emp;
    
    COMMIT;

    DBMS_OUTPUT.PUT_LINE ('Fin du traitement :');
    DBMS_OUTPUT.PUT_LINE ( Vn_nbre_maj || ' lignes traitées.');
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE ('------------------------------------');

END;
/
EXIT
