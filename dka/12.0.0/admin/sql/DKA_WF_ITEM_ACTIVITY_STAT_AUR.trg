    CREATE OR REPLACE TRIGGER DKA_WF_ITEM_ACTIVITY_STAT_AUR
      ----------------------------------------------------------------------------------------------
      -- $$
      -- CAP GEMINI
      -- PROJET            : DALKIA Oracle Applications
      -- NOM               : DKA_WF_ITEM_ACTIVITY_STAT_AUR.trg
      -- DESCRIPTION       : Trigger sur la table PO_HEADERS_ALL
      ---                    Pour contourner le probleme de creation des articles sur iproc 
      ---                    pour le spe de chargement catalogue, il faut une seule ligne par org dans table des activations
      ---
      --- AUTEUR           : Redouane BELAYACHI (Capgemini)
      --- DATE DE CREATION : 02/04/2018
      --- DOC. ASSOCIEE    :
      -- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
      ----------------------------------------------------------------------------------------------
      --- HISTORIQUE DES MODIFICATIONS
      --- Date       Qui Description
      --- ---------- --- ---------------------------------------------------------------------------
      --- 04/03/2018 RBE SPE210 - Chargement catalogue
      --- 04/03/2018 RBE artf3045111 - INC0258745 PROB duplication / désactivation de sites d'achat sur des catalogues. certains sites ne sont pas pris en compt
      ----------------------------------------------------------------------------------------------

       AFTER
       UPDATE
       ON WF_ITEM_ACTIVITY_STATUSES
       FOR EACH ROW
       WHEN (   NEW.ITEM_TYPE = 'POAPPRV'
            AND NEW.ACTIVITY_STATUS = 'COMPLETE'
            AND NEW.ACTIVITY_RESULT_CODE = 'ACTIVITY_PERFORMED'
            AND NEW.end_date IS NOT NULL
            )
    DECLARE
      v_rec_assign      PO_GA_ORG_ASSIGNMENTS%ROWTYPE;
      v_count           NUMBER := 0;
      v_count_assign    NUMBER := 0;
      v_count_lines     NUMBER := 0;
      v_count_icx       NUMBER := 0;
      v_count_total     NUMBER := 0;
      v_po_header_id    PO_HEADERS_ALL.PO_HEADER_ID%type;
    BEGIN

        BEGIN
            SELECT po_header_id 
            INTO v_po_header_id
            FROM po_headers_all 
            WHERE WF_ITEM_KEY=:NEW.ITEM_KEY;
        EXCEPTION
          WHEN OTHERS THEN
            v_po_header_id := NULL;
        END;
        
        IF v_po_header_id IS NOT NULL THEN
        
            --nbre de lignes creees dans la table iproc
            SELECT COUNT(1) 
            INTO v_count_icx 
            FROM ICX_CAT_ITEMS_CTX_HDRS_TLP 
            WHERE PO_HEADER_ID = V_PO_HEADER_ID; 
           
            --Verifier si on a des lignes a traiter
            SELECT COUNT(1) 
            INTO v_count
            FROM DKA_PO_GA_ORG_ASSIGNMENTS
            WHERE po_header_id = v_po_header_id
            ;
        
            -- si il y a des lignes 
            IF V_COUNT > 0 AND v_count_icx > 0 THEN

                --nbre de lignes actives
                SELECT COUNT(1) 
                INTO v_count_assign
                FROM PO_GA_ORG_ASSIGNMENTS
                WHERE po_header_id = v_po_header_id
                AND enabled_flag = 'Y'
                ;
            
                --nbre de lignes de commande illigible
                SELECT COUNT(1)
                INTO v_count_lines
                FROM po_lines_all pla,PO_ATTRIBUTE_VALUES POATR
                WHERE pla.po_header_id = v_po_header_id
                AND POATR.PO_LINE_ID   = PLA.PO_LINE_ID
                AND NVL(POATR.REBUILD_SEARCH_INDEX_FLAG,'Y') = 'Y' --RBE artf3045111
                AND TRUNC(NVL(pla.EXPIRATION_DATE,SYSDATE+1)) > TRUNC(SYSDATE)
                ;
            
                --nbre de ligne a prevenir dans iproc
                v_count_total := v_count_assign * v_count_lines;

                --Si nbre inseree = nbre prevu, 
                --cela veut dire que l insertion est terminee on peut remettre les lignes dans table std des activations 
                IF V_COUNT_ICX = V_COUNT_TOTAL THEN 
                    --supprimer les lignes existent dans table std.
                    DELETE FROM PO_GA_ORG_ASSIGNMENTS
                    WHERE po_header_id = v_po_header_id
                    AND ENABLED_FLAG = 'Y'
                    ;
                    
                    --inserer les lignes qui sont dans table specifique
                    INSERT INTO PO_GA_ORG_ASSIGNMENTS 
                         (SELECT PO_HEADER_ID,
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
                          FROM DKA_PO_GA_ORG_ASSIGNMENTS
                          WHERE po_header_id = v_po_header_id
                          );
                    
                    --Vider la table specifique pour la commande concernee
                    DELETE FROM DKA_PO_GA_ORG_ASSIGNMENTS 
                    WHERE po_header_id = v_po_header_id;
            
                END IF;
            END IF;
        END IF;
    EXCEPTION
      WHEN OTHERS THEN
        app_exception.raise_exception(NULL, NULL, SQLCODE || '=' || substr(SQLERRM, 1, 80));
    END;
    /
    EXIT