CREATE OR REPLACE PACKAGE BODY DKA_SSATIPOIDS_PKG
AS   
--------------------------------------------------------------------------------------------------------------- 
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM		     : DKA_SATI_WEIGHT_PKG.pkb
-- DESCRIPTION	     : CALCUL DU POIDS SATI
--
--- AUTEUR	     : Guilhem LE NEZET (CGEY)
--- DATE DE CREATION : 23/07/2002
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
---------------------------------------------------------------------------------------------------------------
--- 22/04/2003 AD  Modification de la procédure du calcul du poids d'un caractère. 
--- 28/09/2009 EMA La table Dka_ieoapsat01_arch n'est plus utilisée et remplacée par Dka_ieoapsat01_int
--- 10/10/2016 RBE Migration R12
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++               
---------------------------------------------------------------------------------------------------------------
--  Nom           : CHARACTER_WEIGHT 
--  Description   : Fonction qui retourne le poids d'un caractère
--                
--  PARAMETRES :
--     		pv_character               Entrée/Sortie   message d'erreur
--  VALEUR RETOURNEE :
--     Description       : 
--     Valeurs possibles : 
--------------------------------------------------------------------------------------------------------------- 
  FUNCTION character_weight  ( pv_character_name    IN        VARCHAR2,
                               pv_errbuf            IN OUT    VARCHAR2 )
  RETURN NUMBER
  IS
        vn_weight   NUMBER(15);
  BEGIN
        SELECT ds.number_value
        INTO   vn_weight
        FROM   dka_ssatipoids ds
        --WHERE  ds.character_name = UPPER(pv_character_name); 
        WHERE  ds.character_name = (pv_character_name);

        RETURN vn_weight;
    EXCEPTION
        WHEN NO_DATA_FOUND 
        THEN
            vn_weight := 21;
            RETURN vn_weight;    -- le caractère recherché n'est pas présent dans la table
        WHEN OTHERS
        THEN
            pv_errbuf := 'ERREUR FONCTION  CHARACTER_WEIGHT pour retrouver le poids du caractère ' ||pv_character_name;
            RETURN NULL;
  END character_weight;



---------------------------------------------------------------------------------------------------------------
--  Nom           : AMOUNT_WEIGHT 
--  Description   : Procédure qui calcule le poids cumulé pour le montant d'un paiement
--                
--  PARAMETRES :
--     		pv_character               Entrée/Sortie   message d'erreur
--
--
--  VALEUR RETOURNEE :
--     Description       : 
--     Valeurs possibles : 
--------------------------------------------------------------------------------------------------------------- 
FUNCTION amount_weight   ( pv_string    IN        VARCHAR2,
			   pv_errbuf    IN OUT    VARCHAR2
                           )
RETURN NUMBER
IS
        vn_count_weight   	NUMBER (15);
        vn_weight_caracter	NUMBER (15);
        vn_cpt		  	NUMBER(15);
  BEGIN
       -- Initialisation des variables --
       vn_count_weight := 0;
       vn_cpt := 1;
       
       -- Boucle sur le montant --
       WHILE vn_cpt <= 14   LOOP
         -- Calcul du poids d'un caractère --
         vn_weight_caracter := DKA_SSATIPOIDS_PKG.character_weight(SUBSTR(pv_string,vn_cpt,1),pv_errbuf);
         IF vn_weight_caracter IS NULL
         THEN
           RETURN NULL;
         END IF;
         -- Cumul des poids --
         vn_count_weight := vn_count_weight + (vn_weight_caracter*vn_cpt);
         vn_cpt :=  vn_cpt +1  ;
       END LOOP;  
         
        RETURN vn_count_weight;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf := 'ERREUR FONCTION  AMOUNT_WEIGHT pour retrouver le poids cumulé du montant ' ||pv_string;
            RETURN NULL;
END amount_weight;
 			  


---------------------------------------------------------------------------------------------------------------
--  Nom           : BENEFICIARY_WEIGHT 
--  Description   : Procédure qui calcule le poids cumulé pour le bénéficifaire d'un paiement
--                
--  PARAMETRES :
--     		pv_character               Entrée/Sortie   message d'erreur
--  VALEUR RETOURNEE :
--     Description       : 
--     Valeurs possibles : 
--------------------------------------------------------------------------------------------------------------- 
FUNCTION beneficiary_weight   ( pv_string    IN        VARCHAR2,
				pv_errbuf    IN OUT    VARCHAR2)
RETURN NUMBER
IS
        vn_count_weight   	NUMBER (15);
        vn_weight_caracter	NUMBER (15);
        vn_cpt		  	      NUMBER(15);
  BEGIN
       -- Initialisation des variables --
       vn_count_weight := 0;
       vn_cpt := 1;
       
       -- Boucle sur le montant --
       WHILE vn_cpt <= 30   LOOP
         -- Calcul du poids d'un caractère --
         vn_weight_caracter := DKA_SSATIPOIDS_PKG.character_weight(SUBSTR(pv_string,vn_cpt,1),pv_errbuf);
         IF vn_weight_caracter IS NULL
         THEN
           RETURN NULL;
         END IF;
        -- Cumul des poids --
        vn_count_weight := vn_count_weight + (vn_weight_caracter*vn_cpt);
        vn_cpt :=  vn_cpt +1  ;
        
       END LOOP;  
         
        RETURN vn_count_weight;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf := 'ERREUR FONCTION  BENEFICIARY_WEIGHT pour retrouver le poids cumulé du bénéficiaire ' ||pv_string;
            RETURN NULL;
  END beneficiary_weight;


    			  
--------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------  
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur   
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur' 
--		    pv_p_payment_patch	   Entrée
--		    pv_type_enregistrement Entrée 	type_enregistrement  'C= lettre chèque',
--							type_enregistrement  'B= LCR', 
--							type_enregistrement  'W =Virement',
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
--------------------------------------------------------------------------------------------------------------- 
PROCEDURE main(pv_errbuf        	IN OUT VARCHAR2,
               pn_retcode           	OUT NUMBER--,
               --pn_etl_id		IN NUMBER
               )
               
IS
  -- Sélection des lignes d'enregistrement total paiement "08" --
  -- Début modif EMA du 28/09/2009 : La table Dka_ieoapsat01_arch n'est plus utilisée et remplacée par Dka_ieoapsat01_int
  -- CURSOR cur_data_08 (vv_operation_code IN VARCHAR2) IS 
  --   SELECT  substr(text,36,14) amount,
  --           substr(text,50,30) beneficiary
  --     FROM dka_ieoapsat01_arch
  --    WHERE operation_code = vv_operation_code
  --      AND substr(text,1,2)='08'
  --      AND etl_id = pn_etl_id;
  --CURSOR cur_data_08 (vv_operation_code IN VARCHAR2) IS 
    --SELECT  substr(text, 28, 14) amount,
    --        substr(text, 42, 30) beneficiary
    --FROM    dka_ieoapsat01_int
    --WHERE   operation_code = vv_operation_code
    --AND     record_code    ='08';
    --RBE
    CURSOR cur_data_08 IS 
    SELECT    DETAILS.AMOUNT             MONTANT,
              DETAILS.COUNTERPARTYNAME   beneficiary
    FROM      DKA_IEOAPSAT01_APIMP_HDR   ENTETE,
              DKA_IEOAPSAT01_APIMP_LINE  details
    WHERE     1=1 
    AND       ENTETE.HEADER_ID          = DETAILS.HEADER_ID
    ;
    
    vv_amount      		VARCHAR2(14);
    vv_beneficiary      	VARCHAR2(30);
    vn_amount_weight		NUMBER(15);
    vn_beneficiary_weight     NUMBER(15);
    vn_count_payement_b   	NUMBER(10);     
    vn_read_amount_b		NUMBER(15);
    vn_cle_b    		      NUMBER(15);
    
    vn_count_payement_w   	NUMBER(10);     
    vn_read_amount_w		NUMBER(15);
    vn_cle_w    		      NUMBER(15);
    
    vn_count_payement_c   	NUMBER(10);     
    vn_read_amount_c		NUMBER(15);
    vn_cle_c    		      NUMBER(15);
BEGIN   --main                 
           
  --  Initialisations des variables    --	
  vn_amount_weight :=0;
  vn_beneficiary_weight :=0;
   
   vn_read_amount_b :=0;
   vn_count_payement_b := 0;
   vn_cle_b :=0;
   
   vn_read_amount_w :=0;
   vn_count_payement_w := 0;
   vn_cle_w :=0; 
   
   
   vn_read_amount_c :=0;
   vn_count_payement_c := 0;
   vn_cle_c :=0; 
   
     
  ----- Ecriture de l'entête du fichier de sortie -----
  dka_tools_pkg.put_out_header;
  
  
  /* RBE MigR12 pas de type cheque 
  -- *********************************************************************************************************--
  -- Ouverture du curseur pour le type de reglement chèque --
  OPEN cur_data_08 ('B');
  LOOP 
     FETCH cur_data_08 INTO vv_amount,
                            vv_beneficiary;
     EXIT WHEN cur_data_08%NOTFOUND; 
    
      vn_amount_weight :=0;
      vn_beneficiary_weight :=0;
     
     vn_read_amount_b 	:= vn_read_amount_b + to_number(vv_amount,'99999999999999');
     vn_count_payement_b  := vn_count_payement_b + 1;
     
     -- calcul du poids SATI sur le montant : amount_weight  --
     vn_amount_weight := dka_ssatipoids_pkg.amount_weight(vv_amount,pv_errbuf);
     IF vn_amount_weight IS NULL
     THEN 
      pn_retcode := 2;
      RETURN;
     END IF;
     
     -- calcul du poids SATI sur le bénéficiaire : beneficiary_weight  --
     vn_beneficiary_weight := dka_ssatipoids_pkg.beneficiary_weight(vv_beneficiary,pv_errbuf);
     IF vn_amount_weight IS NULL
     THEN 
      pn_retcode := 2;
      RETURN;
     END IF;
     
     -- Valeur de la clé contrôle --
     vn_cle_b := vn_cle_b + vn_beneficiary_weight + vn_amount_weight;
     
   
     
  END LOOP;
  CLOSE cur_data_08;
  
  
  dka_tools_pkg.put_debug_message (' vn_count_payement_b : '||vn_count_payement_b);
  dka_tools_pkg.put_debug_message (' vn_read_amount_b : '||vn_read_amount_b);
  dka_tools_pkg.put_debug_message (' vn_clé_b : '||vn_cle_b);
  */
  -- *********************************************************************************************************--
  -- réinitialisation --
  vn_amount_weight :=0;
  vn_beneficiary_weight :=0;
  
  --OPEN cur_data_08 ('W'); --RBE
  OPEN cur_data_08;
  LOOP 
     FETCH cur_data_08 INTO vv_amount,
                            vv_beneficiary;
     EXIT WHEN cur_data_08%NOTFOUND; 
    
     vn_amount_weight :=0;
     vn_beneficiary_weight :=0;
     
     vn_read_amount_w 	:= vn_read_amount_w + to_number(vv_amount,'99999999999999');
     vn_count_payement_w  := vn_count_payement_w + 1;
                
     -- calcul du poids SATI sur le montant : amount_weight  --
     vn_amount_weight := dka_ssatipoids_pkg.amount_weight(vv_amount,pv_errbuf);
     IF vn_amount_weight IS NULL
     THEN 
      pn_retcode := 2;
      RETURN;
     END IF;
     
     -- calcul du poids SATI sur le bénéficiaire : beneficiary_weight  --
     vn_beneficiary_weight := dka_ssatipoids_pkg.beneficiary_weight(vv_beneficiary,pv_errbuf);
     IF vn_amount_weight IS NULL
     THEN 
      pn_retcode := 2;
      RETURN;
     END IF;
     
     -- Valeur de la clé contrôle --
     vn_cle_w := vn_cle_w + vn_beneficiary_weight + vn_amount_weight;
   
  END LOOP;
  CLOSE cur_data_08;
  dka_tools_pkg.put_debug_message (' vn_count_payement_w : '||vn_count_payement_w);
  dka_tools_pkg.put_debug_message (' vn_read_amount_w : '||vn_read_amount_w);
  dka_tools_pkg.put_debug_message (' vn_clé_w : '||vn_cle_w);
  
  /*
  -- réinitialisation --
  vn_amount_weight :=0;
  vn_beneficiary_weight :=0;
  
  OPEN cur_data_08 ('C');
  LOOP 
     FETCH cur_data_08 INTO vv_amount,
                            vv_beneficiary;
     EXIT WHEN cur_data_08%NOTFOUND; 
     vn_amount_weight :=0;
     vn_beneficiary_weight :=0;
     vn_read_amount_c 	:= vn_read_amount_c + to_number(vv_amount,'99999999999999');
     vn_count_payement_c  := vn_count_payement_c + 1;
                
      -- calcul du poids SATI sur le montant : amount_weight  --
     vn_amount_weight := dka_ssatipoids_pkg.amount_weight(vv_amount,pv_errbuf);
     IF vn_amount_weight IS NULL
     THEN 
      pn_retcode := 2;
      RETURN;
     END IF;
     
     -- calcul du poids SATI sur le bénéficiaire : beneficiary_weight  --
     vn_beneficiary_weight := dka_ssatipoids_pkg.beneficiary_weight(vv_beneficiary,pv_errbuf);
     IF vn_amount_weight IS NULL
     THEN 
      pn_retcode := 2;
      RETURN;
     END IF;
     
     -- Valeur de la clé contrôle --
     vn_cle_c := vn_cle_c + vn_beneficiary_weight + vn_amount_weight;
   
  END LOOP;
  
  dka_tools_pkg.put_debug_message (' vn_count_payement_c : '||vn_count_payement_c);
  dka_tools_pkg.put_debug_message (' vn_read_amount_c : '||vn_read_amount_c);
  dka_tools_pkg.put_debug_message (' vn_clé_c : '||vn_cle_c);
  
    
  CLOSE cur_data_08;
  */
   -- Ecriture dans le fichier de sortie --
   dka_tools_pkg.put_outdebug_message ('******************  Les poids cumulés sont les suivants ******************' 
                    || CHR (10)
                    || CHR (10)
                    || CHR (10)
                    || '****   Pour les virements  *******           nombre :' ||vn_count_payement_w ||'  montant :'|| vn_read_amount_w || ' la clé de contrôle est : ' ||vn_cle_w
                    --RBE MigR12
                    /*|| CHR (10)
                    || CHR (10)
                    || '****   Pour les B.O.R      *******           nombre :' ||vn_count_payement_b ||'  montant :'|| vn_read_amount_b || ' la clé de contrôle est : '||vn_cle_b
                    || CHR (10)
                    || CHR (10)
                    || '****   Pour les chèques    *******           nombre :' ||vn_count_payement_c ||'  montant :'|| vn_read_amount_c || ' la clé de contrôle est : '||vn_cle_c*/
                );
  
  
  
 
  EXCEPTION
  WHEN OTHERS THEN                                                     
  pv_errbuf := SQLERRM(SQLCODE);         
  pn_retcode := 2; 	 

END MAIN;


END DKA_SSATIPOIDS_PKG ; 
/
SHOW ERROR 
EXIT;
/
