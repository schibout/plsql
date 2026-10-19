CREATE OR REPLACE PACKAGE BODY DKA_SPOCLOTURE_PKG AS
--------------------------------------------------------------------------------------------------------------- 
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_SPOCLOTURE_PKG.pkb
-- DESCRIPTION       : traitement de la clôture des traitements GL
---
--- AUTEUR           : Bastien Delattre
--- DATE DE CREATION : 24/06/2016
--- DOC. ASSOCIEE    : 
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
--------------------------------------------------------------------------------------------------------------- 
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--  23/01/2017 NBO artf2086019 - SPE059 : cloture PO: sélection de la période erronée
--  15/02/2017 NBO artf2086019 - SPE059 : cloture PO: sélection de la période erronée
--  16/05/2017 OBE artf2147911 - SPE059 : Cloture PO : Etat de synthèse dans les logs
---------------------------------------------------------------------------------------------------------------


-- variable globale
gv_min_period_name  VARCHAR2(8);

--< OBE artf2147911
gn_livre_a_cloturer   NUMBER := 0;
gn_livre_traite      NUMBER := 0;
gn_livre_cloture     NUMBER := 0;
gn_livre_non_cloture NUMBER := 0;
--> OBE artf2147911

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_CLOSE
--  Description   : Recherche la période à fermer pour une application
--
--  PARAMETRES    :
--     pn_sob_id  number
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date   date
--     pd_end_date   date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE period_to_close (pn_sob_id    IN OUT NUMBER,
         pv_period_name_cl   OUT    VARCHAR2,
         pv_errbuf     OUT    VARCHAR2,
         pn_retcode           OUT    NUMBER ) 
         
IS
vd_start_date  VARCHAR2(100);
vd_end_date    VARCHAR2(100);     

BEGIN     

  pv_errbuf := NULL;
  
  

  -- Recherche de la première période en status ouvert
  SELECT period_name,end_date,period_name
  INTO vd_start_date, vd_end_date, pv_period_name_cl
  FROM gl_period_statuses 
  WHERE application_id = 201        --PO
  AND set_of_books_id = pn_sob_id
  AND closing_status = 'O'          --OPEN
  AND start_date= (Select min(gl.start_date) 
                    from gl_period_statuses gl
                    WHERE gl.application_id = 201        --PO
                    AND gl.set_of_books_id = pn_sob_id
                    AND gl.closing_status = 'O'  );
                    
  dka_tools_pkg.put_log_message('Détermination de la période à fermer : '||TO_CHAR(pv_period_name_cl)); -- OBE artf2147911
  -- dka_tools_pkg.put_log_message('La période à fermer est : '||pv_period_name_cl); -- OBE artf2147911
EXCEPTION
--  23/01/2017 NBO artf2086019 - SPE059 : cloture PO: sélection de la période erronée
WHEN NO_DATA_FOUND THEN
    dka_tools_pkg.put_log_message('Aucune période ouverte !'); 
    pn_retcode := 1; 
WHEN OTHERS THEN
pv_errbuf := substr(SQLERRM,1,250);
dka_tools_pkg.put_log_message('Erreur lors de la détermination de la période à fermer '|| pv_errbuf);

pn_retcode := 2;      
END;
-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_TO_OPEN
--  Description   : Recherche la période suivante
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pv_period_name  varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pd_start_date   date
--     pd_end_date   date
--     pd_period_name   varchar2
-------------------------------------------------------------------------------------------------------------------
PROCEDURE period_to_open       ( pn_sob_id    IN OUT NUMBER,
                                 pv_period_name_cl      IN    VARCHAR2,
            pv_period_name_op      OUT    VARCHAR2,
            pd_start_date          OUT    DATE,
            pd_end_date            OUT    DATE,
            pv_errbuf           OUT    VARCHAR2,
            pn_retcode             OUT    NUMBER ) 
IS
  pv_closing_status varchar2(100);
BEGIN     

  pv_errbuf := NULL;
  --dka_tools_pkg.put_log_message('Lancement de la procédure de détermination de la période à ouvrir: '); -- OBE artf2147911



  SELECT start_date, end_date, period_name , closing_status
  INTO pd_start_date, pd_end_date, pv_period_name_op , pv_closing_status
  FROM gl_period_statuses
  WHERE start_date IN ( SELECT end_date+1 
            FROM gl_period_statuses
            WHERE period_name = pv_period_name_cl
            AND application_id = 201
            AND set_of_books_id = pn_sob_id )
  AND application_id = 201 
  AND set_of_books_id = pn_sob_id;
  
  
  IF pv_closing_status = 'O'
  THEN
    dka_tools_pkg.put_log_message('La période à ouvrir a déjà un statut ouvert');
  --ELSE
  --dka_tools_pkg.put_log_message('La période à ouvrir est la période suivante : '||pv_period_name_op ); -- OBE artf2147911
  END IF;

EXCEPTION
WHEN OTHERS THEN
pv_errbuf := substr(SQLERRM,1,250);  
dka_tools_pkg.put_log_message('Erreur lors de la détermination de la période à ouvrir :'||pv_errbuf);
pn_retcode := 2;  
END;



-------------------------------------------------------------------------------------------------------------------
--  Nom           : OPEN_NEXT_PERIOD
--  Description   : Ouverture de la période suivante
--
--  PARAMETRES    :
--     pn_sob_id  number
--     pv_period_name  varchar2
--
--  VALEUR RETOURNEE :
--     pv_errbuf  varchar2
--     pn_retcode       number
-------------------------------------------------------------------------------------------------------------------
PROCEDURE open_next_period (pn_sob_id         IN      NUMBER,
                            pv_period_name_op IN      VARCHAR2,
                            pd_start_date     IN      DATE,
                            pd_end_date       IN      DATE,
                            pv_errbuf         IN OUT  VARCHAR2,
                            pn_retcode           OUT  NUMBER) 

IS                            

BEGIN                      
    --dka_tools_pkg.put_log_message('Lancement de la procédure d''ouverture de la période.'); -- OBE artf2147911
        
    UPDATE gl_period_statuses        
              SET closing_status ='O'          
              WHERE application_id = 201       
              AND set_of_books_id = pn_sob_id  
              AND period_name = pv_period_name_op 
              AND start_date = pd_start_date   
              AND end_date = pd_end_date;      
              
              COMMIT;
        
    --dka_tools_pkg.put_log_message('La période a été ouverte avec succès.'); -- OBE artf2147911

EXCEPTION
WHEN OTHERS THEN
pv_errbuf := substr(SQLERRM,1,250);  
dka_tools_pkg.put_log_message('Erreur lors de l''ouverture : ' || pv_errbuf);
pn_retcode := 2;    
END open_next_period ;


---------------------------------------------------------------------------------------------------------------
--  Nom           : cloture_livre
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures pour la fermture
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--      pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
----------------------------------------------------------------------------------------------------------------
PROCEDURE cloture_livre(vn_sob_id IN NUMBER,pv_errbuf  IN OUT VARCHAR2,pn_retcode    OUT NUMBER)
IS
vd_start_date      DATE;
vd_end_date      DATE;
vv_period_name_cl  VARCHAR2(8);
vv_period_name_op  VARCHAR2(8);
vv_errbuf          VARCHAR2(150);
vn_retcode         NUMBER;
vn_ledger_id       NUMBER;
                   
x_request_num      NUMBER;
BEGIN
  vn_ledger_id := vn_sob_id;
  ----- détermination de la periode à fermer -----
  period_to_close(vn_ledger_id --IN OUT NUMBER,
                 ,
                  vv_period_name_cl --OUT VARCHAR2,
                 ,
                  vv_errbuf --OUT VARCHAR2,
                 ,
                  vn_retcode); --OUT NUMBER  
                  
              

  IF vn_retcode != 0 THEN
    dka_tools_pkg.put_debug_message('La periode à fermer n''a pas été déterminée');
    pn_retcode := 1;
    RETURN;
  ELSIF gv_min_period_name != vv_period_name_cl THEN
    dka_tools_pkg.put_debug_message('La periode à fermer est différente de la plus petite période');
    pn_retcode := 1;
    RETURN;  
  END IF;

  --dka_tools_pkg.put_debug_message('La période à fermer : ' ||
                                  --vv_period_name_cl);  -- OBE artf2147911

  ----- fermeture de la période en cours -----

  --dka_tools_pkg.put_log_message('update de la période ' ||
                                --vv_period_name_cl || ' pour le sob : ' ||
                                --vn_ledger_id); -- OBE artf2147911

  dka_po_tools_pkg.update_period_statuses(vn_ledger_id, --pn_sob_id  
                                          vv_period_name_cl, --pv_period_name
                                          201, --pn_application  
                                          'C', --pv_closing_status
                                          pv_errbuf,
                                          pn_retcode);
  dka_tools_pkg.put_debug_message('La période ' || vv_period_name_cl ||
                                  ' est fermée');

  ----- détermination de la période à ouvrir -----  
  period_to_open(vn_ledger_id --IN OUT NUMBER
                ,
                 vv_period_name_cl --IN     VARCHAR2
                ,
                 vv_period_name_op --   OUT VARCHAR2
                ,
                 vd_start_date --   OUT DATE
                ,
                 vd_end_date --   OUT DATE                   
                ,
                 vv_errbuf --OUT    VARCHAR2  
                ,
                 vn_retcode); --OUT    NUMBER 

  IF vn_retcode != 0 THEN
    dka_tools_pkg.put_debug_message('La periode à ouvrir n''a pas été déterminée');
    pn_retcode := 1;
    RETURN;
  END IF;

  dka_tools_pkg.put_log_message('Détermination de la période à ouvrir : '||TO_CHAR(vv_period_name_op)); -- OBE artf2147911    
  --dka_tools_pkg.put_debug_message('La période à ouvrir : ' ||
                                  --vv_period_name_op); -- OBE artf2147911

  ----- ouverture de la période suivante -----    
  open_next_period(vn_ledger_id --IN      NUMBER,       
                  ,
                   vv_period_name_op --IN      VARCHAR2,    
                  ,
                   vd_start_date --IN      DATE,       
                  ,
                   vd_end_date --IN      DATE,       
                  ,
                   vv_errbuf --IN OUT  VARCHAR2,                        
                  ,
                   vn_retcode); --   OUT  NUMBER  

  IF vn_retcode != 0 THEN
    pn_retcode := 1;
    dka_tools_pkg.put_debug_message('La periode ' || vv_period_name_op ||
                                    ' n''a pas été ouverte');
    RETURN;
  END IF;

  dka_tools_pkg.put_debug_message('La période ' || vv_period_name_op ||
                                  ' est ouverte');
EXCEPTION
  WHEN OTHERS THEN
    pv_errbuf  := SQLERRM;
    pn_retcode := 2;
  
END;
---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Lance la procédure de cloture pour tous les set_of_books
--
--  PARAMETRES    :
--  pv_errbuf                       Entrée/Sortie           retour de message eventuel
--      pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
----------------------------------------------------------------------------------------------------------------

PROCEDURE main (pv_errbuf  IN OUT VARCHAR2,
                pn_retcode    OUT NUMBER)

IS 
vn_sob_id     NUMBER;  
vv_period_name_cl  VARCHAR2(8);
vv_period_name_op  VARCHAR2(8);
vv_errbuf          VARCHAR2(150);
vn_retcode         NUMBER;
vv_responsibility_name VARCHAR(100);
vn_responsibility_id NUMBER;
vn_application_id NUMBER;
vv_responsibility_key VARCHAR2(100); -- OBE artf2147911

CURSOR cur_ledger_id  IS
select   gl.ledger_id AS ledger_id, gl.name
from     gl_access_set_assignments gasa, gl_ledgers gl
where    access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
and      gl.ledger_id = gasa.ledger_id
and      gl.ledger_category_code = 'PRIMARY'; 
        
BEGIN
  vv_responsibility_name := 'TOUT_PO_ADMINISTRATEUR';      
  SELECT fr.responsibility_id, fr.application_id, fr.responsibility_key -- OBE artf2147911
      INTO vn_responsibility_id, vn_application_id, vv_responsibility_key -- OBE artf2147911
      FROM fnd_responsibility fr
      WHERE fr.responsibility_key = vv_responsibility_name;
      dka_tools_pkg.put_log_message('Responsabilité : '|| vn_responsibility_id || vn_application_id || ' - ' || vv_responsibility_key); -- OBE artf2147911
      
      -- initialisation de l'environement OA pour correspondre a la societe en cours de traitement
      fnd_global.apps_initialize(fnd_global.user_id,vn_responsibility_id,vn_application_id);      
      
      --  23/01/2017 NBO artf2086019 - SPE059 : cloture PO: sélection de la période erronée
	  --  15/02/2017 NBO artf2086019 - SPE059 : cloture PO: sélection de la période erronée
      SELECT DISTINCT period_name
        INTO gv_min_period_name
        FROM gl_period_statuses
       WHERE application_id = 201 --PO
         AND set_of_books_id IN
             (SELECT gl.ledger_id AS ledger_id
                FROM gl_access_set_assignments gasa, gl_ledgers gl
               WHERE access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
                 AND gl.ledger_id = gasa.ledger_id
                 AND gl.ledger_category_code = 'PRIMARY')
         AND closing_status = 'O' --OPEN
         AND start_date =
             (SELECT MIN(gl.start_date)
                FROM gl_period_statuses gl
               WHERE gl.application_id = 201 --PO
                 AND gl.set_of_books_id IN
                     (SELECT gl.ledger_id AS ledger_id
                        FROM gl_access_set_assignments gasa, gl_ledgers gl
                       WHERE access_set_id = Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
                         AND gl.ledger_id = gasa.ledger_id
                         AND gl.ledger_category_code = 'PRIMARY')
                 AND gl.closing_status = 'O');
                 
      --dka_tools_pkg.put_log_message('Période plus ancienne : '||gv_min_period_name); -- OBE artf2147911
		
    FOR rec_ledger IN cur_ledger_id()
    LOOP
        gn_livre_a_cloturer := gn_livre_a_cloturer + 1;
    
        vn_sob_id:= rec_ledger.ledger_id;
		    vn_retcode:=0;
        dka_tools_pkg.put_log_message('Cloture sur le livre '||rec_ledger.ledger_id || '/' || rec_ledger.name);
        cloture_livre(rec_ledger.ledger_id,vv_errbuf,vn_retcode);
        gn_livre_traite := gn_livre_traite + 1;
        
        IF vn_retcode > NVL(pn_retcode,0)
        THEN
          pn_retcode :=  vn_retcode;
          gn_livre_non_cloture := gn_livre_non_cloture + 1; -- OBE artf2147911
          IF vn_retcode = 2
            THEN
              dka_tools_pkg.put_log_message('Fin de la cloture sur le livre suite à une exception '||rec_ledger.ledger_id );
              pv_errbuf := 'Fin de la cloture sur le livre suite à une exception '||rec_ledger.ledger_id;
              RETURN;
            END IF;
        ELSE -- OBE artf2147911
            gn_livre_cloture := gn_livre_cloture + 1;  -- OBE artf2147911
        END IF;
        
        dka_tools_pkg.put_log_message('Fin de la cloture sur le livre '||rec_ledger.ledger_id);
        dka_tools_pkg.put_log_message('----------------------------');
    END LOOP;
	  
    --< OBE artf2147911
    dka_tools_pkg.put_log_message('-------------------------------------');
    dka_tools_pkg.put_log_message('Synthèse du traitement de clôture PO :');
    dka_tools_pkg.put_log_message('-------------------------------------');
    dka_tools_pkg.put_log_message('Nombre de sociétés à clôturer    :'||gn_livre_a_cloturer);
    dka_tools_pkg.put_log_message('Nombre de sociétés traitées      :'||gn_livre_traite);
    dka_tools_pkg.put_log_message('Nombre de sociétés clôturées     :'||gn_livre_cloture);
    dka_tools_pkg.put_log_message('Nombre de sociétés non clôturées :'||gn_livre_non_cloture);
    --> OBE artf2147911    
        
                                
EXCEPTION                            
WHEN OTHERS THEN
    pv_errbuf := SQLERRM;
    pn_retcode := 2;
                        
END main; 
---------------------------------------------------------------------------------------------------------------   
END DKA_SPOCLOTURE_PKG;  -- Package body
/
SHOW ERRORS;
EXIT 
