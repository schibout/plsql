    -- -----------------------------------------------------------------------------
    -- $$
    -- Capgemini
    -- PROJET           : DALKIA Oracle Applications
    -- NOM              : UPDATE_SUPPLIERS_EMP.sql
    -- DESCRIPTION      : Ce script permet de désactiver les fournisseurs
	--                    employés qui ont la matricule GXP à NULL
    --
    -- AUTEUR           : O.BENHAYOUN (Capgemini)
    -- DATE DE CREATION : 29/03/2018
    -- COMMENTAIRES     : A exécuter sous SQLPLUS avec le user apps
    -- -----------------------------------------------------------------------------
    --
    -- -----------------------------------------------------------------------------
    -- HISTORIQUE DES MODIFICATIONS
    -- Date       Qui Description
    -- ---------- --- --------------------------------------------------------------
    -- 
    -- -----------------------------------------------------------------------------

SET SERVEROUTPUT ON SIZE 1000000   
    
DECLARE	
	
    CURSOR Cur_Emp IS
          SELECT a.vendor_id, a.vendor_name 
		  FROM ap_suppliers a, per_all_people_f b WHERE 1=1
          AND a.vendor_type_lookup_code = 'EMPLOYEE'
          AND a.employee_id = b.person_id
          AND b.attribute11 IS NULL
          AND SYSDATE BETWEEN b.effective_start_date AND b.effective_end_date
          ;
    Rec_Emp Cur_Emp%ROWTYPE;
		  
    vn_api_version        NUMBER;
    vv_init_msg_list      VARCHAR2 (200);
    vv_commit             VARCHAR2 (200);
    vn_validation_level   NUMBER;
    vv_return_status      VARCHAR2 (200);
    vn_msg_count          NUMBER;
    vv_msg_data           VARCHAR2 (200);		 
	VN_MSG_INDEX_OUT      NUMBER;
    vn_vendor_id          NUMBER;	
    vr_vendor_rec ap_vendor_pub_pkg.r_vendor_rec_type;
	vv_message  VARCHAR2(500);
    Vn_nbre_maj   NUMBER := 0;

BEGIN
	
	
	DBMS_OUTPUT.PUT_LINE ('------------------------------------');
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE (' Début du traitement...');
	DBMS_OUTPUT.PUT_LINE (' ');
	

	
    OPEN Cur_Emp;
    LOOP
        FETCH Cur_Emp
            INTO Rec_Emp;
        EXIT WHEN Cur_Emp%NOTFOUND;
    
            --Init valeur fournisseur     
            vn_api_version      := 1.0;
            vv_init_msg_list    := FND_API.G_TRUE;
            vv_commit           := FND_API.G_TRUE;
            vn_validation_level := FND_API.G_VALID_LEVEL_FULL;
            vv_return_status    := NULL;
            vn_msg_count        := NULL;
            vv_msg_data         := NULL;
            
            vn_vendor_id := Rec_Emp.vendor_id;		
            vr_vendor_rec.END_DATE_ACTIVE := SYSDATE;
			
			
            --///Update du fournisseur - API
            --DBMS_OUTPUT.PUT_LINE ('Update du fournisseur - API');    
            ap_vendor_pub_pkg.update_vendor(vn_api_version,
                                            vv_init_msg_list,
                                            vv_commit,
                                            vn_validation_level,
                                            vv_return_status,
                                            vn_msg_count,
                                            vv_msg_data,
                                            vr_vendor_rec,
                                            vn_vendor_id
                                            );     
          
             
            IF vv_return_status = FND_API.G_RET_STS_SUCCESS THEN
              --On continue
              DBMS_OUTPUT.PUT_LINE (Rec_Emp.vendor_name||' désactivé.');
              Vn_nbre_maj := Vn_nbre_maj + 1;
            ELSE
              vv_message := '';
              IF vn_msg_count > 0 THEN
                
                FOR v_index IN 1 .. vn_msg_count LOOP
                  fnd_msg_pub.get (p_msg_index => v_index, p_encoded => 'F', p_data => vv_msg_data, p_msg_index_out => vn_msg_index_out);
                  vv_message := substr(vv_message || chr(10) || vv_msg_data,1,500);
                  
                END LOOP;
              
              END IF;
              
              DBMS_OUTPUT.PUT_LINE ('Désactivation du fournisseur impossible : '||vv_message);
            
            END IF; 
		
    END LOOP;
    CLOSE Cur_Emp;
    

    DBMS_OUTPUT.PUT_LINE ('Fin du traitement :');
    DBMS_OUTPUT.PUT_LINE ( Vn_nbre_maj || ' lignes traitées.');
	DBMS_OUTPUT.PUT_LINE (' ');
    DBMS_OUTPUT.PUT_LINE ('------------------------------------');

END;
/
EXIT
