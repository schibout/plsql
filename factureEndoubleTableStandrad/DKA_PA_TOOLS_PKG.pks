CREATE OR REPLACE TRIGGER DKA_PO_HEADERS_BIUR2
  ----------------------------------------------------------------------------------------------
  -- $$
  -- CAP GEMINI
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_PO_HEADERS_BIUR2.trg
  -- DESCRIPTION       : Trigger sur la table PO_HEADERS_ALL
  ---
  --- AUTEUR           : Thierry BOUGAULT (Capgemini)
  --- DATE DE CREATION : 09/02/2006
  --- DOC. ASSOCIEE    :
  -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
  ----------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- -------------------------------------------------------------------------
  --- 09/02/2006 TB  Création du trigger permettant la gestion automatique des frais de port (SPE-100)
  --- 20/06/2006 TB  Ajout d'une condition sur le déclenchement du trigger :
  ---                la commande ne doit pas être en cours d'annulation
  --- 21/07/2006 TB  Intégration d'un nouvelle règle de gestion :
  ---                Prise en compte de la valeur de l'ATTRIBUTE8 (enlèvement au comptoir)
  ---                dans la détermination des actions à mener
  --- 26/02/2007 TB  Modification de la condition de déclenchement (CANCEL_FLAG)
  ---                Modification du test sur l'attribute8
  --- 02/10/2007 TB  Modification d'une condition de déclenchement
  ---                NEW.approved_flag au lieu de OLD.approved_flag
  --- 16/11/2007 ADR ETANCHEITE DALKIA 2007
  --- 30/04/2015 JJA Correction des conditions de déclenchement
  --- 03/02/2017 MEG Correction artf2092860 : DEFECT 500 - GESTION DES FRAIS DE PORT
  --- 10/05/2017 MEG Correction artf2151614 : SPE100 - Ne pas générer de ligne de frais de port sur les commandes ouvertes
  --- 15/03/2018 OBE artf2418788 : SPE100 - Nouvelle ligne de frais de port lors de la réouverture d'une commande
  --- 06/06/2018 OBE artf2705547 : INC0219692 - SPE100 - Pb de génération des frais de port
  --- 03/07/2020 NBO artf07372333 : EDB267 - DGE20200009 - PFAD - Adaptations Oracle SPE061-SPE063-SPE100
  ---------------------------------------------------------------------------------------------

   AFTER
   INSERT
   or
   UPDATE 
   ON po.po_headers_all
   FOR EACH ROW
   
when 
(   NVL(NEW.cancel_flag,'N') = 'N' AND 
  NEW.type_lookup_code = 'STANDARD' AND
  NEW.closed_date IS NULL  AND ((NEW.approved_flag = 'Y')
                   OR (NEW.vendor_id  <> OLD.vendor_id) 
                   OR (NEW.ATTRIBUTE8 <> OLD.ATTRIBUTE8))
  AND OLD.closed_date IS NULL
  AND NVL(NEW.ATTRIBUTE7, 'ORACLE') NOT IN ('IVALUA', 'REPRISE')
) -- Modif TB 26/02/2007
DECLARE
          
          vn_vendor_id   po.po_headers_all.vendor_id%TYPE;
          vn_flag        po.po_headers_all.approved_flag%TYPE;
          vn_rev_num     po.po_headers_all.revision_num%TYPE; 
          vn_montant     DKA_SPOPARAM_FRAIS_PORT.Montant%TYPE;  
          vn_seuil       DKA_SPOPARAM_FRAIS_PORT.Seuil%TYPE;
          vn_count       NUMBER;
          vv_errbuf      VARCHAR2(500);
          vn_retcode     NUMBER;
          -- ETANCHEITE DALKIA 2007
          --vn_org_id      NUMBER := TO_NUMBER(FND_PROFILE.VALUE('ORG_ID'));
   
   BEGIN

        DECLARE
        
        
        CURSOR CUR_ID_NEW
        IS
            SELECT PO_HEADER_ID,
                   PO_LINE_ID,
                   nvl(attribute1,0) attribute1
            FROM   PO.PO_LINES_ALL
            WHERE  UPPER(item_description)  LIKE 'FRAIS DE PORT%'
            AND    PO_HEADER_ID = :NEW.PO_HEADER_ID
            AND    quantity != 0
            -- ETANCHEITE DALKIA 2007
            --AND    ORG_ID = vn_org_id
            ;  
                                    
                                    
        BEGIN

        vn_montant := 0;
        vn_seuil := 0;
        
        -- On verifie si le fournisseur de la commande fait partie des fournisseurs pour lesquels des frais de port sont paramétrés                   
        SELECT vendor_id
        INTO   vn_vendor_id
        FROM   DKA_SPOPARAM_FRAIS_PORT
        WHERE  vendor_id =  :NEW.vendor_id
        -- ETANCHEITE DALKIA 2007
        --AND    ORG_ID = vn_org_id
        ;
        
    IF vn_vendor_id is not null -- le fournisseur est paramétré
    THEN

        vn_flag := :NEW.approved_flag;
        vn_rev_num := :NEW.revision_num; 
            
        -- Mode Mise à Jour
        IF UPDATING 
        THEN

           -- Il n'y a pas d'enlèvement au comptoir
           IF NVL(:NEW.ATTRIBUTE8,'NON') = 'NON' -- Modif TB 26/02/2007
           THEN
            
              -- Changement du fournisseur ??         
              IF (:OLD.vendor_id != :NEW.vendor_id)
              THEN

                 -- On Supprime les lignes de frais de port
                 IF ( vn_flag is NULL OR vn_rev_num = 0 ) 
                 THEN
           
                    FOR rec_id_new IN cur_id_new
                       LOOP 
                         BEGIN
                                                                       
                            DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne(rec_id_new.po_header_id,rec_id_new.po_line_id,vv_errbuf,vn_retcode);

                            IF vn_retcode != 0 THEN
                               app_exception.raise_exception(NULL,NULL,'Erreur SUP 1');
                            END IF;
                         END;
                       END LOOP;  
           
                 ELSE  -- On annule les lignes de frais de port     
                    FOR rec_id_new IN cur_id_new
                       LOOP 
                          BEGIN                

                             DKA_SPOFRAIS_PORT_PKG.Annuler_ligne(rec_id_new.po_header_id,rec_id_new.po_line_id,vv_errbuf,vn_retcode);

                             IF vn_retcode != 0 THEN
                                app_exception.raise_exception(NULL,NULL,'Erreur ANNU 1');
                 
                             END IF;
                          END;
                       END LOOP; 
                 END IF;   
              END IF; -- Fin du test sur changement de fornisseur
              
              
              -- On Supprime les lignes de frais de port (non automatique)
              IF  ( vn_flag is NULL OR vn_rev_num = 0 ) 
              THEN

                 FOR rec_id_new IN cur_id_new
                    LOOP 
                       BEGIN
                          
                          IF rec_id_new.attribute1 != 'A'
                          THEN
                                                                       
                             DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne(rec_id_new.po_header_id,rec_id_new.po_line_id,vv_errbuf,vn_retcode);

                             IF vn_retcode != 0 THEN
                                app_exception.raise_exception(NULL,NULL,'Erreur SUP 1');
                             END IF;
                          END IF;   
                       END;
                    END LOOP;  
           
              ELSE  -- On annule les lignes de frais de port (non automatique) 
                 FOR rec_id_new IN cur_id_new
                    LOOP 
                       BEGIN
                       
                          IF rec_id_new.attribute1 != 'A'
                          THEN
                                       
                             DKA_SPOFRAIS_PORT_PKG.Annuler_ligne(rec_id_new.po_header_id,rec_id_new.po_line_id,vv_errbuf,vn_retcode);
                            
                             IF vn_retcode != 0 THEN
                                app_exception.raise_exception(NULL,NULL,'Erreur ANNU 1');
                 
                             END IF;
                          END IF;
                       END;
                    END LOOP; 
              END IF;-- FIN Supp des lignes de frais de port non automatique
              
           
              -- Calcul du montant                
              DKA_SPOFRAIS_PORT_PKG.Calculer_montant(:OLD.PO_HEADER_ID,vn_montant,vv_errbuf,vn_retcode);

              IF vn_retcode != 0 THEN
                 app_exception.raise_exception(NULL,NULL,'Erreur lors du calcul du nouveau montant');
                 
              END IF;
        
              -- Calcul du seuil
              SELECT    Seuil
              INTO      vn_seuil
              FROM      DKA_SPOPARAM_FRAIS_PORT
              WHERE     vendor_id = :NEW.vendor_id
              -- ETANCHEITE DALKIA 2007
              --AND    ORG_ID = vn_org_id
              ;

              -- Vérification si montant < au seuil et la présence de ligne de Frais de port
              IF vn_montant < vn_seuil
              THEN
                 SELECT COUNT(1)
                 INTO   vn_count
                 FROM   PO.PO_LINES_ALL
                 WHERE  UPPER(item_description)  LIKE 'FRAIS DE PORT%'
                 AND    PO_HEADER_ID = :NEW.PO_HEADER_ID
                 AND    quantity != 0
                 -- ETANCHEITE DALKIA 2007
                 --AND    ORG_ID = vn_org_id
                 ;  
                
                
                IF vn_count = 0 -- Pas de ligne de frais de port
                THEN
                   -- Insertion ligne de frais de port car montant < au seuil
                   --DKA_SPOFRAIS_PORT_PKG.Inserer_ligne(:NEW.PO_HEADER_ID,vn_vendor_id, vv_errbuf,vn_retcode);
                   
                   DECLARE
                     vb_check_exist BOOLEAN := FALSE;
                   
                   BEGIN
                   
                     FOR i IN 1 .. DKA_SPOFRAIS_PORT_PKG.g_index_tab LOOP
                     
                       IF DKA_SPOFRAIS_PORT_PKG.g_header_id_tab(i) = :NEW.PO_HEADER_ID AND
                          DKA_SPOFRAIS_PORT_PKG.g_vendor_id_tab(i) = vn_vendor_id THEN
                       
                         vb_check_exist := TRUE;
                       
                       END IF;
                     
                     END LOOP;
                   
                     IF NOT vb_check_exist THEN
                       DKA_SPOFRAIS_PORT_PKG.g_index_tab := DKA_SPOFRAIS_PORT_PKG.g_index_tab + 1;
                       DKA_SPOFRAIS_PORT_PKG.g_header_id_tab(DKA_SPOFRAIS_PORT_PKG.g_index_tab) := :NEW.PO_HEADER_ID;
                       DKA_SPOFRAIS_PORT_PKG.g_vendor_id_tab(DKA_SPOFRAIS_PORT_PKG.g_index_tab) := vn_vendor_id;
                     END IF;
                   
                   END;
                   
                   IF vn_retcode != 0 THEN
                      app_exception.raise_exception(NULL,NULL,'Erreur lors de l insertion de la ligne de frais de port');
                   END IF;
                   
                END IF; -- Montant < au seuil et déjà une ligne de frais
              
              ELSE -- montant > = seuil
                 DECLARE
                 
                 -- Recherche des éventuelles lignes de frais de port 
                 CURSOR CUR_ID_OLD
                 IS
                    SELECT PO_HEADER_ID,
                           PO_LINE_ID
                    FROM   PO.PO_LINES_ALL
                    WHERE  UPPER(item_description)  LIKE 'FRAIS DE PORT%'
                    AND    PO_HEADER_ID = :NEW.PO_HEADER_ID
                    AND    quantity != 0
                    -- ETANCHEITE DALKIA 2007
                    --AND    ORG_ID = vn_org_id
                    ; 
                 
                 BEGIN
                 
                 vn_flag := :NEW.approved_flag;
                 
                 FOR rec_id_old IN cur_id_old
                 LOOP  
                   BEGIN -- Si le curseur trouve des lignes     
                      
                      IF  ( vn_flag is NULL OR vn_rev_num = 0 ) -- On supprime les lignes de frais de port
                      THEN
                      
                         DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne(rec_id_old.po_header_id,rec_id_old.po_line_id,vv_errbuf,vn_retcode);

                      ELSE -- On annule les lignes de frais de port
                      
                         DKA_SPOFRAIS_PORT_PKG.Annuler_ligne(rec_id_old.po_header_id,rec_id_old.po_line_id,vv_errbuf,vn_retcode);
                      
                      END IF;
                      
                         
                      IF vn_retcode != 0 THEN
                         app_exception.raise_exception(NULL,NULL,'Erreur lors de la suppression de la ligne de frais de port');
                 
                      END IF;
                      
                   END; 
                 END LOOP;                                              
                                                  
                 EXCEPTION -- Si le curseur ne trouve pas de lignes = sortie
                 WHEN OTHERS
                 THEN
                    app_exception.raise_exception;             
              
                 END;
              
              END IF; -- Fin de la comparaison montant / seuil 
        
           ELSE -- La valeur de l'attribute8 est différente de NON ou nul
               
               -- La valeur de l'attribute8 est passée de NON à OUI
               IF (:NEW.ATTRIBUTE8 != :OLD.ATTRIBUTE8)
               THEN

                   -- On Supprime alors les lignes de frais de port qui auraient pu exister auparavant
                   IF ( vn_flag is NULL OR vn_rev_num = 0 ) 
                   THEN
                      FOR rec_id_new IN cur_id_new
                          LOOP 
                             BEGIN
                                                                       
                                DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne(rec_id_new.po_header_id,rec_id_new.po_line_id,vv_errbuf,vn_retcode);

                                IF vn_retcode != 0 THEN
                                   app_exception.raise_exception(NULL,NULL,'Erreur SUP 1');
                                END IF;
                             END;
                          END LOOP;  
           
                   ELSE  -- On annule les lignes de frais de port     
                      FOR rec_id_new IN cur_id_new
                          LOOP 
                             BEGIN                

                                DKA_SPOFRAIS_PORT_PKG.Annuler_ligne(rec_id_new.po_header_id,rec_id_new.po_line_id,vv_errbuf,vn_retcode);

                                IF vn_retcode != 0 THEN
                                   app_exception.raise_exception(NULL,NULL,'Erreur ANNU 1');
                                END IF;
                             END;
                          END LOOP; 
                   END IF;   
               END IF; -- Fin du test de changement de valeur de l'attribute8
                
           END IF; -- Fin test sur enlèvement comptoir
                      
        END IF; -- Fin MAJ
        
    END IF; -- Fin fournisseur paramétré
           
        EXCEPTION  -- le fournisseur n'est pas paramétré 
        
        WHEN NO_DATA_FOUND
        THEN
            NULL;
            
           -- Dans le cas de la Mise a jour du vendor_id 
           IF (UPDATING AND (:OLD.vendor_id != :NEW.vendor_id))
           THEN
              BEGIN
              
              -- On verifie si l'ancien fournisseur était paramétré ?
                            
              SELECT vendor_id
              INTO   vn_vendor_id
              FROM   DKA_SPOPARAM_FRAIS_PORT
              WHERE  vendor_id = :OLD.vendor_id
              -- ETANCHEITE DALKIA 2007
              --AND    ORG_ID = vn_org_id
              ;             
             
              EXCEPTION
              WHEN NO_DATA_FOUND
              THEN

              -- AUCUN FOURNISSEUR de paramétré dans la table spécifique DKA_SPOPARAM_FRAIS_PORT
              Null;

              WHEN OTHERS
              THEN
                  app_exception.raise_exception(NULL,NULL,'Erreur lors de la verification de l ancien fournisseur');             
              
              END;
                  
              -- On determine le HEADER_ID et le LINE_ID pour supprimer les lignes de frais de port existantes
              IF vn_vendor_id is not null
              THEN

                 DECLARE
                 
                 CURSOR CUR_ID_OLD
                 IS
                    SELECT PO_HEADER_ID,
                           PO_LINE_ID
                    FROM   PO.PO_LINES_ALL
                    WHERE  UPPER(item_description)  LIKE 'FRAIS DE PORT%'
                    AND    PO_HEADER_ID = :NEW.PO_HEADER_ID
                    AND    quantity != 0
                    -- ETANCHEITE DALKIA 2007
                    --AND    ORG_ID = vn_org_id
                    ;    
                 
                 BEGIN
                 FOR rec_id_old IN cur_id_old
                 LOOP 
                   BEGIN                
                      -- On supprime les lignes de frais de port     
                      DKA_SPOFRAIS_PORT_PKG.Supprimer_ligne(rec_id_old.po_header_id,rec_id_old.po_line_id,vv_errbuf,vn_retcode);

                      IF vn_retcode != 0 THEN
                         app_exception.raise_exception(NULL,NULL,'Erreur lors de la suppression de la ligne de frais de port');
                 
                      END IF;
                   END;
                 END LOOP;                                              
                                                  
                 EXCEPTION
                 WHEN OTHERS
                 THEN
                    app_exception.raise_exception;             
              
                 END;
              END IF;
           END IF; 
       
        
        WHEN OTHERS
        THEN
            NULL;
        END;
             
   EXCEPTION
   WHEN OTHERS
   THEN
      app_exception.raise_exception(NULL,NULL,SQLCODE||'='||substr(SQLERRM,1,80)||'==> FIN DE TRIGGER PO HEADER ID :'||:NEW.PO_HEADER_ID||'vn_vendor_id :'|| vn_vendor_id|| 'montant :' ||vn_montant || 'seuil : ' || vn_seuil);
   END;
/
SHOW ERRORS;
EXIT
