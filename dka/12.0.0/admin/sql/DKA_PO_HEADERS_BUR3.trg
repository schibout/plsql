----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_PO_HEADERS_BUR3.trg
-- DESCRIPTION       : Trigger sur la table PO_HEADERS_ALL
---                    Ce trigger déclenche l'impression et l'envoi du bon de commande annulé
---                    automatiquement dès l'annulation de la commande
--- AUTEUR           : Sebastien ROLAND (CGEY)
--- DATE DE CREATION : 11/09/2003
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 05/03/2007 CDE Ajout du lancement du STAGE30 (stockage des bons de commande)
--- 05/08/2009 CDE Ajout du lancement du STAGE40 (Envoi dupli par mail au demandeur)
--- 15/11/2013 JJA Ajout du lancement du STAGE25 (Imprimer bon de commande en XML)
--- 24/05/2016 MEG Migration R12
--- 07/03/2018 MEG artf2418123 : SPE063 - Probleme de jeu de traitements lors de l'annulation d'une commande
--- 08/03/2018 MEG artf2420479 : Problème de generation des bons de commandes en anglais (INC0196270) 
--------------------------------------------------------------------------------------------


PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU TRIGGER dka_po_headers_bur3
PROMPT ++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE OR REPLACE TRIGGER dka_po_headers_bur3
   BEFORE UPDATE
   ON po.po_headers_all
   FOR EACH ROW
   WHEN  (             OLD.cancel_flag = 'I'
            AND        NEW.cancel_flag = 'Y'
            AND        NVL(NEW.ATTRIBUTE7, 'ORACLE') NOT IN ('IVALUA', 'REPRISE')              
        )
   
DECLARE

       v_success         BOOLEAN;
       v_user_id         VARCHAR2 (30);   
       v_qty_precision   VARCHAR2 (30);
       v_request_id      NUMBER := 0;
       v_dupli_mail_test VARCHAR2(150);
       e_error_set_lang  EXCEPTION;
       
BEGIN
 
    IF :NEW.org_id IS NOT NULL THEN
        
        -- Affectation de l'organisation
        --fnd_client_info.set_org_context (TO_CHAR (:NEW.org_id));
        PO_MOAC_UTILS_PVT.set_org_context(TO_CHAR(:NEW.org_id));
        
        fnd_profile.get ('USER_ID', v_user_id);
        fnd_profile.get ('REPORT_QUANTITY_PRECISION', v_qty_precision);
        
        -- Recupere le parametre par defaut pour la phase DKA_SPOBON_DUPLI_MAIL
        BEGIN
          SELECT default_value
            INTO v_dupli_mail_test
            FROM FND_DESCR_FLEX_COL_USAGE_VL
           WHERE APPLICATION_ID = '50001'
             AND DESCRIPTIVE_FLEXFIELD_NAME LIKE '$SRS$.DKA_SPOBON_DUPLI_MAIL'
             AND end_user_column_name = 'PV_MAIL_TEST';
        EXCEPTION
          WHEN OTHERS THEN
            v_dupli_mail_test := NULL;
        END;
        
        v_success := fnd_submit.set_mode (TRUE);
        
        IF (v_success) THEN
           
           fnd_submit.set_org_id(TO_CHAR(:NEW.org_id));
           
           --positionnement de la langue
           v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
                   
           IF (NOT v_success) THEN
              RAISE e_error_set_lang;
           END IF;
           
           v_success := fnd_submit.set_request_set('DKA','DKA_SPOBON_PDF_FAX');
        
           IF (v_success) THEN
              
              fnd_submit.set_org_id(TO_CHAR(:NEW.org_id));
              
              --positionnement de la langue
              v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
               
              IF (NOT v_success) THEN
                 RAISE e_error_set_lang;
              END IF;
              
              -- appel du programme d'edition au format PDF
              v_success := fnd_submit.submit_program (
                              'DKA'
                             ,'DKA_SPOBON_PDF'
                             ,'STAGE10'
                             ,'R'
                             ,NULL
                             ,:NEW.segment1
                             ,:NEW.segment1
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,NULL
                             ,'Y'
                             ,NULL
                             ,v_user_id
                             ,v_qty_precision
                             ,'N'
                             ,NULL
                             ,'Y'
                             ,'N'
                           );
                           
/*
              IF (v_success) THEN
                 
                 fnd_submit.set_org_id(TO_CHAR(:NEW.org_id));
                 
                 -- appel du programme de preparation de l'envoi par fax
                 v_success := fnd_submit.submit_program (
                           'DKA'
                           ,'DKA_SPOBON_FAX'
                           ,'STAGE20'
                           );
*/
     
                IF (v_success) THEN
                  
                   fnd_submit.set_org_id(TO_CHAR(:NEW.org_id));
                   
                   --positionnement de la langue
                   v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');
                   
                   IF (NOT v_success) THEN
                      RAISE e_error_set_lang;
                   END IF;
                   
                   -- appel du programme d'impression bon de commande en XML
                   v_success := fnd_submit.submit_program (
                               'DKA'
                              ,'DKA_SPOBON_XML'
                              ,'STAGE25'
                              ,NULL
                              ,NULL
                              );

                   IF (v_success) THEN

                      fnd_submit.set_org_id(TO_CHAR(:NEW.org_id));

                      --positionnement de la langue
                      v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');

                      IF (NOT v_success) THEN
                         RAISE e_error_set_lang;
                      END IF;

                      -- appel du programme de stockage des bons de commande
                      v_success := fnd_submit.submit_program (
                               'DKA'
                               ,'DKA_SPOBON_STOCIMG'
                               ,'STAGE30'
                               );

                       IF (v_success) THEN

                        fnd_submit.set_org_id(TO_CHAR(:NEW.org_id));

                        --positionnement de la langue
                        v_success := fnd_submit.set_nls_options('FRENCH', 'FRANCE');

                        IF (NOT v_success) THEN
                           RAISE e_error_set_lang;
                        END IF;

                        -- appel du programme d'envoi du duplicata par mail au demandeur
                        v_success := fnd_submit.submit_program (
                                 'DKA'
                                ,'DKA_SPOBON_DUPLI_MAIL'
                                ,'STAGE40'
                                ,v_dupli_mail_test
                                );

                          IF (v_success) THEN

                           v_request_id := fnd_submit.submit_set(null,FALSE);

                           :new.attribute15 := to_char(v_request_id);

                          END IF;
                       END IF;
                    END IF;
                 END IF;
              --END IF;
           END IF;
        END IF;
    END IF;     

EXCEPTION
WHEN e_error_set_lang
THEN
   RAISE;
END;
/
SHOW ERROR

EXIT;
