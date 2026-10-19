CREATE OR REPLACE TRIGGER dka_po_req_lines_bur
----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_PO_REQ_LINES_BUR.trg
-- DESCRIPTION      : Trigger sur la table PO_REQUISITION_LINES_ALL
---
--- AUTEUR           : Bernard HANQUIER (CGEY)
--- DATE DE CREATION : 09/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 21/06/2002 BHA Ajout du nom de l'organisation dans la recherche du site de facturation
---                ajout de l'etape appartenance dans la sequence de recherche
---                (appartenance, centre, region)
--- 15/07/2002 BHA Suppression de la mise a jour de l'acheteur dans la table PO_HEADERS_ALL
--- 08/04/2004 SRO Intégration d'une nouvelle règle de gestion lié à ce trigger :
---                affection par défaut du cuf attribute6 de l'entête de commande qui détermine
---                l'envoi automatique de commande à partir des valeurs attribute6
---                des lignes de DIA.
--- 06/05/2004 CDE Modif suite ajout d'une deuxième ligne pour les employés partis
--------------------------------------------------------------------------------------------
--- 19/07/2004 STI Portage specifique PHENIX 2004
---                modification pour le nom de l'organisation (segment1)
--------------------------------------------------------------------------------------------
--- 21/07/2006 TB  Affectation par défaut du CUF ATTRIBUTE8 de l'entête de commande qui
---        détermine l'activation ou non de la gestion 	automatique des frais de port
---        à partir des valeurs de l'ATTRIBUTE8 des lignes de DIA.
---------------------------------------------------------------------------------------------
--- 21/09/2006 CDE Correction requête de selection de la société pour prendre en compte
---                la première ligne et non la ligne en cours de mise à jour
--- 18/06/2009 QVA Ajout permettant de mettre à jour le champs attribute10 et attribute2 de la
---                table PO_HEADERS_ALL que pour VT.
--- 25/11/2009 QVA Ajout permettant de vérifier que le code Parc saisi est présent dans la 
---                table des jeux de valeurs.Si non, on met le code Parc à null.
--- 14/10/2011 EMA DGE20110021 : Ajout de la gestion du paiement direct
--------------------------------------------------------------------------------------------
--- 14/11/2012 JJA Correction la date d'inactivation du lieu de facturation
--------------------------------------------------------------------------------------------
--- 19/06/2013 JJA report : renseignement de l'attribute2 de la table po_headers_all et de 
---                         l'attribute_category for Veolia Property - 06/07/2010  JBS
---------------------------------------------------------------------------------------------
--- 24/05/2016 MEG Migration R12
---------------------------------------------------------------------------------------------
--- 26/04/2018 RBE EDB106
---------------------------------------------------------------------------------------------

BEFORE UPDATE ON po.po_requisition_lines_all FOR EACH ROW

when (   (    NEW.line_location_id IS NOT NULL
              AND OLD.line_location_id IS NULL
             )
          OR NEW.line_location_id <> OLD.line_location_id
         )
DECLARE
    vv_apps_source_code   po_requisition_headers_all.apps_source_code%TYPE;
    vv_po_header_id       po_line_locations_all.po_header_id%TYPE;
    vv_location_id        hr_locations_all.location_id%TYPE;
    vv_org_name           gl_code_combinations.segment1%TYPE; -- PHENIX 2004
    vn_org_id             po_lines_all.org_id%TYPE;
    --vn_org_id             po_requisition_headers_all.org_id%TYPE := NULL; --QVA 18/06/2009
    vn_exist              NUMBER := 0;
    --vn_org_id_prop        po_requisition_headers_all.org_id%TYPE := NULL; --JBS 06/07/2010
    vn_po_line_id         po_line_locations_all.po_line_id%TYPE; --RBE EDB106
BEGIN
  /*QVA 18/06/2009 Recherche de l'org_id de VT*/
   /*
   BEGIN
            SELECT organization_id
            INTO vn_org_id
            FROM hr_all_organization_units hou
            WHERE hou.NAME = 'TRANSPORT_OPE';

            EXCEPTION
            WHEN OTHERS
            THEN
                app_exception.raise_exception;

    END;
    */
  /*Fin QVA*/
  
  /*JBS  06/07/2010 Recherche de l'org_id de VP*/
  
  /*
  BEGIN

          SELECT organization_id
                 INTO vn_org_id_prop
            FROM hr_all_organization_units hou
           WHERE hou.NAME = 'PROPRETE_OPE';

           EXCEPTION
            WHEN OTHERS
            THEN
                app_exception.raise_exception;
  END;
  */
/* Fin JBS*/
  
    BEGIN
        SELECT prh.apps_source_code,
               pll.po_header_id,
               pll.po_line_id --rbe EDB106
          INTO vv_apps_source_code,
               vv_po_header_id,
               vn_po_line_id --rbe EDB106
          FROM po_requisition_headers_all prh,
               po_line_locations_all pll
         WHERE prh.requisition_header_id = :NEW.requisition_header_id
           AND pll.line_location_id = :NEW.line_location_id
           AND ROWNUM = 1;

--        IF vv_apps_source_code = 'POR'
--        THEN
--            UPDATE po_headers_all
--            SET    agent_id = NVL (:NEW.to_person_id, agent_id)
--            WHERE  po_header_id = vv_po_header_id;
--        END IF;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            NULL;
        WHEN OTHERS
        THEN
            app_exception.raise_exception;
    END;

    BEGIN
        BEGIN
            -- PHENIX 2004
-- CDE 210906            SELECT g.segment1
-- CDE 210906              INTO vv_org_name
-- CDE 210906              FROM po_req_distributions_all p, gl_code_combinations g
-- CDE 210906              WHERE p.code_combination_id = g.code_combination_id
-- CDE 210906                    AND p.requisition_line_id = :NEW.requisition_line_id ;
            -- FIN PHENIX 2004

            -- Début CDE 210906
          BEGIN
            SELECT gcc.segment1,
                   pl.org_id
              INTO vv_org_name,
                   vn_org_id
              FROM po_req_distributions_all prda
                  ,po_distributions_all pda
                  ,po_lines_all pl
                  ,gl_code_combinations gcc
             WHERE prda.code_combination_id  = gcc.code_combination_id
               AND pda.req_distribution_id   = prda.distribution_id
               AND pda.po_line_id            = pl.po_line_id
               AND pl.po_header_id           = (SELECT po_header_id
                                                FROM po_line_locations_all
                                                WHERE line_location_id = :NEW.line_location_id)
               AND ROWNUM = 1;

          EXCEPTION
            WHEN NO_DATA_FOUND
             THEN
                NULL;
            WHEN OTHERS
             THEN
                app_exception.raise_exception;
          END;
             -- Fin CDE 210906

            /*
            -- recherche si l'appartenance de l'employe est un site de facturation
            SELECT location_id
              INTO vv_location_id
              FROM hr_locations_all hrla,
                   per_all_people_f pap
             WHERE pap.person_id = :NEW.to_person_id
               AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
               AND hrla.location_code = pap.attribute1 || vv_org_name
               AND NVL(hrla.inactive_date,SYSDATE) >= SYSDATE --JJA 2012/11/14
               AND hrla.bill_to_site_flag = 'Y';
            */
            
            -- recherche du lieu de facturation à partir de l'UO de la commande
            SELECT fsp.bill_to_location_id
              INTO vv_location_id 
              FROM FINANCIALS_SYSTEM_PARAMS_ALL fsp
             WHERE fsp.org_id = vn_org_id;
            
        EXCEPTION
            WHEN NO_DATA_FOUND
            THEN
                /*
                BEGIN
                    -- recherche si le centre de rattachement de l'employe est un site de facturation
                    SELECT location_id
                      INTO vv_location_id
                      FROM hr_locations_all hrla,
                           per_all_people_f pap
                     WHERE pap.person_id = :NEW.to_person_id
                       AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
                       AND hrla.location_code = pap.attribute3 || vv_org_name
                       AND NVL(hrla.inactive_date,SYSDATE) >= SYSDATE --JJA 2012/11/14
                       AND hrla.bill_to_site_flag = 'Y';
                EXCEPTION
                    WHEN NO_DATA_FOUND
                    THEN
                        BEGIN
                            -- recherche si la region de rattachement de l'employe est un site de facturation
                            SELECT location_id
                              INTO vv_location_id
                              FROM hr_locations_all hrla,
                                   per_all_people_f pap
                             WHERE pap.person_id = :NEW.to_person_id
                               AND trunc(sysdate) between pap.effective_start_date and pap.effective_end_date
                               AND hrla.location_code = pap.attribute2 || vv_org_name
                               AND NVL(hrla.inactive_date,SYSDATE) >= SYSDATE --JJA 2012/11/14
                               AND hrla.bill_to_site_flag = 'Y';
                        EXCEPTION
                            WHEN NO_DATA_FOUND
                            THEN
                                vv_location_id    := NULL;
                            WHEN OTHERS
                            THEN
                                app_exception.raise_exception;
                        END;
                    WHEN OTHERS
                    THEN
                        app_exception.raise_exception;
                END;
                */
                vv_location_id    := NULL;
            WHEN OTHERS
            THEN
                app_exception.raise_exception;
        END;

        IF vv_location_id IS NOT NULL
        THEN
            BEGIN
                UPDATE po_headers_all
                SET    bill_to_location_id = vv_location_id
                WHERE  po_header_id = vv_po_header_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        END IF;
    END;

    -- RG2 ajoutée le 08/04/2004
    BEGIN
       IF :NEW.attribute6 = 'N'
        THEN
            BEGIN
                 -- Au moins un enregistrement a été trouvé dans ce cas, on peut donc
                 -- affecter l'attribute6 de l'entête de commande à 'N' pour ne pas envoyer
                 -- automatiquement le bon de commande
                UPDATE po_headers_all
                SET    attribute6 = 'NON'
                WHERE  po_header_id = vv_po_header_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
          ELSE
            BEGIN
                 -- Pas d'enregistrement trouvé dans ce cas, il n'existe pas de
                 -- requisition lié à la commande, toutes les lignes de requisition
                 -- associée à la commande ont l'attribute6 à 'Y'. Dans ce cas, l'attribute6
                 -- de l'entête de commande doit être à 'Y' pour autoriser l'envoi automatique
                UPDATE po_headers_all
                SET    attribute6 = 'OUI'
                WHERE  po_header_id = vv_po_header_id
                AND    attribute6 IS NULL;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        END IF;
    END;

    -- Ajout TB 20/07/2006 Flag pour Enlèvement au comptoir
    BEGIN
       IF :NEW.attribute8 = 'Y'
        THEN
            BEGIN
                 -- Au moins un enregistrement a été trouvé dans ce cas, on peut donc
                 -- affecter l'attribute8 de l'entête de commande à 'Y' pour ne pas gérér
                 -- les frais de port automatiquement
                UPDATE po_headers_all
                SET    attribute8 = 'OUI'
                WHERE  po_header_id = vv_po_header_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
          ELSE
            BEGIN
                 -- Aucune ligne dont l'attribute8 est à 'Y', donc l'attribute8
                 -- de l'entête de commande doit être à 'NON' pour autoriser la gestion automatique
                 -- des frais de port
                UPDATE po_headers_all
                SET    attribute8 = 'NON'
                WHERE  po_header_id = vv_po_header_id
                AND    attribute8 IS NULL;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        END IF;
    END;

    -- Ajout EMA 14/10/2011 Flag pour Paiement direct
    BEGIN
        IF :NEW.attribute13 = 'OUI'
        THEN
            BEGIN
                -- Au moins un enregistrement a été trouvé dans ce cas, on peut donc
                -- affecter l'attribute13 de l'entête de commande à 'OUI' pour le 
                -- paiement direct
                UPDATE po_headers_all
                SET    attribute13 = 'OUI'
                WHERE  po_header_id = vv_po_header_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        ELSE
            BEGIN
                -- Au moins un enregistrement a été trouvé dans ce cas, on peut donc
                -- affecter l'attribute13 de l'entête de commande à 'NON' pour le 
                -- paiement direct
                UPDATE po_headers_all
                SET    attribute13 = 'NON'
                WHERE  po_header_id = vv_po_header_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        END IF;
    END;

    -- Ajout QVA 18/06/2009 renseignement de l'attribute10 de la table po_headers_all et de l'attribute_category

    /*
    BEGIN

     IF :NEW.org_id = vn_org_id THEN
       IF :NEW.attribute10 = 'N' OR :NEW.attribute10 IS NULL
        THEN
            BEGIN
                 -- Au moins un enregistrement a été trouvé dans ce cas, on peut donc
                 -- affecter l'attribute10 de l'entête de commande à 'N'
                UPDATE po_headers_all
                SET    attribute10 = 'NON',
                       ATTRIBUTE_CATEGORY = vn_org_id
                WHERE  po_header_id = vv_po_header_id
                AND    org_id = vn_org_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
         ELSE
            BEGIN
                 -- Pas d'enregistrement trouvé dans ce cas, il n'existe pas de
                 -- requisition lié à la commande, toutes les lignes de requisition
                 -- associée à la commande ont l'attribute10 à 'Y'. Dans ce cas, l'attribute10
                 -- de l'entête de commande doit être à 'Y'.
                UPDATE po_headers_all
                SET    attribute10 = 'OUI',
                       ATTRIBUTE_CATEGORY = vn_org_id
                WHERE  po_header_id = vv_po_header_id
                AND    attribute10 IS NULL
                AND    org_id = vn_org_id;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    NULL;
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        END IF;
      END IF;
    END;
    */

    -- Ajout QVA 18/06/2009 renseignement de l'attribute2 de la table po_headers_all et de l'attribute_category
    BEGIN
     /*QVA 25/11/2009*/
     BEGIN
          SELECT count(*)
          INTO vn_exist
          FROM 
           fnd_flex_values ffv,
           fnd_flex_value_sets ffvs
          WHERE
           ffvs.flex_value_set_name = 'VT_CODE_PARC' 
           and ffv.flex_value_set_id = ffvs.flex_value_set_id
           and ffv.flex_value = :NEW.attribute2;       
     END;
     /*FIN QVA 25/11/2009*/
     
     /*
     IF (:NEW.org_id = vn_org_id ) OR ( :NEW.org_id =vn_org_id_prop )THEN
        IF vn_exist != 0 THEN -- QVA 25/11/2009
         BEGIN
          UPDATE po_distributions_all
          SET    attribute2 = :NEW.attribute2,
                 ATTRIBUTE_CATEGORY =:NEW.org_id  --vn_org_id JBS 06/07/2010
          WHERE  po_header_id = vv_po_header_id
          AND    line_location_id = :NEW.line_location_id
          AND    org_id =:NEW.org_id; -- vn_org_id; JBS 06/07/2010
     
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            app_exception.raise_exception;
         END;   
        /*QVA 25/11/2009*/
     /*    
        ELSE
         BEGIN
          UPDATE po_distributions_all
          SET    attribute2 = NULL,
                 ATTRIBUTE_CATEGORY = :NEW.org_id  --vn_org_id JBS 06/07/2010
          WHERE  po_header_id = vv_po_header_id
          AND    line_location_id = :NEW.line_location_id
          AND    org_id = :NEW.org_id;  --vn_org_id; JBS 06/07/2010
         EXCEPTION
         WHEN NO_DATA_FOUND
         THEN
            NULL;
         WHEN OTHERS
         THEN
            app_exception.raise_exception;
        END;   
        /*FIN QVA 25/11/2009*/ 
     /*
       END IF; 
       
     ELSE
     */
       IF :NEW.attribute2 IS NOT NULL THEN
        BEGIN
        UPDATE po_distributions_all
        SET    attribute2 = NULL,
               ATTRIBUTE_CATEGORY = :NEW.org_id   ---vn_org_id  JBS 06/07/2010
        WHERE  po_header_id = vv_po_header_id
        AND    line_location_id = :NEW.line_location_id;
       -- AND    org_id != vn_org_id;   JBS 06/07/2010
      EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            NULL;
        WHEN OTHERS
        THEN
            app_exception.raise_exception;

       END;
      END IF;
     /*END IF;*/
    END;

    -- RBE
    -- EDB106 ajouté le 26/04/2018
    BEGIN
       IF :NEW.attribute3 IS NOT NULL
        THEN
            BEGIN
                 -- mettre a jour attribute3 de po_lines_all
                UPDATE po_lines_all
                SET    attribute3 = :NEW.attribute3
                WHERE  po_line_id = vn_po_line_id;
            EXCEPTION
                WHEN OTHERS
                THEN
                    app_exception.raise_exception;
            END;
        END IF;
    END;
END;
/
SHOW ERROR

EXIT;
