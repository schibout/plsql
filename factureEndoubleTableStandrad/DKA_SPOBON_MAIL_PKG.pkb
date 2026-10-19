create or replace PACKAGE BODY DKA_SAPDUPLICATIONFRS_PKG AS
------------------------------------------------------------------------
-- $Id: DKA_SAPDUPLICATIONFRS_PKG.pkb
-- Capgemini
-- Nom              : DKA_SAPDUPLICATIONFRS_PKG.pkb
-- Description      : Spécification du package DKA_SAPDUPLICATIONFRS_PKG
-- Auteur           : SELO
-- Date de création : 07/07/2020
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

    vg_phase1                   CONSTANT VARCHAR2(20) := 'VALIDATION_DONNEES';
    vg_phase2                   CONSTANT VARCHAR2(20) := 'INIT';
    vg_user_id                  CONSTANT NUMBER := fnd_profile.value('USER_ID');
    vg_login_id                 CONSTANT NUMBER := fnd_profile.value('LOGIN_ID');
    vg_request_id               CONSTANT NUMBER := fnd_profile.value('CONC_REQUEST_ID');
    vg_org_id                   CONSTANT NUMBER := fnd_profile.value('ORG_ID');
    vg_org_id_principale        hr_all_organization_units.organization_id%TYPE;
    vg_nb_flexv_comp_tech_aj    NUMBER :=0;
    vg_nb_flexv_class_tech_mod  NUMBER :=0;
    vg_nb_flexv_comp_tech_mod   NUMBER :=0;   
    vg_nb_art_renouv_charge     NUMBER :=0;
    vg_nb_art_recycle           NUMBER:=0;
    vg_nb_art_rej_valid         NUMBER:=0;
    vg_nb_art_val_valid         NUMBER:=0;
    vg_nb_art_err_int           NUMBER:=0;
    vg_nb_art_err_aff_cat       NUMBER:=0;
    vg_nb_art_tot_traite        NUMBER:=0;
    vg_tempo                    NUMBER:=20;
    vg_val1                     VARCHAR2(150);
    vg_val_erreur               VARCHAR2(1000):='';
    vg_erreur                   VARCHAR2(1000);    
    vg_nblignes_lot             NUMBER;
    vg_calc_stats               NUMBER;

    TYPE  IdTabTyp      IS TABLE OF NUMBER(15)
    INDEX BY BINARY_INTEGER;

 

 --+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++


 	------------------------------------------------------------------------------------
	--  Nom           : CHARGER_AP_DUPLICA
	--	Description		:	fonction pour alimenation de la table temporaire DKA_IEOMTL_SYSTEM_ITEMS_TMP

	--
	--  PARAMETRES    :
	--      access_id  : id du fichier
	--      pv_file_id : nom du fichier
	--  VALEUR RETOURNEE :
	------------------------------------------------------------------------------------

    FUNCTION CHARGER_AP_DUPLICA (
        access_id          IN NUMBER,
        pv_file_id         OUT VARCHAR2,
        pv_message_erreur  OUT VARCHAR2
    ) RETURN VARCHAR2 IS

	  --DEBUT----------------------------------------------------------------------------------
	  -- définition des variables pour l'insertion dans la table DKA_SAPFRSDUPLI_MASSE_TMP --
	  -----------------------------------------------------------------------------------------

        v_result                         VARCHAR2(200);
        v_file_name                      VARCHAR2(100);
        v_file_id                        VARCHAR2(256);
        v_gfm_id                         NUMBER := NULL;
        src_lob                          BLOB;
        buffer_var1                      CLOB;
        v_separator                      VARCHAR2(1) := ';';
        v_dest_offset                    INTEGER := 1;
        v_src_offset                     INTEGER := 1;
        v_warning                        INTEGER;
        v_lang_context                   NUMBER := dbms_lob.default_lang_ctx;
        v_error                          NUMBER;
        v_existing_records               NUMBER;
       
        v_status                         VARCHAR2(25);
        v_line_num                       NUMBER;
        v_offset                         INTEGER := 1;
        v_line_length                    PLS_INTEGER;
        v_line                           VARCHAR2(32767);
        v_total_length                   BINARY_INTEGER;
        v_cmpt_commit                    NUMBER;
        v_oracle_charset                 fnd_lobs.oracle_charset%TYPE;
        v_line_num                       NUMBER;
        v_i                              NUMBER;
        v_nb_article_unique              NUMBER;
        v_nb_err                         NUMBER :=0;
        v_nb_ligne_err                   NUMBER :=0;
	    v_ch_pb                          VARCHAR2(10000);
        v_message_erreur                 VARCHAR2(10000);
		
		v_record_id                      NUMBER;
		V_LENGTH_FILE                    NUMBER;
		V_VENDOR_NUM                     DKA_SAPFRSDUPLI_MASSE_TMP.VENDOR_NUM%TYPE;
        V_VENDOR_SITE_CODE_REF           DKA_SAPFRSDUPLI_MASSE_TMP.VENDOR_SITE_CODE_REF%TYPE;
        V_ID_IVALUA                      DKA_SAPFRSDUPLI_MASSE_TMP.ID_IVALUA%TYPE;
        V_PERIMETRE_DUPLI                DKA_SAPFRSDUPLI_MASSE_TMP.PERIMETRE_DUPLI%TYPE;
		g_login_id                       fnd_logins.login_id%TYPE     := fnd_global.login_id;

 ------------------------------------------------------------------------------------   
    BEGIN
       -- V_RESULT := 'OK';
        V_ERROR := 0;
        v_cmpt_commit := 0;
        v_message_erreur := NULL;

       -- Purge de la table temporaire DKA_IEOMTL_ERROR --
        EXECUTE IMMEDIATE 'truncate table DKA.DKA_IEOMTL_ERROR';

         
        /*/--alimentation de la table DKA_IEOMTL_SYSTEM_ITEMS_TMP--//*/

        V_GFM_ID := fnd_gfm.get_file_id(access_id);
        IF V_GFM_ID IS NOT NULL THEN
		    begin
                SELECT
                    file_name,
                    DECODE(instr(file_name,'/'),0,file_name,substr(file_name,instr(file_name,'/') + 1) ),
                    file_data,
                    oracle_charset
                INTO
                    V_FILE_NAME,
                    V_FILE_ID,
                    src_lob,
                    V_ORACLE_CHARSEt
                FROM
                    fnd_lobs
                WHERE
                    file_id = V_GFM_ID;
				V_RESULT:='A';
             EXCEPTION
            WHEN OTHERS THEN
		        V_RESULT := 'PB_SIZE';
		    	pv_message_erreur := 'Impossible de traiter le fichier => Erreur : Le nom du fichier dépasse 100 caractères.';
				return(V_RESULT);
	        END;
				    -- convertit le blob en clob
            IF  V_RESULT <> 'PB_FILE' then   
                dbms_lob.createtemporary(buffer_var1,true);
                dbms_lob.converttoclob(dest_lob => buffer_var1,
                                       src_blob => src_lob,
                                       amount => dbms_lob.lobmaxsize,
                                       dest_offset => V_DEST_OFFSET,
                                       src_offset => V_SRC_OFFSET,
                                       blob_csid => nls_charset_id(V_ORACLE_CHARSEt),
                                       lang_context => V_LANG_CONTEXT,warning => v_warning);
            
				    -- get file size				

                V_TOTAL_LENGTH := dbms_lob.getlength(buffer_var1); 
				    --récuperer numéro de ligne

           
                V_I := 0;
                
                WHILE V_OFFSET < V_TOTAL_LENGTH LOOP
                    V_I := V_I + 1;
                    v_ch_pb := '';
                    V_NB_ERR := 0;
                
			    	        --get line size 				
                    V_LINE_LENGTH := instr(buffer_var1,chr(10),V_OFFSET) - V_OFFSET;
                    IF V_LINE_LENGTH < 0 THEN
                        V_LINE_LENGTH := V_TOTAL_LENGTH + 1 - V_OFFSET;
                    END IF;
                    V_LINE := substr(buffer_var1,V_OFFSET,V_LINE_LENGTH);
                
                
                    IF V_I > 1                    -- On ne traite pas la ligne de titre
                    THEN   
			     	           --vv_cmpt_commit:=vv_cmpt_commit+1;
                       BEGIN
                           V_VENDOR_NUM := substr(V_LINE,'1',instr(V_LINE,V_SEPARATOR,1,1) - 1);
                       EXCEPTION
                        WHEN OTHERS THEN
                            V_VENDOR_NUM := NULL;
                            V_NB_ERR := V_NB_ERR +1;
                            v_ch_pb  := v_ch_pb || 'Le numéro du fournisseur dépasse 30 caractères, ';
                       END;
                
                       BEGIN
                           V_VENDOR_SITE_CODE_REF := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,1) + 1, ( (instr(V_LINE,V_SEPARATOR,1,2) ) - (instr(V_LINE,V_SEPARATOR,1,1) + 1) ) );
                       EXCEPTION
                        WHEN OTHERS THEN
                            V_VENDOR_SITE_CODE_REF := NULL;
                            V_NB_ERR := V_NB_ERR +1;
                            v_ch_pb  := v_ch_pb || 'Le code site référence dépasse 15 caractères, ';
                       END;
                
                       BEGIN
                           V_ID_IVALUA := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,2) + 1, ( (instr(V_LINE,V_SEPARATOR,1,3) ) - (instr(V_LINE,V_SEPARATOR,1,2) + 1) ) );
                       EXCEPTION
                        WHEN OTHERS THEN
                            V_ID_IVALUA := NULL;
                            V_NB_ERR := V_NB_ERR +1;
                            v_ch_pb  := v_ch_pb || 'L''ID Ivalua dépasse 9 caractères, ';
                       END;
                
                       BEGIN
                           V_PERIMETRE_DUPLI := substr(V_LINE,instr(V_LINE,V_SEPARATOR,1,3) + 1, ( (length(V_LINE) ) - (instr(V_LINE,V_SEPARATOR,1,3) + 1) ) );             
						 EXCEPTION
                        WHEN OTHERS THEN
                            V_PERIMETRE_DUPLI := NULL;
                            V_NB_ERR := V_NB_ERR +1;
                            v_ch_pb  := v_ch_pb || 'Le périmètre de duplication dépasse 7 caractères. ';                        
                       END;
                
                       IF V_NB_ERR>0 
                       THEN
                           v_nb_ligne_err := v_nb_ligne_err + 1;
                           v_message_erreur := substr(v_message_erreur ||CHR(10)||'Ligne N°'||V_I||' => Erreur : '||v_ch_pb, 1, 1000);
                       END IF;
                    --COMMIT;
                
                    /*// --------------------------------------------Insertion dans la table spécifique dka_ieomtl_system_items_tmp--------------------------------------//*/
                       select DKA_SAPFRSDUPLI_MASSE_TMP_S.nextval
                         into v_record_id
                         from dual;
                    
                       INSERT INTO DKA_SAPFRSDUPLI_MASSE_TMP (      RECORD_ID,
			    	                                                VENDOR_NUM,
                                                                    VENDOR_SITE_CODE_REF,
                                                                    ID_IVALUA,
                                                                    PERIMETRE_DUPLI,
			    													STATUT,
			    													creation_date,
			    													created_by,
			    													last_update_date,
			    													last_updated_by,
			    													LOGIN_ID,
			    													file_name,
			    													line_num,
			    													error_id,
			    													NBR_DUPLI_OK,
			    													NBR_DUPLI_KO,
			    													NBR_SITE_EXIST,
			    													NBR_SITE_IGNORED																
			    											    ) 
			    										 VALUES (
			    													v_record_id,
			    													TRIM(V_VENDOR_NUM),
			    													TRIM(V_VENDOR_SITE_CODE_REF),
                                                                    TRIM(V_ID_IVALUA),
                                                                    TRIM(V_PERIMETRE_DUPLI),
                                                                    'NEW',
			    													SYSDATE,
			    													VG_USER_ID,
			    													SYSDATE,
			    													VG_USER_ID,
			    													g_login_id,
			    													V_FILE_NAME,
			    													V_I,
			    													NULL,
			    													NULL,
			    													NULL,
			    													NULL,
			    													NULL
			    												);
                
                        --COMMIT;
                    END IF;
                
                    V_OFFSET := V_OFFSET + V_LINE_LENGTH + 1;
                
                
                END LOOP;
	

     

                /*/------------vérification de l'unicité du code article dans le fichier------------/*/
                
                --V_NB_ARTICLE_UNIQUE := DKA_SAPDUPLICATIONFRS_PKG.controle_unicite;
                
                IF v_nb_ligne_err >0  THEN 
                   V_RESULT := 'PB_LONGUEUR';
                   pv_message_erreur := 'Impossible de traiter le fichier =>'||v_nb_ligne_err ||' ligne(s) en erreur : '||CHR(10)|| v_message_erreur;
                 
                      DELETE FROM DKA_SAPFRSDUPLI_MASSE_TMP
                         WHERE
                            STATUT = 'NEW'
                            AND CREATED_BY = VG_USER_ID
                            AND TO_CHAR(CREATION_DATE,'DD/MM/RRRR') = TO_CHAR(SYSDATE,'DD/MM/RRRR');
                
                        COMMIT;  
                               
                ELSE  --IF V_NB_ERR =0 AND  V_NB_ARTICLE_UNIQUE =0 THEN 
                
                
                    V_RESULT := 'OK';
                    
                    COMMIT;  
                    
                END IF;

            END IF;		

        ELSE
            V_RESULT := 'PB_FILE';
            pv_message_erreur := 'Impossible de traiter le fichier => Problème lors de la lecture du fichier';
        END IF;

        pv_file_id := V_FILE_ID;


        return(V_RESULT);
    EXCEPTION
        WHEN OTHERS THEN
/*		    V_RESULT := 'PB_FILE';
			return(V_RESULT);
			pv_message_erreur := 'Nom du fichier dépasse 100 caractères.';
*/          
		  return(sqlerrm || 'Impossible d''inserer des enregistrements dans la table temporaire');
    END CHARGER_AP_DUPLICA;


END DKA_SAPDUPLICATIONFRS_PKG;


/
SHOW ERRORS

EXIT