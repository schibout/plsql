    CREATE OR REPLACE TRIGGER DKA_PO_HEADERS_AUR
      ----------------------------------------------------------------------------------------------
      -- $$
      -- CAP GEMINI
      -- PROJET            : DALKIA Oracle Applications
      -- NOM               : DKA_PO_HEADERS_AIU.trg
      -- DESCRIPTION       : Trigger sur la table PO_HEADERS_ALL
      ---                    Pour contourner le probleme de creation des articles sur iproc 
      ---                    pour le spe de chargement catalogue, il faut une seule ligne par org dans table des activations
      ---
      --- AUTEUR           : Redouane BELAYACHI (Capgemini)
      --- DATE DE CREATION : 16/03/2018
      --- DOC. ASSOCIEE    :
      -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
      ----------------------------------------------------------------------------------------------
      --- HISTORIQUE DES MODIFICATIONS
      --- Date       Qui Description
      --- ---------- --- ---------------------------------------------------------------------------
      --- 04/03/2018 RBE  Chargement catalogue
      ----------------------------------------------------------------------------------------------

       AFTER
       UPDATE
       ON po.po_headers_all
       FOR EACH ROW
       WHEN (   NEW.AUTHORIZATION_STATUS = 'REQUIRES REAPPROVAL'
            AND OLD.AUTHORIZATION_STATUS = 'APPROVED'
            AND new.TYPE_LOOKUP_CODE = 'BLANKET'
            AND new.GLOBAL_AGREEMENT_FLAG = 'Y'
            )
    DECLARE
      v_count NUMBER := 0;
      v_rec_assign     PO_GA_ORG_ASSIGNMENTS%ROWTYPE;
    BEGIN
        
        IF :NEW.AUTHORIZATION_STATUS = 'REQUIRES REAPPROVAL' THEN

            SELECT count(1)
            INTO v_count
            FROM(
            SELECT organization_id,COUNT(1)
            FROM PO_GA_ORG_ASSIGNMENTS 
            WHERE po_header_id = :NEW.po_header_id
            --AND ENABLED_FLAG = 'Y'
            group by organization_id
            having count(1)> 1)
            ;
            
            IF v_count > 0 THEN
                --vider la table specifique
                DELETE FROM DKA_PO_GA_ORG_ASSIGNMENTS 
                WHERE po_header_id = :NEW.po_header_id;
                
                --remplir la table specifique avec les donnees de la table std pour les lignes actives
                INSERT INTO DKA_PO_GA_ORG_ASSIGNMENTS 
                       (PO_HEADER_ID,
                        ORGANIZATION_ID,
                        ENABLED_FLAG,
                        VENDOR_SITE_ID,
                        LAST_UPDATE_DATE,
                        LAST_UPDATED_BY,
                        CREATION_DATE,
                        CREATED_BY,
                        LAST_UPDATE_LOGIN,
                        PURCHASING_ORG_ID,
                        ORG_ASSIGNMENT_ID
                        )
                    (SELECT *
                     FROM PO_GA_ORG_ASSIGNMENTS
                     WHERE po_header_id = :NEW.po_header_id
                     --AND ENABLED_FLAG = 'Y'
                     );
                
                --Vider les lignes actives dans la table standard 
                DELETE FROM PO_GA_ORG_ASSIGNMENTS
                WHERE po_header_id = :NEW.po_header_id
                --AND ENABLED_FLAG = 'Y'
                ;
                
                --Pour chaque org active chercher si ligne est deja dans est iproc sinon on prend la 1ere ligne trouvee
                --il faut que la table std contienne une seule ligne par org pour que le standard cree les articles dans iproc
                FOR rec_org IN (SELECT distinct organization_id 
                                FROM DKA_PO_GA_ORG_ASSIGNMENTS
                                WHERE PO_HEADER_ID = :NEW.po_header_id
                                )
                LOOP
                    BEGIN
                        SELECT dp.PO_HEADER_ID,
                            dp.ORGANIZATION_ID,
                            dp.ENABLED_FLAG,
                            dp.VENDOR_SITE_ID,
                            dp.LAST_UPDATE_DATE,
                            dp.LAST_UPDATED_BY,
                            dp.CREATION_DATE,
                            dp.CREATED_BY,
                            dp.LAST_UPDATE_LOGIN,
                            dp.PURCHASING_ORG_ID,
                            dp.ORG_ASSIGNMENT_ID 
                        INTO v_rec_assign
                        FROM DKA_PO_GA_ORG_ASSIGNMENTS dp, ICX_CAT_ITEMS_CTX_HDRS_TLP ic, po_vendor_sites_all pvs
                        WHERE dp.po_header_id = ic.po_header_id
                        AND dp.vendor_site_id = ic.supplier_site_id
                        AND dp.organization_id = ic.org_id
                        AND dp.po_header_id = :NEW.po_header_id
                        AND dp.organization_id = rec_org.organization_id
                        AND pvs.vendor_site_id = ic.supplier_site_id
                        AND pvs.PURCHASING_SITE_FLAG = 'Y' 
                        AND NVL(pvs.INACTIVE_DATE,SYSDATE+1) > SYSDATE 
                        AND rownum = 1
                        ;
                    EXCEPTION
                    WHEN OTHERS THEN
                        BEGIN 
                            SELECT dp.PO_HEADER_ID,
                                dp.ORGANIZATION_ID,
                                dp.ENABLED_FLAG,
                                dp.VENDOR_SITE_ID,
                                dp.LAST_UPDATE_DATE,
                                dp.LAST_UPDATED_BY,
                                dp.CREATION_DATE,
                                dp.CREATED_BY,
                                dp.LAST_UPDATE_LOGIN,
                                dp.PURCHASING_ORG_ID,
                                dp.ORG_ASSIGNMENT_ID 
                            INTO v_rec_assign
                            FROM DKA_PO_GA_ORG_ASSIGNMENTS dp, po_vendor_sites_all pvs
                            WHERE 1=1
                            AND dp.po_header_id = :NEW.po_header_id
                            AND dp.organization_id = rec_org.organization_id
                            AND pvs.vendor_site_id = dp.vendor_site_id
                            AND pvs.PURCHASING_SITE_FLAG = 'Y' 
                            AND NVL(pvs.INACTIVE_DATE,SYSDATE+1) > SYSDATE 
                            AND rownum = 1
                            ;
                        EXCEPTION
                        WHEN OTHERS THEN
                            SELECT PO_HEADER_ID,
                                ORGANIZATION_ID,
                                ENABLED_FLAG,
                                VENDOR_SITE_ID,
                                LAST_UPDATE_DATE,
                                LAST_UPDATED_BY,
                                CREATION_DATE,
                                CREATED_BY,
                                LAST_UPDATE_LOGIN,
                                PURCHASING_ORG_ID,
                                ORG_ASSIGNMENT_ID
                            INTO v_rec_assign
                            FROM DKA_PO_GA_ORG_ASSIGNMENTS dp
                            WHERE 1=1
                            AND dp.po_header_id = :NEW.po_header_id
                            AND dp.organization_id = rec_org.organization_id 
                            AND rownum = 1
                            ;
                        END;
                    END;
                    
                    v_rec_assign.last_update_date := SYSDATE;
                    INSERT INTO PO_GA_ORG_ASSIGNMENTS VALUES v_rec_assign;
                
                END LOOP;
                
                --Vider les lignes iproc concernant la commande en cours.
                DELETE FROM ICX_CAT_ITEMS_CTX_DTLS_TLP 
                WHERE po_line_id IN (SELECT po_line_id 
                                     FROM po_lines_all 
                                     WHERE po_header_id = :NEW.po_header_id
                                     );
                                     
                DELETE FROM ICX_CAT_ITEMS_CTX_HDRS_TLP 
                WHERE PO_HEADER_ID = :NEW.po_header_id;
                
            END IF;
        END IF;
/* --Cela ne fonctionne pas ici car les lignes iproc sont crees apres approbation, deplace dans trigger icx
        IF :old.AUTHORIZATION_STATUS = 'APPROVED' AND :NEW.AUTHORIZATION_STATUS = 'APPROVED' THEN
            
            select count(1)
            into v_count
            from DKA_PO_GA_ORG_ASSIGNMENTS 
            WHERE po_header_id = :NEW.po_header_id;
            
            if v_count > 0 then
            
                 --Remettre les lignes supprimes.
                DELETE FROM PO_GA_ORG_ASSIGNMENTS
                WHERE po_header_id = :NEW.po_header_id
                AND ENABLED_FLAG = 'Y'
                ;
                
                INSERT INTO PO_GA_ORG_ASSIGNMENTS 
                     (SELECT * FROM DKA_PO_GA_ORG_ASSIGNMENTS
                      WHERE po_header_id = :NEW.po_header_id
                      );
                
                DELETE FROM DKA_PO_GA_ORG_ASSIGNMENTS 
                WHERE po_header_id = :NEW.po_header_id;
            
            end if;
        END IF;
*/
    EXCEPTION
      WHEN OTHERS THEN
        app_exception.raise_exception(NULL, NULL, SQLCODE || '=' || substr(SQLERRM, 1, 80));
    END;
    /
    EXIT