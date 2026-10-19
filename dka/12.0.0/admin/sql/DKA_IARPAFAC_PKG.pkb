CREATE OR REPLACE PACKAGE BODY Dka_Iarpafac_Pkg
AS

---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI ERNST AND YOUNG
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DKA_IARPAFAC_PKG.pks
-- DESCRIPTION       : DKA_IARPAFAC_PKG package body :
---
--- AUTEUR           : Guillaume Chabrier
--- DATE DE CREATION : 15/01/2002
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 18/6/02    GC  Modification de l'insertion du montant
--- 05/07/2002 SYB UPDATE_REQUEST_ID : correction Ano : ajout de and oa_status = 'P' pour ne pas re-transférer les factures
---                                     deja transférée dans l'open interface
---                MAIN : ajout de oa_status = 'P' dans le curseur cur_group pour eviter re-transfert
--- 10/07/2002 BER UPDATE_REQUEST_ID + MAIN : correction Ano precedente: oa_status != 'A' au lieu de  ='P'
---                LOAD_INVOICE_LINE : retrait du tax_rate pour que le montant des lignes de TVA ne soit pas recalcule par l Open interface
---        ajout de la procedure load_invoice_TVASPEC_line, NON UTILISEE POUR LE MOMENT
---         cette procedure ajoute une ligne de produit fictive pour le passage de ligne de TVA isolee (solution Oracle)
---         peut etre utile en cas de nouvelles complications sur les lignes de TVA
--- 27/08/2002 SYB Insertion du FOLIO dans l'attribute9 pour le controle des flux
--- 07/01/2003 XD  get_ar_gl_date : on compare annee+mois au lieu du mois tout seul
--- 17/01/2003 XD  main : correction cur_group et vv_millesim
--  11/02/2003 EF  Prise en compte de la date GL pour la determination des differents segments de la cle GL
---                       --> Passage de la date GL aux procedures:
---                             -- get_acct_area
---                             -- get_ccid_ttc
---                             -- get_ccid_tax
---                             -- load_invoice_line
---                             -- get_ccid_attributes_line
---                             -- get_ccid_surtaxe
--                       --> Modification de la procedure load_invoice_header
--                              -- Demarrer par la recherche de la date GL
--                              -- Passer la date GL a :
--                                               - get_acct_area
--                                               - get_ccid_ttc
--                       --> Modification de la procedure load_invoice_line
--                              -- Passer la date GL a :
--                                               - get_ccid_attributes_line
--                                               - get_ccid_tax
--                                               - get_ccid_surtaxe
--                       --> Utilisation de la table MIGR_GROUP_ACCOUNT_CLASS_BILAN  au lieu de PAY_GROUP_ACCOUNT_CLASS_4
---                      --> Gestion du NO_DATA_FOUND dans get_millesim_batch_id
---                               -- Ajout du company_code dans l'appel de get_millesim_batch_id
---                                  afin d'afficher le nom de l'organisation en cas de NO_DATA_FOUND
---                               -- Ajout de l'exception NO_DATA_FOUND dans get_millesim_batch_id
---                               -- Gestion du retour de get_millesim_batch_id dans la procedure main en cas de NO_DATA_FOUND
---                               -- Marquage des lignes des factures en erreur (Exception e_error_group dans main())
--- 12/03/2003 XD  get_ar_gl_date : correction du cas 1
--- 16/04/03   SBEL Creation d'un curseur qui corrige les code tva qui ne correspondent
---                  pas au montant calculé dans l'open interface.(cursor cc)
--- 23/04/2003 XD  run_import : on se remet dans la responsabilité initiale après lancement du traitement
--- 29/04/2003 EB  Modification du calcul de la date GL dans GET_AR_GL_DATE/
--- 30/04/2003 SBEL modification de la recherche des segments (get_ccid_tax)
--- 30/06/2003 FL   Il manquait des rollbacks en cas d'erreur du traîtement (les factures restaient en partie dans l interface
--- 08/07/2003 FL   modifications des règles de génération de la date GL des factures (get_ar_gl_date)
--- 09/07/2003 XD  load_invoice_line : appel de DKA_PA_TOOLS_PKG.pa_check_transaction_data pour controle
---                                    de coherence des donnees
---                Mise en forme du script
--- 11/08/2003 FL  get_ccid_tax: ccid definitif et provisoir dans l open interface
--- 12/08/2003 FL  Modification du CURSOR cur_rejections: batch_source_name !='REFAC'
--- 14/08/2003 XD  get_acct_area : modification du calcul du Centre de Gestion
--- 12/09/2003 XD  main : Suppression des lignes à 0
--- 24/10/2003 GV  ajout du TRUNC à pd_date et à pd_gl_date pour éviter les problèmes de comparaison pour le dernier jour du mois
---                main : - Ajout du N° de facture pour le message d'erreur "le montant TTC est different de HT+TAX"
---                       - Ajout du calcul de statistiques
---                       - Ne plus lancer l'import pièce par pièce mais en une seule fois, donc :
---                       - Mettre en commentaire le RUN_IMPORT
---                       - Modifier le curseur cur_rejections pour qu'il traite en fait toutes les pièces
---                       - Ajout d'un Wait_For_Request pour attendre que l'import de toutes les pièces soit fini
--- 12/12/2003 GV get_ar_gl_date : modification du calcul de la date comptable pour rejeter les pièces sur une période
---                                future
---               main : mise en commentaire du premier champ dans l'ORDER BY du curseur CUR_TAX_LINE
--- 12/01/2004 GV main : Suppression des lignes à 0 sur les factures nulles uniquement (TTC = 0)
---                      Ajout condition sur le tax_rate pour génération automatique des lignes de TVA
---                      (cas des factures exonérées asns lignes de TVA qui généraient des lignes à 0 à tort)
---               get_ar_gl_date : ne plus prendre le dernier jour du mois mais SYSDATE si celle-ci est dans
---                                la période AR ouverte
---                                -> ajout d'un nouveau paramètre pd_gl_date_OI qui alimentera la date GL de
---                                   l'Open Interface
---               get_ccid_surtaxe : Vérifier dans le jeu de valeur du compte local si le segment4 doit
---                                  être calculé ou non
--- 17/06/2004 SFE Portage spécifique pour projet PHENIX 2004.
---                Impacts sur get_millesim_batch_id, get_ccid_ttc, get_ccid_atriutes_line, get_ccid_tax,
---                            get_ccid_surtaxe, main, check_project, run_import et run_recyclage_rejections.
--- 21/07/2004 EB PHENIX 2004
---               Load_invoice_header, Load_invoice_tvaspec_line, load_invoice_line : Alimentation de l'attribute5 et du link_to_line_attribute5
--- 24/06/2005 EMA Suite à la recette fonctionnelle : modification de la procédure get_ar_tax => suppression
---                de la jointure sur le segment1
--- 05/07/2005 JV  procédure get_ccid_tax -> si le segment1 =XXXX remplacer par company_code
--- 21/07/2005 CD  Complément report de maintenance pour gestion de l'attribute5
--- 22/07/2005 CD  get_ccid_tax : Correction calcul segment2
--- 23/05/2006 GV  main : L'ajustement des écarts sur la TVA calculée n'est plus fait sur la dernière ligne produit
---                       de la facture mais par type de TVA (ceci oblige ainsi la lecture du curseur cur_tax_line
---                       et ramène ainsi le bon type)
--- 26/09/2006 TB  load_invoice_line : changement du paramètre de date pour pa_check_transaction_data
---                get_ccid_attributes_line : correction du journal pour la ccid
--- 28/09/2006 TB  main : modification du calcul de la TVA : ajout d'une rupture sur le function_code
---                       modification du test sur la rupture du curseur TVA : mise en commentaire du tax_equal_flag à Y
--- 25/10/2006 EM  Le calcul des statistiques sur la table RA_INTERFACE_LINES_ALL devient obsolète.
--- 10/11/2006 GV  main : ajout de l'id de la ligne 411 pour l'erreur pièce deséquilibrée
--- 03/04/2007 GV  main : ajout rupture supplémentaire sur le cumul lignes HT / somme TVA pour gestion des factures avec des lignes TVA
---                       ayant le même taux et le même code fonction
--- 18/05/2009 MT  main : Status of the invoiced which are falling in next closed peroids have to be updated from 'P' to 'Z' and vice versa
--- 19/05/2011 EMA Si le nouveau champ type_evt_dep de la table dka_iarpafac_interface est renseigné,
---                on ne va plus chercher le type de dépense ou d'évènement dans la table de transco
---                mais on prend la valeur du champ (plus d'appel de la procédure get_transaction_type)
--- 01/02/2012 CDE Ajout des commentaires des lignes de factures dans la table AR_CUSTOMER_TRX_ALL
--- 15/04/2015 BCO INC000000671429 - Demande de correctif suite pb écart de TVA pour petits montants
--- 05/05/2016 RBE Migration R12


--- 07/11/2016 PBR Migration R12. Prise en compte des modifications apportées dans la SFD et des modifications au niveau des données en entrée.
---                Le programme peut maintenant être lancé à partir d'une résponsabilité MOAC.
---                Le traitement standard se lance pour toutes les organisations (l'org_id de l'interface est déterminée à partir du couple region-company_code)
--- 10/02/2016 YWA artf2099786
--- 16/03/2017 EFL artf2122732: Modification de la recherche des comptages.
--  21/04/2017 YWA artf2143664
--  27/04/2017 MEG artf2146567 : INT006 - Traitement des rejets de l'interface client - Defect Bout_En_bout_Helios_Ref #614
--  03/05/2017 MEG artf2148883 : INT006 : Defect # 641 - La valeur du segment5 n'est pas determine
--  05/05/2017 MEG artf2149718 : INT006 : Interface des factures clients - les lignes OA_STATUS = A ne sont pas supprimées
--  15/05/2017 NBO artf2153141 - INT006 - Alimentation de la colonne tax_rate - Defect Bout_en_Bout_Helios_Ref #641
--  25/05/2017 YWA artf2158775 : INT006 - Suppression des messages DKA_PROGRAM_MESSAGES - IARPAFAC -Defect Bout_En_Bout_Helios_Ref #675
--  23/06/2017 OBE artf2176433 : INT006 - Lancement de RAXMTR en erreur - Defect Bout_En_Bout_Helios_Ref #799
--  25/07/2017 OBE artf2200212 : INT006 - Interface des factures client - factures en rejet pour calcul HT/TTC différent - defect BeB #990
--  08/08/2017 OBE artf2209666 : INT006 - Interface des factures client - Erreur à la recherche du centre de gestion - defect BeB #1043
--  22/08/2017 RBE artf2211292 : INT006 - Import des factures clients - Il y a des valeurs codés en dur au niveau des comptes
--  23/08/2017 JJA artf2214380 : INT006 - Tache majoritaire - Defect Beb #1055
--  22/05/2018 OBE artf2663866 : INC0219013 Import facture INT006 segmentation - Modification des champs segmentation et task code
--  03/01/2019 NBO artf3057680 : INC0277073 Factures clients sont en rejets dans la table spécifique
--  03/04/2019 SNK artf07231300 : EDB241 LOT2 ADAPTATION SPECIF - DGE20190010_OracleR12_Finance_Société DALKIA SUISSE_Besoin général
--  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
--  06/08/2019 AAM artf07147612 : EDB233 : Détermination du code RUM et remontée de l¿information du mode de règlement lorsqu¿il s¿agit du prélèvement.
--  09/09/2019 JWY artf07147612 : EDB233 : Détermination du code RUM et remontée de l¿information du mode de règlement lorsqu¿il s¿agit du prélèvement.
--  16/10/2019 NBO artf07286069 : INC0329483 - Optimisation chargement facture CLients
 -- 30/10/2020 JWY artf07418193 : INC0474541 - Correction détermination de l'instrument de règlement
 -- 17/01/2022 SELO EDB325
-- 22/08/2022 SELO TASK0183310- Autorisation de débit qui ramène deux RUM
-- 19/01/2024 SHA KDFI-1496 - NC - AR - Mauvais RUM chargé lors de l'import facture client
-------------------------------------------------------------------------------------------------------------

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
    gn_request_id            NUMBER (15);
    gn_user_id               fnd_user.user_id%TYPE;
    gn_login_id              fnd_logins.login_id%TYPE;
    gn_responsibility_id     fnd_responsibility.responsibility_id%TYPE;
    gn_resp_application_id   fnd_application.application_id%TYPE;
    gn_term_id               NUMBER (15); --Condition de paiment A_ECHEANCE
    cv_line                  VARCHAR2 (100)                              := '=======================================================';

    gv_origin                VARCHAR2(150) := 'XXX'; --JWYC
    gv_company_code          VARCHAR2(150);
    gv_invoice_number        VARCHAR2(150);
	

    cn_segment1_offset      CONSTANT NUMBER := Dka_Tools_Pkg.segment_size(2) + 1; -- PHENIX 2004: Ajout.
    cn_segment1_size        CONSTANT NUMBER := Dka_Tools_Pkg.segment_size(1);     -- PHENIX 2004: Ajout.
    cn_segment2_offset      CONSTANT NUMBER := 1;                                 -- PHENIX 2004: Ajout.
    cn_segment2_size        CONSTANT NUMBER := Dka_Tools_Pkg.segment_size(2);     -- PHENIX 2004: Ajout.

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
---------------------------------------------------------------------------------------------------------------
--  Nom           : init
--  Description   : Procédure d'initialisation du package
--                  Génère l'entête du fichier de sortie
--
--  PARAMETRES    :
--      ************************
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE init (
    pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode      OUT      NUMBER
    )
    IS
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('>initialisation');
        ----- Initialisation des variables -----
        pn_retcode                := 0;
        pv_errbuf                 := NULL;
        --procédure insérant une entête dans le fichier
        --de sortie avec comme titre le nom du traitement
        --la date et l'heure de lancement.
        Dka_Tools_Pkg.put_out_header;
        gn_request_id             := Fnd_Global.conc_request_id;
        gn_user_id                := Fnd_Global.user_id;
        gn_login_id               := Fnd_Global.login_id;
        gn_responsibility_id      := Fnd_Global.resp_id;
        gn_resp_application_id    := Fnd_Global.resp_appl_id;
        Dka_Tools_Pkg.put_debug_message (' REQUEST_ID :'|| gn_request_id);

        -- YWA artf2158775
        -- purger l'ensemble des messages précédent de la table dka_program_messages.
        DELETE dka_program_messages WHERE prog_name = 'IARPAFAC';

        BEGIN
            SELECT term_id
            INTO   gn_term_id
            FROM   ra_terms
            WHERE  NAME = 'A_ECHEANCE';
        EXCEPTION
            WHEN OTHERS
            THEN
                pn_retcode    := 2;
                pv_errbuf     := 'Condition de paiement A_ECHEANCE introuvable !';
                RETURN;
        END;

        --Initialisation de la procédure de duplication des sites clients
        Dka_Iclientifs_Pkg.init (pv_errbuf, pn_retcode);
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E001', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            Dka_Tools_Pkg.put_debug_message ('>init : '|| SQLERRM); --affichage .log
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                NULL, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors de l''initialisation de l''interface modifiée IARPAFAC'
            ); --texte message
            pn_retcode    := 2;
    END init;


---------------------------------------------------------------------------------------------------------------
--  Nom           : update_request_id
--  Description   : Procédure de mise à jour de la colonne OA_REQUEST_ID pour les enregs
--                  à traiter
--
--  PARAMETRES    :
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE update_request_id (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        --- Mise à jour de la colonne oa_request_id -----
        UPDATE dka_iarpafac_interface
        SET    oa_request_id = gn_request_id,
               oa_status     = 'P'
        WHERE      1=1
        AND oa_status != 'A';
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E002',
                                 'ERROR',
                                 SQLERRM,
                                 'REQUEST_ID',
                                 gn_request_id,
                                 'Une erreur est survenue lors de la mise à jour de la colonne REQUEST_ID'
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                NULL, --ID explicite
                'request_id', --Non colonne en question
                gn_request_id, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors de la mise à jour de la colonne REQUEST_ID'
            );
            pn_retcode    := 2;
    END update_request_id;

--artf2153141 - INT006 - Alimentation de la colonne tax_rate - Defect Bout_en_Bout_Helios_Ref #641
---------------------------------------------------------------------------------------------------------------
--  Nom           : update_tax_rate
--  Description   : Procédure de mise à jour de la colonne TAX_RATE pour les enregs
--                  à traiter
--
--  PARAMETRES    :
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: '0=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE update_tax_rate (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        --- Mise à jour de la colonne oa_request_id -----
        UPDATE dka_iarpafac_interface
        SET
         TAX_RATE = (SELECT lpad(zr.percentage_rate*100,4,'0')
                      FROM  zx_rates_b zr
                      WHERE tax_rate_code = TAX_CODE
                        AND zr.active_flag = 'Y')
        WHERE      1=1
        AND oa_status != 'A'
        AND TAX_CODE IS NOT NULL
        ;

    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E002',
                                 'ERROR',
                                 SQLERRM,
                                 'REQUEST_ID',
                                 gn_request_id,
                                 'Une erreur est survenue lors de la mise à jour de la colonne TAX_RATE'
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                NULL, --ID explicite
                'tax_rate', --Non colonne en question
                gn_request_id, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors de la mise à jour de la colonne TAX_RATE'
            );
            pn_retcode    := 2;
    END update_tax_rate;

---------------------------------------------------------------------------------------------------------------
--  Nom           : update_group_id
--  Description   : Procédure de mise à jour la colonne GROUP_ID des enregistrements pour une même
--                  origine OA
--
--
--  PARAMETRES    :
--     pv_company_code           Entrée
--     pv_fmt_origin             Entrée
--     pn_group_id               Entrée
--     pv_errbuf                 Entrée/Sortie    message d'erreur
--     pn_retcode                Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE update_group_id (
        pr_rec_line       IN       NUMBER,
    pv_company_code   IN       VARCHAR2,
        pv_region         IN       VARCHAR2,
        pv_fmt_origin     IN       VARCHAR2,
        pn_group_id       IN       NUMBER,
        pv_millesim       IN       VARCHAR2,
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
    vn_number_lines NUMBER;
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        ----- Mise à jour de la colonne group_id -----
        UPDATE dka_iarpafac_interface dii
        SET    dii.GROUP_ID = pn_group_id
        WHERE      dii.fmt_origin = pv_fmt_origin
               AND dii.company_code = pv_company_code
               AND dii.region = pv_region
               AND dii.oa_status = 'P'
               AND dii.oa_request_id = gn_request_id
               AND TO_CHAR(EXTRACT(YEAR FROM dii.fmt_invoice_date)) = pv_millesim -- R12
               AND EXISTS ( SELECT 1
                            FROM   dka_iarpafac_interface diittc
                            WHERE      diittc.fmt_origin = dii.fmt_origin
                                   AND diittc.company_code = dii.company_code
                                   AND diittc.region = dii.region
                                   AND diittc.oa_request_id = dii.oa_request_id
                                   AND diittc.invoice_number = dii.invoice_number
                                   AND diittc.line_type = 'CLIENT'
                                   AND TO_CHAR(EXTRACT(YEAR FROM diittc.fmt_invoice_date)) = TO_CHAR(EXTRACT(YEAR FROM dii.fmt_invoice_date))); --R12

    EXCEPTION
        WHEN OTHERS THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E003', 'ERROR', SQLERRM, 'GROUP_ID', pn_group_id);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line, --ID explicite --artf3056354 SNIK 23/01/2019
                'request_id', --Non colonne en question
                pn_group_id, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors de la mise à jour de la colonne GROUP_ID'
            ); --texte message
            pn_retcode    := 2;
    END update_group_id;


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_millesim_batch_id
--  Description   : Procédure de mise à jour du batch_source_name et id comme parametres de lancement
--                  de l'open interface.
--                  Principe : concaténation de l'origine formatée (en l'occurence 'SYSTEME_AMONT') et
--                             du millésime(année du groupe de factures)
--
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE get_millesim_batch_id (
      pr_rec_line            IN       NUMBER,
        pn_org_id              IN       NUMBER,
        pv_fmt_origin          IN       VARCHAR2,
        pv_millesim            IN       VARCHAR2,
        pv_company_code        IN       VARCHAR2,
        pv_batch_source_name   OUT      VARCHAR2,
        pn_batch_source_id     OUT      NUMBER,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
    BEGIN
        -- On prend l'année du groupe de facture
        --pv_batch_source_name    := pv_company_code || '_' || pv_fmt_origin || '_' || pv_millesim; -- PHENIX 2004

        pv_batch_source_name :=  'SYSTEME_AMONT' || '_' || pv_millesim; --R12 PBR Origine suivant la régle de gestion RG12

        SELECT rbs.batch_source_id
        INTO   pn_batch_source_id
        FROM   ra_batch_sources_all rbs
        WHERE  1=1
        AND NAME = pv_batch_source_name
        AND org_id = pn_org_id;

        pn_retcode              := 0;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pn_retcode    := 1;
            --affichage .log + .out
            Dka_Tools_Pkg.put_outdebug_message ('!!! Erreur');
            Dka_Tools_Pkg.put_outdebug_message ('!!! Le batch_Souce n''est pas pas défini');
            Dka_Tools_Pkg.put_outdebug_message ('!!! Nom: '|| pv_batch_source_name);
            Dka_Tools_Pkg.put_outdebug_message ('!!! Organisation: '|| pv_company_code || ' (' || TO_CHAR (pn_org_id) || ')');
            pv_errbuf     :=    'Le batch_Souce '
                             || pv_batch_source_name
                             || ' n''est pas pas défini pour l''organisation '
                             || pv_company_code
                             || ' ('
                             || TO_CHAR (pn_org_id)
                             || ')';
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line, --ID explicite --artf3056354 SNIK 23/01/2019
                'group_id', --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                pv_errbuf
            ); --texte message
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E034', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line, --ID explicite --artf3056354 SNIK 23/01/2019
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors de la mise à jour du parametre : batch_source_name'
            ); --texte message
            pn_retcode    := 2;
    END get_millesim_batch_id;


---------------------------------------------------------------------------------------------------------------
--  Nom           : load_invoice_header
--  Description   : Procédure de controle de l'entête d'une facture
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004: Modification procedure.
    PROCEDURE load_invoice_header (
        pr_rec_line            IN       dka_iarpafac_interface%ROWTYPE,
        pn_org_id              IN       NUMBER,
        pn_sob_id              IN       NUMBER,
        pn_cust_acct_site_id   OUT      NUMBER,
        pn_cust_account_id     OUT      NUMBER,
        pv_partner_code        OUT      VARCHAR2,
        pv_acct_area           OUT      VARCHAR2,
        pd_gl_date             OUT      DATE,
        pd_gl_date_OI          OUT      DATE,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        vv_segment1   VARCHAR2 (30);
        vv_segment2   VARCHAR2 (30);
        vv_segment3   VARCHAR2 (30);
        vv_segment4   VARCHAR2 (30);
        vv_segment5   VARCHAR2 (30);
        vv_segment6   VARCHAR2 (30);
        vv_segment7   VARCHAR2 (30);
        vv_segment8   VARCHAR2 (30);
        vv_segment9   VARCHAR2 (30);    -- PHENIX 2004: Ajout.
        vv_segment10  VARCHAR2 (30);    -- PHENIX 2004: Ajout.
        vv_segment11  VARCHAR2 (30); --R12
        vv_segment12  VARCHAR2 (30); --R12
    BEGIN
        /****************************** CONTROLE DE LA DATE ********************************/
        Dka_Tools_Pkg.put_debug_message ('Contrôle de la date comptable');
        get_ar_gl_date (pr_rec_line,   -- IN
                        pd_gl_date,    -- OUT
                        pd_gl_date_OI, -- OUT
                        pn_sob_id,     -- IN
                        pv_errbuf,     -- IN OUT
                        pn_retcode);   -- OUT

        IF pn_retcode != 0
        THEN
            RETURN;
        END IF;

        /************************ DETERMINATION DU CENTRE DE GESTION ******************************/
        Dka_Tools_Pkg.put_debug_message ('Détermination du centre de gestion');
        get_acct_area (pr_rec_line,  -- IN
                       pd_gl_date,   -- IN
                       pv_acct_area, -- OUT
                       pv_errbuf,    -- IN OUT
                       pn_retcode);  -- OUT

        IF pn_retcode != 0
        THEN
            RETURN;
        END IF;

        /************************ CONTROLE DES INFORMATIONS CLIENTS **************************/
        Dka_Tools_Pkg.put_debug_message ('Récupération des informations du client.');
        get_customer_info (
            pr_rec_line,          --IN
            pv_acct_area,         --IN
            pn_org_id,            --IN
            pn_cust_acct_site_id, --     OUT
            pn_cust_account_id,   --     OUT
            pv_partner_code,      --     OUT
            pv_errbuf,            --IN   OUT
            pn_retcode            --     OUT
        );

        IF pn_retcode != 0
        THEN
            RETURN;
        END IF;

        /****************************** DETERMINATION DES SEGMENTS **************************/
        Dka_Tools_Pkg.put_debug_message ('détermination des segments de la ligne CLIENT');
        get_ccid_ttc (
            pr_rec_line,      --IN
            pv_acct_area,     --IN
            pv_partner_code,  --IN
            pd_gl_date,       --IN
            pn_cust_acct_site_id,    --IN
            vv_segment1,      --    OUT
            vv_segment2,      --    OUT
            vv_segment3,      --    OUT
            vv_segment4,      --    OUT
            vv_segment5,      --    OUT
            vv_segment6,      --    OUT
            vv_segment7,      --    OUT
            vv_segment8,      --    OUT
            vv_segment9,      --    OUT      -- PHENIX 2004: Ajout.
            vv_segment10,     --    OUT      -- PHENIX 2004: Ajout.
            vv_segment11, --R12
            vv_segment12, --R12
            pv_errbuf,        --IN  OUT
            pn_retcode        --    OUT
        );

        IF pn_retcode != 0
        THEN
            RETURN;
        END IF;

        /************************* INSERTION DE LA CLE COMPTABLE *******************************/

        INSERT INTO ra_interface_distributions_all
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     interface_line_attribute3,
                     interface_line_attribute4,
                     interface_line_attribute5, -- (Modif EB21072004 PHENIX 2004)
                     account_class,
                     amount,
                     PERCENT,
                     interface_status,
                     code_combination_id,
                     segment1,
                     segment2,
                     segment3,
                     segment4,
                     segment5,
                     segment6,
                     segment7,
                     segment8,
                     segment9,           -- PHENIX 2004: Ajout.
                     segment10,          -- PHENIX 2004: Ajout.
                     segment11,
                     segment12,
                     org_id
                    )
        VALUES      ( -- RA_INTERFACE_DISTRIBUTIONS_ALL
                     'FACTURATION', -- Interface_Line_Context
                     pr_rec_line.origin, -- Interface_Line_Attribute1
                     pr_rec_line.company_code, -- Interface_Line_Attribute2
                     pr_rec_line.invoice_number, -- Interface_Line_Attribute3
                     '1', -- interface_line_attribute4 --tjs à 1 sinon ligne non comptabilisée ds OA
                     to_char(to_date(pd_gl_date,'DD/MM/YY'),'YYYYMM'), -- interface_line_attribute5   (Modif EB21072004 PHENIX 2004)
                     'REC', --account_class
                     NULL ,--amount
                     100, --percent
                     NULL, --interface_status
                     NULL, --code_combination_id
                     vv_segment1, --segment1
                     vv_segment2, --segment2
                     vv_segment3, --segment3
                     vv_segment4, --segment4
                     vv_segment5, --segment5
                     vv_segment6, --segment6
                     vv_segment7, --segment7
                     vv_segment8, --segment8
                     vv_segment9, --segment7           -- PHENIX 2004: Ajout.
                     vv_segment10, --segment8          -- PHENIX 2004: Ajout.
                     vv_segment11, --R12
                     vv_segment12, --R12
                     pn_org_id ); --org_id

        Dka_Tools_Pkg.put_debug_message (' ligne correctement insérée');
    EXCEPTION --load_invoice_header
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E005', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors des contrôles d''une ligne de facture'
            ); --texte message
    END load_invoice_header;
    -- PHENIX 2004: Fin modification procedure.

---------------------------------------------------------------------------------------------------------------
--  Nom           : set_tax_equal_flag
--  Description   : Procedure qui met a jour le champ tax_equal_flag de la table DKA_IARPAFAC_INTERFACE
--                   Ce flag repere sur une facture, les lignes de produit et de TVA qui peuvent etre relie
--                   directement (lignes de TVA non regroupes)
---------------------------------------------------------------------------------------------------------------
    PROCEDURE set_tax_equal_flag (
        pn_group_id         IN   dka_iarpafac_interface.GROUP_ID%TYPE,
        pv_origin           IN   dka_iarpafac_interface.origin%TYPE,
        pv_company_code     IN   dka_iarpafac_interface.company_code%TYPE,
        pv_invoice_number   IN   dka_iarpafac_interface.invoice_number%TYPE
    )
    IS
        CURSOR cur_lignes_produit
        IS
            SELECT iarpafac_id,
                   tax_code,
                   ROUND (fmt_amount * TO_NUMBER (tax_rate) / 10000, 1) montant
            FROM   dka_iarpafac_interface
            WHERE      GROUP_ID = pn_group_id
                   AND invoice_number = pv_invoice_number
                   AND company_code = pv_company_code
                   AND origin = pv_origin
                   AND line_type IN ('PRODUIT', 'SURTAXE')
                   AND tax_code IS NOT NULL
                   AND tax_code != '0';

        rec_lignes_produit   cur_lignes_produit%ROWTYPE;
        vn_ligne_tax_id      NUMBER;
    BEGIN
        FOR rec_lignes_produit IN cur_lignes_produit
        LOOP
            BEGIN
                SELECT iarpafac_id
                INTO   vn_ligne_tax_id
                FROM   dka_iarpafac_interface
                WHERE  1=1
                 AND GROUP_ID = pn_group_id
                 AND invoice_number = pv_invoice_number
                 AND company_code = pv_company_code
                 AND origin = pv_origin
                 AND line_type = 'GESTION'
                 AND tax_code = rec_lignes_produit.tax_code
                 AND ROUND (fmt_amount, 1) = rec_lignes_produit.montant
                 AND tax_equal_flag IS NULL
                 AND ROWNUM = 1;
            EXCEPTION
                WHEN NO_DATA_FOUND
                THEN
                    vn_ligne_tax_id    := NULL;
            END;

            IF vn_ligne_tax_id IS NOT NULL
            THEN
                UPDATE dka_iarpafac_interface
                SET    tax_equal_flag = 'Y'
                WHERE     iarpafac_id = vn_ligne_tax_id
                       OR iarpafac_id = rec_lignes_produit.iarpafac_id;
            END IF;
        END LOOP;
    END set_tax_equal_flag;
-->>Debut AAM artf07147612 EDB233
---------------------------------------------------------------------------------------------------------------
--  Nom           : create_ext_instrument
--  Description   : Création de l'extension d'instrument de règlement
--  PARAMETRES    : p_instrument_id
--                  p_client
--                  p_payment_channel
--  VALEUR RETOURNEE :identifiant de l'extension de réglement

---------------------------------------------------------------------------------------------------------------
    FUNCTION create_ext_instrument ( p_INSTRUMENT_PAYMENT_USE_ID   IN NUMBER
                                    , p_payment_channel             IN VARCHAR2
                                    , p_cust_account_id             IN NUMBER
                                    , p_account_site_id             IN NUMBER
                                    , p_org_id                      IN NUMBER
                                    , p_party_id                    IN NUMBER
									, p_payer_id                    IN NUMBER
                                    , p_invoice_number              IN VARCHAR2)
  RETURN NUMBER

    IS
    l_return_status           varchar2(1000);
    l_msg_count               number;
    l_msg_data                varchar2(4000);
    l_customer_context_rec    Iby_Fndcpt_Common_Pub.PayerContext_rec_type;
    l_TrxnExtension_rec_type  Iby_Fndcpt_Trxn_Pub.TrxnExtension_rec_type;
    l_Result_rec_type         Iby_Fndcpt_Common_Pub.Result_rec_type;
    l_trx_entity_id           NUMBER ;
	l_debit_auth_id           NUMBER;
	p_debtor_party_id         NUMBER;  

    BEGIN
	    begin
		    select party_id
			  into p_debtor_party_id
			  from hz_cust_accounts
             where cust_account_id = p_cust_account_id;
		
		EXCEPTION when  others then
			    Fnd_File.put_line(Fnd_File.LOG, 'ERROR : '||SQLERRM);
				Fnd_File.put_line (Fnd_File.OUTPUT, 'ERROR : '||SQLERRM);
		END;
		
		BEGIN
		-- EDB325 SELO	
			  select debit_authorization_id 
			   INTO l_debit_auth_id
			   from iby_debit_authorizations ida, iby_pmt_instr_uses_all ipiusa, hr_operating_units hou 
			   ,XLE_ENTITY_PROFILES xep --Ajout SHA KDFI-1496
			  where ida.external_bank_account_id = ipiusa.instrument_id 
				and ipiusa.instrument_type = 'BANKACCOUNT'
				and ipiusa.ext_pmt_party_id  = p_payer_id
				and ipiusa.instrument_payment_use_id = p_INSTRUMENT_PAYMENT_USE_ID
				and nvl(ida.auth_cancel_date,sysdate+10) > sysdate
				and nvl(ida.debit_auth_end,sysdate+10) > sysdate
				and ida.curr_rec_indi = 'Y'
				AND ida.DIRECT_DEBIT_MAX_COUNT IS null
				and hou.default_legal_context_id = ida.creditor_legal_entity_id
				AND xep.legal_entity_id = hou.default_legal_context_id--Ajout SHA KDFI-1496
                and ida.creditor_le_name =XEP.name --Ajout SHA KDFI-1496
				and hou.organization_id= p_org_id
				and ida.debtor_party_id = p_debtor_party_id;
		EXCEPTION when too_many_rows then
		        Fnd_File.put_line(Fnd_File.LOG, 'Problème pour récupérer le debit_authorization_id: '||p_INSTRUMENT_PAYMENT_USE_ID||' - '|| p_payer_id||'  - '||p_org_id);
				Fnd_File.put_line (Fnd_File.OUTPUT, 'Problème pour récupérer le debit_authorization_id: '||p_INSTRUMENT_PAYMENT_USE_ID||' - '|| p_payer_id||' - '||p_org_id);
			
			when others then
			    Fnd_File.put_line(Fnd_File.LOG, 'ERROR : '||SQLERRM);
				Fnd_File.put_line (Fnd_File.OUTPUT, 'ERROR : '||SQLERRM);
		END;
		
	
	-- EDB325 SELO FIN
	
    l_customer_context_rec.payment_function             := 'CUSTOMER_PAYMENT';
    l_customer_context_rec.Party_Id                     := p_party_id;
    l_customer_context_rec.Org_Type                     := 'OPERATING_UNIT';
    l_customer_context_rec.Org_Id                       := p_org_id;
    l_customer_context_rec.Cust_Account_Id              := p_cust_account_id;                  -- paying_customer_id
    l_customer_context_rec.Account_Site_Id              := p_account_site_id;                  -- paying_site_use_id
    l_TrxnExtension_rec_type.po_number                  := NULL;
    l_TrxnExtension_rec_type.po_line_number             := NULL;
    l_TrxnExtension_rec_type.instrument_security_code   := NULL;
    l_TrxnExtension_rec_type.voiceauth_flag             := NULL;
    l_TrxnExtension_rec_type.voiceauth_code             := NULL;
    l_TrxnExtension_rec_type.voiceauth_date             := NULL;
    l_TrxnExtension_rec_type.additional_info            := NULL;
    l_TrxnExtension_rec_type.seq_type_last              := 'N';
    l_TrxnExtension_rec_type.Originating_Application_Id := 222;
    l_TrxnExtension_rec_type.Order_Id := p_invoice_number; --Invoice number
    l_TrxnExtension_rec_type.Trxn_Ref_Number1 := 'TRANSACTION';
	
	
	l_TrxnExtension_rec_type.Debit_Authorization_Id := l_debit_auth_id; -- EDB325 SELO
    --Call Create_Transaction_Extension first

    fnd_file.put_line(fnd_file.LOG, 'Appel API Create Transaction Extension');

       IBY_FNDCPT_TRXN_PUB.Create_Transaction_Extension (
         p_api_version       => 1.0,
         p_init_msg_list     => Fnd_Api.G_true,
         p_commit            => Fnd_Api.G_true,
         x_return_status     => l_return_status,
         x_msg_count         => l_msg_count,
         x_msg_data          => l_msg_data,
         p_payer             => l_customer_context_rec,
         p_payer_equivalency => Iby_Fndcpt_Common_Pub.G_PAYER_EQUIV_UPWARD, --G_PAYER_EQUIV_FULL,
         p_pmt_channel       => p_payment_channel,
         p_instr_assignment  => p_INSTRUMENT_PAYMENT_USE_ID,                            -- INSTRUMENT_PAYMENT_USE_ID
         p_trxn_attribs      => l_TrxnExtension_rec_type,
         x_entity_id         => l_trx_entity_id,
         x_response          => l_Result_rec_type);

      IF l_return_status = fnd_api.g_ret_sts_success  THEN
        IF l_msg_count > 1 THEN
          FOR I IN 1 .. l_msg_count LOOP
           APPS.FND_MSG_PUB.GET(P_MSG_INDEX     => APPS.FND_MSG_PUB.G_NEXT,
                     P_ENCODED                  => APPS.FND_API.G_FALSE,
                     p_data                     => l_msg_data,
                     p_msg_index_out            => l_msg_count);
          END LOOP;
        END IF;

        dbms_output.put_line('instr ok '||l_trx_entity_id);

        Dka_Tools_Pkg.put_log_message ('l_return_status :' || l_return_status);
        dbms_output.put_line('l_return_status :' || l_return_status);

        Dka_Tools_Pkg.put_log_message ('l_msg_count = ' || l_msg_count) ;
        dbms_output.put_line('l_msg_count = ' || l_msg_count) ;

        Dka_Tools_Pkg.put_log_message('l_msg_data = ' || substr(l_msg_data,5)) ;
        dbms_output.put_line('l_msg_data = ' || substr(l_msg_data,5)) ;

        Dka_Tools_Pkg.put_log_message('l_cr_id  = ' || l_trx_entity_id  ) ;
        dbms_output.put_line('l_cr_id  = ' || l_trx_entity_id  ) ;
        RETURN l_trx_entity_id;
    ELSE

        IF l_msg_count > 1 THEN
          FOR I IN 1 .. l_msg_count LOOP
           APPS.FND_MSG_PUB.GET(P_MSG_INDEX     => APPS.FND_MSG_PUB.G_NEXT,
                     P_ENCODED                  => APPS.FND_API.G_FALSE,
                     p_data                     => l_msg_data,
                     p_msg_index_out            => l_msg_count);
          END LOOP;
        END IF;
        dbms_output.put_line('instr ko '|| l_trx_entity_id);
        DBMS_OUTPUT.put_line ('l_return_status :' || l_return_status);
        DBMS_OUTPUT.put_line('l_msg_count = ' || l_msg_count) ;
        DBMS_OUTPUT.put_line('l_msg_data = ' || l_msg_data) ;
        DBMS_OUTPUT.put_line('l_cr_id  = ' || l_trx_entity_id  ) ;
      RETURN null;
      END IF;
    EXCEPTION
      WHEN OTHERS THEN
       -- writelog('EXCEPTION lors de la créationde l''extension de réglement ' ||'-  ERR : '||SQLERRM,0,0);
       null;
    END  create_ext_instrument;
--<<Fin AAM artf07147612 EDB233
---------------------------------------------------------------------------------------------------------------
--  Nom           : load_invoice_line
--  Description   : Procédure de controle d'une ligne de facture et chargement dans
--                  les tables d'open interface AR : RA_INTERFACE_LINES_ALL
--                                              et : RA_INTERFACE_DISTRIBUTIONS_ALL
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004: Procedure modifiée.
    PROCEDURE load_invoice_line (
        pr_rec_line            IN       dka_iarpafac_interface%ROWTYPE,
        pn_line_num_cnt        IN       NUMBER,
        pn_link_to_line        IN       NUMBER,
        pn_cust_acct_site_id   IN       NUMBER,
        pn_cust_account_id     IN       NUMBER,
        pv_partner_code        IN       VARCHAR2,
        pv_acct_area           IN       VARCHAR2,
        pd_gl_date             IN       DATE,
        pd_gl_date_OI          IN       DATE,
        pv_typmvt              IN       VARCHAR2,
        pn_org_id              IN       NUMBER,
        pv_batch_source_name   IN       VARCHAR2,
        pn_project_id_majo     IN       NUMBER,
        pn_task_id_majo        IN       NUMBER,
        pv_indicage            IN       VARCHAR2,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        vn_project_id              NUMBER;
        vn_project_id_case_refac   NUMBER;
        vn_set_of_books_id         NUMBER;
        vn_task_id                 NUMBER;
        vn_task_id_case_refac      NUMBER;
        --vn_task_id_majo            NUMBER;
        --vn_project_id_majo         NUMBER;
        vn_tax_id                  NUMBER;
        vv_tax_code                VARCHAR2 (50);
        vv_tax_type                VARCHAR2 (30);
        vd_fmt_due_date            DATE;
        vn_fmt_amount              NUMBER;
        vv_segment1                VARCHAR2 (30);
        vv_segment2                VARCHAR2 (30);
        vv_segment3                VARCHAR2 (30);
        vv_segment4                VARCHAR2 (30);
        vv_segment5                VARCHAR2 (30);
        vv_segment6                VARCHAR2 (30);
        vv_segment7                VARCHAR2 (30);
        vv_segment8                VARCHAR2 (30);
        vv_segment9                VARCHAR2 (30);    -- PHENIX 2004: Ajout.
        vv_segment10               VARCHAR2 (30);    -- PHENIX 2004: Ajout.
        vv_segment11               VARCHAR2 (30); --R12 ajout des segments de réserve
        vv_segment12               VARCHAR2 (30); --R12 ajout des segments de réserve
        vv_attribute1              VARCHAR2 (30);
        vv_attribute2              VARCHAR2 (30);
        vv_attribute3              VARCHAR2 (30);
        vv_attribute4              VARCHAR2 (30);
        vv_attribute5              VARCHAR2 (30);
        vv_attribute6              VARCHAR2 (30);
        vv_attribute7              VARCHAR2 (30);
        vv_attribute8              VARCHAR2 (30);
        vv_attribute12             VARCHAR2 (30);
        vv_attribute_category      VARCHAR2 (30);
        vv_int_segment1            VARCHAR2 (30);
        vv_int_segment2            VARCHAR2 (30);
        vv_int_segment3            VARCHAR2 (30);
        vv_int_segment4            VARCHAR2 (30);
        vv_int_segment5            VARCHAR2 (30);
        vv_int_segment6            VARCHAR2 (30);
        vv_int_segment7            VARCHAR2 (30);
        vv_int_segment8            VARCHAR2 (30);
        vv_int_segment9            VARCHAR2 (30);    -- PHENIX 2004: Ajout.
        vv_int_segment10           VARCHAR2 (30);    -- PHENIX 2004: Ajout.
        vv_int_segment11           VARCHAR2 (30); --R12
        vv_int_segment12           VARCHAR2 (30); --R12
        vv_systeme_amont_x         VARCHAR2 (17);
        V_CONVERSION_RATE          NUMBER;
		v_payer_id                 NUMBER; -- EDB325 SELO
        vv_type                    ra_cust_trx_types_all.TYPE%TYPE; -- PHENIX 2004
    vn_currency_code           VARCHAR2 (3); -- artf07231300 SNK 03/04/2019 EDB241
    -->>Debt AAM artf07147612 EDB233
    v_PAYING_CUSTOMER_ID       NUMBER;
    v_PAYING_SITE_USE_ID       NUMBER;
    v_RECEIPT_METHOD_ID        AR_RECEIPT_METHODS.RECEIPT_METHOD_ID%TYPE;
    v_PAYMENT_TRXN_EXTENSION_ID  NUMBER;
    v_INSTRUMENT_PAYMENT_USE_ID  iby_pmt_instr_uses_all.INSTRUMENT_PAYMENT_USE_ID%TYPE;
    v_org_id                     HR_OPERATING_UNITS.organization_id%TYPE;
    v_party_id                   hz_cust_accounts.party_id%TYPE;

    --<<Fin AAM artf07147612 EDB233
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('>load_invoice_line');
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        --R12 récupération de l'id de la tâche et du projet majoritaire
        /* JJA 2017/08/23
          BEGIN
            SELECT pt.task_id, ppa.project_id
            INTO vn_task_id_majo, vn_project_id_majo
            FROM pa_tasks pt
            JOIN pa_projects_all ppa ON (pt.project_id = ppa.project_id)
            where task_number = pr_rec_line.segmentation;
          EXCEPTION
            WHEN NO_DATA_FOUND THEN
              vn_task_id_majo := NULL;
              vn_project_id_majo := NULL;
            WHEN TOO_MANY_ROWS THEN
              Dka_Tools_Pkg.put_debug_message ('plusieurs tâches existent avec ce code : ' || pr_rec_line.segmentation);
              raise;
          END;
         */

        -- PHENIX 2004
        BEGIN
          SELECT TYPE
          INTO   vv_type
          FROM   ra_cust_trx_types_all
          WHERE  name = pv_typmvt
          AND    ORG_ID = pn_org_id; --R12, on prend celui de l'organisation en cours.

        EXCEPTION WHEN NO_DATA_FOUND THEN
          Dka_Tools_Pkg.put_debug_message ('Type de mouvement inconnu : ' || pv_typmvt);
          RAISE;
        END;
        -- FIN PHENIX 2004

        --R12 PBR Récupération du set_of_books_id en fonction du company_code issu du fichier
        BEGIN
          SELECT ledger_id
          INTO vn_set_of_books_id
          FROM gl_ledgers
          WHERE SHORT_NAME = pr_rec_line.company_code;
        EXCEPTION
        WHEN NO_DATA_FOUND THEN
          Dka_Tools_Pkg.put_debug_message ('Le livre correspondant à la société : ' || pr_rec_line.company_code || ' n''existe pas');
          RAISE;
        END;

        /******************************** CONTROLE DES LIGNE DE PRODUIT ****************************/
        IF pr_rec_line.line_type = 'PRODUIT'
        THEN
            /************************* CONTROLE INFO PROJET *************************/
            -- R12 PBR RG7 détermination du type de traitement 'AR_REFAC' ou 'AR_NORMAL'
            Dka_Tools_Pkg.put_debug_message ('Vérification du projet');
            check_project (
                pr_rec_line, --IN
                pv_acct_area, --IN
                pn_org_id, --IN
                vn_project_id, --OUT
                vn_project_id_case_refac, --    OUT
                vn_task_id, --    OUT
                vn_task_id_case_refac, -- OUT
                --vn_project_appart      ,    --    OUT
                pv_errbuf, --IN  OUT
                pn_retcode
            ); --    OUT

            IF pn_retcode != 0
            THEN
                RETURN;
            END IF;
            Dka_Tools_Pkg.put_debug_message ('alimentation des segments de la clef.');
            /***************** DETERMINATION DES SEGMENTS LIGNE PRODUIT ***********************/
            -- RG9 on alimente les différents attibuts en fonction du type de traitement.
            get_ccid_attributes_line (
                pr_rec_line, --IN
                vn_project_id, --IN
                vn_project_id_case_refac, --IN
                vn_task_id, --IN
                vn_task_id_case_refac, --IN
                pn_cust_acct_site_id, --IN
                pv_acct_area , --IN
                pv_partner_code, --IN
                pd_gl_date, --IN
                vv_segment1, --OUT
                vv_segment2, --OUT
                vv_segment3, --OUT
                vv_segment4, --OUT
                vv_segment5, --OUT
                vv_segment6, --OUT
                vv_segment7, --OUT
                vv_segment8, --OUT
                vv_segment9, --OUT  -- PHENIX 2004: Ajout.
                vv_segment10,--OUT  -- PHENIX 2004: Ajout.
                vv_segment11, --OUT R12
                vv_segment12, --OUT R12
                vv_attribute1, --OUT
                vv_attribute2, --OUT
                vv_attribute3, --OUT
                vv_attribute4, --OUT
                vv_attribute5, --OUT
                vv_attribute6, --OUT
                vv_attribute7, --OUT
                vv_attribute8, --OUT
                vv_attribute12, --OUT
                vv_attribute_category, --OUT
                pv_errbuf, --IN OUT
                pn_retcode
            ); --OUT

            IF pn_retcode != 0
            THEN
                RETURN;
            END IF;

            /***************** VERIFICATION DE COHERENCE DES DONNEES ***********************/
                IF SUBSTR (pr_rec_line.local_account, 1, 1) = '6'
                THEN
                -- Modif GV20031024 : Ajout du TRUNC pour le passage de la date
                    -- RBE - MigrR12 procedure migree dans DKA_PA_TOOLS_PKG
                    DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_retcode,
                        pn_project_id                  => vn_project_id,
                        pn_tache_id                    => vn_task_id, -- R12 on se base sur l'id de la tâche.
                        pv_expenditure_type            => vv_attribute2,
                        pv_event_type                  => NULL,
                        pd_date                        => TRUNC(pd_gl_date_OI)--, -- Modif TB 26/09/2006
                        --pv_refac                       => 'N' -- RBE supprimé
                    );
                ELSE
                    -- RBE - MigrR12 procedure migree dans DKA_PA_TOOLS_PKG
                    DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_retcode,
                        pn_project_id                  => vn_project_id,
                        pn_tache_id                    => vn_task_id,  -- R12 on se base sur l'id de la tâche.
                        pv_expenditure_type            => NULL,
                        pv_event_type                  => vv_attribute2,
                        pd_date                        => TRUNC(pd_gl_date_OI)--, -- Modif TB 26/09/2006
                        --pv_refac                       => 'N' -- RBE supprimé
                    );
                END IF;

            IF pn_retcode != 0
            THEN
                Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                pn_retcode    := 1;
                Dka_Tools_Pkg.ins_prog_message (
                    gn_request_id,
                    'IARPAFAC',
                    'OA',
                    'DKA_IARPAFAC_INTERFACE',
                    pr_rec_line.iarpafac_id,
                    NULL,
                    NULL,
                    'E',
                    pv_errbuf
                );
                RETURN;
            END IF;

            -- En cas de refac, controle de coherence des donnees sur le projet à refacturer
            IF vn_project_id_case_refac IS NOT NULL
            THEN
                IF SUBSTR (pr_rec_line.local_account, 1, 1) = '6'
                THEN
                    -- Modif GV20031024 : Ajout d'un TRUNC pour le passage de la date
                    -- RBE - MigrR12 procedure migree dans DKA_PA_TOOLS_PKG
                    DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_retcode,
                        pn_project_id                  => vn_project_id_case_refac, -- R12 Projet d'origine déduit de la tâche présente dans le fichier
                        pn_tache_id                    => vn_task_id_case_refac, -- R12 Id de la tâche d'origine présente  dans le fichier.
                        pv_expenditure_type            => vv_attribute2,
                        pv_event_type                  => NULL,
                        pd_date                        => TRUNC(pd_gl_date_OI)--, -- Modif TB 26/09/2006
                        --pv_refac                       => 'Y' -- RBE Supprimé
                    );
                ELSE
                    -- RBE - MigrR12 procedure migree dans DKA_PA_TOOLS_PKG
                    DKA_PA_TOOLS_PKG.pa_check_transaction_data (
                        pv_errbuf                      => pv_errbuf,
                        pn_retcode                     => pn_retcode,
                        pn_project_id                  => vn_project_id_case_refac, -- R12 Projet d'origine déduit de la tâche présente dans le fichier
                        pn_tache_id                    => vn_task_id_case_refac, -- R12 Id de la tâche d'origine présente  dans le fichier.
                        pv_expenditure_type            => NULL,
                        pv_event_type                  => vv_attribute2,
                        pd_date                        => TRUNC(pd_gl_date_OI)--, -- Modif TB 26/09/2006
                        --pv_refac                       => 'Y' -- RBE supprimé
                    );
                END IF;

                IF pn_retcode != 0
                THEN
                    Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                    Dka_Tools_Pkg.put_debug_message ('>fin load_data');
                    pn_retcode    := 1;
                    Dka_Tools_Pkg.ins_prog_message (
                        gn_request_id,
                        'IARPAFAC',
                        'OA',
                        'DKA_IARPAFAC_INTERFACE',
                        pr_rec_line.iarpafac_id,
                        NULL,
                        NULL,
                        'E',
                        pv_errbuf
                    );
                    RETURN;
                END IF;
            END IF;


--------------------------------------------------------------------------
            IF pn_retcode != 0
            THEN
                RETURN;
            END IF;

---------------------------------------------------------------------------
        /******************************CONTROLE DES LIGNES DE TAXE *********************************/
        ELSIF pr_rec_line.line_type = 'GESTION'
        THEN
            /**************************** CONTROLE DE LA TVA ******************************/
            get_ar_tax (
                pr_rec_line, --IN
                pn_org_id, --IN
                pv_acct_area, --IN
                vn_tax_id, --   OUT
                vv_tax_code, --   OUT
                vv_tax_type, --   OUT
                pv_errbuf, --IN OUT
                pn_retcode
            ); --   OUT

            IF pn_retcode != 0
            THEN
                RETURN;
            END IF;

            /****************** DETERMINATION DES SEGMENTS LIGNES DE TAXE ***************/
            get_ccid_tax (
                pr_rec_line, --IN
                pv_acct_area, --IN
                pn_org_id, --IN
                vv_tax_code, --IN
                vv_tax_type, --IN
                vn_tax_id, --IN
                pd_gl_date, --IN
                vv_segment1, --   OUT
                vv_segment2, --   OUT
                vv_segment3, --   OUT
                vv_segment4, --   OUT
                vv_segment5, --   OUT
                vv_segment6, --   OUT
                vv_segment7, --   OUT
                vv_segment8, --   OUT
                vv_segment9, --   OUT  -- PHENIX 2004: Ajout.
                vv_segment10,--   OUT  -- PHENIX 2004: Ajout.
                vv_segment11, --OUT R12
                vv_segment12, --OUT R12
                vv_int_segment1, --   OUT
                vv_int_segment2, --   OUT
                vv_int_segment3, --   OUT
                vv_int_segment4, --   OUT
                vv_int_segment5, --   OUT
                vv_int_segment6, --   OUT
                vv_int_segment7, --   OUT
                vv_int_segment8, --   OUT
                vv_int_segment9, --   OUT   -- PHENIX 2004: Ajout.
                vv_int_segment10, --   OUT  -- PHENIX 2004: Ajout.
                vv_int_segment11, --OUT R12
                vv_int_segment12, --OUT R12
                pv_errbuf, --IN OUT
                pn_retcode
            ); --   OUT


--------------------------------------------------------------------------
            IF pn_retcode != 0
            THEN
                RETURN;
            END IF;
---------------------------------------------------------------------------
        /****************** DETERMINATION DES SEGMENTS LIGNES DE SURTAXE ***************/
        ELSIF pr_rec_line.line_type = 'SURTAXE'
        THEN
            -- si le compte local commence par 467 => il s'agit d'un cas de surtaxe

            get_ccid_surtaxe (
                pr_rec_line, --IN
                pv_acct_area, --IN
                pd_gl_date, --IN
                vv_segment1, --   OUT
                vv_segment2, --   OUT
                vv_segment3, --   OUT
                vv_segment4, --   OUT
                vv_segment5, --   OUT
                vv_segment6, --   OUT
                vv_segment7, --   OUT
                vv_segment8, --   OUT
                vv_segment9, --   OUT      -- PHENIX 2004: Ajout.
                vv_segment10, --   OUT     -- PHENIX 2004: Ajout.
                vv_segment11, --OUT R12
                vv_segment12, --OUT R12
                vv_attribute8, --OUT R12
                pv_errbuf, --    OUT
                pn_retcode
            ); --
--------------------------------------------------------------------------
            IF pn_retcode != 0
            THEN
                RETURN;
            END IF;
---------------------------------------------------------------------------
        END IF;

        -- contrôle de la date d'échéance (due_date)
        -- pour les mouvements AVOIR ou Annul AVOIR la due_date n'est pas renseignée
        -- (modification edu 18/6/02)
        -- controle du signe du montant, savoir si montant est + ou - selon le type de mouvement
        --   et selon le signe de la ligne

        --RG20 : signe du montant en fonction du type de mouvement
        IF vv_type = 'CM' -- PHENIX 2004 : Utilisation de la classe du type de mouvement
        THEN
            vd_fmt_due_date    := NULL;
            vn_fmt_amount    := pr_rec_line.fmt_amount * (-1); -- * to_number(pr_rec_line.sign||'1');
        ELSE
            vd_fmt_due_date    := pr_rec_line.fmt_due_date;
            vn_fmt_amount    := pr_rec_line.fmt_amount; -- * to_number(pr_rec_line.sign||'1');
        END IF;

        --R12

    --Début artf07231300 SNK 03/04/2019 EDB241
    BEGIN
          SELECT currency_code
          INTO vn_currency_code
          FROM gl_ledgers
          WHERE SHORT_NAME = pr_rec_line.company_code;
        END;


    IF pr_rec_line.currency != 'EUR' AND  vn_currency_code != pr_rec_line.currency THEN  --FIN artf07231300 SNK 03/04/2019 EDB241
          BEGIN
            SELECT CONVERSION_RATE
            INTO V_CONVERSION_RATE
            FROM GL_DAILY_RATES_V
            WHERE 1=1
            AND USER_CONVERSION_TYPE = 'COMPTABLE'
            AND TO_CURRENCY = 'EUR'
            AND FROM_CURRENCY = PR_REC_LINE.CURRENCY
            AND CONVERSION_DATE = PR_REC_LINE.FMT_INVOICE_DATE;

          EXCEPTION WHEN NO_DATA_FOUND THEN
            Dka_Tools_Pkg.put_debug_message ('Taux par defaut introuvable pour devise : ' || pr_rec_line.currency);
            RAISE; -- il faut rejeté la facture si la devise en entrée ne correspond pas.
          END;
        END IF;

    -->>Debut AAM artf07147612 EDB233
    IF pr_rec_line.RECEIPT_METHOD = 'PRELEVT' THEN
          v_PAYING_CUSTOMER_ID       := pn_cust_account_id;

          SELECT u.site_use_id into v_PAYING_SITE_USE_ID
          FROM hz_cust_site_uses_all  u,
               hz_cust_acct_sites_all s,
               hz_cust_accounts       a
         WHERE (a.cust_account_id = pn_cust_account_id)
           AND (u.cust_acct_site_id = s.cust_acct_site_id)
           AND (s.cust_account_id = a.cust_account_id)
           AND s.cust_acct_site_id = pn_cust_acct_site_id;

          --v_PAYING_SITE_USE_ID       := pn_cust_acct_site_id;
          -- determination de la variable v_RECEIPT_METHOD_ID
        BEGIN
          SELECT RECEIPT_METHOD_ID
        INTO   v_RECEIPT_METHOD_ID
        FROM   AR_RECEIPT_METHODS
        WHERE  NAME = 'PRELEVT';
        EXCEPTION
              WHEN OTHERS THEN
                  v_RECEIPT_METHOD_ID := 1000;
        END ;

        -- determination de la variable v_PAYMENT_TRXN_EXTENSION_ID ;
        -- Recherche de l'instrument de règlement
        IF (pr_rec_line.origin != nvl(gv_origin, pr_rec_line.origin) OR
            pr_rec_line.company_code != nvl(gv_company_code, pr_rec_line.company_code) OR
            pr_rec_line.invoice_number !=  nvl(gv_invoice_number, pr_rec_line.invoice_number)) THEN

            fnd_file.put_line(fnd_file.LOG, 'Recherche instrument reglement : '||pr_rec_line.REGION||pr_rec_line.company_code ||'/'||pn_cust_account_id); -- JWYC

        BEGIN
          SELECT acc_instr.INSTRUMENT_PAYMENT_USE_ID, hou.organization_id, ext_payer.ext_payer_id
            INTO v_INSTRUMENT_PAYMENT_USE_ID, v_org_id, v_payer_id
            FROM iby_pmt_instr_uses_all  acc_instr,
                 iby_external_payers_all ext_payer,
                 HR_OPERATING_UNITS      hou
           WHERE 1 = 1
             AND acc_instr.ext_pmt_party_id = ext_payer.ext_payer_id
             AND acc_instr.payment_function = 'CUSTOMER_PAYMENT' -- JWYC
             AND ext_payer.payment_function = 'CUSTOMER_PAYMENT'
             AND hou.organization_id = ext_payer.ORG_ID
             AND hou.NAME(+) = pr_rec_line.REGION || pr_rec_line.company_code
             AND ext_payer.cust_account_id = pn_cust_account_id
             AND ext_payer.acct_site_use_id = v_PAYING_SITE_USE_ID -- JWYC 30/10/2020 INC0474541
             AND acc_instr.order_of_preference =
                 (SELECT min(order_of_preference)
                    FROM iby_pmt_instr_uses_all
                   WHERE ext_pmt_party_id = acc_instr.ext_pmt_party_id
                     AND payment_function = acc_instr.payment_function);
        EXCEPTION
              WHEN OTHERS THEN
                fnd_file.put_line(fnd_file.LOG, 'Erreur '||SQLERRM);
				
			--	fnd_file.put_line(fnd_file.LOG, 'Erreur EDB325 '||pr_rec_line.REGION || pr_rec_line.company_code || ' v_PAYING_SITE_USE_ID =' || v_PAYING_SITE_USE_ID || ' pn_cust_account_id= '|| pn_cust_account_id  ); 
                  v_INSTRUMENT_PAYMENT_USE_ID := null;
        END;
        BEGIN
          SELECT party_id
        INTO  v_party_id
        FROM  hz_cust_accounts
        WHERE cust_account_id = pn_cust_account_id;
        END;

        --Création de l'extension d'instrument de règlement --API IBY_FNDCPT_TRXN_PUB.CREATE_TRANSACTION_EXTENSION
          v_PAYMENT_TRXN_EXTENSION_ID := create_ext_instrument (   p_INSTRUMENT_PAYMENT_USE_ID => v_INSTRUMENT_PAYMENT_USE_ID
                                                                     , p_payment_channel           => 'BANK_ACCT_XFER'
                                                                     , p_cust_account_id           =>  pn_cust_account_id
                                                                     , p_account_site_id           =>  v_PAYING_SITE_USE_ID
                                                                     , p_org_id                    =>  v_org_id
                                                                     , p_party_id                  =>  v_party_id
																	 , p_payer_id                  =>  v_payer_id
                                                                     , p_invoice_number            =>  pr_rec_line.invoice_number);


       fnd_file.put_line(fnd_file.LOG, 'v_PAYMENT_TRXN_EXTENSION_ID : '||v_PAYMENT_TRXN_EXTENSION_ID);


       INSERT INTO dka_iarpafac_prelev_tmp
         (origin,
          company_code,
          invoice_number,
          receipt_method_id,
          paying_customer_id,
          paying_site_use_id,
          payment_trxn_extension_id,
          oa_status)
       VALUES
         (pr_rec_line.origin,
          pr_rec_line.company_code,
          pr_rec_line.invoice_number,
          v_RECEIPT_METHOD_ID,
          v_PAYING_CUSTOMER_ID,
          v_PAYING_SITE_USE_ID,
          v_PAYMENT_TRXN_EXTENSION_ID,
          'P');

    /*
      ELSE
      fnd_file.put_line(fnd_file.LOG, 'ON FORCE A NULL'); --JWYC

        v_PAYMENT_TRXN_EXTENSION_ID:= null;
        v_PAYING_CUSTOMER_ID       := null;
        v_PAYING_SITE_USE_ID       := null;


    */

      END IF;

    END IF;

    gv_origin := pr_rec_line.origin ;
    gv_company_code := pr_rec_line.company_code ;
    gv_invoice_number := pr_rec_line.invoice_number;


        --<<Fin AAM artf07147612 EDB233
        /*********************** INSERTION DES DONNÉES VALIDES DANS AR INTERFACE ***************/
        Dka_Tools_Pkg.put_debug_message ('>insertion RA_INTERFACE_LINES_ALL');

        INSERT INTO ra_interface_lines_all
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     interface_line_attribute3,
                     interface_line_attribute4,
                     interface_line_attribute5, -- (Modif EB21072004 PHENIX 2004)
                     batch_source_name,
                     set_of_books_id,
                     line_type,
                     description,
                     currency_code,
                     amount,
                     cust_trx_type_name,
                     term_name,
                     term_id,
                     orig_system_bill_customer_ref,
                     orig_system_bill_customer_id,
                     orig_system_bill_address_ref,
                     orig_system_bill_address_id,
                     orig_system_ship_customer_ref,
                     orig_system_ship_address_ref,
                     link_to_line_context,
                     link_to_line_attribute1,
                     link_to_line_attribute2,
                     link_to_line_attribute3,
                     link_to_line_attribute4,
                     link_to_line_attribute5,
                     conversion_type,
                     conversion_date,
                     conversion_rate,
                     trx_date,
                     gl_date,
                     trx_number,
                     line_number,
                     tax_rate,
                     tax_rate_code,--tax_code, R12
                     tax_code, --R12
                     taxable_flag, --R12
                     ship_date_actual,
                     sales_order_date,
                     comments,
                     internal_notes,
                     header_attribute_category,
                     header_attribute1,
                     header_attribute2,
                     header_attribute3,
                     header_attribute4,
                     header_attribute10, --R12
                     header_attribute11, --R12
                     attribute9,
                     attribute10,
                     last_updated_by,
                     last_update_date,
                     last_update_login,
                     tax_exempt_flag,
                     created_by,
                     creation_date,
                     org_id,
                     amount_includes_tax_flag,
                     reference_line_context,
                     reference_line_attribute1,
                     reference_line_attribute2,
                     reference_line_attribute3,
                     reference_line_attribute4,
                     purchase_order,
                     quantity --R12 RG6
           -->> Debut AAM artf07147612 EDB233
           --          ,PAYING_CUSTOMER_ID
           --          ,PAYING_SITE_USE_ID
           --          ,RECEIPT_METHOD_ID
           --          ,PAYMENT_TRXN_EXTENSION_ID
            --<< Fin AAM artf07147612 EDB233
                    )
        VALUES      ( -- RA_INTERFACE_LINES_ALL
                     'FACTURATION',               -- Interface_Line_Context
                     pr_rec_line.origin,          -- Interface_Line_Attribute1
                     pr_rec_line.company_code,    -- Interface_Line_Attribute2
                     pr_rec_line.invoice_number,  -- Interface_Line_Attribute3
                     TO_CHAR (pn_line_num_cnt),   -- Interface_Line_Attribute4
                     to_char(to_date(pd_gl_date,'DD/MM/YY'),'YYYYMM'), -- interface_line_attribute5  (Modif EB21072004 PHENIX 2004)
                     pv_batch_source_name,        -- Batch_Source_Name
                     vn_set_of_books_id, --1,    Modif R12.
                     DECODE (pr_rec_line.line_type, 'PRODUIT', 'LINE', 'GESTION', 'TAX', 'SURTAXE', 'LINE'), -- Line_Type
                     pr_rec_line.description,     -- Description
                     pr_rec_line.currency,        --'EUR',                       -- Currency_Code
                     vn_fmt_amount,               -- Amount
                     pv_typmvt,                   -- Cust_Trx_Type_Name
                     NULL,                        -- Term_Name
                     DECODE (vv_type,'CM', TO_CHAR(NULL), gn_term_id), -- term_id
                     NULL,                        -- Orig_System_Bill_Customer_Ref
                     pn_cust_account_id,          -- Orig_System_Bill_Customer_id
                     NULL,                        -- Orig_System_Bill_Address_ref
                     pn_cust_acct_site_id,        -- Orig_System_Bill_Address_id
                     NULL,                        -- Orig_System_Ship_Customer_Ref
                     NULL,                        -- Orig_System_Ship_Address_Ref
                     DECODE(pr_rec_line.line_type, 'GESTION', 'FACTURATION', TO_CHAR (NULL)),              -- Link_To_Line_Context
                     DECODE(pr_rec_line.line_type, 'GESTION', pr_rec_line.origin, TO_CHAR (NULL)),         -- Link_To_Line_Attribute1
                     DECODE(pr_rec_line.line_type, 'GESTION', pr_rec_line.company_code, TO_CHAR (NULL)),   -- Link_To_Line_Attribute2
                     DECODE(pr_rec_line.line_type, 'GESTION', pr_rec_line.invoice_number, TO_CHAR (NULL)), -- Link_To_Line_Attribute3
                     DECODE(pr_rec_line.line_type, 'GESTION', TO_CHAR (pn_link_to_line), TO_CHAR (NULL)),  -- Link_To_Line_Attribute4
                     DECODE(pr_rec_line.line_type, 'GESTION', TO_CHAR(to_date(pd_gl_date,'DD/MM/YY'),'YYYYMM'), TO_CHAR (NULL)), -- Link_To_Line_Attribute5 -- CDE 210705
                     DECODE(pr_rec_line.currency, vn_currency_code, 'User', 'Comptable'),                              -- Conversion_type R12 RG1BIS
                     DECODE(pr_rec_line.currency, vn_currency_code, NULL, to_char(to_date(pd_gl_date,'DD/MM/YY'),'YYYYMM')), -- Convertion_date R12 RG1BIS                         ,
                     DECODE(pr_rec_line.currency, vn_currency_code, 1, V_CONVERSION_RATE),                             -- Convertion_rate R12 RG1BIS
                     pr_rec_line.fmt_invoice_date, -- Trx_Date
                     DECODE (pr_rec_line.line_type, 'PRODUIT', pd_gl_date_OI, 'SURTAXE', pd_gl_date_OI, NULL), -- Gl_Date (Modif GV20040112)
                     pr_rec_line.invoice_number,   -- Trx_Number
                     NULL, --pn_line_num_cnt                              -- Line_number
                     NULL, --)                                 -- Tax_Rate
                     DECODE (pr_rec_line.line_type, 'GESTION', vv_tax_code, NULL), -- Tax_rate_Code -- RG22Bis
                     VV_TAX_CODE,--DECODE (pr_rec_line.line_type, 'PRODUIT', vv_tax_code, NULL), -- Tax_Code -- RG22Bis
                     DECODE(pr_rec_line.line_type, 'PRODUIT', 'N', NULL),
                     DECODE (pr_rec_line.line_type, 'PRODUIT', vd_fmt_due_date, 'SURTAXE', vd_fmt_due_date, NULL), -- Ship_date_actual
                     NULL, -- Sales_order_date
                     DECODE (pv_indicage, NULL, NULL, 'Mvt lié : ' || pv_indicage), --commentaire Modif  CDE 02/02/2012
                     NULL,                      -- internal_notes
                     'FACTURATION',             -- header_attribute_category
                     pr_rec_line.origin,        -- header_attribute1
                     pr_rec_line.company_code,  -- header_attribute2
                     pr_rec_line.invoice_number, -- header_attribute3
                                               --,TO_CHAR(pn_line_num_cnt)
                                               --,pr_rec_line.line_number                      -- header_attribute4
                     DECODE (pr_rec_line.line_type, 'GESTION', 2, 1), -- header_attribute4
                     pn_task_id_majo, --pn_project_id_majo,        -- header_attribute10 -- R12 (RG21)
                     pn_project_id_majo,        --header_attribute11 R12 (RG21)
                     pr_rec_line.origin,        -- attribute9 RG4
                     pr_rec_line.fic_ident,     -- attribute10
                     NULL,                      -- Last_updated_by
                     NULL,                      -- Last_update_date
                     NULL,                      -- Last_Update_Login
                     DECODE (pr_rec_line.line_type, 'GESTION', 'S', TO_CHAR (NULL)), -- tax_exempt_flag                                                                                   ,
                     NULL,                      -- Created_by
                     NULL,                      -- Creation_date
                     pn_org_id,                 -- Org_Id
                     NULL,                      -- Amount_includes_tax_flag
                     NULL,                      --'FACTURATION'                               --reference_line_context
                     NULL,                      --pr_rec_line.origin                           --reference_line_attribute1
                     NULL,                      --pr_rec_line.company_code                    --reference_line_attribute2
                     NULL,                      --pv_indicage                                  --reference_line_attribute3
                     NULL,                      --'1'                                         --reference_line_attribute4
                     SUBSTR(pr_rec_line.comments,1,50),       -- purchase order MODIF CDEF
                     pr_rec_line.quantity       -- R12 PBR RG6
           -->>Debut AAM artf07147612 EDB233
           --          ,v_PAYING_CUSTOMER_ID
           --          ,v_PAYING_SITE_USE_ID
           --          ,v_RECEIPT_METHOD_ID
           --          ,v_PAYMENT_TRXN_EXTENSION_ID
           --<<Fin AAM  artf07147612 EDB233
                    );
					

        Dka_Tools_Pkg.put_debug_message ('>insertion RA_INTERFACE_DISTRIBUTIONS_ALL');
        INSERT INTO ra_interface_distributions_all
                    (interface_line_context,
                     interface_line_attribute1,
                     interface_line_attribute2,
                     interface_line_attribute3,
                     interface_line_attribute4,
                     interface_line_attribute5,
                     account_class,
                     amount,
                     PERCENT,
                     interface_status,
                     code_combination_id,
                     segment1,
                     segment2,
                     segment3,
                     segment4,
                     segment5,
                     segment6,
                     segment7,
                     segment8,
                     segment9,           -- PHENIX 2004: Ajout.
                     segment10,          -- PHENIX 2004: Ajout.
                     segment11, --R12
                     segment12, --R12
                     attribute_category, --R12
                     attribute1,
                     attribute2,
                     attribute3,
                     attribute4,
                     attribute5,
                     attribute6,
                     attribute7,
                     attribute8,
                     attribute12,
                     org_id,
                     interim_tax_segment1,
                     interim_tax_segment2,
                     interim_tax_segment3,
                     interim_tax_segment4,
                     interim_tax_segment5,
                     interim_tax_segment6,
                     interim_tax_segment7,
                     interim_tax_segment8,
                     interim_tax_segment9,     -- PHENIX 2004: Ajout.
                     interim_tax_segment10,     -- PHENIX 2004: Ajout.
                     interim_tax_segment11, --R12
                     interim_tax_segment12  --R12
                    )
        VALUES      ( -- RA_INTERFACE_DISTRIBUTIONS_ALL
                     'FACTURATION', -- Interface_Line_Context
                     pr_rec_line.origin, -- Interface_Line_Attribute1
                     pr_rec_line.company_code, -- Interface_Line_Attribute2
                     pr_rec_line.invoice_number, -- Interface_Line_Attribute3
                     pn_line_num_cnt, -- interface_line_attribute4
                     to_char(to_date(pd_gl_date,'DD/MM/YY'),'YYYYMM'), -- interface_line_attribute5
                     DECODE (pr_rec_line.line_type, 'PRODUIT', 'REV', 'GESTION', 'TAX', 'SURTAXE', 'REV', NULL), --account_class
                     vn_fmt_amount, --amount
                     NULL, --percent
                     NULL, --interface_status
                     NULL, --code_combination_id
                     vv_segment1, --segment1
                     vv_segment2 ,--segment2
                     vv_segment3, --segment3
                     vv_segment4, --segment4
                     vv_segment5, --segment5
                     vv_segment6, --segment6
                     vv_segment7, --segment7
                     vv_segment8, --segment8
                     vv_segment9, --segment9       -- PHENIX 2004: Ajout.
                     vv_segment10, --segment10     -- PHENIX 2004: Ajout.
                     vv_segment11, --R12
                     vv_segment12, --R12
                     vv_attribute_category, --R12
                     vv_attribute1, --attribute1
                     vv_attribute2, --attribute2
                     vv_attribute3, --attribute3
                     vv_attribute4, --attribute4
                     vv_attribute5, --attribute5
                     vv_attribute6, --attribute6
                     vv_attribute7, --attribute7
                     vv_attribute8, --attribute8
                     vv_attribute12, --R12 RG11-1
                     pn_org_id, --org_id
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment1, NULL), --interim_tax_segment1
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment2, NULL), --interim_tax_segment2
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment3, NULL), --interim_tax_segment3
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment4, NULL), --interim_tax_segment4
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment5, NULL), --interim_tax_segment5
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment6, NULL), --interim_tax_segment6
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment7, NULL), --interim_tax_segment7
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment8, NULL), --interim_tax_segment8
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment9, NULL), --interim_tax_segment9              -- PHENIX 2004: Ajout.
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment10, NULL), --interim_tax_segment10             -- PHENIX 2004: Ajout.
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment11, NULL), --interim_tax_segment9             -- PHENIX 2004: Ajout.
                     DECODE (pr_rec_line.local_account, '445715', vv_int_segment12, NULL) --interim_tax_segment10             -- PHENIX 2004: Ajout.
                    );
				
        Dka_Tools_Pkg.put_debug_message (' ligne correctement insérée');
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E006', 'ERROR', SQLERRM); -- PHENIX 2004 : Code du message incorrect
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'Une erreur est survenue lors des contrôles d''une ligne de facture'
            ); --texte message
    END load_invoice_line;
    -- PHENIX 2004: Fin procedure modifiée.


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_acct_area
--  Description   : n
--Procédure qui détermine le centre de gestion à partir du type d'info et du champs segmentatio
--  PARAMETRES    :
--  R12 : Obsoléte
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE get_acct_area (
        pr_rec_line    IN       dka_iarpafac_interface%ROWTYPE,
        pd_date        IN       DATE,
        pv_acct_area   OUT      VARCHAR2,
        pv_errbuf      IN OUT   VARCHAR2,
        pn_retcode     OUT      NUMBER
    )
    IS
        vv_segmentation   VARCHAR2 (30);
        vv_errbuf         VARCHAR2 (200);
        vn_retcode        NUMBER;
        vn_info_type      NUMBER;
    BEGIN
        --si info_type = 1 => segmentation contient le code etablissement ANAEL, une transco est
        --nécessaire pour determiner le centre de gestion (acct_area) dans OA


        IF SUBSTR (pr_rec_line.local_account, 1, 1) IN ('6', '7')
        THEN
            vn_info_type                := 3;
            --vv_segmentation             := pr_rec_line.project_code; -- R12 PBR Le champ project_code n'existe plus
            vv_segmentation             := pr_rec_line.task_code;

            BEGIN -- OBE artf2209666
            --Ici on doit déterminer le centre de gestion en fonction du code tâche. R12.
              SELECT substr(hou.NAME, 1, 3)
              INTO pv_acct_area
              FROM hr_operating_units hou
              JOIN pa_projects_all ppa ON (ppa.org_id = hou.organization_id)
              JOIN pa_tasks pt ON (pt.project_id = ppa.project_id)
              WHERE pt.task_number = pr_rec_line.task_code;
            --< OBE artf2209666
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                  pv_errbuf     := Dka_Tools_Pkg.get_message (
                                       'DKA',
                                       'DKA_IARPAFAC_E009',
                                       'ERROR',
                                       SQLERRM,
                                       'INV_NUM',
                                       pr_rec_line.invoice_number,
                                       'ORIGINE',
                                       pr_rec_line.origin,
                                       'COMPANY',
                                       pr_rec_line.company_code,
                                       'TASK_CODE', --R12
                                       pr_rec_line.task_code --R12
                                   );
                  Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                  --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
                  Dka_Tools_Pkg.ins_prog_message (
                      gn_request_id, --N°traitement
                      'IARPAFAC', --Non interface
                      'OA', --Source
                      'DKA_IARPAFAC_INTERFACE', --Table
                      pr_rec_line.iarpafac_id, --ID explicite
                      NULL, --Non colonne en question
                      NULL, --valeur colonne
                      'E', --Erreur ou Warning
                      'Le code tâche ' || pr_rec_line.task_code || ' est invalide' --R12
                  ); --texte message
                  pn_retcode    := 1;
            END;
            --> OBE artf2209666

        ELSIF pr_rec_line.fmt_info_type = 1
        THEN

            vn_info_type       := pr_rec_line.fmt_info_type;
            vv_segmentation    := Dka_Stransco_Pkg.get_value_f ('DKA_ETAB_CG', pr_rec_line.fmt_invoice_date, pv_errbuf, pr_rec_line.segmentation);

            IF vv_segmentation IS NULL
            THEN
                pv_errbuf     := Dka_Tools_Pkg.get_message (
                                     'DKA',
                                     'DKA_IARPAFAC_E008',
                                     'INV_NUM',
                                     pr_rec_line.invoice_number,
                                     'ORIGINE',
                                     pr_rec_line.origin,
                                     'COMPANY',
                                     pr_rec_line.company_code
                                 );
                Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                Dka_Tools_Pkg.ins_prog_message (
                    gn_request_id,
                    'IARPAFAC',
                    'OA',
                    'DKA_IARPAFAC_INTERFACE',
                    pr_rec_line.iarpafac_id, --ID explicite
                    'SEGMENTATION',
                    pr_rec_line.segmentation,
                    'E',
                    'Impossible d''extraire les informations concernant le cdg'
                );
                pn_retcode    := 1;
                RETURN;
            END IF;

            pv_acct_area :=  vv_segmentation; --R12
        ELSE

            vn_info_type       := pr_rec_line.fmt_info_type;
            vv_segmentation    := pr_rec_line.segmentation; --le centre de gestion est contenu dans le champ segmentation

            pv_acct_area := vv_segmentation; --R12
        END IF;

        --on affecte vv_segmentation à get_acct_area_interface en entrée et on ressort vv_acct_area
        --qui sera le centre de gestion pour toute les lignes de la facture

  -- Modif GV20031024 : Ajout d'un TRUNC à pd_date pour comparaison au même niveau de format date
    -- RBE MigR12
  /*
        Dka_Ibdsoc_Tools_Pkg.get_acct_area_interface (
            pr_rec_line.company_code,
            --pr_rec_line.fmt_info_type,
            vn_info_type,
            vv_segmentation,
            TRUNC(pd_date),
            pv_acct_area,
            vv_errbuf,
            vn_retcode
        );
*/

------------------------------------------------------------------------------------
        IF vn_retcode != 0
        THEN
            pv_errbuf    := Dka_Tools_Pkg.get_message (
                                'DKA',
                                'DKA_IARPAFAC_E007',
                                'INV_NUM',
                                pr_rec_line.invoice_number,
                                'ORIGINE',
                                pr_rec_line.origin,
                                'COMPANY',
                                pr_rec_line.company_code
                            );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            Dka_Tools_Pkg.put_debug_message (vv_errbuf); --affichage .log
            ---- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'le centre de gestion n''a pas pu être déterminé'
            ); --texte message
            RETURN;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('  centre de gestion : '|| pv_acct_area);
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E009', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'une erreur est survenue lors de la MAJ du centre de gestion'
            ); --texte message
    END get_acct_area;


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ar_gl_date
--  Description   : Procédure de transcodage de la date GL
--                  Le mois de invoice_date est comparé au mois de gl_date
--                  selon qu'il soit : IDENTIQUE  => pd_gl_date := SYSDATE
--                           ou bien : ANTÉRIEUR  => pd_gl_date := 1er jour de la periode ouverte en cours
--                           ou bien : POSTÉRIEUR => pd_gl_date := RAISE e_error
--
--                  Si aucune période AR n'est ouverte => rejet de la facture
--                  L'exception NO_DATA_FOUND gére l'insertion et l'affichage du message d'erreur
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     Description       : pd_gl_date
--                         pd_gl_date_OI
--     Valeurs possibles : DATE
---------------------------------------------------------------------------------------------------------------
    PROCEDURE get_ar_gl_date (
        pr_rec_line   IN       dka_iarpafac_interface%ROWTYPE,
        pd_gl_date    OUT      DATE,
        pd_gl_date_OI OUT      DATE,
        pn_sob_id     IN       NUMBER,
        pv_errbuf     IN OUT   VARCHAR2,
        pn_retcode    OUT      NUMBER
    )
    IS
        vd_p_start     DATE; --date d'ouverture de la période AR ouvertes
        vd_p_end       DATE; --date de fermeture de la période AR ouvertes
        e_error_period EXCEPTION;

    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        -- Modif GV20031212 : Changement du calcul de la date comptable => on se base sur la date comptable du AF
        --
        SELECT MAX(start_date), Max(end_date)
        INTO   vd_p_start, vd_p_end
        FROM   gl_period_statuses
        WHERE  closing_status = 'O'
           AND set_of_books_id = pn_sob_id--Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID')
           AND application_id = 222;

        pd_gl_date := vd_p_end; -- Date pd_gl_date -> dernier jour de la période AR ouverte

        -- RG22 Calcul de la date GL.

        --  03/01/2019 NBO artf3057680 : INC0277073 Factures clients sont en rejets dans la table spécifique
        --IF (to_number(extract(month FROM pr_rec_line.fmt_invoice_date)) = to_number(substr(pr_rec_line.gl_date,5,2)) ) THEN -- YWA artf2143664  -- CAS A
        IF (to_number(to_char(pr_rec_line.fmt_invoice_date,'YYYYMM')) = to_number(pr_rec_line.gl_date)) THEN
          pd_gl_date :=  TRUNC(SYSDATE);
          pd_gl_date_OI := TRUNC(SYSDATE);
        ELSE
          --IF (to_number(extract(month FROM pr_rec_line.fmt_invoice_date)) < to_number(substr(pr_rec_line.gl_date,5,2) )) THEN -- YWA artf2143664  -- CAS B
          IF ((to_number(to_char(pr_rec_line.fmt_invoice_date,'YYYYMM')) < to_number(pr_rec_line.gl_date) )) THEN -- YWA artf2143664  -- CAS B
            --IF (to_number(extract(month FROM pd_gl_date)) = to_number(substr(pr_rec_line.gl_date,5,2))) THEN -- YWA artf2143664  -- CAS B1
            IF (to_number(to_char(pd_gl_date,'YYYYMM')) = to_number(pr_rec_line.gl_date)) THEN -- YWA artf2143664  -- CAS B1
              pd_gl_date    := vd_p_start;
              pd_gl_date_OI := TRUNC(SYSDATE);
            ELSE
              RAISE e_error_period;
            END IF;
          ELSE  -- CAS B2
            RAISE e_error_period;
          END IF;
        END IF;

        -- Modif GV20040112 : La date comptable GL pour l'Open Interface est SYSDATE si SYSDATE est dans la
        --                    période AR ouverte
        --
        --Modification R12 PBR
        /*IF TRUNC(SYSDATE) BETWEEN vd_p_start AND vd_p_end
        THEN
           pd_gl_date_OI := TRUNC(SYSDATE);
        ELSE
           pd_gl_date_OI := pd_gl_date;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('      Date comptable AF : '|| pr_rec_line.gl_date);
        --
        -- La période comptable de la ligne ne peut pas être postérieure à la période GL ouverte
        IF TO_NUMBER(pr_rec_line.gl_date) > TO_NUMBER(TO_CHAR(pd_gl_date, 'YYYYMM'))
        THEN
          RAISE e_error_period ;
        END IF;*/

        Dka_Tools_Pkg.put_debug_message ('      Date comptable GL : '|| pd_gl_date);
        Dka_Tools_Pkg.put_debug_message ('      Date comptable GL pour OI : '|| pd_gl_date_OI);
        pn_retcode    := 0;

    EXCEPTION
        WHEN e_error_period
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E035');

            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                'GL_DATE', --Non colonne en question
                pr_rec_line.gl_date, --valeur colonne
                'E', --Erreur ou Warning
                'La période comptable de la pièce est postérieure à la période comptable AR ouverte' --texte message
            );
            pn_retcode    := 1;
        WHEN TOO_MANY_ROWS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E011', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'plusieurs périodes AR sont ouvertes en même temps' --texte message
            );
            pn_retcode    := 1;
        WHEN NO_DATA_FOUND
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA', --ERREUR : pas de période ouverte pour ce mouvement
                                 'DKA_IARPAFAC_E012',
                                 'INVOICE_NUMBER',
                                 pr_rec_line.invoice_number );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                pv_errbuf --texte message
                );
            pn_retcode    := 1;
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E013', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                SQLERRM --texte message
            );
            Dka_Tools_Pkg.put_debug_message ('>get_ar_gl_date : '|| SQLERRM);
            pn_retcode    := 2;
    END get_ar_gl_date;


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ar_tax
--  Description   : procedure de controle et de transcodage du code TVA
--                  via les tables AP_TAX_CODES_ALL et GL_CODE_COMBINATIONS
--
--  PARAMETRES    :
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004: Modification procedure, début.
    PROCEDURE get_ar_tax (
        pr_rec_line    IN       dka_iarpafac_interface%ROWTYPE,
        pn_org_id      IN       NUMBER,
        pv_acct_area   IN       VARCHAR2,
        pn_tax_id      OUT      NUMBER,
        pv_tax_code    OUT      VARCHAR2,
        pv_tax_type    OUT      VARCHAR2,
        pv_errbuf      IN OUT   VARCHAR2,
        pn_retcode     OUT      NUMBER
    )
    IS
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        /*SELECT avtab.tax_code,
               avtab.vat_tax_id
        INTO   pv_tax_code,
               pn_tax_id
        FROM   gl_code_combinations gcc,
               ar_vat_tax_all_b avtab
        WHERE      avtab.tax_account_id = gcc.code_combination_id
               AND gcc.segment3 = pr_rec_line.local_account
               -- Debut modif EMA du 24/06/2005
               -- AND segment1 = pr_rec_line.company_code   -- PHENIX 2004: pv_acct_area || pr_rec_line.company_code -> pr_rec_line.company_code.
               -- Fin modif EMA du 24/06/2005
               AND tax_rate = TO_NUMBER (pr_rec_line.tax_rate) / 100
               AND org_id = pn_org_id
               AND avtab.enabled_flag = 'Y'
               AND pr_rec_line.fmt_invoice_date BETWEEN avtab.start_date AND NVL (avtab.end_date, pr_rec_line.fmt_invoice_date);*/

        --Migration R12: On détermine le code taxe à partir des informations fournies dans le fichier. Utilisations des nouvelles tables ZX (E-Tax).
        select zr.TAX_RATE_CODE,
               zr.tax_rate_id,
               DECODE(zx.interim_tax_ccid, NULL ,'IMMEDIATE', 'DEFERRED') TAX_TYPE
        INTO   pv_tax_code,
               pn_tax_id,
               pv_tax_type
        from gl_code_combinations gcc
        --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
        JOIN zx_accounts zx ON (gcc.CODE_COMBINATION_ID = zx.tax_account_ccid and zx.tax_account_entity_code = 'RATES'
        and zx.internal_organization_id = pn_org_id)
        JOIN zx_rates_b zr  ON (zx.tax_account_entity_id = zr.tax_rate_id)
        WHERE 1=1
        AND gcc.segment3 = pr_rec_line.local_account
        AND gcc.segment2 = pr_rec_line.region
        AND gcc.segment1 = pr_rec_line.company_code
        AND zr.percentage_rate*100 = To_number(pr_rec_line.tax_rate)
        AND zr.active_flag = 'Y';

        Dka_Tools_Pkg.put_debug_message ('  tax_code : '|| pv_tax_code);
        Dka_Tools_Pkg.put_debug_message ('  pv_tax_type : '|| pv_tax_type);
        pn_retcode    := 0;
    EXCEPTION
        WHEN NO_DATA_FOUND
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E014',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'LOCAL_ACCOUNT',
                                 pr_rec_line.local_account
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                'local_account', --Non colonne en question
                pr_rec_line.local_account, --valeur colonne
                'E', --Erreur ou Warning
                'Aucun code de tva n''a pu être déterminé'
            ); --texte message
            pn_retcode    := 1;
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E015', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                'local_account', --Non colonne en question
                pr_rec_line.local_account, --valeur colonne
                'W', --Erreur ou Warning
                'Une erreur est survenue lors de la mise à jour de la TVA'
            ); --texte message
            pn_retcode    := 2;
    END get_ar_tax;
    -- PHENIX 2004: Modification procedure, fin.


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_transaction_type
--  Description   : Procédure qui détermine le type de transaction (evenement ou depense)
--                  Selon la classe de compte(6 ou 7)un type de context différent est passé
--                  en parametre dka_stransco_pkg.get_value_f
--                          Classe 6  => 'PA_EXPENDITURE_TYPE'
--                          Classe 7  => 'PA_EVENT_TYPE'
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE get_transaction_type (
        pr_rec_line           IN       dka_iarpafac_interface%ROWTYPE,
        pv_expenditure_type   OUT      VARCHAR2,
        pv_event_type         OUT      VARCHAR2,
        pv_errbuf             IN OUT   VARCHAR2,
        pn_retcode            OUT      NUMBER
    )
    IS
        vv_transaction_type           VARCHAR2 (30);
        vv_transaction_type_context   VARCHAR2 (30);
        vv_errbuf                     VARCHAR2 (200);
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode             := 0;
        pv_errbuf              := NULL;

        --on passe en parametre le type de context en fonction de la classe de compte (6 ou 7) du sous_compte
        IF SUBSTR (pr_rec_line.local_account, 1, 1) = '6'
        THEN
            vv_transaction_type_context    := 'PA_EXPENDITURE_TYPE';
        ELSIF SUBSTR (pr_rec_line.local_account, 1, 1) = '7'
        THEN
            vv_transaction_type_context    := 'PA_EVENT_TYPE';
        END IF;

        vv_transaction_type    := Dka_Stransco_Pkg.get_value_f (
                                      vv_transaction_type_context,
                                      pr_rec_line.fmt_invoice_date,
                                      vv_errbuf,
                                      pr_rec_line.local_account,
                                      pr_rec_line.analytic_nature
                                  );


-------------------------------------------------------------------------
        IF vv_transaction_type IS NULL
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E016',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'LOCAL_ACCOUNT',
                                 pr_rec_line.local_account
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                'local_account/analytic_nature', --Non colonne en question
                pr_rec_line.local_account || ';' || pr_rec_line.analytic_nature, --valeur colonne
                'E', --Erreur ou Warning
                'le type d''evenement n''est pas déterminé'
            ); --texte message
            pn_retcode    := 1;
            RETURN;
        END IF;

        -- si classe 6 alors pv_expenditure_type = vv_transaction_type
        IF SUBSTR (pr_rec_line.local_account, 1, 1) = '6'
        THEN
            pv_expenditure_type    := vv_transaction_type;
        -- si classe 7 alors pv_event_type = vv_transaction_type
        ELSIF SUBSTR (pr_rec_line.local_account, 1, 1) = '7'
        THEN
            pv_event_type    := vv_transaction_type;
        END IF;

        Dka_Tools_Pkg.put_debug_message ('   type event :'|| vv_transaction_type);
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E003', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                SQLERRM
            ); --texte message
    END get_transaction_type;


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_ttc
--  Description   : Procedure qui ramene la clé comptable pour une ligne CLIENT(ttc)
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004: Procedure modifiée.
    PROCEDURE get_ccid_ttc (
        pr_rec_line       IN       dka_iarpafac_interface%ROWTYPE,
        pv_acct_area      IN       VARCHAR2,
        pv_partner_code   IN       VARCHAR2,
        pd_date           IN       DATE,
        pn_cust_acct_site_id IN    NUMBER, -- R12
        pv_segment1       OUT      VARCHAR2,
        pv_segment2       OUT      VARCHAR2,
        pv_segment3       OUT      VARCHAR2,
        pv_segment4       OUT      VARCHAR2,
        pv_segment5       OUT      VARCHAR2,
        pv_segment6       OUT      VARCHAR2,
        pv_segment7       OUT      VARCHAR2,
        pv_segment8       OUT      VARCHAR2,
        pv_segment9       OUT      VARCHAR2,     -- PHENIX 2004: Ajout.
        pv_segment10      OUT      VARCHAR2,     -- PHENIX 2004: Ajout.
        pv_segment11      OUT      VARCHAR2, --R12
        pv_segment12      OUT      VARCHAR2, --R12
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
        vn_retcode_seg    NUMBER; --utilisé dans le message d'erreur pour renseigner le segment en erreur
        vv_errbuf         VARCHAR2 (200);
        e_error_segment   EXCEPTION;
    BEGIN
        ---- Initialisation des variables -----
        pv_errbuf      := NULL;
        pn_retcode     := 0;
        --détermination segment 1
        pv_segment1    := pr_rec_line.company_code; -- PHENIX 2004: pv_acct_area || pr_rec_line.company_code -> pr_rec_line.company_code.

        IF pv_segment1 IS NULL
        THEN
            vn_retcode_seg    := 1;
            RAISE e_error_segment;
        END IF;

        -- détermination segment 2
        pv_segment2    := pr_rec_line.region ; -- Modification R12 RG11-2

        IF pv_segment2 IS NULL           -- PHENIX 2004: Ajout.
        THEN                             -- PHENIX 2004: Ajout.
            vn_retcode_seg    := 2;      -- PHENIX 2004: Ajout.
            RAISE e_error_segment;       -- PHENIX 2004: Ajout.
        END IF;                          -- PHENIX 2004: Ajout.

        --détermination segment 3
        pv_segment3    := pr_rec_line.local_account;

        IF pv_segment3 IS NULL
        THEN
            vn_retcode_seg    := 3;
            RAISE e_error_segment;
        END IF;

        --détermination segment 4 -- PHENIX 2004: segment 2 -> segment 4.
        pv_segment4    := Dka_Stransco_Pkg.get_value_f (        -- PHENIX 2004: pv_segment2 -> pv_segment4.
                              'MIGR_GROUP_ACCOUNT_CLASS_BILAN', --'AR_GROUP_ACCOUNT_CLASS_4'
                              pd_date,
                              vv_errbuf,
                              pr_rec_line.local_account
                          );

        IF pv_segment4 IS NULL         -- PHENIX 2004: pv_segment2 -> pv_segment4.
        THEN
            vn_retcode_seg    := 4;    -- PHENIX 2004: 2 -> 4.
            RAISE e_error_segment;
        END IF;

        --détermination segment 5            -- PHENIX 2004: segment4 -> segment5.
        --ce qui arrive de get_customer_info
        --pv_segment5    := pv_partner_code;   -- PHENIX 2004: pv_segment4 -> pv_segment5.

        BEGIN

          SELECT gcc.segment5
            INTO pv_segment5
            FROM hz_parties             party,
                 hz_cust_Accounts       acnt,
                 hz_cust_acct_Sites_all site,
                 hz_Cust_Site_uses_all  uses,
                 hz_party_sites         ps,
                 hz_locations           loc,
                 gl_code_combinations   gcc
           WHERE party.party_id = acnt.party_id
             AND acnt.CUST_ACCOUNT_ID = site.CUST_ACCOUNT_ID
             AND site.CUST_ACCT_SITE_ID = uses.CUST_ACCT_SITE_ID
             AND ps.party_site_id = site.party_site_id
             AND loc.location_id = ps.location_id
             AND gcc.code_combination_id = uses.gl_id_rev
             AND site.cust_acct_site_id = pn_cust_acct_site_id;

        EXCEPTION
        WHEN OTHERS THEN
            vn_retcode_seg    := 5;
            RAISE e_error_segment;
        END;

        IF pv_segment5 IS NULL               -- PHENIX 2004: pv_segment4 -> pv_segment5.
        THEN
            vn_retcode_seg    := 5;          -- PHENIX 2004: 4 -> 5.
            RAISE e_error_segment;
        END IF;

        --détermination segment 6            -- PHENIX 2004: 5 -> 6.
        pv_segment6    := '0';               -- PHENIX 2004: pv_segment5 -> pv_segment6.

        IF pv_segment6 IS NULL               -- PHENIX 2004: pv_segment5 -> pv_segment6.
        THEN
            vn_retcode_seg    := 6;          -- PHENIX 2004: 5 -> 6.
            RAISE e_error_segment;
        END IF;

        --détermination segment 7            -- PHENIX 2004: 6 -> 7.
        pv_segment7    := '0';               -- PHENIX 2004: pv_segment6 -> pv_segment7.

        IF pv_segment7 IS NULL               -- PHENIX 2004: pv_segment6 -> pv_segment7.
        THEN
            vn_retcode_seg    := 7;          -- PHENIX 2004: 6 -> 7.
            RAISE e_error_segment;
        END IF;

        --détermination segment 8            -- PHENIX 2004: 7 -> 8.
        pv_segment8    := '0';               -- PHENIX 2004: pv_segment7 -> pv_segment8.

        IF pv_segment8 IS NULL               -- PHENIX 2004: pv_segment7 -> pv_segment8.
        THEN
            vn_retcode_seg    := 8;          -- PHENIX 2004: 7 -> 8.
            RAISE e_error_segment;
        END IF;

        --détermination segment 9            -- PHENIX 2004: 8 -> 9.
        pv_segment9    := '0';               -- PHENIX 2004: pv_segment8 -> pv_segment9.

        IF pv_segment9 IS NULL               -- PHENIX 2004: pv_segment8 -> pv_segment9.
        THEN
            vn_retcode_seg    := 9;          -- PHENIX 2004: 8 -> 9.
            RAISE e_error_segment;
        END IF;

        --détermination segment 10           -- PHENIX 2004: Ajout.
        pv_segment10   := '0';               -- PHENIX 2004: Ajout.

        pv_segment11   :=  '0'; --R12
        pv_segment12   :=  '0'; --R12

        Dka_Tools_Pkg.put_debug_message ( '  ccid :'  || pv_segment1|| pv_segment2 || pv_segment3
                                          || pv_segment4 || pv_segment5|| pv_segment6 || pv_segment7
                                          || pv_segment8 || pv_segment9 || pv_segment10 || pv_segment11 || pv_segment12);
    EXCEPTION
        WHEN e_error_segment THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E018',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'SEGMENT',
                                 vn_retcode_seg
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message
            pn_retcode    := 1;
        WHEN OTHERS THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E019', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message
            pn_retcode    := 2;
    END get_ccid_ttc;
    -- PHENIX 2004: Fin procedure modifiée.


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_attributes_line
--  Description   : Procedure qui ramene la clé comptable pour une ligne de PRODUIT
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004: Procedure modifiee.
    PROCEDURE get_ccid_attributes_line (
        pr_rec_line                IN       dka_iarpafac_interface%ROWTYPE,
        pn_project_id              IN       NUMBER,
        pn_project_id_case_refac   IN       NUMBER,
        pn_task_id                 IN       NUMBER,
        pn_task_id_case_refac      IN       NUMBER,   --R12
        pn_cust_acct_site_id       IN       NUMBER,   --R12
        pv_acct_area               IN       VARCHAR2, --R12
        pv_partner_code            IN       VARCHAR2,
        pd_date                    IN       DATE,
        pv_segment1                OUT      VARCHAR2,
        pv_segment2                OUT      VARCHAR2,
        pv_segment3                OUT      VARCHAR2,
        pv_segment4                OUT      VARCHAR2,
        pv_segment5                OUT      VARCHAR2,
        pv_segment6                OUT      VARCHAR2,
        pv_segment7                OUT      VARCHAR2,
        pv_segment8                OUT      VARCHAR2,
        pv_segment9                OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment10               OUT      VARCHAR2,  -- PHENIX 2004: Ajout.
        pv_segment11   OUT      VARCHAR2, --R12
        pv_segment12   OUT      VARCHAR2, --R12
        pv_attribute1              OUT      VARCHAR2,
        pv_attribute2              OUT      VARCHAR2,
        pv_attribute3              OUT      VARCHAR2,
        pv_attribute4              OUT      VARCHAR2,
        pv_attribute5              OUT      VARCHAR2,
        pv_attribute6              OUT      VARCHAR2,
        pv_attribute7              OUT      VARCHAR2,
        pv_attribute8              OUT      VARCHAR2,
        pv_attribute12             OUT      VARCHAR2,
        pv_attribute_category      OUT      VARCHAR2,
        pv_errbuf                  IN OUT   VARCHAR2,
        pn_retcode                 OUT      NUMBER
    )
    IS
        vv_expenditure_type   VARCHAR2 (30);
        vv_event_type         VARCHAR2 (30);
        vn_retcode_seg        NUMBER; --utilisé dans le message d'erreur pour renseigner le segment en erreur
        vv_errbuf             VARCHAR2 (200);
        e_error_segment       EXCEPTION;
        vv_segment1           gl_code_combinations.segment1%TYPE;  -- PHENIX 2004: Ajout.
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode               := 0;
        pv_errbuf                := NULL;

        -- Début modif EMA du 19/05/2011 --
        IF pr_rec_line.type_evt_dep IS NULL THEN
            --procedure get_transaction_type
            get_transaction_type (pr_rec_line,
                vv_expenditure_type, --context 'PA_EXPENDITURE_TYPE', classe 6
                vv_event_type, --context 'PA_EVENT_TYPE', classe 7
                pv_errbuf,
                pn_retcode);
        ELSE
            IF SUBSTR (pr_rec_line.local_account, 1, 1) = '6' THEN
                vv_expenditure_type := pr_rec_line.type_evt_dep;
            ELSIF SUBSTR (pr_rec_line.local_account, 1, 1) = '7' THEN
                vv_event_type       := pr_rec_line.type_evt_dep;
            END IF;
        END IF;
        -- Fin modif EMA du 19/05/2011 --
--------------------------------------------------------------
        IF pn_retcode != 0
        THEN
            RETURN;
        END IF;
--------------------------------------------------------------
        --determination du segment1
        -- Modif GV20031024 : Ajout d'un TRUNC pour comparaison au même niveau de format
    -- RBE MigR12
/*
        vv_segment1              := Dka_Ibdsoc_Tools_Pkg.get_proj_acct_area_company_f (  -- PHENIX 2004: pv_segment1 -> vv_segment1.
                                        pn_project_id,
                                        '0', -- la procedure retournera cdg/soc
                                        TRUNC(pd_date),
                                        pr_rec_line.company_code
                                    );
*/
        --pv_segment1 := SUBSTR(vv_segment1, cn_segment1_offset, cn_segment1_size);   -- PHENIX 2004: Ajout.
        --R12: le segment1 correspond au company_code, on récupére donc la valeur du fichier plat.
        pv_segment1 :=  pr_rec_line.company_code;

        IF pv_segment1 IS NULL
        THEN
            vn_retcode_seg    := 1;
            RAISE e_error_segment;
        END IF;

        --determination du segment2     -- PHENIX 2004: Ajout.

        --pv_segment2 := SUBSTR(vv_segment1, cn_segment2_offset, cn_segment2_size);   -- PHENIX 2004: Ajout.
        --R12: On alimente le segment2 en fonction de l'id du projet récupéré à partir du code tâche fourni dans le fichier plat (RG11-1) :
        pv_segment2 :=  Dka_Spaautoaccounting_Pkg.uo_projet(pn_project_id);

        --pv_segment2 := pr_rec_line.region; -- Voir si on ne peut pas l'alimenter directement avec la valeur du champ REGION de la table (CF RG11-2).

        IF pv_segment2 IS NULL          -- PHENIX 2004: Ajout.
        THEN                            -- PHENIX 2004: Ajout.
            vn_retcode_seg    := 2;     -- PHENIX 2004: Ajout.
            RAISE e_error_segment;      -- PHENIX 2004: Ajout.
        END IF;

        --determination du segment3
        pv_segment3 := pr_rec_line.local_account;

        IF pv_segment3 IS NULL
        THEN
            vn_retcode_seg    := 3;
            RAISE e_error_segment;
        END IF;

        --determination du segment4    -- PHENIX 2004: 2 -> 4.
             --selon la classe de compte (6 ou 7) on appel une procedure differente
        IF SUBSTR (pr_rec_line.local_account, 1, 1) = '6'
        THEN
            --RBE MigR12
            pv_segment4 := Dka_Spaautoaccounting_Pkg.cpt_groupe_couts(
                                  pn_project_id,
                                  vv_expenditure_type,
                                  NULL,
                                  pn_task_id );


            IF pv_segment4 IS NULL          -- PHENIX 2004: pv_segment2 -> pv_segment4.
            THEN
                Dka_Tools_Pkg.put_debug_message ('pn_project_id : ' || pn_project_id );
                Dka_Tools_Pkg.put_debug_message ('pn_task_id : ' || pn_task_id );
                vn_retcode_seg    := 4;     -- PHENIX 2004: 2 -> 4.
                RAISE e_error_segment;
            END IF;
        ELSIF SUBSTR (pr_rec_line.local_account, 1, 1) = '7'
        THEN
            --determination du segment2 pour classe 7
            -- Modif GV20031024 : Ajout d'un TRUNC pour comparaison date au même niveau de format
            --RBE MigR12
            pv_segment4 := Dka_Spaautoaccounting_Pkg.CPT_GROUPE_PRODUIT(pn_project_id, vv_event_type, pn_task_id);     --modification R12, on prend en compte l'id de la tâche.
            IF pv_segment4 IS NULL
            THEN
                Dka_Tools_Pkg.put_debug_message ('pn_project_id : ' || pn_project_id );
                Dka_Tools_Pkg.put_debug_message ('pn_task_id : ' || pn_task_id );
                vn_retcode_seg    := 4;
                RAISE e_error_segment;
            END IF;
        END IF;

        --determination du segment5
        --R12 modification de l'alimentation du segment Interco voir RG63
        --pv_segment5 := Dka_Spaautoaccounting_Pkg.code_interco(vv_expenditure_type, pn_project_id, pn_cust_acct_site_id);
        BEGIN

          SELECT gcc.segment5
            INTO pv_segment5
            FROM hz_parties             party,
                 hz_cust_Accounts       acnt,
                 hz_cust_acct_Sites_all site,
                 hz_Cust_Site_uses_all  uses,
                 hz_party_sites         ps,
                 hz_locations           loc,
                 gl_code_combinations   gcc
           WHERE party.party_id = acnt.party_id
             AND acnt.CUST_ACCOUNT_ID = site.CUST_ACCOUNT_ID
             AND site.CUST_ACCT_SITE_ID = uses.CUST_ACCT_SITE_ID
             AND ps.party_site_id = site.party_site_id
             AND loc.location_id = ps.location_id
             AND gcc.code_combination_id = uses.gl_id_rev
             AND site.cust_acct_site_id = pn_cust_acct_site_id;

        EXCEPTION
        WHEN OTHERS THEN
            vn_retcode_seg    := 5;
            RAISE e_error_segment;
        END;

        IF pv_segment5 IS NULL
        THEN
            vn_retcode_seg    := 5;
            RAISE e_error_segment;
        END IF;

        --determination du segment6
        -- Modif GV20031024 : Ajout d'un TRUNC pour comparaison au même niveau de format
        -- RBE
        pv_segment6              := Dka_Spaautoaccounting_Pkg.centrefi(pn_project_id); -- Modification R12. PBR RG58

        IF pv_segment6 IS NULL
        THEN
            vn_retcode_seg    := 6;
            RAISE e_error_segment;
        END IF;

        --determination du segment7
        --RBE MigR12
        pv_segment7              := Dka_Spaautoaccounting_Pkg.affaire (pn_project_id);   --R12 PBR RG64

        IF pv_segment7 IS NULL
        THEN
            vn_retcode_seg    := 7;
            RAISE e_error_segment;
        END IF;

        --determination du segment8
        --RBE MigR12
        pv_segment8              := Dka_Spaautoaccounting_Pkg.projetfi(pn_project_id);  --Modification R12 PBR RG59
        IF pv_segment8 IS NULL
        THEN
            vn_retcode_seg    := 8;
            RAISE e_error_segment;
        END IF;

        --determination du segment9
        pv_segment9              := '0';

        IF pv_segment9 IS NULL
        THEN
            vn_retcode_seg    := 9;
            RAISE e_error_segment;
        END IF;

        --determination du segment10
        pv_segment10             := '0';
        pv_segment11 := '0'; --R12
        pv_segment12 := '0'; --R12


        --determination de attribute1
        pv_attribute1            := pn_project_id; -- RG9 Project_id (cas de refac, il s'agit de l'id du projet Refac)
        IF pv_attribute1 IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('pv_attribute1');
            pn_retcode    := 1;
            RAISE e_error_segment;
        END IF;

        --determination de attribute2
        pv_attribute2            := vv_event_type; -- RG9 on stocke l'evénement produit.
        IF pv_attribute2 IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('pv_attribute2');
            pn_retcode    := 1;
            RAISE e_error_segment;
        END IF;

        -- RG9, Code projet d'imputation d'origine du produit récupéré à partir du code tâche du fichier
        pv_attribute3            := pn_project_id_case_refac;

        --determination de attribute4
        pv_attribute4            := pn_task_id; -- RG9, code tâche du projet (tâche de la REFAC dans le cas d'une refac).
        IF pv_attribute4 IS NULL
        THEN
            Dka_Tools_Pkg.put_debug_message ('pv_attribute4');
            RAISE e_error_segment;
        END IF;

        --determination de attribute5
        pv_attribute5            := '0';
        IF pv_attribute5 IS NULL
        THEN
            RAISE e_error_segment;
        END IF;

        --determination de attribute6
        pv_attribute6            := '0';
        IF pv_attribute6 IS NULL
        THEN
            RAISE e_error_segment;
        END IF;

        --determination de attribute7
        pv_attribute7            := pn_task_id_case_refac; -- RG9 id de la tâche d'origine issu du code tâche du fichier plat.
        IF pv_attribute7 IS NULL
        THEN
            RAISE e_error_segment;
        END IF;

        --determination de attribute8
        --IF pv_segment3 IN ('467300', '467296') THEN --RG29 ON alimente l'attribute8 dans le cas de la surtaxe communale.
        IF DKA_AR_TOOLS_PKG.issurtaxeaccount(pv_segment3) = 'TRUE' THEN --RBE artf2211292
          pv_attribute8 := pv_segment5;
        ELSE
          pv_attribute8 := NULL;
        END IF;

        --R12 RG11-1, on alimente le cuf avec la valeur de l'UO pour SLA.
        pv_attribute12 := pv_segment2;

        --determination de attribute_category
        pv_attribute_category    := 'Y';
        IF pv_attribute_category IS NULL
        THEN
            RAISE e_error_segment;
        END IF;

        Dka_Tools_Pkg.put_debug_message ( '  ccid :'
            || pv_segment1 ||'.'
            || pv_segment2 ||'.'
            || pv_segment3 ||'.'
            || pv_segment4 ||'.'
            || pv_segment5 ||'.'
            || pv_segment6 ||'.'
            || pv_segment7 ||'.'
            || pv_segment8 ||'.'
            || pv_segment9 ||'.'  -- PHENIX 2004: Ajout.
            || pv_segment10 ||'.'
            || pv_segment11 ||'.'
            || pv_segment12 );
        Dka_Tools_Pkg.put_debug_message(' att1: '     -- PHENIX 2004: Ajout.
            || pv_attribute1 ||' att2: '
            || pv_attribute2 ||' att3: '
            || pv_attribute3 ||' att4: '
            || pv_attribute4 ||' att_cat: '
            || pv_attribute7 ||' id tâche fichier ' --R12
            || pv_attribute12 ||' UO pour SLA: ' --R12
            || pv_attribute_category);
    EXCEPTION
        WHEN e_error_segment THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E018',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'SEGMENT',
                                 vn_retcode_seg
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné '
            ); --texte message

            pn_retcode    := 1;
        WHEN OTHERS THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E019', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message

            pn_retcode    := 2;
    END get_ccid_attributes_line;
    -- PHENIX 2004: Procedure modifiée - fin.

---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_tax
--  Description   : Procedure qui ramene la clé comptable pour une ligne de TAX(tva)
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
-- PHENIX 2004: Procedure modifiee.
PROCEDURE get_ccid_tax (
        pr_rec_line       IN       dka_iarpafac_interface%ROWTYPE,
        pv_acct_area      IN       VARCHAR2,
        pn_org_id         IN       NUMBER,
        vv_tax_code       IN       VARCHAR2,
        pv_tax_type       IN       VARCHAR2,
        pn_tax_id         IN       VARCHAR2,
        pd_date           IN       DATE,
        pv_segment1       OUT      VARCHAR2,
        pv_segment2       OUT      VARCHAR2,
        pv_segment3       OUT      VARCHAR2,
        pv_segment4       OUT      VARCHAR2,
        pv_segment5       OUT      VARCHAR2,
        pv_segment6       OUT      VARCHAR2,
        pv_segment7       OUT      VARCHAR2,
        pv_segment8       OUT      VARCHAR2,
        pv_segment9       OUT      VARCHAR2,   -- PHENIX 2004: Ajout.
        pv_segment10      OUT      VARCHAR2,   -- PHENIX 2004: Ajout.
        pv_segment11   OUT      VARCHAR2, --R12
        pv_segment12   OUT      VARCHAR2, --R12
        pv_int_segment1   OUT      VARCHAR2,
        pv_int_segment2   OUT      VARCHAR2,
        pv_int_segment3   OUT      VARCHAR2,
        pv_int_segment4   OUT      VARCHAR2,
        pv_int_segment5   OUT      VARCHAR2,
        pv_int_segment6   OUT      VARCHAR2,
        pv_int_segment7   OUT      VARCHAR2,
        pv_int_segment8   OUT      VARCHAR2,
        pv_int_segment9   OUT      VARCHAR2,   -- PHENIX 2004: Ajout.
        pv_int_segment10  OUT      VARCHAR2,   -- PHENIX 2004: Ajout.
        pv_int_segment11   OUT      VARCHAR2, --R12
        pv_int_segment12   OUT      VARCHAR2, --R12
        pv_errbuf         IN OUT   VARCHAR2,
        pn_retcode        OUT      NUMBER
    )
    IS
        vn_retcode_seg    NUMBER; --utilisé dans le message d'erreur pour renseigner le segment en erreur
        vv_errbuf         VARCHAR2 (200);
        e_error_segment   EXCEPTION;
        e_error_tax       EXCEPTION;
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;


        -- Si la tva est sur ENCAISSEMENT alors aller chercher la ccid dans GL_CODE_COMBINATIONS
        -- on doit renseigner les segment interim de ra_interface_distributions_all

        IF pv_tax_type = 'DEFERRED'
        THEN
        BEGIN
            SELECT gcc_interim.segment1,
                   gcc_interim.segment2,
                   gcc_interim.segment3,
                   gcc_interim.segment4,
                   gcc_interim.segment5,
                   gcc_interim.segment6,
                   gcc_interim.segment7,
                   gcc_interim.segment8,
                   gcc_interim.segment9,     -- PHENIX 2004: Ajout.
                   gcc_interim.segment10,    -- PHENIX 2004: Ajout.
                   gcc_interim.segment11, --R12
                   gcc_interim.segment12, --R12
                   gcc_definitif.segment1,
                   gcc_definitif.segment2,
                   gcc_definitif.segment3,
                   gcc_definitif.segment4,
                   gcc_definitif.segment5,
                   gcc_definitif.segment6,
                   gcc_definitif.segment7,
                   gcc_definitif.segment8,
                   gcc_definitif.segment9,   -- PHENIX 2004: Ajout.
                   gcc_definitif.segment10,   -- PHENIX 2004: Ajout.
                   gcc_definitif.segment11, --R12
                   gcc_definitif.segment12 --R12
            INTO   pv_int_segment1,
                   pv_int_segment2,
                   pv_int_segment3,
                   pv_int_segment4,
                   pv_int_segment5,
                   pv_int_segment6,
                   pv_int_segment7,
                   pv_int_segment8,
                   pv_int_segment9,          -- PHENIX 2004: Ajout.
                   pv_int_segment10,         -- PHENIX 2004: Ajout.
                   pv_int_segment11, --R12
                   pv_int_segment12, --R12
                   pv_segment1,
                   pv_segment2,
                   pv_segment3,
                   pv_segment4,
                   pv_segment5,
                   pv_segment6,
                   pv_segment7,
                   pv_segment8,
                   pv_segment9,              -- PHENIX 2004: Ajout.
                   pv_segment10,              -- PHENIX 2004: Ajout.
                   pv_segment11, --R12
                   pv_segment12  --R12
            from
               gl_code_combinations gcc_definitif
               --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
               JOIN zx_accounts zx ON (gcc_definitif.CODE_COMBINATION_ID = zx.tax_account_ccid and zx.tax_account_entity_code = 'RATES'
               and zx.internal_organization_id = pn_org_id )
               JOIN gl_code_combinations gcc_interim ON (gcc_interim.code_combination_id = zx.INTERIM_TAX_CCID)
               JOIN zx_rates_b zr  ON (zx.tax_account_entity_id = zr.tax_rate_id)
            WHERE 1=1
               AND gcc_definitif.segment3 = pr_rec_line.local_account
               AND gcc_definitif.segment2 = pr_rec_line.region
               AND gcc_definitif.segment1 = pr_rec_line.company_code
               --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
               --AND zr.tax_rate_code = vv_tax_code
               AND zr.tax_rate_id = pn_tax_id;
          EXCEPTION
           WHEN OTHERS THEN
              Dka_Tools_Pkg.put_debug_message ('**** erreur: pas de segments interim_tax_ccid et tax_account_id pour le code '|| vv_tax_code ||
              ' Dans la table ar_vat_tax_all_b ' );
              RAISE;

          END;

        ELSE
            pv_int_segment1    := NULL;
            pv_int_segment2    := NULL;
            pv_int_segment3    := NULL;
            pv_int_segment4    := NULL;
            pv_int_segment5    := NULL;
            pv_int_segment6    := NULL;
            pv_int_segment7    := NULL;
            pv_int_segment8    := NULL;
            pv_int_segment9    := NULL;        -- PHENIX 2004: Ajout.
            pv_int_segment10   := NULL;        -- PHENIX 2004: Ajout.
            pv_int_segment11   := NULL; --R12
            pv_int_segment12   := NULL; --R12

            SELECT gcc.segment1,
                   gcc.segment2,
                   gcc.segment3,
                   gcc.segment4,
                   gcc.segment5,
                   gcc.segment6,
                   gcc.segment7,
                   gcc.segment8,
                   gcc.segment9,               -- PHENIX 2004: Ajout.
                   gcc.segment10,               -- PHENIX 2004: Ajout.
                   gcc.segment11, --R12
                   gcc.segment12 --R12
            INTO   pv_segment1,
                   pv_segment2,
                   pv_segment3,
                   pv_segment4,
                   pv_segment5,
                   pv_segment6,
                   pv_segment7,
                   pv_segment8,
                   pv_segment9,                -- PHENIX 2004: Ajout.
                   pv_segment10,                -- PHENIX 2004: Ajout.
                   pv_segment11, --R12
                   pv_segment12 --R12
            FROM   gl_code_combinations gcc
               --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
               JOIN zx_accounts zx ON (gcc.CODE_COMBINATION_ID = zx.tax_account_ccid and zx.tax_account_entity_code = 'RATES'
               and zx.internal_organization_id = pn_org_id)
               JOIN zx_rates_b zr  ON (zx.tax_account_entity_id = zr.tax_rate_id)
            WHERE 1=1
               AND gcc.segment3 = pr_rec_line.local_account
               AND gcc.segment2 = pr_rec_line.region
               AND gcc.segment1 = pr_rec_line.company_code
           --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
           --    AND zr.tax_rate_code = vv_tax_code
               AND zr.tax_rate_id = pn_tax_id;
        END IF;


                 --JV 06/07/2005 : Vérification si segment1 = XXXX

        IF pv_segment1 = 'XXXX'
        THEN
        pv_segment1 := pr_rec_line.company_code;
        END IF;

        pv_segment2 := pr_rec_line.region; -- Modification R12 RG13 . --pv_acct_area ; -- PHENIX 2004: Ajout.



        IF pv_int_segment1 = 'XXXX'
        THEN
        pv_int_segment1 := pr_rec_line.company_code;
        END IF;

        pv_int_segment2 := pr_rec_line.region; -- PHENIX 2004: Ajout.

        Dka_Tools_Pkg.put_debug_message (
               '  ccid :'
            || pv_segment1 ||'.'
            || pv_segment2 ||'.'
            || pv_segment3 ||'.'
            || pv_segment4 ||'.'
            || pv_segment5 ||'.'
            || pv_segment6 ||'.'
            || pv_segment7 ||'.'
            || pv_segment8 ||'.'
            || pv_segment9 ||'.'            -- PHENIX 2004: Ajout.
            || pv_segment10 ||'.'             -- PHENIX 2004: Ajout.
            || pv_segment11 ||'.'
            ||  pv_segment12);

        Dka_Tools_Pkg.put_debug_message (
               '  ccid INTERIM :'
            || pv_int_segment1 ||'.'
            || pv_int_segment2 ||'.'
            || pv_int_segment3 ||'.'
            || pv_int_segment4 ||'.'
            || pv_int_segment5 ||'.'
            || pv_int_segment6 ||'.'
            || pv_int_segment7 ||'.'
            || pv_int_segment8 ||'.'
            || pv_int_segment9 ||'.'            -- PHENIX 2004: Ajout.
            || pv_int_segment10 ||'.'             -- PHENIX 2004: Ajout.
            || pv_int_segment11 ||'.'
            || pv_int_segment12);

    EXCEPTION
        WHEN e_error_segment
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E018',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'SEGMENT',
                                 vn_retcode_seg
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message
            pn_retcode    := 1;
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E019', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message
            pn_retcode    := 2;
    END;
-- PHENIX 2004: Procedure modifiee - fin.


---------------------------------------------------------------------------------------------------------------
--  Nom           : get_ccid_surtaxe
--  Description   : Procedure qui ramene la clé comptable pour une ligne de PRODUIT(surtaxe)
--                  Compte dont la racine est '467'
--
--  PARAMETRES    :
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004: Procedure modifiee
    PROCEDURE get_ccid_surtaxe (
        pr_rec_line    IN       dka_iarpafac_interface%ROWTYPE,
        pv_acct_area   IN       VARCHAR2,
        pd_date        IN       DATE,
        pv_segment1    OUT      VARCHAR2,
        pv_segment2    OUT      VARCHAR2,
        pv_segment3    OUT      VARCHAR2,
        pv_segment4    OUT      VARCHAR2,
        pv_segment5    OUT      VARCHAR2,
        pv_segment6    OUT      VARCHAR2,
        pv_segment7    OUT      VARCHAR2,
        pv_segment8    OUT      VARCHAR2,
        pv_segment9    OUT      VARCHAR2,       -- PHENIX 2004: Ajout.
        pv_segment10   OUT      VARCHAR2,       -- PHENIX 2004: Ajout.
        pv_segment11   OUT      VARCHAR2, --R12
        pv_segment12   OUT      VARCHAR2, --R12
        pv_attribute8  OUT      VARCHAR2,
        pv_errbuf      IN OUT   VARCHAR2,
        pn_retcode     OUT      NUMBER
    )
    IS
        vn_retcode_seg    NUMBER; --utilisé dans le message d'erreur pour renseigner le segment en erreur
        vv_errbuf         VARCHAR2 (200);
        e_error_segment   EXCEPTION;
        vn_calcul_flag    VARCHAR2(1); -- Flag pour savoir si calcul du segment4 ou pas

    BEGIN
        ----- Initialisation des variables -----
        pn_retcode     := 0;
        pv_errbuf      := NULL;

        -- Modif GV20040112 : Vérifier dans le jeu de valeur du compte local si vrai compte surtaxe ou pas
        SELECT ffv.attribute10
        INTO   vn_calcul_flag
        FROM   fnd_flex_values_vl ffv,
               fnd_flex_value_sets ffvs
        WHERE  ffvs.flex_value_set_name = 'DAOPCCF_LOCAL'
           AND ffvs.flex_value_set_id = ffv.flex_value_set_id
           AND ffv.flex_value = pr_rec_line.local_account;
        -- Fin Modif GV20040112
		
		
        --determination du segment1
        pv_segment1    := pr_rec_line.company_code;    -- PHENIX 2004: pv_acct_area || pr_rec_line.company_code -> pr_rec_line.company_code.

        IF pv_segment1 IS NULL
        THEN
            vn_retcode_seg    := 1;
            RAISE e_error_segment;
        END IF;

        --determination du segment2           -- PHENIX 2004: Ajout.
        pv_segment2    := pr_rec_line.region; --R12, on prend la region du fichier.  -- PHENIX 2004: Ajout.

        IF pv_segment2 IS NULL                -- PHENIX 2004: Ajout.
        THEN                                  -- PHENIX 2004: Ajout.
            vn_retcode_seg    := 2;           -- PHENIX 2004: Ajout.
            RAISE e_error_segment;            -- PHENIX 2004: Ajout.
        END IF;                               -- PHENIX 2004: Ajout.

        --determination du segment3
        pv_segment3    := pr_rec_line.local_account;

        IF pv_segment3 IS NULL
        THEN
            vn_retcode_seg    := 3;
            RAISE e_error_segment;
        END IF;

        --determination du segment4     -- PHENIX 2004: 2 -> 4.
        -- Modif GV20040112 : Segment2 = 25080 si vrai compte de surtaxe, sinon calcul par Transco
        IF NVL(vn_calcul_flag, 'N') = 'Y'
        THEN
            pv_segment4    := '25080';                            -- PHENIX 2004: pv_segment2 -> pv_segment4.
			
        ELSE
            pv_segment4    := Dka_Stransco_Pkg.get_value_f (      -- PHENIX 2004: pv_segment2 -> pv_segment4.
                                  'MIGR_GROUP_ACCOUNT_CLASS_BILAN',
                                  pd_date,
                                  vv_errbuf,
                                  pr_rec_line.local_account
                              );
        END IF;
        -- Fin Modif GV20040112

        IF pv_segment4 IS NULL         -- PHENIX 2004: pv_segment2 -> pv_segment4.
        THEN
            vn_retcode_seg    := 4;    -- PHENIX 2004: 2 -> 4.
            RAISE e_error_segment;
        END IF;


        --determination du segment5    -- PHENIX 2004: 4 -> 5.
        -- Modif GV20040112 : Segment5 = 0 si le compte locla n'est pas un vrai compet de surtaxe            -- PHENIX 2004: 4 -> 5.
        --R12
		
        /*IF NVL(vn_calcul_flag, 'N') = 'Y'
        THEN
           pv_segment5 := 'CSC' || pr_rec_line.function_code;   -- PHENIX 2004: pv_segment4 -> pv_segment5.
        ELSE*/
           pv_segment5 := '0'; --R12, l'organisme collecteur est déplacé dans le CUF attribute8 (RG29).
        --END IF;
        -- Fin Modif GV20040112
        

        IF pv_segment5 IS NULL                                  -- PHENIX 2004: pv_segment4 -> pv_segment5.
        THEN
            vn_retcode_seg    := 5;                             -- PHENIX 2004: 4 -> 5.
            RAISE e_error_segment;
        END IF; --R12

        --determination du segment6          -- PHENIX 2004: 5 -> 6.
        pv_segment6    := '0';               -- PHENIX 2004: pv_segment5 -> pv_segment6.

        IF pv_segment6 IS NULL               -- PHENIX 2004: pv_segment5 -> pv_segment6.
        THEN
            vn_retcode_seg    := 6;          -- PHENIX 2004: 5 -> 6.
            RAISE e_error_segment;
        END IF;

        --determination du segment7          -- PHENIX 2004: 6 -> 7.
        pv_segment7    := '0';               -- PHENIX 2004: pv_segment6 -> pv_segment7.

        IF pv_segment7 IS NULL               -- PHENIX 2004: pv_segment6 -> pv_segment7.
        THEN
            vn_retcode_seg    := 7;          -- PHENIX 2004: 6 -> 7.
            RAISE e_error_segment;
        END IF;

        --determination du segment8          -- PHENIX 2004: 7 -> 8.
        pv_segment8    := '0';               -- PHENIX 2004: pv_segment7 -> pv_segment8.

        IF pv_segment8 IS NULL               -- PHENIX 2004: pv_segment7 -> pv_segment8.
        THEN
            vn_retcode_seg    := 8;          -- PHENIX 2004: 7 -> 8.
            RAISE e_error_segment;
        END IF;

        --determination du segment9          -- PHENIX 2004: 8 -> 9.
        pv_segment9    := '0';               -- PHENIX 2004: pv_segment9 -> pv_segment9.

        IF pv_segment9 IS NULL               -- PHENIX 2004: pv_segment9 -> pv_segment9.
        THEN
            vn_retcode_seg    := 9;          -- PHENIX 2004: 8 -> 9.
            RAISE e_error_segment;
        END IF;

        --determination du segment10         -- PHENIX 2004: Ajout.
        pv_segment10   := '0';               -- PHENIX 2004: Ajout.
        pv_segment11 := 0; --R12
        pv_segment12 := 0; --R12

        --R12
        pv_attribute8 := 'CSC'||pr_rec_line.function_code;

        Dka_Tools_Pkg.put_debug_message (
               '  ccid :'
            || pv_segment1 || '.'
            || pv_segment2 || '.'
            || pv_segment3 || '.'
            || pv_segment4 || '.'
            || pv_segment5 || '.'
            || pv_segment6 || '.'
            || pv_segment7 || '.'
            || pv_segment8 || '.'
            || pv_segment9 || '.'                  -- PHENIX 2004: Ajout.
            || pv_segment10 || '.'                 -- PHENIX 2004: Ajout.
            || pv_segment11 || '.'
            || pv_segment12
        );
    EXCEPTION
        WHEN e_error_segment
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E018',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'SEGMENT',
                                 vn_retcode_seg
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message
            pn_retcode    := 1;
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E019', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                'clé comptable invalide, segment non renseigné'
            ); --texte message
            pn_retcode    := 2;
    END get_ccid_surtaxe;
    -- PHENIX 2004: Procedure modifiee - fin.

---------------------------------------------------------------------------------------------------------------
--  Nom           : get_customer_info
--  Description   : Procédure de controle des informations concernant le client
--                  (existance de la reference anael(sub_account) dans OA)
--                  Un client doit être référencé dans OA. (si non => rejet) Si oui nous controlons
--                  qu'il a bien une adresse qui lui est attribuée. Si ce n'est pas le cas c'est que
--                  le client est nouveau (mais déjà connu)avec une adresse par défaut. Nous lui attribuons
--                  donc une nouvelle adresse grace à la procedure dka_iclientifs_pkg.duplicate_addr.
--
--
--  PARAMETRES    :      pn_cust_acct_site_id,
--                       pn_cust_account_id,
--                       pv_partner_code
--
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE get_customer_info (
        pr_rec_line            IN       dka_iarpafac_interface%ROWTYPE,
        pv_acct_area           IN       VARCHAR2,
        pn_org_id              IN       NUMBER,
        pn_cust_acct_site_id   OUT      NUMBER,
        pn_cust_account_id     OUT      NUMBER,
        pv_partner_code        OUT      VARCHAR2,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        vn_exist_ref_anael     NUMBER;
        vn_ref_anael_in_acct   NUMBER;
        vv_errbuf              VARCHAR2 (200);
        vn_retcode             NUMBER;
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode    := 0;
        pv_errbuf     := NULL;

        --on controle si la reference anael(sub_account) existe dans OA
        SELECT COUNT (1)
        INTO   vn_exist_ref_anael
        FROM   hz_cust_acct_sites_all
        WHERE  attribute3 = pr_rec_line.sub_account;

         Dka_Tools_Pkg.put_debug_message ('vn_exist_ref_anael : ' ||vn_exist_ref_anael);
        --si le sous_compte n'est pas referencé
        IF vn_exist_ref_anael = 0
        THEN

        --rejet car le client de la facture est inconnu dans OA
         ---------------------------------------------------------------------------------
         --ERREUR : la reference ANAEL +SUB_ACCOUNT est inconnue dans Oracle
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E020',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'SUB_ACCOUNT',
                                 pr_rec_line.sub_account
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID de la ligne
                'SUB_ACCOUNT', --Non colonne en question
                pr_rec_line.sub_account, --valeur colonne
                'E', --Erreur ou Warning
                'la référence ANAEL n''existe pas dans Oracle'
            ); --texte message
            pn_retcode    := 1;
            RETURN;
        ELSE --si count != 0  ,le client est référencé
            BEGIN
                --on regarde si la reference anael(sub_account)existe pour le couple
                --acct_area/company_code (centre de gestion/societe) de l'entete de facture
                SELECT COUNT (1)
                INTO   vn_ref_anael_in_acct
                FROM   hz_cust_acct_sites_all hcasa,
                       hz_cust_accounts hca,
                       hz_cust_site_uses_all hcsua
                WHERE      hca.cust_account_id = hcasa.cust_account_id
                       AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id
                       AND hcasa.attribute3 = pr_rec_line.sub_account
                       AND hcasa.org_id = pn_org_id;
                       --AND SUBSTR (hcsua.location, 1, 3) = pr_rec_line.region; R12, location n'est plus préfixé avec la région.
                Dka_Tools_Pkg.put_debug_message ('vn_ref_anael_in_acct : ' ||vn_ref_anael_in_acct);
                IF vn_ref_anael_in_acct = 0 THEN
                    --c'est que le client est référencé (d'après le 1er controle)mais n'est pas rattaché
                    -- au couple cdg/soc de l'ent de facture
                    IF vn_retcode != 0 THEN
                        Dka_Tools_Pkg.put_debug_message (vv_errbuf);
                        pv_errbuf     := Dka_Tools_Pkg.get_message (
                                             'DKA',
                                             'DKA_IARPAFAC_E021',
                                             'INV_NUM',
                                             pr_rec_line.invoice_number,
                                             'ORIGINE',
                                             pr_rec_line.origin,
                                             'COMPANY',
                                             pr_rec_line.company_code,
                                             'SUB_ACCOUNT',
                                             pr_rec_line.sub_account,
                                             'ACCT_AREA',
                                             pv_acct_area
                                         );
                        Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
                        --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
                        Dka_Tools_Pkg.ins_prog_message (
                            gn_request_id, --N°traitement
                            'IARPAFAC', --Non interface
                            'OA', --Source
                            'DKA_IARPAFAC_INTERFACE', --Table
                            pr_rec_line.iarpafac_id, --ID explicite
                            NULL, --Non colonne en question
                            NULL, --valeur colonne
                            'E', --Erreur ou Warning
                            'L''adresse du client n''a pas été dupliquée'
                        ); --texte message
                        pn_retcode    := 1;
                        RETURN;
                    END IF;

---------------------------------------------------------------------------
                    -- PHENIX 2004: suppression: Dka_Tools_Pkg.put_debug_message ('  adresse dupliquée avec succés');
                ELSIF vn_ref_anael_in_acct > 1 THEN
-----------------------------------------------------------------------------------
--toomanyrows : le site client existe trop de fois dans notre cdg soc
--rejet
                    pv_errbuf     := Dka_Tools_Pkg.get_message (
                                         'DKA',
                                         'DKA_IARPAFAC_E_022',
                                         'INV_NUM',
                                         pr_rec_line.invoice_number,
                                         'ORIGINE',
                                         pr_rec_line.origin,
                                         'COMPANY',
                                         pr_rec_line.company_code,
                                         'SUB_ACCOUNT',
                                         pr_rec_line.sub_account
                                     );
                    Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
                    --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
                    Dka_Tools_Pkg.ins_prog_message (
                        gn_request_id, --N°traitement
                        'IARPAFAC', --Non interface
                        'OA', --Source
                        'DKA_IARPAFAC_INTERFACE', --Table
                        pr_rec_line.iarpafac_id, --ID explicite
                        NULL, --Non colonne en question
                        NULL, --valeur colonne
                        'E', --Erreur ou Warning
                        'le site client existe trop de fois dans notre cdg soc'
                    ); --texte message
                    pn_retcode    := 1;
                    RETURN;
                END IF;
								
                -- on recupere les infos de notre site dans notre cdg/soc
                SELECT hcasa.cust_acct_site_id,
                       hca.cust_account_id,
                       NVL (hca.attribute1, '0')
                INTO   pn_cust_acct_site_id,
                       pn_cust_account_id,
                       pv_partner_code
                FROM   hz_cust_acct_sites_all hcasa,
                       hz_cust_accounts hca,
                       hz_cust_site_uses_all hcsua
                WHERE      hca.cust_account_id = hcasa.cust_account_id
                       AND hcasa.attribute3 = pr_rec_line.sub_account
                       AND hcasa.org_id = pn_org_id
                       --AND SUBSTR (hcsua.location, 1, 3) = pv_acct_area R12 ON ne se base plus sur ce champ pour sélectionner le site du client.
                       AND hcsua.cust_acct_site_id = hcasa.cust_acct_site_id;

                Dka_Tools_Pkg.put_debug_message ('  code partenaire : '|| pv_partner_code);
                Dka_Tools_Pkg.put_debug_message ('       account_id : '|| pn_cust_account_id);
                Dka_Tools_Pkg.put_debug_message ('          site_id : '|| pn_cust_acct_site_id);
            EXCEPTION
                WHEN NO_DATA_FOUND THEN
                    pv_errbuf     := Dka_Tools_Pkg.get_message (
                                         'DKA',
                                         'DKA_IARPAFAC_E021',
                                         'INV_NUM',
                                         pr_rec_line.invoice_number,
                                         'ORIGINE',
                                         pr_rec_line.origin,
                                         'COMPANY',
                                         pr_rec_line.company_code,
                                         'SUB_ACCOUNT',
                                         pr_rec_line.sub_account,
                                         'ACCT_AREA',
                                         pv_acct_area
                                     );
                    Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
                    --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
                    Dka_Tools_Pkg.ins_prog_message (
                        gn_request_id, --N°traitement
                        'IARPAFAC', --Non interface
                        'OA', --Source
                        'DKA_IARPAFAC_INTERFACE', --Table
                        pr_rec_line.iarpafac_id, --ID explicite
                        NULL, --Non colonne en question
                        NULL, --valeur colonne
                        'E', --Erreur ou Warning
                        'L''adresse du client n''a pas été dupliquée' ); --texte message
                    pn_retcode    := 1;
                WHEN TOO_MANY_ROWS THEN
                    --la duplication a dupliquer trop de fois
                    --rejet
                    --toomanyrows : le site client existe trop de fois dans notre cdg soc
                    pv_errbuf     := Dka_Tools_Pkg.get_message (
                                         'DKA',
                                         'DKA_IARPAFAC_E022',
                                         'INV_NUM',
                                         pr_rec_line.invoice_number,
                                         'ORIGINE',
                                         pr_rec_line.origin,
                                         'COMPANY',
                                         pr_rec_line.company_code,
                                         'SUB_ACCOUNT',
                                         pr_rec_line.sub_account);
                    Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
                    --- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
                    Dka_Tools_Pkg.ins_prog_message (
                        gn_request_id, --N°traitement
                        'IARPAFAC', --Non interface
                        'OA', --Source
                        'DKA_IARPAFAC_INTERFACE', --Table
                        pr_rec_line.iarpafac_id, --ID explicite
                        NULL, --Non colonne en question
                        NULL, --valeur colonne
                        'E', --Erreur ou Warning
                        'la duplication de site client a dupliquer trop de fois'); --texte message
                    pn_retcode    := 1;
            END;
        END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E023', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                SQLERRM
            ); --texte message
    END get_customer_info;


---------------------------------------------------------------------------------------------------------------
--  Nom           : check_project
--  Description   : Procedure permettant de déterminer le code projet correspondant à l'unité opérationnelle
--                  L'org_id est dédiut du code_société(société emmétrice de la facture),
--                  le code_projet pointe sur une organisation mais elle peut être differente de celle
--                  de la ligne, il s'agit là d'un projet "à refacturer"
--                  La determination du type de traitement s'effectue comme suit :
--                   Comparaison entre la société emmétrice(org_id) et la société déduite du projet(project_code)
--                   Deux traitements possibles :
--
--                    -société emmétrice(org_id)  IDENTIQUE   société déduite du projet(project_code)
--                       => traitement AR_NORMAL
--
--                    -société emmétrice(org_id)  DIFFERENTE  société déduite du projet(project_code)
--                       => traitement AR_REFAC
--
--  PARAMETRES
--      ************************
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE check_project (
        pr_rec_line                IN       dka_iarpafac_interface%ROWTYPE,
        pv_acct_area               IN       VARCHAR2,
        pn_org_id                  IN       NUMBER,
        pn_project_id              OUT      NUMBER,
        pn_project_id_case_refac   OUT      NUMBER,
        pn_task_id                 OUT      NUMBER,
        pn_task_id_case_refac      OUT      NUMBER,
        --pn_project_appart           OUT  NUMBER,
        pv_errbuf                  IN OUT   VARCHAR2,
        pn_retcode                 OUT      NUMBER
    )
    IS
        vn_project_org_id       NUMBER;
        vn_project_id           NUMBER;
        vv_refac_segment1       VARCHAR2 (7);
        vv_refac_project_name   VARCHAR2 (30);
        vv_segment1             VARCHAR2 (7);
        vv_task_number          VARCHAR2 (15);
        vv_errbuf               VARCHAR2 (200);
        vn_retcode              NUMBER;
        e_error                 EXCEPTION;
        vv_project_company_code gl_ledgers.short_name%TYPE;
        vn_company_code         pa_project_classes.project_id%TYPE;
    BEGIN
        ----- Initialisation des variables -----
        pn_retcode     := 0;
        pv_errbuf      := NULL;

        --déroulement de la procédure
          --SI traitement AR_NORMAL
                --pn_project_id      contient le résultat SELECT ramenant le code projet société emmétrice facture
                --pn_project_id_case_REFAC  est NULL

        --SI traitement AR_REFAC
               --pn_project_id             contient le parametre de sortie de pa_get_code_z_refac
               --pn_project_id_case_REFAC  contient le résultat du SELECT ci-haut

        --Ainsi pn_project_id est déterminé correctement pour controler la tache du projet, le type, etc
        --et pn_project_id_case_REFAC pour les insertions dans les segments de la clé où les deux valeurs sont demandées

        /*SELECT ppc.class_code, ppc.project_id                  -- PHENIX 2004: Ajout.
        INTO  vv_project_company_code, pn_project_id           -- PHENIX 2004: Ajout.
        FROM   pa_projects_all ppa, pa_project_classes ppc     -- PHENIX 2004: Ajout.
        WHERE  ppa.project_id = ppc.project_id                 -- PHENIX 2004: Ajout.
        AND    ppc.class_category = 'SOCIETE'                  -- PHENIX 2004: Ajout.
        AND    ppa.segment1 = pr_rec_line.project_code ;       -- PHENIX 2004: Ajout.*/

        --  Modification R12: On détermine la société du projet à partir du code tâche UNIQUE
        --  RG7
        SELECT GL.SHORT_NAME, ppa.project_id, pt.task_id
        INTO vv_project_company_code, pn_project_id, pn_task_id
        FROM PA_PROJECTS_ALL PPA
        JOIN PA_TASKS PT ON (PPA.PROJECT_ID = PT.PROJECT_ID)
        JOIN HR_OPERATING_UNITS HOU ON (PPA.ORG_ID = HOU.ORGANIZATION_ID)
        JOIN GL_LEDGERS GL ON (HOU.SET_OF_BOOKS_ID = GL.LEDGER_ID)
        WHERE PT.TASK_NUMBER = PR_REC_LINE.SEGMENTATION --PR_REC_LINE.TASK_CODE -- OBE artf2663866
    ;

        --on compare l'org_id du code_projet et l'org_id du mouvement

        --si company_code projet = company_code mouvement => traitement AR_NORMAL -- PHENIX 2004: si l'org_id projet = org_id mouvement -> si company_code projet = company_code
        IF vv_project_company_code = pr_rec_line.company_code -- PHENIX 2004: IF vn_project_org_id = pn_org_id -> IF vv_project_company_code = pr_rec_line.company_code
        THEN
            pn_project_id_case_refac    := NULL; --on initialise a null
            Dka_Tools_Pkg.put_debug_message ('  traitement AR_NORMAL');
        --si l'org_id projet != org_id mouvement => traitement AR_REFAC
        ELSE
            pn_project_id    := NULL; --on initialise car désormais non NULL
            Dka_Tools_Pkg.put_debug_message ('  traitement AR_REFAC');
            --on affecte la valeur de l'org_id du projet AR_REFAC à pn_project_id

            --R12 La fonction pa_get_code_z_refac a été déplacé dans le package DKA_PA_TOOLS_PKG.
            DKA_PA_TOOLS_PKG.pa_get_code_z_refac (
                pn_org_id,
                pr_rec_line.company_code,
                pr_rec_line.region, --code région déterminé à partir du fichier plat.
                vv_refac_segment1, --out code z_refac
                pn_project_id, --out
                vv_refac_project_name, --out
                vv_errbuf,
                vn_retcode
            );



-------------------------------------------------------------------------------
            IF vn_retcode != 0
            THEN
                pv_errbuf     := Dka_Tools_Pkg.get_message (
                                     'DKA',
                                     'DKA_IARPAFAC_E024',
                                     'INV_NUM',
                                     pr_rec_line.invoice_number,
                                     'ORIGINE',
                                     pr_rec_line.origin,
                                     'COMPANY',
                                     pr_rec_line.company_code
                                 );
                Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
                Dka_Tools_Pkg.put_outdebug_message ('Erreur code refac'); --affichage .log + .out

                --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
                Dka_Tools_Pkg.ins_prog_message (
                    gn_request_id, --N°traitement
                    'IARPAFAC', --Non interface
                    'OA', --Source
                    'DKA_IARPAFAC_INTERFACE', --Table
                    pr_rec_line.iarpafac_id, --ID explicite
                    NULL, --Non colonne en question
                    NULL, --valeur colonne
                    'E', --Erreur ou Warning
                    'le code z_refac n''a pas été trouvé'
                ); --texte message
                pn_retcode    := 1;
                RETURN;
            END IF;

            --R12, récupération de la tâche du projet refac pour alimenter l'attribute4 de la ligne de ventilation
            BEGIN
              SELECT task_id
              INTO pn_task_id
              FROM pa_tasks
              WHERE project_id = pn_project_id;
            EXCEPTION
              WHEN NO_DATA_FOUND THEN
                 Dka_Tools_Pkg.put_debug_message ('le projet de Refac n''a pas de tâche définie: '|| pn_project_id);
                 Raise;
            END;

-------------------------------------------------------------------------------

            Dka_Tools_Pkg.put_debug_message ('  organisation du projet : '|| pn_project_id);
            --on ramene l'org_id projet ds pn_project_id_case_REFAC
            --Ainsi pn_project_id_case_REFAC contient bien la valeur attendue
            --pour les segments de la clé en cas de REFAC
            SELECT ppa.project_id
            INTO   pn_project_id_case_refac
            FROM   pa_projects_all ppa
            JOIN   pa_tasks pt ON (ppa.project_id = pt.project_id)
            WHERE  1=1
            -- Modification R12. RG7, on se base sur le task_number du fichier pour récupérer le projet correspondant.
      AND  pt.task_number = pr_rec_line.segmentation -- pr_rec_line.task_code -- OBE artf2663866
            --AND segment1 = pr_rec_line.project_code
            AND template_flag = 'N';


        --(nul besoin de procédure d'erreur ici)

        END IF;

        --on determine le task_id(la tâche)du projet
        vv_segment1    := NULL; --attendu ainsi
        -- RBE

        --R12 PBR RG9/RG11 récupération du task_id en fonction du task_number du fichier plat alimentation de l'attribute7 d ela ligne de ventilation.
        SELECT task_id
        INTO pn_task_id_case_refac
        FROM pa_tasks
        WHERE task_number = pr_rec_line.segmentation -- pr_rec_line.task_code -- OBE artf2663866
    ;

        /*
        Dka_Pa_Tools_Pkg.pa_get_project_task (
            pv_errbuf,
            pn_retcode,
            pn_project_id, --in
            vv_segment1, --in
            pn_task_id, --out
            vv_task_number
        ); --out*/

        Dka_Tools_Pkg.put_debug_message ('Projet : ' || pn_project_id ||' task_id : '|| pn_task_id || ' project refac : '|| pn_project_id_case_refac ||' task refac : '|| pn_task_id_case_refac);

-------------------------------------------------------------------------------
        IF vn_retcode != 0 THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E025',
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'PROJECT_CODE',
                                 pn_project_id
                             );
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'la tache du projet n''a pas été déterminé'
            ); --texte message
            pn_retcode    := 1;
            RETURN;
        END IF;


-------------------------------------------------------------------------------

        Dka_Tools_Pkg.put_debug_message ('tache du projet : '|| pn_task_id);  -- R12 : La tâche est récupérée directement à partir du fichier plat.
    /*
                      --on détermine l'appartenance du projet
                      BEGIN
                        SELECT haou.organization_id
                        INTO   pn_project_appart
                        FROM   pa_cost_dist_overrides pcdo,
                               hr_all_organization_units haou
                        WHERE  pcdo.project_id = vn_project_id
                         AND   pr_rec_line.fmt_invoice_date >= pcdo.start_date_active
                         AND   pr_rec_line.fmt_invoice_date <= nvl (pcdo.end_date_active,pr_rec_line.fmt_invoice_date)
                         AND   pcdo.override_from_organization_id = haou.organization_id;

                      -- On vérifie que la société d'appartenance du projet est identique à celle du mouvement
                      IF  pn_project_appart != pn_org_id
                      THEN

                       NULL;
                       END IF;

                      EXCEPTION
                      WHEN TOO_MANY_ROWS THEN
                      NULL;
                      END;
    */

    EXCEPTION
        WHEN NO_DATA_FOUND THEN
            --le code projet project_code n'est pas valide
            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                 'DKA',
                                 'DKA_IARPAFAC_E009',
                                 'ERROR',
                                 SQLERRM,
                                 'INV_NUM',
                                 pr_rec_line.invoice_number,
                                 'ORIGINE',
                                 pr_rec_line.origin,
                                 'COMPANY',
                                 pr_rec_line.company_code,
                                 'TASK_CODE', --R12
                                 pr_rec_line.segmentation -- pr_rec_line.task_code --R12 -- OBE artf2663866
                             );
           Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); -- OBE artf2209666
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                'Le code tâche ' || pr_rec_line.segmentation /*pr_rec_line.task_code*/ || ' est invalide' --R12 -- OBE artf2663866
            ); --texte message
            pn_retcode    := 1;
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E027', 'ERROR', SQLERRM);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); -- OBE artf2209666
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                pr_rec_line.iarpafac_id, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                SQLERRM
            ); --texte message
            pn_retcode    := 1;--2; -- OBE artf2209666
    END check_project;


---------------------------------------------------------------------------------------------------------------
--  Nom           : run_import
--  Description   : lancement procédure standard du traitement standard RAXMTR
--                  de l'open interface avec la procédure du package standard
--                  FND_REQUEST.SUBMIT_REQUEST
--
--  PARAMETRES    :pv_company_code Entrée
--                 pv_source       Entrée
--                 pn_group_id     Entrée
--                 --pv_hold_code    Entrée
--                 pn_request_id   Sortie
--                 pv_errbuf       Entrée/Sortie    message d'erreur
--                 pn_retcode      Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004
    PROCEDURE run_import (
    pv_company_code        IN       VARCHAR2,
        pv_fmt_origin          IN       VARCHAR2,
        pn_group_id            IN       NUMBER,
        pn_org_id              IN       NUMBER,
        pn_request_id          OUT      NUMBER,
        pv_batch_source_name   IN       VARCHAR2,
        pv_batch_source_id     IN       NUMBER,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        rec_param              dka_parameters%ROWTYPE;
        vv_ar_responsibility   VARCHAR2 (50);
        vn_responsibility_id   NUMBER;
        vn_application_id      NUMBER;
        vn_set_of_books_id     NUMBER;
        vn_batch_source_id     NUMBER;
        e_error                EXCEPTION;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('>run_import ');
        pv_errbuf               := NULL;
        pn_retcode              := 0;

         -- 16/10/19 - NBO - INC0329483 - Optimisation chargement facture CLients
          Fnd_Stats.Gather_Table_Stats(Ownname => 'AR',
                               Tabname => 'RA_INTERFACE_LINES_ALL',
                               Percent => 100,
                               Degree  => 8,
                               Cascade => True);

          Fnd_Stats.Gather_Table_Stats(Ownname => 'AR',
                               Tabname => 'RA_INTERFACE_DISTRIBUTIONS_ALL',
                               Percent => 100,
                               Degree  => 8,
                               Cascade => True);

        --récupération des parametres utilisés par le traitement
        /*Dka_Tools_Pkg.get_parameter ('IARPAFAC', 'AR_RESPONSIBILITY_KEY', rec_param, pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
            RETURN;
        END IF;

        vv_ar_responsibility    := rec_param.varchar2_value;
        Dka_Tools_Pkg.put_debug_message (' parametres utilisés: '|| vv_ar_responsibility);

        --récupération des variables nécessaires au lancement du traitement
        SELECT fr.responsibility_id,
               fr.application_id
        INTO   vn_responsibility_id,
               vn_application_id
        FROM   fnd_responsibility fr
        WHERE  fr.responsibility_key = 'AR' || pv_company_code || ' ' || 'ADMINISTRATEUR';

        Dka_Tools_Pkg.put_debug_message (' variables de lancement : '|| vn_responsibility_id || ' et ' || vn_application_id);
        --récupération du set_of_book_id
        vn_set_of_books_id      := Fnd_Profile.VALUE ('GL_SET_OF_BKS_ID');
        Dka_Tools_Pkg.put_debug_message (' set_of_book_id: '|| vn_set_of_books_id);
        -- initialisation de l-environement OA pour correspondre a la societe en cours de traitement
        Fnd_Global.apps_initialize (Fnd_Global.user_id, vn_responsibility_id, vn_application_id);
        Dka_Tools_Pkg.put_debug_message ('>fnd_global.apps_initialize');*/
        pn_request_id           :=
                Fnd_Request.submit_request (
                    application  => 'AR', --APPL
                    program      => 'RAXMTR', --PROG
                    description  => NULL, --PROGRAM_NAME
                    start_time   => NULL, --START
                    sub_request  => FALSE, --SUB_REQUEST
                    argument1    => 1, --ARGUMENT1 --Number of instances
                    argument2    => pv_batch_source_id, --ARGUMENT2  --Batch source
                    argument3    => pv_batch_source_name, --ARGUMENT3 --Batch source
                    argument4    => Fnd_Date.date_to_canonical (SYSDATE), --Default Date              --ARGUMENT4
                    argument5    => NULL, --Transaction Field            --ARGUMENT5
                    argument6    => NULL, --Transaction Type             --ARGUMENT6
                    argument7    => NULL, --Low Bill to customer num     --ARGUMENT7
                    argument8    => NULL, --High Bill to customer num    --ARGUMENT8
                    argument9    => NULL, --Low Bill to customer name    --ARGUMENT9
                    argument10   => NULL, --High Bill to customer name   --ARGUMENT10
                    argument11   => NULL, --Low GL Date                  --ARGUMENT11
                    argument12   => NULL, --High GL Date                 --ARGUMENT12
                    argument13   => NULL, --Low Ship Date                --ARGUMENT13
                    argument14   => NULL, --High Ship Date               --ARGUMENT14
                    argument15   => NULL, --Low Transaction number       --ARGUMENT15
                    argument16   => NULL, --High Transaction number      --ARGUMENT16
                    argument17   => NULL, --Low Sales order number       --ARGUMENT17
                    argument18   => NULL, --High Sales order number      --ARGUMENT18
                    argument19   => NULL, --Low Invoice date             --ARGUMENT19
                    argument20   => NULL, --High Invoice date            --ARGUMENT20
                    argument21   => NULL, --Low Ship to customer num     --ARGUMENT21
                    argument22   => NULL, --High Ship to customer num    --ARGUMENT22
                    argument23   => NULL, --Low Ship to customer name    --ARGUMENT23
                    argument24   => NULL, --High Ship to customer name   --ARGUMENT24
                    argument25   => 'N', --Base due date on trx date     --ARGUMENT25
                    argument26   => NULL, --Due date adjustment days      --ARGUMENT26,
                    argument27   => Fnd_Profile.Value ('ORG_ID')
                );

        IF pn_request_id IS NULL
        THEN
            pn_retcode    := 1;
            Dka_Tools_Pkg.put_outdebug_message (
                '=> le traitement d''importation n''a pas pu être lancé pour le facteur de regroupement  '|| TO_CHAR (pn_group_id)
            ); -- message tel soc pas pu lancer approb mais pas return
        ELSE
            pn_retcode    := 0;
            Dka_Tools_Pkg.put_outdebug_message ('=> traitement d''import de l''interface coopérative : '|| TO_CHAR (pn_request_id));
            COMMIT; -- commit indispensable à la prise en compte du traitement pour FND_CONCURRENT.WAIT_FOR_REQUEST
        END IF;

        -- Retour dans l'environnement initial
        --Fnd_Global.apps_initialize (gn_user_id, gn_responsibility_id, gn_resp_application_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E033', 'ERROR', SQLERRM);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                NULL, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'W', --Erreur ou Warning
                SQLERRM
            ); --texte message
            pn_retcode    := 2;
    END run_import;
    -- FIN PHENIX 2004


---------------------------------------------------------------------------------------------------------------
--  Nom           : run_recyclage_rejections
--  Description   : lancement procédure standard du traitement standard RAXMTR
--                  de l'open interface avec la procédure du package standard
--                  FND_REQUEST.SUBMIT_REQUEST
--
--  PARAMETRES    :pv_company_code Entrée
--                 pv_source       Entrée
--                 pn_group_id     Entrée
--                 --pv_hold_code    Entrée
--                 pn_request_id   Sortie
--                 pv_errbuf       Entrée/Sortie    message d'erreur
--                 pn_retcode      Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    -- PHENIX 2004
    PROCEDURE run_recyclage_rejections (
        pv_company_code        IN       VARCHAR2,
        pv_batch_source_name   IN       VARCHAR2,
        pn_batch_source_id     IN       NUMBER,
        pn_org_id              IN       NUMBER,
        pn_request_id          OUT      NUMBER,
        pv_errbuf              IN OUT   VARCHAR2,
        pn_retcode             OUT      NUMBER
    )
    IS
        rec_parameters         dka_parameters%ROWTYPE;
        vv_ar_responsibility   VARCHAR2 (50);
        vn_responsibility_id   NUMBER;
        vn_application_id      NUMBER;
        vn_set_of_books_id     NUMBER;
    BEGIN
        Dka_Tools_Pkg.put_debug_message ('>run_recyclage_rejections ');
        pv_errbuf               := NULL;
        pn_retcode              := 0;


        pn_request_id := Fnd_Request.submit_request (
                    application  => 'AR', --APPL
                    program      => 'RAXMTR', --PROG
                    description  => NULL, --PROGRAM_NAME
                    start_time   => NULL, --START
                    sub_request  => FALSE, --SUB_REQUEST
                    argument1    => 1, --ARGUMENT1 --Number of instances
                    argument2    => pn_org_id,---99, -- Organisation. R12 On lance pour toutes les organisations. -- OBE artf2176433
                    argument3    => pn_batch_source_id, --ARGUMENT2  --Batch source
                    argument4    => pv_batch_source_name, --ARGUMENT3 --Batch source
                    argument5    => Fnd_Date.date_to_canonical (SYSDATE), --Default Date              --ARGUMENT4
                    argument6    => NULL, --Transaction Field            --ARGUMENT5
                    argument7    => NULL, --Transaction Type             --ARGUMENT6
                    argument8    => NULL, --Low Bill to customer num     --ARGUMENT7
                    argument9    => NULL, --High Bill to customer num    --ARGUMENT8
                    argument10   => NULL, --Low Bill to customer name    --ARGUMENT9
                    argument11   => NULL, --High Bill to customer name   --ARGUMENT10
                    argument12   => NULL, --Low GL Date                  --ARGUMENT11
                    argument13   => NULL, --High GL Date                 --ARGUMENT12
                    argument14   => NULL, --Low Ship Date                --ARGUMENT13
                    argument15   => NULL, --High Ship Date               --ARGUMENT14
                    argument16   => NULL, --Low Transaction number       --ARGUMENT15
                    argument17   => NULL, --High Transaction number      --ARGUMENT16
                    argument18   => NULL, --Low Sales order number       --ARGUMENT17
                    argument19   => NULL, --High Sales order number      --ARGUMENT18
                    argument20   => NULL, --Low Invoice date             --ARGUMENT19
                    argument21   => NULL, --High Invoice date            --ARGUMENT20
                    argument22   => NULL, --Low Ship to customer num     --ARGUMENT21
                    argument23   => NULL, --High Ship to customer num    --ARGUMENT22
                    argument24   => NULL, --Low Ship to customer name    --ARGUMENT23
                    argument25   => NULL, --High Ship to customer name   --ARGUMENT24
                    argument26   => 'N',  --Base due date on trx date    --ARGUMENT25
                    argument27   => NULL  --Due date adjustment days     --ARGUMENT26,
                );

        IF pn_request_id IS NULL
        THEN
            pn_retcode    := 1;
            Dka_Tools_Pkg.put_outdebug_message ('=> le traitement de recyclage n''a pas pu être lancé pour la société  '|| pv_company_code);
        ELSE
            pn_retcode    := 0;
            Dka_Tools_Pkg.put_outdebug_message ('=> Recyclage automatique de l''interface coopérative : '|| TO_CHAR (pn_request_id));
            COMMIT; -- commit indispensable à la prise en compte du traitement pour FND_CONCURRENT.WAIT_FOR_REQUEST
        END IF;
        -- Retour dans l'environnement initial
        --Fnd_Global.apps_initialize (gn_user_id, gn_responsibility_id, gn_resp_application_id);
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E033', 'ERROR', SQLERRM);
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --texte message
            pn_retcode    := 2;
    END run_recyclage_rejections;

---------------------------------------------------------------------------------------------------------------
--  Nom           : update_prlvt_invoice
--  Description   : Procédure de mise à jour des factures en mode prélèvement
--                  Renseigne les informations relatives au prélèvement dans AR pour les factures concernées
--
--  PARAMETRES    :
--  ************************
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
    PROCEDURE update_prlvt_invoice(pv_errbuf  IN OUT VARCHAR2,
                                   pn_retcode OUT NUMBER) IS

      CURSOR listeFact IS
        SELECT *
          FROM dka_iarpafac_prelev_tmp
         WHERE oa_status in ('P', 'R')
           for update of oa_status, rejection_reason;

      e_fact_rejected EXCEPTION;
      vn_cust_trx_id NUMBER;

    BEGIN

      FOR IC in listeFact LOOP
        BEGIN

          BEGIN

            SELECT customer_trx_id
              INTO vn_cust_trx_id
              FROM RA_CUSTOMER_TRX_ALL rcta
             WHERE rcta.trx_number = IC.invoice_number
               AND rcta.attribute1 = IC.origin
               AND rcta.attribute2 = IC.company_code
               AND rcta.bill_to_customer_id = IC.paying_customer_id
               AND rcta.creation_date > sysdate -5 --JWYC 30/10/2020
               AND rcta.receipt_method_id is null;

          EXCEPTION
            WHEN NO_DATA_FOUND THEN

              UPDATE dka_iarpafac_prelev_tmp
                 set oa_status        = 'R',
                     rejection_reason = 'Facture introuvable dans AR'
               where current of listeFact;

              raise e_fact_rejected;

          END;

          UPDATE RA_CUSTOMER_TRX_ALL
             SET RECEIPT_METHOD_ID         = IC.RECEIPT_METHOD_ID,
                 PAYING_CUSTOMER_ID        = IC.PAYING_CUSTOMER_ID,
                 PAYING_SITE_USE_ID        = IC.PAYING_SITE_USE_ID,
                 PAYMENT_TRXN_EXTENSION_ID = IC.PAYMENT_TRXN_EXTENSION_ID
           WHERE CUSTOMER_TRX_ID = vn_cust_trx_id;

          IF (SQL%ROWCOUNT = 1) THEN

            UPDATE dka_iarpafac_prelev_tmp
               set oa_status = 'A'
             where current of listeFact;

          ELSE

            UPDATE dka_iarpafac_prelev_tmp
               set oa_status        = 'R',
                   rejection_reason = 'Probleme dans la mise a jour, trx_id ' ||
                                      vn_cust_trx_id
             where current of listeFact;

          END IF;

        EXCEPTION
          WHEN e_fact_rejected THEN
            NULL;
          WHEN OTHERS THEN
            pv_errbuf := 'update_prlvt_invoice / Facture ' || IC.invoice_number || ' / ' ||
                         SQLERRM;
            Dka_Tools_Pkg.put_outdebug_message(pv_errbuf);
            pn_retcode := 2;

        END;

      END LOOP;

    END update_prlvt_invoice;

---------------------------------------------------------------------------------------------------------------
--  Nom           : MAIN
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES :
--    pv_errbuf                         Entrée/Sortie           retour de message eventuel
--        pn_retcode                    Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
--
---------------------------------------------------------------------------------------------------------------
    PROCEDURE main (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   OUT      NUMBER
    )
    IS
        vn_origins_cnt                  NUMBER; --compteur d'origines
        vn_invoices_to_create_cnt       NUMBER; --compteur de factures
        vn_lines_to_request_cnt         NUMBER; --compteur de lignes
        vn_first_line_cnt               NUMBER; --controle 1ere ligne passée
        vn_line_num_cnt                 NUMBER; --incrément (de 1) pour line_att4 (ds load_invoice_line)
        vn_fmt_amount_ttc_cnt           NUMBER; --controle montant TTC
        vn_fmt_amount_ht_cnt            NUMBER; --controle montant HT+TAX
        vv_line_type_flag               VARCHAR2 (1); --controle si ligne HT
        vn_error_inv_cnt                NUMBER                   := 0; --compteur de facture en erreur pour le groupe
        vn_error_inv_tot_cnt            NUMBER; --compteur de facture en erreur tous groupes
        vn_requests_cnt                 NUMBER; --compteur de groupe de facture
        vn_link_to_line                 NUMBER; --compteur de ligne pour lien entre ligne HT et TAX pour OA
        vn_ht_cnt                       NUMBER; --compteur
        vn_link_to_line_ht              NUMBER; --compteur de ligne pour lien entre ligne HT et TAX pour package
        va_request_ids                  Pa_Utils.idtabtyp; ---Tableau
        vv_phase      VARCHAR2 (10);
        vv_status     VARCHAR2 (10);
        vv_dev_phase      VARCHAR2 (10);
        vv_dev_status     VARCHAR2 (10);
        vn_erreur     NUMBER (15);
        vn_compteur     NUMBER (15);
        vv_batch_source_name            VARCHAR2 (50); -- PHENIX 2004 : au lieu de 20
        vn_batch_source_id              NUMBER;
        vn_batch_source_id_rejections   NUMBER;
        vv_millesim                     VARCHAR2 (4);
        vn_group_id                     NUMBER; --determine le N° d'un groupe(lot)de factures

        vv_type_mouvement               VARCHAR2(25);-- PHENIX 2004
        vn_cust_acct_site_id            NUMBER;
        vn_cust_account_id              NUMBER;
        vv_partner_code                 VARCHAR2 (30);
        vv_acct_area                    VARCHAR2 (10);
        vd_gl_date                      DATE;
        vd_gl_date_OI                   DATE;
        vn_request_id                   NUMBER;
        vn_project_id_majo              NUMBER;
        vn_task_id_majo                 NUMBER;
        vn_trash                        NUMBER;
        vv_errbuf                       VARCHAR2 (200);
        vn_retcode                      NUMBER;
        e_error                         EXCEPTION;
        e_error_line                    EXCEPTION;
        e_error_invoice                 EXCEPTION;
        e_error_group                   EXCEPTION;
        e_error_main                    EXCEPTION;
        e_error_rejections              EXCEPTION;
        vn_iarpafac_id                  NUMBER; -- Ajout GV20061110 : pour mémoriser l'Id de la facture

        vn_comment_compteur              NUMBER; --compteur de ligne pour le commentaire

        --Curseur sur le regroupement (société / origine / année)
        -- MOdification R12 suppression du champ invoice_date.
        CURSOR cur_group
        IS
            SELECT   company_code,
                     fmt_origin,
                     TO_CHAR(extract(year from fmt_invoice_date)) annee, --SUBSTR (invoice_date, 1, 4) annee*/ Modification R12 PBR
                     region,
                     ORGANIZATION_ID,
                     set_of_books_id,
           IARPAFAC_ID
            FROM     dka_iarpafac_interface dii,
                     HR_OPERATING_UNITS hou
            WHERE        1=1 -- etl_status = 'A' le statut ETL n'existe plus en R12.
                     AND oa_status != 'A'
                     AND oa_request_id = gn_request_id
                     AND line_type = 'CLIENT'
                     and hou.NAME (+) = dii.REGION||dii.company_code
            GROUP BY company_code,
                     fmt_origin,
                     TO_CHAR(extract(year from fmt_invoice_date)),
                     region,
                     ORGANIZATION_ID,
                     set_of_books_id,
           IARPAFAC_ID;--SUBSTR (invoice_date, 1, 4);

        --Curseur sur factures du regroupement sur société, origine amont et numéro de facture et region
        CURSOR cur_invoice (vn_group_id   IN   NUMBER)
        IS
            SELECT   origin,
                     invoice_number,
                     company_code,
                     MAX (link_to_number) indicage,
                     SUM (DECODE (line_type, 'CLIENT', 0, fmt_amount)) mt_total_lignes,
                     region
            FROM     dka_iarpafac_interface
            WHERE        GROUP_ID = vn_group_id
                     --AND etl_status = 'A' le statut ETL n'existe plus en R12
                     AND oa_status != 'A'
            GROUP BY origin,
                     invoice_number,
                     company_code,
                     region;

        --Curseur sur les lignes de la facture courante
        -- l'order by permet d'obtenir la ligne TTC en premier,
        -- puis de regrouper les lignes tax et ht de même taux de tva
        CURSOR cur_line (
            pv_company_code     IN   VARCHAR2,
            pv_origin           IN   VARCHAR2,
            pv_invoice_number   IN   VARCHAR2,
            vn_group_id         IN   NUMBER
        )
        IS
            SELECT   *
            FROM     dka_iarpafac_interface
            WHERE        GROUP_ID = vn_group_id
                     AND invoice_number = pv_invoice_number
                     AND company_code = pv_company_code
                     AND origin = pv_origin
                     AND line_type != 'GESTION'
            ORDER BY DECODE (
                         line_type,
                         'CLIENT', 'A', --permet d'avoir les lignes clients en 1er
                         --'SURTAXE','Z',  --permet d'avoir les lignes surtaxe en dernier
                         DECODE (tax_code, NULL, 'A', '0', 'B', 'C'), DECODE (tax_equal_flag, 'Y', 'B', 'C')
                     ),
                     DECODE (tax_code, NULL, 'A', '0', 'B', 'C' || tax_code), --permet d avoir les lignes avec TVA en dernier
                     function_code, -- Ajout GV20060927 : pour trier par code fonction
                     --tax_line_type, -- Ajout GV20070403 : pour trier par type de compte TVA
                     --ROUND (fmt_amount * TO_NUMBER (tax_rate) / 10000, 1),
                     --DECODE(line_type,    --permet de regrouper les lignes de produit et de gestion qui vont ensemble
                     --       'PRODUIT',round(fmt_amount*to_number(tax_rate)/10000 ,1),
                     ROUND(fmt_amount,1), -- OBE artf2209666
                     line_number;

        -- curseur sur les lignes de TVA
        CURSOR cur_tax_line ( pv_company_code     IN   VARCHAR2,
                              pv_origin           IN   VARCHAR2,
                              pv_invoice_number   IN   VARCHAR2,
                              vn_group_id         IN   NUMBER)
        IS
            SELECT   *
            FROM     dka_iarpafac_interface
            WHERE        GROUP_ID = vn_group_id
                     AND invoice_number = pv_invoice_number
                     AND company_code = pv_company_code
                     AND origin = pv_origin
                     AND line_type = 'GESTION'
            ORDER BY --tax_equal_flag, -- Modif GV20031212
                     DECODE (tax_code, NULL, 'A', '0', 'B', 'C' || tax_code),
                     function_code, -- Ajout GV20060927 : pour trier par code fonction
                     --tax_line_type, -- Ajout GV20070403 : pour trier par type de compte TVA
                     ROUND (fmt_amount, 1),
                     line_number;

        -- AD --
          -- Curseur sur société devant faire l'objet d'un recyclage automatique
          -- Modif GV20031024 : Ce curseur devient en fait le curseur qui va traiter toutes pièces, car
          -- l'import ne se fait plus pièce par pièce mais en une seule fois => mis en commentaire du NOT EXISTS
        CURSOR cur_rejections
        IS
            SELECT   rila.interface_line_attribute2, -- société
                     rila.batch_source_name, -- Origine + millésim
                     rila.org_id -- afin de trouver le batch_source_id
            FROM     ra_interface_lines_all rila
            WHERE    (rila.interface_status != 'P' OR rila.interface_status IS NULL)
                      AND rila.batch_source_name !='REFAC'
                     /* AND NOT EXISTS ( SELECT 'X'
                                      FROM   dka_iarpafac_interface dii
                                      WHERE      dii.oa_status != 'A'
                                             AND dii.etl_status = 'A'
                                             AND dii.line_type = 'CLIENT'
                                             AND dii.company_code = rila.interface_line_attribute2
                                             AND (dii.fmt_origin || '_' || SUBSTR (dii.invoice_date, 1, 4)) =
                                                                                                             rila.batch_source_name) */
            GROUP BY rila.interface_line_attribute2,
                     rila.org_id,
                     rila.batch_source_name;

        -- AD --

        rec_tax_line                    cur_tax_line%ROWTYPE;
        vn_tax_amount                   NUMBER;
        vn_tax_amount_remaining         NUMBER;
        vn_nb_revenue_line_with_tax     NUMBER;
        vn_current_rev_line_with_tax    NUMBER;
        -- AD --
        rec_rejections                  cur_rejections%ROWTYPE;

        -- Ajout variables pour correction calcul TVA GV20060523
        vv_tax_code                     VARCHAR2(50); -- Type de TVA en cours -- YWA artf2099786
        vv_function_code                VARCHAR2(3); -- Ajout GV20060927
        vv_tax_line_type                VARCHAR2(1); -- Ajout GV20070403
        vn_nb_lignes_ht                 NUMBER;      -- Nb de lignes de produits pour le type de TVA en cours
        vn_tax_sum                      NUMBER;      -- Somme des lignes TVA de la table pour le type en cours
        vn_tax_code_sum                 NUMBER;      -- Somme des lignes TVA recalculées pour le type en cours
        vn_tax_difference               NUMBER;      -- Différence entre la TVA en table et la TVA recalculée
        -- Fin ajout variables GV20060523
  -- AD --
        --- 18/05/2009 MT variable declarations
        vv_max_gl_date     DATE;


-------------------------------------------------------------------------------------------------------
    BEGIN --main
        Dka_Tools_Pkg.put_debug_message ('IARPAFAC');
        Dka_Tools_Pkg.put_debug_message ('>main ');


-------------------------------------------------------------------------------------------------------
  /*********************************** INITIALISATION ****************************************/
   ----- Initialisation des variables -----
        pv_errbuf               := NULL;
        pn_retcode              := 0;
        vv_errbuf               := NULL;
        vn_retcode              := 0;
        vn_error_inv_tot_cnt    := 0;
        ----- Initialisation état de sortie -----

        fnd_file.put_line(fnd_file.LOG, 'Entrée dans la phase d''initialisation');
        init (pv_errbuf, pn_retcode);

        IF pn_retcode != 0
        THEN
            RAISE e_error_main;
        END IF;

         -- 16/10/19 - NBO - INC0329483 - Optimisation chargement facture CLients
        Fnd_Stats.Gather_Table_Stats(Ownname => 'DKA',
                               Tabname => 'DKA_IARPAFAC_INTERFACE',
                               Percent => 100,
                               Degree  => 8,
                               Cascade => True);

        --- 18/05/2009 MT start--------------


        --- 18/05/2009 MT end--------------

        ----- Suppression des lignes à 0 -----
        -- Modif GV20040112 : suppression des lignes à zéro si la facture est elle-même nulle
        DELETE dka_iarpafac_interface
        WHERE (((company_code, invoice_number) IN
              (SELECT company_code, invoice_number
               FROM dka_iarpafac_interface
               WHERE line_type = 'CLIENT'
                 AND fmt_amount = 0))
               OR
               oa_status = 'A');

        ---< JWY artf07147612
        DELETE dka_iarpafac_prelev_tmp
        WHERE oa_status = 'A';

        UPDATE dka_iarpafac_prelev_tmp
        SET OA_STATUS = 'P',
        REJECTION_REASON = NULL
        WHERE oa_status in ('P', 'R');
        ---JWY artf07147612>

        ---- initialisation OA_REQUEST_ID dans la table DKA_IARPAFAC_INTERFACE ----
        update_request_id (pv_errbuf, pn_retcode);

        IF vn_retcode != 0
        THEN
            RAISE e_error_main;
        END IF;

        ---- artf2153141 - INT006 - Alimentation de la colonne tax_rate - Defect Bout_en_Bout_Helios_Ref #641
        ---- initialisation TAX_RATE dans la table DKA_IARPAFAC_INTERFACE ----
        update_tax_rate (pv_errbuf, pn_retcode);

        IF vn_retcode != 0
        THEN
            RAISE e_error_main;
        END IF;

--------------------------------------------------------------------------------
        COMMIT;
--------------------------------------------------------------------------------
        ----- Comptage des systèmes amont traités/factures a inserer/lignes a traiter -----
        SELECT COUNT (DISTINCT origin), NVL(SUM(DECODE(line_type,'CLIENT',1,0)),0), COUNT (1)
        INTO   vn_origins_cnt, vn_invoices_to_create_cnt, vn_lines_to_request_cnt
        FROM   dka_iarpafac_interface
        WHERE  oa_request_id = gn_request_id
               AND oa_status != 'A';

        ----- Affichage -----
        Dka_Tools_Pkg.put_outdebug_message (cv_line);
        Dka_Tools_Pkg.put_outdebug_message ('Nombre d''origines à traiter : '|| TO_CHAR (vn_origins_cnt));
        Dka_Tools_Pkg.put_outdebug_message ('Nombre de factures à créer  : '|| TO_CHAR (vn_invoices_to_create_cnt));
        Dka_Tools_Pkg.put_outdebug_message ('Nombre de lignes à traiter  : '|| TO_CHAR (vn_lines_to_request_cnt));

/***************************** TRAITEMENT PAR SOCIETE/ORIGINE ************************************/
--ouverture du curseur sur les différentes origines en attente de traitement
--------------------------------------------------------------------------------------------------
        vn_requests_cnt         := 0; --compteur de groupe de facture

        --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
        fnd_file.put_line(fnd_file.LOG, to_char(sysdate, 'DD/MM/RRRR HH24:MI:SS') || ' : Entrée dans la phase d''initialisation du regroupement');

        FOR rec_group IN cur_group LOOP

--------------------------------------------------------------------------------------------------
            BEGIN --group

--------------------------------------------------------------------------------------------------
                vn_error_inv_cnt    := 0; --facture en erreur

/*************************** REGROUPEMENT ***********************************/

                ---- Attribution d'un numéro de regroupement ----
                BEGIN --group_id
                    SELECT ra_trx_number_1000_s.NEXTVAL
                    INTO   vn_group_id
                    FROM   DUAL;

                    ---- Affichage ----
                    Dka_Tools_Pkg.put_outdebug_message (cv_line);
                    Dka_Tools_Pkg.put_outdebug_message ('TRAITEMENT GROUPE N° '|| vn_group_id);
                    Dka_Tools_Pkg.put_outdebug_message ('ORIGINE (format OA) : '|| rec_group.fmt_origin);
                    Dka_Tools_Pkg.put_outdebug_message ('SOCIÉTÉ : '|| rec_group.company_code);

                    vv_millesim    := rec_group.annee;

                    SELECT max(end_date)
                    INTO  vv_max_gl_date
                    FROM   gl_period_statuses
                    WHERE  closing_status = 'O'
                     AND set_of_books_id = rec_group.set_of_books_id
                     AND application_id = 222;


                    -- update invoice(s) status to Z where the gl_date is in next closing period.
                    UPDATE dka_iarpafac_interface
                    SET    oa_status = 'Z'
                    WHERE  oa_status = 'P'
                    AND    gl_date   > to_char(vv_max_gl_date,'YYYYMM');

                    dka_tools_pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' invoice(s) status has been updated to Z.');

                    -- Update invoice(s) status to P from Z where the gl_date is in current open period.
                    UPDATE dka_iarpafac_interface
                    SET    oa_status = 'P'
                    WHERE  oa_status = 'Z'
                    AND    gl_date   = to_char(vv_max_gl_date,'YYYYMM');

                    dka_tools_pkg.put_debug_message (TO_CHAR (SQL%ROWCOUNT) || ' invoice(s) status has been updated from Z to P.');

                    ---- Mise à jour du champ Group_id dans la table temporaire dka_iarpafac_interface ----
                    update_group_id (rec_group.IARPAFAC_ID,rec_group.company_code, rec_group.region , rec_group.fmt_origin, vn_group_id, vv_millesim, vv_errbuf, vn_retcode);

                    IF vn_retcode != 0
                    THEN
                        RAISE e_error_main;
                    END IF;

                    COMMIT;
                    /************************* DÉTERMINATION DE L'ORG_ID ***************************************/


                    /********************** RECUPERATION DU BATCH_SOURCE_ID ET NAME ****************************/

                    get_millesim_batch_id (
              rec_group.IARPAFAC_ID, --IN --artf3056354 SNIK 23/01/2019
                        rec_group.ORGANIZATION_ID, --IN
                        rec_group.fmt_origin, --IN
                        vv_millesim, --IN
                        rec_group.company_code,
                        vv_batch_source_name, --        OUT
                        vn_batch_source_id, --        OUT
                        vv_errbuf, --IN      OUT
                        vn_retcode
                    ); --         OUT

                    IF vn_retcode = 2
                    THEN
                        RAISE e_error_main;
                    END IF;

                    IF vn_retcode = 1
                    THEN
                        -- Pas de batch_source defini
                        --  -->   On marque les lignes erreur
                        --  --> + On passe au groupe suivant
                        RAISE e_error_group;
                    END IF;

                    -- Affichage
                    Dka_Tools_Pkg.put_outdebug_message ('BATCH_SOURCE_NAME : '|| vv_batch_source_name);
                    Dka_Tools_Pkg.put_outdebug_message ('BATCH_SOURCE_ID : '|| vn_batch_source_id);

-------------------------------------------------------------------------------------------
                END; --group_id


/******************************* TRAITEMENT PAR FACTURE ************************************/
--ouverture du curseur sur les différentes factures en attente de traitement
--------------------------------------------------------------------------------------------
                FOR rec_inv IN cur_invoice (vn_group_id)
                LOOP
---------------------------------------------------------------------------------------------
                    BEGIN --invoice


                        Dka_Tools_Pkg.put_debug_message (cv_line);
                        Dka_Tools_Pkg.put_debug_message ('Mouvement N° '|| rec_inv.invoice_number);
                        Dka_Tools_Pkg.put_debug_message (cv_line);

---------------------------------------------------------------------------------------------

                        -- initialisation des variables de controle du montant et de l'existence d'une ligne HT + cnt de lignes
                        vn_first_line_cnt               := 0; --controle 1ere ligne passée
                        --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
                        vn_line_num_cnt                 := 1; --incrément (de 1) pour line_number (ds load_invoice_line) - On commence à 1 à cause de l'entête
                        vn_fmt_amount_ttc_cnt           := 0; --controle montant TTC
                        vn_fmt_amount_ht_cnt            := 0; --controle montant HT+TAX
                        vv_line_type_flag               := NULL; --controle si ligne HT
                        vn_link_to_line                 := 0; --lien entre ligne de taxe et ht ds OA
                        vn_ht_cnt                       := 0; --compteur de ligne ht
                        vn_link_to_line_ht              := 0; --lien entre ligne de taxe et ht ds package
                        vn_tax_amount                   := 0; --montant de la TVA recalculee a partir de la ligne de produit
                        vn_tax_amount_remaining         := 0; --montant de la TVA restant sur la ligne courante venant du fichier
                        vn_nb_revenue_line_with_tax     := 0; --nb de lignes de produit ou surtaxe avec TVA sur une facture
                        vn_current_rev_line_with_tax    := 0; --"numero" courant de la ligne de produit avec TVA
                        vv_tax_code                     := NULL; -- ajout GV20060523 : init du type de TVA
                        vv_function_code                := NULL; -- ajout GV20060927 : init du code fonction
                        vv_tax_line_type                := NULL; -- ajout GV20070403 : init du type de ligne de TVA
                        --renseignement du tax_equal_flag pour reperer les lignes de TVA directement reliable aux lignes de produit
                        set_tax_equal_flag (vn_group_id, rec_inv.origin, rec_inv.company_code, rec_inv.invoice_number);

                        vn_project_id_majo         := NULL;
                        vn_task_id_majo            := NULL;

                        IF cur_tax_line%ISOPEN
                        THEN
                            CLOSE cur_tax_line;
                        END IF;

                        OPEN cur_tax_line (rec_inv.company_code, rec_inv.origin, rec_inv.invoice_number, vn_group_id);

                        SELECT COUNT (1)
                        INTO   vn_nb_revenue_line_with_tax
                        FROM   dka_iarpafac_interface
                        WHERE      GROUP_ID = vn_group_id
                               AND invoice_number = rec_inv.invoice_number
                               AND company_code = rec_inv.company_code
                               AND origin = rec_inv.origin
                               AND line_type IN ('PRODUIT', 'SURTAXE')
                               AND tax_code IS NOT NULL
                               AND tax_code != '0';

                        --Calcul du project_id du projet majoritaire de ce mouvement
                        -- Modification R12, on récupére l'id du projet majoritaire à partir du task_code présent dans la table.
                        BEGIN
                            SELECT ppa.project_id,pt.task_id
                            INTO   vn_project_id_majo,vn_task_id_majo
                            FROM   pa_projects_all ppa, pa_tasks pt
                            WHERE  1=1
                            AND ppa.project_id = pt.project_id
                            AND pt.task_number = (SELECT DISTINCT task_code --R12 project_code devient task_code.
                                                  FROM            dka_iarpafac_interface
                                                  WHERE 1=1
                                                  AND GROUP_ID = vn_group_id
                                                  AND invoice_number = rec_inv.invoice_number
                                                  AND company_code = rec_inv.company_code
                                                  AND origin = rec_inv.origin
                                                  AND line_type = 'PRODUIT'
                                                  AND fmt_amount = (SELECT MAX (fmt_amount)
                                                                     FROM   dka_iarpafac_interface
                                                                     WHERE 1=1
                                                                     AND GROUP_ID = vn_group_id
                                                                     AND invoice_number = rec_inv.invoice_number
                                                                     AND company_code = rec_inv.company_code
                                                                     AND origin = rec_inv.origin
                                                                     AND line_type = 'PRODUIT'));
                        EXCEPTION
                            WHEN OTHERS THEN
                                vn_project_id_majo    := NULL;
                                vn_task_id_majo       := NULL;
                        END;




/******************************* TRAITEMENT PAR LIGNES DE FACTURE **************************/
--ouverture du curseur sur les différentes lignes de factures en attente de traitement
--------------------------------------------------------------------------------------------
                        FOR rec_line IN cur_line (rec_inv.company_code, rec_inv.origin, rec_inv.invoice_number, vn_group_id)
                        LOOP
---------------------------------------------------------------------------------------------
                            BEGIN

---------------------------------------------------------------------------------------------

                                --LINE_CHECK
                                vn_first_line_cnt    := vn_first_line_cnt + 1;
                                Dka_Tools_Pkg.put_debug_message ('début du traitement des lignes');
                                --on vérifie si la 1ere ligne passée est bien de type CLIENT(entete)
                                --si ce n'est pas le cas => rejet de toutes les lignes
                                IF vn_first_line_cnt = 1 AND rec_line.line_type != 'CLIENT' THEN
----------------------------------------------------------------------------------
                                    pv_errbuf     := Dka_Tools_Pkg.get_message (
                                                         'DKA',
                                                         'DKA_IARPAFAC_E029',
                                                         'INV_NUM',
                                                         rec_line.invoice_number,
                                                         'ORIGINE',
                                                         rec_line.origin,
                                                         'COMPANY',
                                                         rec_line.company_code
                                                     );
                                    Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                                    ----- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages -----
                                    Dka_Tools_Pkg.ins_prog_message (
                                        gn_request_id, --N°traitement
                                        'IARPAFAC', --Non interface
                                        'OA', --Source
                                        'DKA_IARPAFAC_INTERFACE', --Table
                                        rec_line.iarpafac_id, --ID explicite
                                        NULL, --Non colonne en question
                                        NULL, --valeur colonne
                                        'E', --Erreur ou Warning
                                        'la 1ere ligne n''est pas l''entete'
                                    );
                                    pn_retcode    := 1;
                                    --update oa_status de toutes les lignes de la facture à 'R'(Reject)
                                    RAISE e_error_line;
-----------------------------------------------------------------------------------
                                END IF;

                                /******************** LANCEMENT PROCÉDURE PRINCIPALE D'UNE FACTURE *******************/

                                --traitement selon le type de ligne
                                IF rec_line.line_type = 'CLIENT' THEN
                                    Dka_Tools_Pkg.put_debug_message ('Traitement de la ligne CLIENT');
                                    -- Ajout GV20061110 : on mémorise l'Id de la ligne CLIENT pour l'avoir à disposition
                                    --                    en cas d'erreur de pièce deséquilibrée
                                    vn_iarpafac_id := rec_line.iarpafac_id;
                                    -- Fin modif GV20061110

                                    --Modification R12: Le type de mouvement est transcodé par l'EAI. On alimente la variable avec le champ de la table.
                                    vv_type_mouvement := rec_line.typmvt; --Dka_Stransco_Pkg.get_value_f ('CUST_TRX_TYPE',rec_line.fmt_invoice_date, pv_errbuf, rec_line.typmvt);

                                    /*IF vv_type_mouvement IS NULL THEN
                                        Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                                        Dka_Tools_Pkg.ins_prog_message (
                                            gn_request_id, --N°traitement
                                            'IARPAFAC', --Non interface
                                            'OA', --Source
                                            'DKA_IARPAFAC_INTERFACE', --Table
                                            rec_line.iarpafac_id, --ID explicite
                                            'Type de mouvement AR', --Non colonne en question
                                            rec_line.typmvt, --valeur colonne
                                            'E', --Erreur ou Warning
                                            'La transco n''existe pas'
                                        ); --texte message
                                        pn_retcode    := 1;
                                        RETURN;
                                    END IF;*/

                                    --Modification R12 : RG65: Les types de mouvements ne sont plus préfixés du code de la société.
                                    --vv_type_mouvement := rec_line.company_code || '_' || vv_type_mouvement;

                                    -- FIN PHENIX 2004

                                    --FMT_AMOUNT
                                    --on détermine le signe du montant, selon qu'in soit + ou - (FACTURE ou AVOIR)
                                    --on affecte la valeur absolue du montant TTC qu'on comparera au résultat HT+TAX plus bas
                                    --IF vv_typmvt LIKE '%AVO%'
                                    --THEN
                                    --vn_fmt_amount_ttc_cnt := ABS(rec_line.fmt_amount);
                                    --ELSE
                                    vn_fmt_amount_ttc_cnt  := rec_line.fmt_amount;
                                    --END IF;

                                    -- Affichage --
                                    Dka_Tools_Pkg.put_debug_message ('LIGNE N° '|| rec_line.line_number || ' (' || rec_line.line_type || ')');

                                    /************ Lancement des différents controles entête ****************/
                                    load_invoice_header (
                                        rec_line,
                                        rec_group.ORGANIZATION_ID, --IN
                                        rec_group.set_of_books_id,  --IN --R12
                                        vn_cust_acct_site_id, --OUT
                                        vn_cust_account_id, --OUT
                                        vv_partner_code, -- OUT
                                        vv_acct_area, -- OUT
                                        vd_gl_date, -- OUT
                                        vd_gl_date_OI, -- OUT
                                        pv_errbuf,
                                        pn_retcode);

                                    IF pn_retcode = 1
                                    THEN
                                        IF cur_tax_line%ISOPEN
                                        THEN
                                            CLOSE cur_tax_line;
                                        END IF;

                                        RAISE e_error_line;
                                    ELSIF pn_retcode = 2
                                    THEN
                                        IF cur_tax_line%ISOPEN
                                        THEN
                                            CLOSE cur_tax_line;
                                        END IF;

                                        RAISE e_error_main;
                                    END IF;
							
                                    IF (rec_inv.mt_total_lignes != vn_fmt_amount_ttc_cnt) THEN--on vérifie que le montant TTC = total des lignes
--------------------------------------------------------------------------------
                                        pv_errbuf     := Dka_Tools_Pkg.get_message (
                                                             'DKA',
                                                             'DKA_IARPAFAC_E031',
                                                             'INV_NUM',
                                                             rec_inv.invoice_number,
                                                             'ORIGINE',
                                                             rec_inv.origin,
                                                             'COMPANY',
                                                             rec_inv.company_code
                                                         );
                                        Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                                        ----- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages -----
                                        Dka_Tools_Pkg.ins_prog_message (
                                            gn_request_id, --N°traitement
                                            'IARPAFAC', --Non interface
                                            'OA', --Source
                                            'DKA_IARPAFAC_INTERFACE', --Table
                                            rec_line.iarpafac_id, --ID explicite
                                            NULL, --Non colonne en question
                                            NULL, --valeur colonne
                                            'E', --Erreur ou Warning
                                            'le montant TTC est different du total des autres lignes'
                                        );
                                        pn_retcode    := 1;

                                        --MAJ oa_status de toutes les lignes de la facture à 'R'(Reject)
                                        IF cur_tax_line%ISOPEN
                                        THEN
                                            CLOSE cur_tax_line;
                                        END IF;

                                        RAISE e_error_line;
-----------------------------------------------------------------------------------
                                    END IF;

                                ELSE --lignes PRODUIT, GESTION ou SURTAXE
                                    --FMT_AMOUNT
                                    --on cumule les montants HT+TAX qu'on comparera plus bas au montant TTC de la meme facture
                                    --IF vv_typmvt LIKE '%AVO%'
                                    --THEN
                                    --vn_fmt_amount_ht_cnt := ABS(vn_fmt_amount_ht_cnt) + ABS(rec_line.fmt_amount);
                                    --ELSE
                                    vn_fmt_amount_ht_cnt    := vn_fmt_amount_ht_cnt + rec_line.fmt_amount;
                                    --END IF;

                                    --LINE_COUNT
                                    --flag à 'Y' => signal qu'au moins une ligne autre que entete est passée
                                    vv_line_type_flag       := 'Y';

                                    --LINE_NUMBER (cd DOC290 §3.4.1.2)
                                    --Les lignes arrivent de l'amont dans un ordre non identifiées. Pour les regrouper correctement;
                                    --le dernier curseur sur les lignes ordonne les lignes selon le tax_code, le montant et le taux
                                    --(voir def curseur). A ce niveau les lignes arrivent en groupes HT et TAX. Pour identifier chaque
                                    --couple de lignes HT et TAX, l'algorithme suivant est nécessaire :

                                    IF rec_line.line_type = 'PRODUIT' OR rec_line.line_type = 'SURTAXE' THEN
                                        vn_line_num_cnt       := vn_line_num_cnt + 1; --incrément compteur toutes lignes
                                        vn_ht_cnt             := vn_ht_cnt + 1; --incrément compteur ligne ht
                                        vn_link_to_line_ht    := vn_ht_cnt; --affectation du nb de lignes ht passées ds la série
                                        vn_link_to_line       := 0;
                                    ELSIF rec_line.line_type = 'GESTION' THEN
                                        vn_line_num_cnt    := vn_line_num_cnt + 1; --incrément compteur toutes lignes
                                        vn_link_to_line    := vn_line_num_cnt - vn_link_to_line_ht; --ligne total - nb ligne ht de la série
                                        vn_ht_cnt          := 0;
                                    END IF;

                                    -- Affichage --
                                    Dka_Tools_Pkg.put_debug_message ('-------------------------------------------------------');
                                    Dka_Tools_Pkg.put_debug_message ('LIGNE N° '|| vn_line_num_cnt || ' (' || rec_line.line_type || ')');
                                    /*********** Lancement des différents controles lignes ****************/

                                    load_invoice_line (
                                        rec_line, --IN
                                        vn_line_num_cnt, --IN
                                        vn_link_to_line, --IN
                                        vn_cust_acct_site_id, --IN
                                        vn_cust_account_id, --IN
                                        vv_partner_code, --IN
                                        vv_acct_area, --IN
                                        vd_gl_date, --IN
                                        vd_gl_date_OI, --IN
                                        vv_type_mouvement, --PHENIX 2004 vv_typmvt, --IN
                                        rec_group.ORGANIZATION_ID, --IN
                                        vv_batch_source_name, --IN
                                        vn_project_id_majo, --IN
                                        vn_task_id_majo, --IN
                                        rec_inv.indicage, --IN
                                        pv_errbuf,
                                        pn_retcode);

                                    -- si sortie en erreur :
                                            -- un ROLLBACK est effectué(ds e_error_invoice)sur toutes les insertions éventuelles
                                            -- dans les tables d'open interface. Notons que seuls les messages inserrés dans
                                            -- la table dka_program_messages ne seront pas effacés grace à un Autonomouscommit.
                                    IF pn_retcode != 0
                                    THEN
                                        --MAJ oa_status de toutes les lignes de la facture à 'R'(Reject)
                                        IF cur_tax_line%ISOPEN
                                        THEN
                                            CLOSE cur_tax_line;
                                        END IF;

                                        RAISE e_error_line;
                                    END IF;

                                    --Génération automatique de la ligne de TVA

                                    -- Modif GV20040112 : Générer la ligne de TVA que si le tax_rate est différent de 0
                                    --                    afin de ne pas créer de lignes de TVA nulles à tort en cas de
                                    --                    factures exonérées
                                    IF (rec_line.line_type = 'PRODUIT' OR rec_line.line_type = 'SURTAXE')
                                        AND rec_line.tax_code IS NOT NULL
                                        AND rec_line.tax_code != '0'
                                        AND rec_line.tax_rate != 0
                                    THEN
                                        vn_line_num_cnt                 := vn_line_num_cnt + 1; --incrément compteur toutes lignes
                                        vn_link_to_line                 := vn_line_num_cnt - vn_link_to_line_ht; --ligne total - nb ligne ht de la série
                                        vn_ht_cnt                       := 0;
                                        vn_current_rev_line_with_tax    := vn_current_rev_line_with_tax + 1;


                    --- 15/04/2015 BCO INC000000671429 - Demande de correctif suite pb écart de TVA pour petits montants
                                        IF  /*modif TB 28/09/2006 rec_line.tax_equal_flag = 'Y'
                                           OR*/ vn_tax_amount_remaining = 0
                                                 OR /*AND*/ ((vv_tax_code != rec_line.tax_code OR vv_tax_code IS NULL) -- OBE artf2200212
                                                 OR (vv_function_code != rec_line.function_code OR vv_function_code IS NULL))
                                                 --OR (vv_tax_line_type != rec_line.tax_line_type OR vv_tax_line_type IS NULL)) R12
                                        THEN
                                            FETCH cur_tax_line INTO rec_tax_line;
                                            vn_tax_amount_remaining    := rec_tax_line.fmt_amount;
                                            Dka_Tools_Pkg.put_debug_message ('vn_tax_amount_remaining : ' || vn_tax_amount_remaining);

                                        END IF;

                                        -- Ajout GV20060523 : cumul TVA pour correction par type au lieu d'une correction globale
                                        -- => On calcule la somme TVA pour le type en cours
                                        IF NVL(vv_tax_code, '$') <> NVL(rec_tax_line.tax_code, '$')
                                          OR NVL(vv_function_code, '$') <> NVL(rec_tax_line.function_code, '$') -- GV20060927: Ajout rupture sur code fonction
                                            --OR NVL(vv_tax_line_type, '$') <> NVL(rec_tax_line.tax_line_type, '$') -- GV20070403 : Ajour rupture sur type de compte TVA R12
                                        THEN
                                            SELECT SUM(DECODE(line_type, 'PRODUIT', 1, 'SURTAXE', 1, 0)),
                                                   SUM(DECODE(line_type, 'GESTION', fmt_amount, 0))
                                            INTO vn_nb_lignes_ht,
                                                 vn_tax_sum
                                            FROM dka_iarpafac_interface
                                            WHERE group_id = vn_group_id
                                              AND line_type != 'CLIENT'
                                              AND invoice_number = rec_inv.invoice_number
                                              AND company_code = rec_inv.company_code
                                              AND origin = rec_inv.origin
                                              AND tax_code = rec_tax_line.tax_code
                                              AND NVL(function_code, '$') = nvl(rec_tax_line.function_code, '$');  -- Ajout GV20060927
                                              --AND NVL(tax_line_type, '$') = nvl(rec_tax_line.tax_line_type, '$'); -- Ajout GV20070403  R12

                                            -- Mémorisation du rec_tax_line.tax_code dans vv_tax_code, qui va servir de rupture
                                            vv_tax_code := rec_tax_line.tax_code;
                                            vv_function_code := rec_tax_line.function_code; -- Ajout GV20060927
                                            --vv_tax_line_type := rec_tax_line.tax_line_type; -- Ajout GV20070403

                                            -- RAZ de la somme TVA calculée
                                            vn_tax_code_sum := 0;
                                        END IF;


                                        vn_tax_amount :=  ROUND (rec_line.fmt_amount * TO_NUMBER (rec_line.tax_rate) / 10000, 2); --TVA recalculee
                                         Dka_Tools_Pkg.put_debug_message ('rec_line.fmt_amoun : ' || rec_line.fmt_amount);

                                         Dka_Tools_Pkg.put_debug_message ('vn_tax_amount : ' || vn_tax_amount);


                                        vn_tax_amount_remaining         := vn_tax_amount_remaining - vn_tax_amount;
                                        rec_tax_line.fmt_amount         := TO_CHAR (vn_tax_amount); --modification du montant sur le record memorise
                                        vn_tax_code_sum := vn_tax_code_sum + vn_tax_amount; -- ajout GV20060523

                                        --vn_fmt_amount_ht_cnt            := vn_fmt_amount_ht_cnt + rec_tax_line.fmt_amount; --pour controle mt global

                                        /* Mise en commentaire GV20060523
                                        --Rectification de l'eventuel ecart sur lignes de tva recalculees
                                        IF      (vn_current_rev_line_with_tax = vn_nb_revenue_line_with_tax) --on est sur la derniere ligne de produit avec tax, donc la derniere ligne
                                            AND (vn_fmt_amount_ht_cnt != rec_inv.mt_total_lignes) --il y a un ecart sur la tva recalculee
                                        THEN
                                            vn_tax_amount              :=
                                                                   vn_tax_amount - (vn_fmt_amount_ht_cnt - rec_inv.mt_total_lignes); --on enleve l'ecart
                                            vn_tax_amount_remaining    :=
                                                         vn_tax_amount_remaining + (vn_fmt_amount_ht_cnt - rec_inv.mt_total_lignes);
                                            rec_tax_line.fmt_amount    := TO_CHAR (vn_tax_amount);
                                            vn_fmt_amount_ht_cnt       := rec_inv.mt_total_lignes;
                                        END IF;
                                        */

                                        -- Ajout GV20060523 : rectification des écarts sur les lignes de TVA recalculée
                                        --                    par type de TVA
                                        IF vn_nb_lignes_ht = vn_current_rev_line_with_tax
                                        THEN
                                            vn_current_rev_line_with_tax := 0;
                                            vn_tax_difference := vn_tax_sum - vn_tax_code_sum;

                                            IF vn_tax_difference != 0 -- Somme TVA calculée != Somme TVA table
                                            THEN
                                                Dka_Tools_Pkg.put_debug_message('    > Rectification TVA calculée pour le type : ' || vv_tax_code);
                                                Dka_Tools_Pkg.put_debug_message('    > Ecart de : ' || vn_tax_difference);
                                                Dka_Tools_Pkg.put_debug_message('    > Montant ligne TVA ' || vn_tax_amount || ' ajusté de ' || vn_tax_difference);
                                                vn_tax_amount := vn_tax_amount + vn_tax_difference;
                                                rec_tax_line.fmt_amount := TO_CHAR(vn_tax_amount);
                                                vn_tax_amount_remaining := 0;
                                            END IF;
                                        END IF;
                                        vn_fmt_amount_ht_cnt := vn_fmt_amount_ht_cnt + rec_tax_line.fmt_amount; -- déplacé
                                        -- fin ajout GV20060523

                                        -- Affichage --
                                        Dka_Tools_Pkg.put_debug_message ('-------------------------------------------------------');
                                        Dka_Tools_Pkg.put_debug_message ('LIGNE N° '|| vn_line_num_cnt || ' (' || rec_tax_line.line_type || ')');
                                        Dka_Tools_Pkg.put_debug_message ('-------------LIGNE DE TAXE SUPPLEMENTAIRE---------------');

                                        load_invoice_line (
                                            rec_tax_line, --IN
                                            vn_line_num_cnt, --IN
                                            vn_line_num_cnt - 1, -- la ligne de produit associee precede la ligne de tva
                                            --vn_link_to_line,       --IN
                                            vn_cust_acct_site_id, --IN
                                            vn_cust_account_id, --IN
                                            vv_partner_code, --IN
                                            vv_acct_area, --IN
                                            vd_gl_date, --IN
                                            vd_gl_date_OI, --IN
                                            vv_type_mouvement, --PHENIX 2004 vv_typmvt, --IN
                                            rec_group.ORGANIZATION_ID, --IN
                                            vv_batch_source_name, --IN
                                            vn_project_id_majo, --IN
                                            vn_task_id_majo, --IN
                                            rec_inv.indicage, --IN
                                            pv_errbuf,
                                            pn_retcode
                                        );
                                    END IF;
                                -- Fin TVA
                                END IF;

                                -- si sortie en erreur :
                                   -- un ROLLBACK est effectué(ds e_error_invoice)sur toutes les insertions éventuelles
                                   -- dans les tables d'open interface. Notons que seuls les messages inserés dans
                                   -- la table dka_program_messages ne seront pas effacés grace à un Autonomuscommit.
                                IF pn_retcode != 0
                                THEN
                                    --MAJ oa_status de toutes les lignes de la facture à 'R'(Reject)
                                    IF cur_tax_line%ISOPEN
                                    THEN
                                        CLOSE cur_tax_line;
                                    END IF;

                                    RAISE e_error_line;
                                END IF;
                            EXCEPTION --curseur line
                                WHEN e_error_line
                                THEN
                                    RAISE e_error_invoice;
                                WHEN OTHERS
                                THEN
                                    ROLLBACK;
                                    Dka_Tools_Pkg.put_debug_message ('>procedure main (line) : '|| SQLERRM);
                                    pn_retcode    := 2;
                                    RAISE e_error_main;
                            END; --invoice

------------------------------------------------------------------------------------------
                        END LOOP; --rec_line


------------------------------------------------------------------------------------------
                        IF cur_tax_line%ISOPEN
                        THEN
                            CLOSE cur_tax_line;
                        END IF;

                        -- LINE_COUNT
                        -- on vérifie qu'il a bien au moins une ligne de ventilation passée
                        -- si vv_line_type_flag != 'Y' => aucune lignes n'est pasées
                        IF NVL(vv_line_type_flag,'N') != 'Y'
                        THEN

---------------------------------------------------------------------------------
                            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                                 'DKA',
                                                 'DKA_IARPAFAC_E030',
                                                 'INV_NUM',
                                                 rec_inv.invoice_number,
                                                 'ORIGINE',
                                                 rec_inv.origin,
                                                 'COMPANY',
                                                 rec_inv.company_code
                                             );
                            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                            ----- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages -----
                            Dka_Tools_Pkg.ins_prog_message (
                                gn_request_id, --N°traitement
                                'IARPAFAC', --Non interface
                                'OA', --Source
                                'DKA_IARPAFAC_INTERFACE', --Table
                                NULL, --ID explicite
                                'invoice_number', --Non colonne en question
                                rec_inv.invoice_number, --valeur colonne
                                'E', --Erreur ou Warning
                                'aucune ligne de ventilation'
                            );
                            pn_retcode    := 1;
                            --MAJ oa_status de toutes les lignes de la facture à 'R'(Reject)
                            RAISE e_error_invoice;

-----------------------------------------------------------------------------------
                        END IF;

                        --FMT_AMOUNT
                        --on vérifie que le montant TTC = HT+TAX

                        IF vn_fmt_amount_ht_cnt != vn_fmt_amount_ttc_cnt
                        THEN

---------------------------------------------------------------------------------
                            pv_errbuf     := Dka_Tools_Pkg.get_message (
                                                 'DKA',
                                                 'DKA_IARPAFAC_E031',
                                                 'INV_NUM',
                                                 rec_inv.invoice_number,
                                                 'ORIGINE',
                                                 rec_inv.origin,
                                                 'COMPANY',
                                                 rec_inv.company_code
                                             );
			
                            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
                            Dka_Tools_Pkg.put_outdebug_message ('vn_fmt_amount_ht_cnt : ' || vn_fmt_amount_ht_cnt);
                            Dka_Tools_Pkg.put_outdebug_message ('vn_fmt_amount_ttc_cnt : ' || vn_fmt_amount_ttc_cnt);
                            ----- Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages -----
                            -- Modif GV20031024 : Ajout du N° de facture pour le message d'erreur
                            -- Modif GV20061110 : Ajout de l'ID de ligne client mémorisée pour qu'elle apparaisse dans l'état
                            Dka_Tools_Pkg.ins_prog_message (
                                gn_request_id, --N°traitement
                                'IARPAFAC', --Non interface
                                'OA', --Source
                                'DKA_IARPAFAC_INTERFACE', --Table
                                vn_iarpafac_id, --ID explicite
                                'ORIGIN|INVOICE_NUM|SOCIETE', --Non colonne en question
                                rec_inv.origin || '|' || rec_inv.invoice_number || '|' || rec_inv.company_code, --valeur colonne
                                'E', --Erreur ou Warning
                                'le montant TTC est different de HT+TAX'
                            );
                            pn_retcode    := 1;
                            --MAJ oa_status de toutes les lignes de la facture à 'R'(Reject)
                            RAISE e_error_invoice;

-----------------------------------------------------------------------------------
                        END IF;

                        /************************* VALIDATION DE LA FACTURE COURANTE ************************/
                        UPDATE dka_iarpafac_interface
                        SET    oa_status = 'A'
                        WHERE  1=1
                        AND GROUP_ID = vn_group_id
                        AND invoice_number = rec_inv.invoice_number
                        AND company_code = rec_inv.company_code;

                        COMMIT;

                    /*********************** EXCEPTION du curseur 'cur_invoice' ************************/
                    EXCEPTION --curseur invoice
                        WHEN e_error_invoice
                        THEN
                            ROLLBACK;

                            BEGIN
                                UPDATE dka_iarpafac_interface
                                SET    oa_status = 'R'
                                WHERE      GROUP_ID = vn_group_id
                                       AND invoice_number = rec_inv.invoice_number
                                       AND company_code = rec_inv.company_code;

                                Dka_Tools_Pkg.put_debug_message ('MAJ oa_status à ''R''(rejet curseur invoice)');
                                Dka_Tools_Pkg.put_outdebug_message (cv_line);
                                vn_error_inv_cnt        := vn_error_inv_cnt + 1; --compteur de facture en erreur pour le groupe
                                vn_error_inv_tot_cnt    := vn_error_inv_tot_cnt + 1; --compteur de facture en erreur tous groupes
                                COMMIT;
                            EXCEPTION
                                WHEN OTHERS
                                THEN
                                    pn_retcode    := 2;
                                    RAISE e_error_main;
                            END;

                            IF pn_retcode = 2
                            THEN
                                RAISE e_error_main;
                            END IF;
                        WHEN OTHERS
                        THEN
                            ROLLBACK;
                            pn_retcode    := 2;
                            RAISE e_error_main;
                    END; --invoice

---------------------------------------------------------------------------------------------------
                END LOOP; --rec_inv

                Dka_Tools_Pkg.put_outdebug_message (cv_line);

---------------------------------------------------------------------------------------------------
                Dka_Tools_Pkg.put_outdebug_message (
                    NVL (vn_error_inv_cnt, '0') || ' facture(s) en erreur pour le groupe N° ' || vn_group_id
                );
                Dka_Tools_Pkg.put_outdebug_message (cv_line);

------------------------------------------------------------------------------------------------------

            EXCEPTION -- curseur group
                WHEN e_error_group THEN
                    -- On passe les factures attachees au groupe en erreur
                    UPDATE dka_iarpafac_interface
                    SET    oa_status = 'R',
                           last_update_date = SYSDATE
                    WHERE  GROUP_ID = vn_group_id;

                    SELECT COUNT (*)
                    INTO   vn_trash
                    FROM   dka_iarpafac_interface
                    WHERE      oa_status = 'R'
                           AND GROUP_ID = vn_group_id
                           AND line_type = 'CLIENT';

                    -- vn_trash := SQL%ROWCOUNT;

                    Dka_Tools_Pkg.put_debug_message ('MAJ oa_status à ''R''(rejet curseur groupe)');
                    vn_error_inv_cnt        := vn_error_inv_cnt + vn_trash; --compteur de facture en erreur pour le groupe
                    vn_error_inv_tot_cnt    := vn_error_inv_tot_cnt + vn_trash; --compteur de facture en erreur tous groupes
                    Dka_Tools_Pkg.put_outdebug_message (cv_line);
                    Dka_Tools_Pkg.put_outdebug_message (
                        NVL (vn_error_inv_cnt, '0') || ' facture(s) en erreur pour le groupe N° ' || vn_group_id
                    );
                    Dka_Tools_Pkg.put_outdebug_message (cv_line);
                    COMMIT;
                -- On passe au groupe suivant de la boucle
                WHEN OTHERS
                THEN
                    ROLLBACK;
                    pn_retcode    := 2;
                    RAISE e_error_main;
            END; --group

-------------------------------------------------------------------------------------------------------
        END LOOP; --rec_group

        --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
        fnd_file.put_line(fnd_file.LOG, to_char(sysdate, 'DD/MM/RRRR HH24:MI:SS') || ' : Fin dans la phase d''initialisation du regroupement');


        Dka_Tools_Pkg.put_outdebug_message (cv_line);

-------------------------------------------------------------------------------------------------------
        Dka_Tools_Pkg.put_outdebug_message ('Total facture(s) en erreur : '|| NVL (vn_error_inv_tot_cnt, '0'));
        Dka_Tools_Pkg.put_outdebug_message (cv_line);
        -------------------------------------------------------------------------------------------------------
-- AD --
  -- Modif GV20031024 : Ajout du calcul de statistiques avant import
  -- Début modif EMA du 25/10/2006 : le calcul des statistiques devient obsolète
  -- EXECUTE IMMEDIATE 'ANALYZE TABLE AR.RA_INTERFACE_LINES_ALL ESTIMATE STATISTICS';
  -- Fin modif EMA du 25/10/2006
  --
  vn_compteur := 0;
  vn_erreur   := 0;

    --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
  Dka_Tools_Pkg.put_log_message('Préparation du recyclage automatique des rejets dans l open interface');

        OPEN cur_rejections;

        LOOP
            FETCH cur_rejections INTO rec_rejections;
            EXIT WHEN cur_rejections%NOTFOUND;

            BEGIN
                Dka_Tools_Pkg.put_outdebug_message ('------------------------------------------------------------------');
                Dka_Tools_Pkg.put_outdebug_message ('RECYCLAGE SOCIÉTÉ : '|| rec_rejections.interface_line_attribute2);

                SELECT rbs.batch_source_id
                INTO   vn_batch_source_id_rejections
                FROM   ra_batch_sources_all rbs
                WHERE  1=1
                AND NAME = rec_rejections.batch_source_name
                AND org_id = rec_rejections.org_id;

                IF SQL%ROWCOUNT = 0
                THEN
                    RAISE e_error_rejections;
                END IF;

                run_recyclage_rejections (
                    rec_rejections.interface_line_attribute2, --IN
                    rec_rejections.batch_source_name, -- IN
                    vn_batch_source_id_rejections, -- IN
                    rec_rejections.org_id, -- IN
                    vn_request_id, --OUT
                    pv_errbuf,
                    pn_retcode
                );
                Dka_Tools_Pkg.put_outdebug_message ('------------------------------------------------------------------');
                vn_compteur := vn_compteur + 1;
                va_request_ids (vn_compteur) := vn_request_id;

                IF pn_retcode = 2
                THEN
                    RAISE e_error_main;
                END IF;
            EXCEPTION
                WHEN e_error_rejections
                THEN
                    Dka_Tools_Pkg.put_outdebug_message ('!!! Erreur : le traitement de recyclage n''a pas été lancé');
                    Dka_Tools_Pkg.put_outdebug_message ('!!! Le batch_Source n''est pas défini');
                    Dka_Tools_Pkg.put_outdebug_message ('!!! Nom: '|| rec_rejections.batch_source_name);
                    Dka_Tools_Pkg.put_outdebug_message ('!!! Organisation: '|| rec_rejections.interface_line_attribute2|| ' ('|| TO_CHAR (rec_rejections.org_id)|| ')');
                    Dka_Tools_Pkg.put_outdebug_message ('------------------------------------------------------------------');
                WHEN OTHERS
                THEN
                    pv_errbuf    := Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E034', 'ERROR', SQLERRM);
                    Dka_Tools_Pkg.put_outdebug_message (pv_errbuf); --affichage .log + .out
            END;
        END LOOP;

        CLOSE cur_rejections;

        -- Modif GV20031024 : Ajout d'un wait_for_request pour attendre la fin de l'import de toutes les pièces
        WHILE vn_compteur > 0
        LOOP
        IF NOT (Fnd_Concurrent.wait_for_request(va_request_ids(vn_compteur),
                                                15,
                                                0,
                                                vv_phase,
                                                vv_status,
                                                vv_dev_phase,
                                                vv_dev_status,
                                                vv_errbuf))
        THEN
          Dka_Tools_Pkg.put_outdebug_message(vn_erreur||'Traitement numéro ' || TO_CHAR(va_request_ids(vn_compteur)) || ' trop long ou tombé en erreur');
          vn_erreur := vn_erreur + 1;
        ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL')
        THEN
          Dka_Tools_Pkg.put_debug_message('Traitement numéro ' || TO_CHAR(va_request_ids(vn_compteur)) || ' correctement exécuté');
        ELSE
          Dka_Tools_Pkg.put_outdebug_message(vn_erreur||'Traitement numéro ' || TO_CHAR(va_request_ids(vn_compteur)) || ' trop long ou tombé en erreur');
          vn_erreur := vn_erreur + 1;
        END IF;  ----- >fin IF NOT -----
              vn_compteur := vn_compteur - 1;
        END LOOP;
        -- Fin Modif GV20031024
        --  17/04/2019 NBO TASK0075220  : Optimisation du traitement import factures AR
        Dka_Tools_Pkg.put_log_message ('Fin du recyclage automatique des rejets dans l''open interface');

        COMMIT;

        -- JWY artf07147612
        update_prlvt_invoice(pv_errbuf, pn_retcode);

        COMMIT;
-- AD --
---------------------------------------------------------------------------------------------------------------
    EXCEPTION --main
        WHEN e_error_main
        THEN
            Dka_Tools_Pkg.put_debug_message ('le traitement s''est terminé en erreur de type OTHERS');
            Dka_Tools_Pkg.put_debug_message (SQLERRM);
            Dka_Tools_Pkg.put_debug_message (pv_errbuf);
            RETURN;
        WHEN OTHERS
        THEN
            pn_retcode    := 2;
            pv_errbuf     := SQLERRM; --Dka_Tools_Pkg.get_message ('DKA', 'DKA_IARPAFAC_E031', 'ERROR', SQLERRM); -- OBE artf2209666
            Dka_Tools_Pkg.put_outdebug_message (pv_errbuf);
            Dka_Tools_Pkg.put_debug_message ('>main : '|| SQLERRM);
            --Insertion du vv_errbuf dans la table des messages d'erreurs dka_program_messages -----
            Dka_Tools_Pkg.ins_prog_message (
                gn_request_id, --N°traitement
                'IARPAFAC', --Non interface
                'OA', --Source
                'DKA_IARPAFAC_INTERFACE', --Table
                NULL, --ID explicite
                NULL, --Non colonne en question
                NULL, --valeur colonne
                'E', --Erreur ou Warning
                SUBSTR (SQLERRM, 1, 197)
            );
    END main;
------------------------------------------------------------------------------------------
---------------------
END Dka_Iarpafac_Pkg; -- Package body

/
SHOW ERRORS
EXIT;
