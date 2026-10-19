CREATE OR REPLACE PACKAGE BODY DKA_SGLEQUILIB_PKG
AS
---------------------------------------------------------------------------------------------------------------
-- CAP GEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM                 : DKA_SGLEQUILIB_PKG.pkb
-- DESCRIPTION         : EQUILIBRE COMPTABLE PAR CENTRE DE GESTION
--
--- AUTEUR         : Samira LARDJOUNE (Cap gemini)
--- DATE DE CREATION : 23/06/2005
--- DOC. ASSOCIEE    :
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 01/03/2006  SL  Rajout des conditions sur set_of books_id
--- 11/05/2007  SL  Modifi Init, Ajout de la fonction check_param permettant de vérifier l'exsitance du paramétrage de la pièce répétitive
---                 pour toutes les classes. Modification suite adaptations aux normes IFRS et création d'une nouvelle clé
--                  de synthèse D.D.CLASSE.T.T.T.T.T.T.T
--- 11/12/2007  SL  Insert_param, get_rec_header_id, get_line_num, update_num_line,main : Insertion en automatique
--                  du paramétrage manquant dans le lot de pièces répétitives
--  21/07/2009  SL  Adaptation des différentes fonctions/procédures pour prendre en compte l'éclatement du lot
--                  d'equilibre par centre de gestion en plusieurs lots (un par société segmentée)
--  12/05/2016 JPE  MIGRATION : Adaptation des différentes fonctions/procédures pour les adapter à l'environnement R12
--  11/01/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
--  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
--  20/07/2017 RBE artf2199612 : SPE084 - Nouvelle clé de synthèse - defect beB # 939
--  18/05/2018 NBO artf2650476 - INC0204377 - Société 0804 / GL : absence d'équilibrage par Centre de Gestion
--  06/05/2019 AAM artf07249170 - SPE084 - Equilibre par centre de gestion en avertissement (INC0314336)
--  13/09/2019 JWY artf07249170 - SPE084 - Equilibre par centre de gestion en avertissement - Exclusion des UO inactives
---------------------------------------------------------------------------------------------------------------
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PUBLIQUES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
gv_period_name                        VARCHAR2(10);
--gv_recurring_batch_id                 NUMBER (10);
gv_set_of_book_id                     NUMBER(5) ;
gv_sob_name                           VARCHAR2(10);
gv_access_set_id                      NUMBER(5) ;
gv_je_batch_id                        gl_je_batches.je_batch_id%TYPE;
gv_autopost_set_id                    gl_automatic_posting_sets.autopost_set_id%TYPE;
gv_user_id                            fnd_user.user_id%TYPE;
--gv_responsibility_id                  fnd_responsibility.responsibility_id%TYPE;
--gv_application_id                     fnd_responsibility.application_id%TYPE;
gv_nb_ko_nb                           NUMBER(5); -- cpteur d'erreur non bloquant

-- JPE 12/05/2016 Migration R12 : RG3 : Une pièce sera générée pour chaque société segmentée. Son nom sera de la forme "REGUL EQUILIBRE CDG"
-- JPE 12/05/2016 Migration R12 : RG7 : Le nom du lot généré sera "REGUL EQUILIBRE CDG"
gv_header_name                        VARCHAR2(30) := 'REGUL EQUILIBRE CDG';
gv_je_category_name                   VARCHAR2(30) ;
gv_je_category                        VARCHAR2(30) ;
gv_currency_code                      VARCHAR2(30) := 'EUR';
--gv_batch_name                         VARCHAR2(30) ;
gv_cpte_equil_1_7                     VARCHAR2(30) ;
gv_cpte_gpe_equil_1_7                 VARCHAR2(30) ;
gv_cpte_equil_8                       VARCHAR2(30) ;
gv_cpte_gpe_equil_8                   VARCHAR2(30) ;
gv_cpte_equil_9                       VARCHAR2(30) ;
gv_cpte_gpe_equil_9                   VARCHAR2(30) ;
gv_amount_type                        VARCHAR2(10);
gv_cle_synthese                          gl_summary_templates.concatenated_description%TYPE;

vv_rec_header_id                      NUMBER;
vv_rec_batch_id                       NUMBER;
vv_rec_line_num                       NUMBER;
vv_rule_num                           NUMBER;
vn_ccid                               gl_code_combinations.code_combination_id%TYPE;
vv_errbuf                             VARCHAR2(1000);
vn_retcode                            NUMBER;
cpt                                   NUMBER := 0;
incorrect_key                         EXCEPTION;
error_data                            EXCEPTION;

Vn_Request_Id_GLPAUTOP                Fnd_Concurrent_Requests.Request_Id%TYPE;
Vn_Request_Id_GLPRJE                  Fnd_Concurrent_Requests.Request_Id%TYPE; --identifiant traitement repetitive
Vn_nb_traitement                      Number := 0;
Gv_nb_KO                              Number := 0;

-- Exception Sortie du programme
Erreur_Prog_E EXCEPTION;

gv_template_id                        NUMBER(5); -- 11/05/2007

TYPE Myrecord IS RECORD(
Request_Id                            Fnd_Concurrent_Requests.Request_Id%TYPE,
Recurring_Batch_Id                    Gl_Recurring_Batches.Recurring_Batch_Id%TYPE,
Recurring_Batch_Name                  Gl_Recurring_Batches.Name%TYPE,
Traitement_Ok                         VARCHAR2(2));

TYPE Mytable IS TABLE OF Myrecord INDEX BY BINARY_INTEGER;

Gt_Request_Id                         Mytable;

--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--+++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
--  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
 PROCEDURE get_code_combination_id(pv_segment1            IN VARCHAR2,
                                   pv_segment2            IN VARCHAR2,
                                   pv_segment3            IN VARCHAR2,
                                   pv_segment4            IN VARCHAR2,
                                   pv_segment5            IN VARCHAR2,
                                   pv_segment6            IN VARCHAR2,
                                   pv_segment7            IN VARCHAR2,
                                   pv_segment8            IN VARCHAR2,
                                   pv_segment9            IN VARCHAR2,
                                   pv_segment10           IN VARCHAR2,
                                   pv_segment11           IN VARCHAR2,
                                   pv_segment12           IN VARCHAR2,
                                   pn_code_combination_id OUT NUMBER,
                                   pv_errbuf              OUT VARCHAR2,
                                   pn_retcode             OUT NUMBER,
                                   pv_validation_flag     IN VARCHAR2 DEFAULT 'Y');

---------------------------------------------------------------------------------------------------------------
--  Nom           : get_first_char
--  Description   : Fonction pour chercher la premiere lettre en fonction du code societé
--
--  AUTEUR     : RBE artf2199612
--  PARAMETRES :
--  VALEUR RETOURNEE : Caractere trouvé
---------------------------------------------------------------------------------------------------------------
 FUNCTION get_first_char
 RETURN VARCHAR2
 IS
 code_ascii NUMBER := 65; --Correspond à lettre A
 BEGIN
    code_ascii := code_ascii + TRUNC(TO_NUMBER(gv_sob_name)/1000);
    return CHR(code_ascii);
 END;
---------------------------------------------------------------------------------------------------------------
--  Nom           : Init
--  Description   : Procédure d'initialisation, Récupération des paramètres
--
--  PARAMETRES :
--  pn_period                 Entree             Nom de la période
--  pn_batch_name             Entree             Nom du lot répétitif
--  pn_access_set_id         Entree             Set_of_book_id
--  pv_errbuf                 Entree/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A

--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 PROCEDURE  Init
            (pn_period            IN  VARCHAR2,
             pv_errbuf            IN OUT   VARCHAR2,
             pn_retcode           IN OUT   NUMBER
            ) Is

  vr_data             DKA_PARAMETERS%ROWTYPE;

 BEGIN

    dka_tools_pkg.put_debug_message ('Init(+)');

    --  11/01/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
    /*Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'GL_RESPONSIBILITY_KEY', vr_data, pn_retcode, pv_errbuf);

    select     fr.responsibility_id,
            fr.application_id,
            fnd_global.USER_ID
    into       gv_responsibility_id,
            gv_application_id,
            gv_user_id
    from       fnd_responsibility fr
    where      fr.responsibility_key = vr_data.varchar2_value;

    -- connexion à la responsabilité
    fnd_global.APPS_INITIALIZE (gv_user_id, gv_responsibility_id, gv_application_id);
   */
   --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
   gv_user_id := Fnd_Profile.VALUE ('USER_ID');

   SELECT   pn_period
   INTO     gv_period_name
   FROM     dual;

   SELECT   Fnd_Profile.VALUE ('GL_ACCESS_SET_ID')
   INTO     gv_access_set_id
   FROM     dual;

   Dka_tools_pkg.put_debug_message ('access_set_id : ' || gv_access_set_id);

   Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'GL_AUTOPOST_SET_NAME', vr_data, pn_retcode, pv_errbuf);
   dka_tools_pkg.put_debug_message ('GL_AUTOPOST_SET_NAME vr_data.varchar2_value ' || vr_data.varchar2_value);
   SELECT   autopost_set_id
   INTO     gv_autopost_set_id
   -- JPE 17/05/2016 Migration R12 : VUE EN R12
   FROM     gl_automatic_posting_sets gaps
   WHERE    1 = 1
   AND      gaps.autopost_set_name = vr_data.varchar2_value;
   -- JPE 17/05/2016 MIGRATION R12 : Champ set_of_books_id renommé par set_of_books_id_11I
   -- AND      gaps.set_of_books_id_11I = gv_set_of_book_id; -- modif 01/03/2006

  Dka_tools_pkg.put_debug_message ('Récupération des informations pour l autoimputation ----> Ok ');

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'GL_CLE_SYNTHESE', vr_data, pn_retcode, pv_errbuf); --10/05/2007
  gv_cle_synthese := vr_data.varchar2_value;

  Dka_tools_pkg.put_debug_message ('Connexion etablie ----> Ok ');

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'CPTE_LOC_EQUIL_1_7', vr_data, pn_retcode, pv_errbuf);
  gv_cpte_equil_1_7 := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'CPTE_LOC_EQUIL_8', vr_data, pn_retcode, pv_errbuf);
  gv_cpte_equil_8 := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'CPTE_LOC_EQUIL_9', vr_data, pn_retcode, pv_errbuf);
  gv_cpte_equil_9 := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'CPTE_GPE_EQUIL_1_7', vr_data, pn_retcode, pv_errbuf);
  gv_cpte_gpe_equil_1_7 := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'CPTE_GPE_EQUIL_8', vr_data, pn_retcode, pv_errbuf);
  gv_cpte_gpe_equil_8 := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'CPTE_GPE_EQUIL_9', vr_data, pn_retcode, pv_errbuf);
  gv_cpte_gpe_equil_9 := vr_data.varchar2_value;

  --Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'GL_RECURRING_BATCH_NAME', vr_data, pn_retcode, pv_errbuf);
  --gv_batch_name := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'TYPE_MONTANT', vr_data, pn_retcode, pv_errbuf);
  gv_amount_type := vr_data.varchar2_value;

  Dka_Tools_Pkg.get_parameter('DKA_SGLEQUILIB', 'TYPE_PIECE', vr_data, pn_retcode, pv_errbuf);
  gv_je_category_name := vr_data.varchar2_value;

  Select je_category_name
  Into   gv_je_category
  From   gl_je_categories_tl gjc
  Where  gjc.language = 'F'
  And    gjc.user_je_category_name = gv_je_category_name;

   Dka_tools_pkg.put_debug_message ('Init (-)');

 Exception
  When Others then
            pv_errbuf     := 'sortie de Init avec erreur EXCEPTION OTHERS:' || SQLERRM;
            pn_retcode    := 2;
            dbms_output.put_line ( 'Problème dans la phase d initialisation ---> ECHEC');
 End Init;

---------------------------------------------------------------------------------------------------------------
--  Nom           : LAUNCH_REQUEST
--  Description   : Procédure lançant la génération des pièces répétitives
--
--  pv_errbuf                 Entree/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 Procedure  launch_request
            (
            pv_errbuf    IN OUT   VARCHAR2,
            pv_retcode   OUT   NUMBER
            ) Is


CURSOR CUR_LOT
IS
SELECT distinct gjb.recurring_batch_id,
       gjb.name
FROM   gl_recurring_batches gjb
WHERE  1 = 1
--  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
AND    gjb.recurring_batch_type = 'M'
AND    EXISTS (
          SELECT gjb.recurring_batch_id, count(grh.recurring_header_id) from
          gl_recurring_headers grh,
          gl_period_statuses gps
          where  1 = 1
          and    grh.je_category_name = gv_je_category
          and    grh.recurring_batch_id = gjb.recurring_batch_id
          and    gps.application_id =  101
          --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
          --and    gps.set_of_books_id = gv_set_of_book_id
          and    gps.period_name = gv_period_name
          and    nvl(grh.start_date_active,gps.start_date) <= gps.start_date
          and    nvl(grh.end_date_active,gps.end_date) >= gps.end_date
          group by gjb.recurring_batch_id
          having count(grh.recurring_header_id) >= 1
          )
AND NOT EXISTS (
          SELECT 'X' from
          gl_recurring_headers grh,
          gl_period_statuses gps
          where  1 = 1
          and    grh.je_category_name != gv_je_category
          and    grh.recurring_batch_id = gjb.recurring_batch_id
          and    gps.application_id =  101
          --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
          --and    gps.set_of_books_id = gv_set_of_book_id
          and    gps.period_name = gv_period_name
          and    nvl(grh.start_date_active,gps.start_date) <= gps.start_date
          and    nvl(grh.end_date_active,gps.end_date) >= gps.end_date
          )
;


 BEGIN
     Vn_nb_traitement := 0;
     dka_tools_pkg.put_debug_message ('launch_request (+)');

     dka_tools_pkg.put_debug_message ('param : '|| 'gv_je_category : '|| gv_je_category || ' *** '
                                  --    ||' gv_set_of_book_id '||gv_set_of_book_id
                                      ||' gv_access_set_id '|| gv_access_set_id
                                      ||' gv_period_name '|| gv_period_name
                                      );

     FOR REC_LOT IN CUR_LOT LOOP

      dka_tools_pkg.put_debug_message ('traitement lot : '||REC_LOT.name );

       Vn_Request_Id_GLPRJE := Fnd_Request.Submit_Request (
                                   'SQLGL'              -- APPLICATION SHORT NAME
                                 , 'GLPRJE'        -- CONCURRENT PROGRAM NAME
                                 , NULL            -- DESCRIPTION
                                 , NULL            -- START
                                 , FALSE           -- SUB_REQUEST
                                                                  -- ARGUMENTS
                                 , REC_LOT.recurring_batch_id -- 1  Livre
                                 , gv_period_name
                                 , gv_access_set_id
                                 , ''
                                 , ''
                                 , ''
                                 , 'N'
                              );
       -- Validation pour soumettre le traitement


       IF Vn_Request_Id_GLPRJE = 0
       THEN
          Pv_errbuf := '!!!! Erreur lors de la soumission du programme de generation d ecriture repetitive(GLPRJE) ';
          dka_tools_pkg.put_outdebug_message (Pv_errbuf);
          dka_tools_pkg.put_outdebug_message (Fnd_Message.Get);
          dka_tools_pkg.put_outdebug_message ('Erreur lors du traitement du lot : ' || REC_LOT.name
                                              || ' id : '|| REC_LOT.recurring_batch_id);
          -- Sortie en erreur
          Pv_Retcode := 2;
          Gv_nb_KO := Gv_nb_KO + 1;
       ELSE
          -- Programme soumis
         dka_tools_pkg.put_debug_message ( 'Generation d ecriture repetitive - Programme soumis :' ||TO_CHAR(Vn_Request_Id_GLPRJE) );

         Vn_nb_traitement                                     := Vn_nb_traitement + 1 ;
         Gt_Request_Id(Vn_nb_traitement).Request_Id           := Vn_Request_Id_GLPRJE;
         Gt_Request_Id(Vn_nb_traitement).Recurring_Batch_Id   := REC_LOT.recurring_batch_id;
         Gt_Request_Id(Vn_nb_traitement).Recurring_Batch_Name := REC_LOT.name;
         Gt_Request_Id(Vn_nb_traitement).Traitement_Ok        := 'OK';

       END IF;

     END LOOP;

     COMMIT;

     dka_tools_pkg.put_debug_message ('launch_request (-)');

  EXCEPTION
      WHEN OTHERS
      THEN
          pv_retcode    := 2;
          pv_errbuf     := 'sortie de launch_request pour la raison suivante : '||SQLERRM;
          dbms_output.put_line ( 'Problème lors de la génération d écriture répétitive ---> ECHEC');
 END launch_request;

---------------------------------------------------------------------------------------------------------------
--  Nom           : wait_GLPRJE
--  Description   : Attente de la fin d'execution du traitement GLPRJE soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  PROCEDURE wait_GLPRJE
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        )
    IS

      Vb_Trash      BOOLEAN;
      Vv_Phase      VARCHAR2(50);
      Vv_Status     VARCHAR2(50);
      Vv_Dev_Phase  VARCHAR2(50);
      Vv_Dev_Status VARCHAR2 (50);
      Vv_Message    VARCHAR2 (500);

    BEGIN

         dka_tools_pkg.put_debug_message ('wait_GLPRJE (+)');
          -- Attente de la fin d'execution des programmes
          FOR nb in 1..Vn_nb_traitement LOOP

                Vb_Trash := FND_CONCURRENT.WAIT_FOR_REQUEST (
                                                  Gt_Request_Id(Vn_nb_traitement).Request_Id, -- REQUEST_ID
                                                  10                     , -- INTERVAL
                                                  0                      , -- MAX_WAIT (pas de delai)
                                                  Vv_Phase               , -- PHASE
                                                  Vv_Status              , -- STATUS
                                                  Vv_Dev_Phase           , -- DEV_PHASE
                                                  Vv_Dev_Status          , -- DEV_STATUS
                                                  Vv_Message               -- MESSAGE
                                                );

                dka_tools_pkg.put_debug_message ('Gt_Request_Id(Vn_nb_traitement).Request_Id ' ||   Gt_Request_Id(Vn_nb_traitement).Request_Id);
                dka_tools_pkg.put_debug_message ('Vn_nb_traitement ' ||   Vn_nb_traitement);
                dka_tools_pkg.put_debug_message ('Vv_Phase ' ||   Vv_Phase);
                dka_tools_pkg.put_debug_message ('Vv_Status ' ||   Vv_Status);
                dka_tools_pkg.put_debug_message ('Vv_Dev_Phase ' ||   Vv_Dev_Phase);
                dka_tools_pkg.put_debug_message ('Vv_Dev_Status ' ||   Vv_Dev_Status);
                dka_tools_pkg.put_debug_message ('Vv_Message' ||   Vv_Message);
                IF not Vb_Trash Then
                  pv_errbuf     := 'Pb dans l attente WAIT_GLPRJE';
                  raise Erreur_Prog_E;
               ELSE
                 Vn_nb_traitement := Vn_nb_traitement - 1 ;
               END IF;

               IF Vv_Status = 'Erreur' Then
                  pv_errbuf := pv_errbuf || Vv_Message ;
                  dbms_output.put_line ( 'Traitement de génération de pièces répétitives s est terminé en erreur');
                  raise Erreur_Prog_E;
               END IF;

          END LOOP;
         dka_tools_pkg.put_debug_message ('wait_GLPRJE (-)');
    EXCEPTION
        /*WHEN Erreur_Prog_E
        THEN
            pn_retcode := 2;
            dka_tools_pkg.put_debug_message(pv_errbuf);*/

        WHEN OTHERS
        THEN
            pv_errbuf     := 'sortie de WAIT_GLPRJE avec erreur EXCEPTION OTHERS:' || SQLERRM;
            pn_retcode    := 2;
            dka_tools_pkg.put_outdebug_message ( 'Traitement de génération de pièces répétitives en erreur');
    END wait_GLPRJE;

--------------------------------------------------------------------------------------------------------------
--  Nom           : wait_GLPAUTOP
--  Description   : Attente de la fin d'execution du traitement GLPAUTOP soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

      PROCEDURE wait_GLPAUTOP
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        )
    IS

      Vb_Trash      BOOLEAN;
      Vv_Phase      VARCHAR2(50);
      Vv_Status     VARCHAR2(50);
      Vv_Dev_Phase  VARCHAR2(50);
      Vv_Dev_Status VARCHAR2 (50);
      Vv_Message    VARCHAR2 (50);

    BEGIN
          -- Attente de la fin d'execution des programmes
          Vb_Trash := FND_CONCURRENT.WAIT_FOR_REQUEST ( Vn_Request_Id_GLPAUTOP, -- REQUEST_ID
                                            10                     , -- INTERVAL
                                            0                      , -- MAX_WAIT (pas de delai)
                                            Vv_Phase               , -- PHASE
                                            Vv_Status              , -- STATUS
                                            Vv_Dev_Phase           , -- DEV_PHASE
                                            Vv_Dev_Status          , -- DEV_STATUS
                                            Vv_Message               -- MESSAGE
                                          );

         IF not Vb_Trash Then
            pv_errbuf     := pv_errbuf || 'Pb dans l attente WAIT_GLPAUTOP';
            raise Erreur_Prog_E;
         END IF;

         IF Vv_Status = 'Erreur' Then
            pv_errbuf := pv_errbuf || Vv_Message ;
            raise Erreur_Prog_E;
         END IF;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'sortie de WAIT_GLPAUTOP avec erreur EXCEPTION OTHERS:' || SQLERRM;
            pn_retcode    := 2;
    END wait_GLPAUTOP;


--------------------------------------------------------------------------------------------------------------
--  Nom           : wait_GLPOS
--  Description   : Attente de la fin d'execution du traitement GLPOS soumis
--
--  PARAMETRES    :
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

      PROCEDURE wait_GLPOS
       (
        pv_errbuf    IN OUT   VARCHAR2,
        pn_retcode   IN OUT   NUMBER
        )
    IS

      Vb_Trash                      BOOLEAN;
      Vv_Phase                      VARCHAR2(50);
      Vv_Status                     VARCHAR2(50);
      Vv_Dev_Phase                  VARCHAR2(50);
      Vv_Dev_Status                 VARCHAR2 (50);
      Vv_Message                    VARCHAR2 (50);
      VV_Request_id_GLPOS           Fnd_Concurrent_Requests.Request_Id%TYPE:=NULL;

    BEGIN

         BEGIN
             Select Fcrs.REQUEST_ID
             Into   VV_Request_id_GLPOS
             From   Fnd_conc_req_summary_v Fcrs
             Where  1 = 1
             and    Fcrs.PARENT_REQUEST_ID = Vn_Request_Id_GLPAUTOP
             --and    fcrs.PROGRAM_SHORT_NAME = 'GLPPOS' -- OU GLPPOSS --RBE artf2199612
             ;

             IF VV_Request_id_GLPOS IS NOT NULL THEN --RBE artf2199612

                  -- Attente de la fin d'execution des programmes
                  Vb_Trash := FND_CONCURRENT.WAIT_FOR_REQUEST ( VV_Request_id_GLPOS, -- REQUEST_ID
                                                    10                     , -- INTERVAL
                                                    0                      , -- MAX_WAIT (pas de delai)
                                                    Vv_Phase               , -- PHASE
                                                    Vv_Status              , -- STATUS
                                                    Vv_Dev_Phase           , -- DEV_PHASE
                                                    Vv_Dev_Status          , -- DEV_STATUS
                                                    Vv_Message               -- MESSAGE
                                                  );

                 IF not Vb_Trash Then
                    pv_errbuf     := pv_errbuf || 'Pb dans l attente WAIT_GLPOS';
                    raise Erreur_Prog_E;
                 END IF;

                 IF Vv_Status = 'Erreur' Then
                    pv_errbuf := pv_errbuf || Vv_Message ;
                    raise Erreur_Prog_E;
                 END IF;
             END IF;
         EXCEPTION
         WHEN OTHERS THEN
            NULL;
         END;
    EXCEPTION
        WHEN OTHERS
        THEN
            pv_errbuf     := 'sortie de WAIT_GLPOS avec erreur EXCEPTION OTHERS:' || SQLERRM;
            pn_retcode    := 2;
    END wait_GLPOS;


---------------------------------------------------------------------------------------------------------------
--  Nom           : delete_batch
--  Description   : Procédure supprimant un lot
--
--  pv_je_batch_id            Entrée             Identifiant du lot à supprimer
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
Procedure delete_batch ( pv_je_batch_id IN NUMBER,
                         pv_errbuf      IN OUT   VARCHAR2,
                         pn_retcode     IN OUT   NUMBER
                         ) is

 vv_row_id               gl_je_batches_v.ROW_ID%TYPE;
 vv_name                 gl_je_batches_v.NAME%TYPE;

 begin

   SELECT    gjb.ROW_ID,
             gjb.NAME
   INTO      vv_row_id,
             vv_name
   FROM      gl_je_batches_v gjb
   WHERE     gjb.JE_BATCH_ID = pv_je_batch_id;
   -- JPE 17/05/2016 MIGRATION R12 : Champ inexistant dans la vue en R12
   --AND       gjb.set_of_books_id = gv_set_of_book_id; -- modif 01/03/2006

   GL_JE_BATCHES_PKG.Delete_Row
                     (vv_row_id,
                            pv_je_batch_id);

 exception
   when others then
   pv_errbuf     := 'sortie de delete_batch avec erreur EXCEPTION OTHERS:' || SQLERRM;
   pn_retcode    := 2;
 end delete_batch;

---------------------------------------------------------------------------------------------------------------
--  Nom           : delete_header
--  Description   : Procédure de suppression d'une pièce
--
--  pv_je_header_id           Entrée             Identifiant de la pièce à supprimer
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 procedure delete_header (pv_je_header_id IN NUMBER,
                          pv_errbuf    IN OUT   VARCHAR2,
                          pn_retcode     IN OUT   NUMBER) is



   vv_row_id                        gl_je_headers_v.ROW_ID%TYPE;
   vv_header_mode                   VARCHAR2(2) := 'Y';
   vv_Batch_RowId                   gl_je_headers_v.BATCH_ROWID%TYPE;
   vv_Je_Batch_Id                   gl_je_headers_v.je_batch_id%TYPE;
   -- JPE 17/05/2016 MIGRATION R12 : Champ renommé set_of_books_id par ledger_id
   vv_Set_Of_Books_Id               gl_je_headers_v.ledger_id%TYPE;
   vv_Actual_Flag                   gl_je_headers_v.actual_flag%TYPE;
   vv_Period_Name                   gl_je_headers_v.period_name%TYPE;
   vv_Batch_Name                    gl_je_headers_v.BATCH_NAME%TYPE;
   vv_Batch_Status                  gl_je_headers_v.BATCH_STATUS%TYPE;
   vv_Status_Verified               gl_je_headers_v.status_verified%TYPE;
   vv_Batch_Effective_Date          gl_je_headers_v.BATCH_DEFAULT_EFFECTIVE_DATE%TYPE;
   vv_Batch_Posted_Date             gl_je_headers_v.BATCH_POSTED_DATE%TYPE;
   vv_Batch_Date_Created            gl_je_headers_v.BATCH_DATE_CREATED%TYPE;
   vv_Budgetary_Control_Status      gl_je_headers_v.budgetary_control_status%TYPE;
   vv_Approval_Status_Code          gl_je_headers_v.approval_status_code%TYPE;
   vv_Batch_Control_Total           gl_je_headers_v.BATCH_CONTROL_TOTAL%TYPE;
   vv_Batch_Running_Total_Dr        gl_je_headers_v.BATCH_RUNNING_TOTAL_DR%TYPE;
   vv_Batch_Running_Total_Cr        gl_je_headers_v.BATCH_RUNNING_TOTAL_CR%TYPE;
   vv_Average_Journal_Flag          gl_je_headers_v.average_journal_flag%TYPE;
   vv_Posting_Run_Id                gl_je_headers_v.posting_run_id%TYPE;
   vv_Request_Id                    gl_je_headers_v.request_id%TYPE;
   vv_Packet_Id                     gl_je_headers_v.packet_id%TYPE;
   vv_Unreservation_Packet_Id       gl_je_headers_v.unreservation_packet_id%TYPE;
   vv_Org_Id                        gl_je_headers_v.org_id%TYPE;
   vv_user_id                       gl_je_headers_v.last_updated_by%TYPE := fnd_global.USER_ID;
   vv_login_id                      gl_je_headers_v.last_update_login%TYPE := fnd_global.USER_ID;
   vv_doc_sequence_id               gl_je_headers_v.doc_sequence_id%TYPE;
   vv_doc_sequence_value            gl_je_headers_v.doc_sequence_value%TYPE;
   -- JPE 18/05/2016 MIGRATION R12 : Champs Chart_of_Accounts_ID, Period_Set_Name, Accounted_Period_Type ajoutés dans la R12
   vv_Chart_of_Accounts_ID          gl_je_headers_v.Chart_of_Accounts_ID%TYPE;
   vv_Period_Set_Name                  gl_je_headers_v.Period_Set_Name%TYPE;
   vv_Accounted_Period_Type         gl_je_headers_v.Accounted_Period_Type%TYPE;
 Begin

   select  Row_Id,
           'Y' ,
           Batch_RowId,
           Je_Batch_Id,
           -- JPE 17/05/2016 MIGRATION R12 : Champ set_of_books_id renommé par ledger_id
           Ledger_id,
           Actual_Flag,
           Period_Name,
           Batch_Name,
           Chart_of_Accounts_ID,
           Period_Set_Name,
           Accounted_Period_Type,
           Batch_Status,
           Status_Verified,
           Batch_Default_Effective_Date,
           Batch_Posted_Date,
           Batch_Date_Created,
           Budgetary_Control_Status,
           Approval_Status_Code,
           Batch_Control_Total,
           Batch_Running_Total_Dr,
           Batch_Running_Total_Cr,
           Average_Journal_Flag,
           Posting_Run_Id,
           Request_Id,
           Packet_Id,
           Unreservation_Packet_Id,
           Org_Id,
           gv_user_id, --a remplacer,
           gv_user_id, --a remplacer
           Doc_Sequence_Id,
           Doc_Sequence_Value
    into   vv_Row_Id,
           vv_header_mode,
           vv_Batch_RowId,
           vv_Je_Batch_Id,
           vv_Set_Of_Books_Id,
           vv_Actual_Flag,
           vv_Period_Name,
           vv_Batch_Name,
           vv_Chart_of_Accounts_ID,
           vv_Period_Set_Name,
           vv_Accounted_Period_Type,
           vv_Batch_Status,
           vv_Status_Verified,
           vv_Batch_Effective_Date,
           vv_Batch_Posted_Date,
           vv_Batch_Date_Created,
           vv_Budgetary_Control_Status,
           vv_Approval_Status_Code,
           vv_Batch_Control_Total,
           vv_Batch_Running_Total_Dr,
           vv_Batch_Running_Total_Cr,
           vv_Average_Journal_Flag,
           vv_Posting_Run_Id,
           vv_Request_Id,
           vv_Packet_Id,
           vv_Unreservation_Packet_Id,
           vv_Org_Id,
           vv_user_id,
           vv_login_id,
           vv_doc_sequence_id,
           vv_doc_sequence_value
    from   gl_je_headers_v g
    --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
    where  g.je_header_id = pv_je_header_id;
    -- JPE 17/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
  --  And    g.ledger_id = gv_set_of_book_id; -- modif 01/03/2006;

    -- JPE 17/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
    GL_JE_HEADERS_PKG.Delete_Row(
      X_RowId                                    => vv_Row_Id,
      X_Je_Header_Id                            => pv_je_header_id,
      X_Header_Mode                                => vv_header_mode,
      X_Batch_Row_Id                            => vv_Batch_RowId,
      X_Je_Batch_Id                                => vv_Je_Batch_Id,
      X_Ledger_id                                => vv_Set_Of_Books_Id,
      X_Actual_Flag                                => vv_Actual_Flag,
      X_Period_Name                                => vv_Period_Name,
      X_Batch_Name                                => vv_Batch_Name,
      X_Chart_of_Accounts_ID                    => vv_Chart_of_Accounts_ID,
      X_Period_Set_Name                            => vv_Period_Set_Name,
      X_Accounted_Period_Type                   => vv_Accounted_Period_Type,
      X_Batch_Status                            => vv_Batch_Status,
      X_Status_Verified                         => vv_Status_Verified,
      X_Batch_Default_Effective_Date            => vv_Batch_Effective_Date,
      X_Batch_Posted_Date                       => vv_Batch_Posted_Date,
      X_Batch_Date_Created                      => vv_Batch_Date_Created,
      X_Budgetary_Control_Status                => vv_Budgetary_Control_Status,
      X_Approval_Status_Code                    => vv_Approval_Status_Code,
      X_Batch_Control_Total                     => vv_Batch_Control_Total,
      X_Batch_Running_Total_Dr                  => vv_Batch_Running_Total_Dr,
      X_Batch_Running_Total_Cr                  => vv_Batch_Running_Total_Cr,
      X_Average_Journal_Flag                    => vv_Average_Journal_Flag,
      X_Posting_Run_Id                          => vv_Posting_Run_Id,
      X_Request_Id                                 => vv_Request_Id,
      X_Packet_Id                                 => vv_Packet_Id,
      X_Unreservation_Packet_Id                 => vv_Unreservation_Packet_Id,
      --X_Org_Id                                  => vv_Org_Id,
      X_Last_Updated_By                         => vv_user_id,
      X_Last_Update_Login                       => vv_login_id);


     dka_tools_pkg.put_outdebug_message ('Suppression de la pièce effectuée ' ||
                                         ' Doc sequence_id : '|| vv_doc_sequence_id ||
                                         ' Doc_sequence_Value : ' || vv_doc_sequence_value
                                          );

 Exception
   When Others Then
   pv_errbuf     := 'sortie de delete_header avec erreur EXCEPTION OTHERS:' || SQLERRM;
   pn_retcode    := 2;
 End delete_header;

---------------------------------------------------------------------------------------------------------------
--  Nom           : delete_lines
--  Description   : Procédure de suppression d'une écriture
--
--  pv_je_header_id           Entrée             Identifiant de la pièce pour laquelle une écriture
--                                               doit être supprimée
--  pv_je_line_num            Entrée             Numéro de la ligne à supprimer
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
  Procedure delete_lines (pv_je_header_id IN NUMBER,
                          pv_je_line_num  IN NUMBER,
                          pv_errbuf    IN OUT   VARCHAR2,
                          pn_retcode     IN OUT   NUMBER) is

  vv_Row_Id               gl_je_lines_v.ROW_ID%TYPE;
  vv_Recon_RowId          gl_je_lines_v.RECON_ROWID%TYPE;

  Begin

      -- JPE 17/05/2016 MIGRATION R12 : Champ WAD_ROW_ID remplacé par RECON_ROWID
      Select ROW_ID,
             RECON_ROWID
      Into   vv_Row_Id,
             vv_Recon_RowId
      From   gl_je_lines_v g
      Where  1 = 1
      And    g.je_header_id = pv_je_header_id
--  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
      And    g.je_line_num = pv_je_line_num;
      -- JPE 17/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
      --And    g.ledger_id = gv_set_of_book_id; --modif 01/03/2006

      GL_JE_LINES_PKG.Delete_Row(
        X_RowId       => vv_ROW_ID,
        X_Recon_Rowid => vv_Recon_RowId);
  Exception
   When Others Then
   pv_errbuf     := 'sortie de delete_lines avec erreur EXCEPTION OTHERS:' || SQLERRM;
   pn_retcode    := 2;
  End delete_lines;

---------------------------------------------------------------------------------------------------------------
--  Nom           : check_data
--  Description   : Procédure de vérification des pièces et des écritures
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  Procedure check_data (pv_errbuf    IN OUT   VARCHAR2,
                        pn_retcode OUT NUMBER) is

  Cursor cur_headers (pv_je_batch_id NUMBER) is
  Select gjh.je_header_id,
         gjh.je_batch_id,
         gjh.running_total_accounted_dr,
         gjh.running_total_accounted_cr
  From   gl_je_headers gjh
  where  gjh.je_batch_id = pv_je_batch_id
  and    nvl(gjh.running_total_accounted_dr,0) = nvl(gjh.running_total_accounted_cr,0)
  and    nvl(gjh.running_total_accounted_dr,0) = 0;

  Cursor cur_lines (pv_je_batch_id NUMBER) is
  Select gjl.je_header_id,
         gjl.je_line_num,
         gjl.accounted_dr,
         gjl.accounted_cr
  from   gl_je_headers gjh,
         gl_je_lines gjl
  where  gjh.je_header_id = gjl.je_header_id
  and    gjh.je_batch_id = pv_je_batch_id
  and    nvl(gjl.accounted_dr,0) = 0
  and    nvl(gjl.accounted_cr,0) = 0;

  Cursor CUR_LOT_GEN IS
  Select gjb.je_batch_id,
         gjb.RUNNING_TOTAL_ACCOUNTED_DR,
         gjb.RUNNING_TOTAL_ACCOUNTED_CR,
         gjb.NAME
  From   gl_je_batches gjb,
         gl_recurring_batches grb
  Where  1 = 1
  And    substr(gjb.name,0,instr(gjb.name,':')-1)= grb.name --recuperation
  And    gjb.DEFAULT_PERIOD_NAME = gv_period_name
  And    status = 'U'-- non imputé
  --And    gjb.JE_SOURCE_NAME = 'Recurring' --Pièce répétitive
  -- JPE 17/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id et SET_OF_BOOKS_ID_11I
  and    exists (Select 'X'
                 From   gl_je_headers gjh
                 Where  gjh.je_category = gv_je_category
                 And    gjh.je_batch_id = gjb.JE_BATCH_ID
                 And    gjh.period_name = gv_period_name
                 )
  ;

  vv_debit                       gl_je_batches.RUNNING_TOTAL_ACCOUNTED_DR%TYPE;
  vv_credit                      gl_je_batches.RUNNING_TOTAL_ACCOUNTED_CR%TYPE;
  Rec_cur_headers                cur_headers%RowType;
  Rec_cur_lines                  cur_lines%Rowtype;
  btch_Name                      gl_je_batches.name%TYPE;
  Posting                        NUMBER;


  Begin

  Posting := 0;

  dka_tools_pkg.put_debug_message ('check_data (+)');

  FOR REC_LOT_GEN IN CUR_LOT_GEN LOOP
  --Recupération du je_batch_id du lot généré
  dka_tools_pkg.put_debug_message ('Recupération du je_batch_id du lot généré');

  vv_debit := REC_LOT_GEN.running_total_accounted_dr;
  vv_credit := REC_LOT_GEN.running_total_accounted_cr;
  gv_je_batch_id := REC_LOT_GEN.je_batch_id;
  btch_Name := REC_LOT_GEN.name;


      dka_tools_pkg.put_outdebug_message (' Nom du lot : "' || btch_Name ||'"'
                                         || ' (je_batch_id : '|| REC_LOT_GEN.je_batch_id ||')'
                                         || '  Debit : ' || vv_debit
                                         || ' Credit : ' || vv_credit );


  -- Vérification que le total du lot est différent de 0

      IF vv_debit = 0 And vv_credit = 0 THEN
         dka_tools_pkg.put_outdebug_message (' Le lot généré est nul --> Suppression');
         Dka_Sglequilib_pkg.delete_batch (REC_LOT_GEN.je_batch_id, pv_errbuf, pn_retcode);

           IF pn_retcode = 2 --la suppression du lots'est mal déroulée
           THEN
              pv_errbuf := pv_errbuf || 'la suppression du lot ne s est pas déroulée correctement';
              RAISE Erreur_Prog_E;
           END IF;

      ELSE -- le lot contient des pièces différentes de 0

         Posting := Posting + 1;

         open  cur_headers(REC_LOT_GEN.je_batch_id);

         dka_tools_pkg.put_debug_message('nb_pieces a 0 :' || cur_headers%ROWCOUNT);

          Loop

            Fetch cur_headers Into Rec_cur_headers;
            Exit When cur_headers%NotFound;

              IF nvl(Rec_cur_headers.running_total_accounted_dr,0) = 0 And nvl(Rec_cur_headers.running_total_accounted_cr,0) = 0 THEN

                 dka_tools_pkg.put_outdebug_message ('=> Suppression pièces à 0 (je_header_id : '||
                                                  Rec_cur_headers.je_header_id ||')');

                 Dka_Sglequilib_pkg.delete_header(pv_je_header_id => Rec_cur_headers.je_header_id ,
                                                  pv_errbuf => pv_errbuf,
                                                  pn_retcode => pn_retcode
                                                  );

                   IF pn_retcode = 2 --la suppression du lots'est mal déroulée
                   THEN
                      pv_errbuf := pv_errbuf || 'Suppression incorrecte pour la pièce dont je_header_id : '||Rec_cur_headers.je_header_id;
                      RAISE Erreur_Prog_E;
                   END IF;


              END IF;

          End Loop;
          Close cur_headers;

          open cur_lines (REC_LOT_GEN.je_batch_id);

          Loop

             Fetch cur_lines into Rec_cur_lines;
             Exit When cur_lines%NotFound;

               IF nvl(Rec_cur_lines.accounted_dr,0) = 0 and nvl(Rec_cur_lines.accounted_cr,0) = 0 THEN

                  dka_tools_pkg.put_outdebug_message ('=> Lignes à zero --> Suppression ligne n '|| Rec_cur_lines.je_line_num||
                                                    ' de la piece dont je_header_id : '|| Rec_cur_lines.je_header_id);

                  Dka_Sglequilib_pkg.delete_lines (pv_je_header_id => Rec_cur_lines.je_header_id,
                                                   pv_je_line_num => Rec_cur_lines.je_line_num,
                                                   pv_errbuf => pv_errbuf,
                                                   pn_retcode => pn_retcode
                                                   );

                  IF pn_retcode = 2 --la suppression du lots'est mal déroulée
                   THEN
                      pv_errbuf := pv_errbuf || 'Suppression incorrecte pour la ligne n '|| Rec_cur_lines.je_line_num||
                                                    ' de la piece dont je_header_id : '|| Rec_cur_lines.je_header_id;
                      RAISE Erreur_Prog_E;
                   END IF;

               END IF;

           End loop;
           Close cur_lines;

      END IF; -- Fin IF vv_debit = 0 And vv_credit = 0
    END LOOP;

        IF posting >= 1 THEN

             run_posting(pv_errbuf, pn_retcode); -- lancer le posting uniquement s'il y a des choses à imputer

             IF pn_retcode = 2 THEN
                pv_errbuf := pv_errbuf || ' Erreur lors du posting ' ;
                RAISE Erreur_Prog_E;
             END IF;

             wait_GLPAUTOP(pv_errbuf, pn_retcode);

             IF pn_retcode = 2 THEN
                pv_errbuf := pv_errbuf || ' Erreur lors de l''attente du programme d''auoimputation ' ;
                RAISE Erreur_Prog_E;
             END IF;

             wait_GLPOS(pv_errbuf, pn_retcode);

             IF pn_retcode = 2 THEN
                pv_errbuf := pv_errbuf || ' Erreur lors de l''attente du posting ' ;
                RAISE Erreur_Prog_E;
             END IF;
        END IF;

     dka_tools_pkg.put_debug_message ('check_data (-)');

  Exception

   When Others Then
   pv_errbuf     := pv_errbuf || 'sortie de check_data avec erreur EXCEPTION OTHERS:' || SQLERRM;
   pn_retcode    := 2;

  End check_data;

---------------------------------------------------------------------------------------------------------------
--  Nom           : run_posting
--  Description   : Procédure de lancement du programme d'imputation automatique
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  Procedure run_posting (pv_errbuf    IN OUT   VARCHAR2, Pv_Retcode OUT NUMBER) is
  Begin
        Vn_Request_Id_GLPAUTOP := Fnd_Request.Submit_Request (
                                   'SQLGL'              -- APPLICATION SHORT NAME
                                 , 'GLPAUTOP'        -- CONCURRENT PROGRAM NAME
                                 , NULL            -- DESCRIPTION
                                 , NULL            -- START
                                 , FALSE           -- SUB_REQUEST
                                                                  -- ARGUMENTS
                                 , gv_access_set_id -- set_of_book_id
                                 , gv_autopost_set_id
                              );


       -- Validation pour soumettre le traitement
       COMMIT;

       IF Vn_Request_Id_GLPAUTOP = 0
       THEN
          Pv_errbuf := '!!!! Erreur lors de la soumission du programme d imputation ';
          dka_tools_pkg.put_outdebug_message (Pv_errbuf);
          dka_tools_pkg.put_outdebug_message (Fnd_Message.Get);
          -- Sortie en erreur
          Pv_Retcode := 2;
       END IF;
  End run_posting;

---------------------------------------------------------------------------------------------------------------
--  Nom           : check_param
--  Description   : Procédure vérifiant qu'il existe une formule pour chaque classe mouvementée
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  Procedure check_param (pv_errbuf    IN OUT   VARCHAR2, Pv_Retcode OUT NUMBER) is

  Cursor Cur_ste is
  select segment1,
         segment2,
         segment3
  from   gl_code_combinations_kfv gcc
  where  gcc.template_id = gv_template_id
  and gcc.segment1 = get_first_char||SUBSTR(gv_sob_name,2) --RBE artf2199612
  and   not  exists
       (
        select 'X'
        from    GL_RECURRING_LINE_CALC_RULES grlc,
                GL_RECURRING_LINES GRL,
                gl_recurring_headers grh,
                --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                gl_recurring_batches grb,
                gl_period_statuses gps
        where   grlc.segment1 = gcc.segment1
        and     grlc.segment2 = gcc.segment2
        and     grlc.segment3 = gcc.segment3
        and     grlc.segment4 = gcc.segment4
        and     grlc.segment5 = gcc.segment5
        and     grlc.segment6 = gcc.segment6
        and     grlc.segment7 = gcc.segment7
        and     grlc.segment8 = gcc.segment8
        and     grlc.segment9 = gcc.segment9
        and     grlc.segment10 = gcc.segment10
        and     grl.RECURRING_HEADER_ID = grlc.recurring_header_id
        and     grh.recurring_header_id = grl.recurring_header_id
        and     grl.recurring_line_num = grlc.recurring_line_num
        and     gps.set_of_books_id = gv_set_of_book_id
        and     gps.period_name = gv_period_name
        --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
        and     grb.recurring_batch_type = 'M'
        and     nvl(grh.start_date_active,gps.start_date) <= gps.start_date
        and     nvl(grh.end_date_active,gps.end_date) >= gps.end_date
        and     grh.je_category_name = gv_je_category
       )
  -->>debut JWY artf07249170     
  AND EXISTS (SELECT 1 FROM hr_operating_units hou, gl_periods gp WHERE gp.period_name = gv_period_name and nvl(hou.date_to, to_date('31/12/4712', 'DD/MM/YYYY'))
     > gp.end_date AND substr(hou.name, 1, 3) = gcc.segment2 AND substr(hou.name, 5, 3) = substr(gcc.segment1,2,3))
  --<<fin JWY artf07249170
  order by segment1,
           segment2,
           segment3
   ;

  cpt       NUMBER(5);
  Rec_Cur_ste Cur_ste%ROWTYPE;

  Begin

  dka_tools_pkg.put_debug_message ('check_param(+)');

  cpt := 0;

  OPEN Cur_ste;

  Loop

      Fetch Cur_ste Into Rec_Cur_ste;
      Exit When Cur_ste%NotFound;

      cpt := cpt + 1;

      dka_tools_pkg.put_outdebug_message (
                                pv_errbuf || 'Defaut de paramétrage pour la societe '||Rec_Cur_ste.segment1 ||
                                ' Centre de gestion : ' || Rec_Cur_ste.segment2 || ' Classe : ' ||Rec_Cur_ste.segment3);

  End loop;

  IF cpt = 0 THEN
   dka_tools_pkg.put_outdebug_message ('==> OK ');
  ELSE
   Pv_Retcode := 1;
   gv_nb_ko_nb := gv_nb_ko_nb + 1;
/*   dka_tools_pkg.put_outdebug_message ('==> KO');
   dka_tools_pkg.put_outdebug_message ('N.B.: Si un déséquilibre existe pour le paramétrage manquant, '||
                                        'il doit être géré manuellement');*/
  END IF;

  dka_tools_pkg.put_debug_message ('check_param(-)');
  Exception
    When OTHERS Then
      Pv_Retcode := 2;
      pv_errbuf := pv_errbuf || '!!!! Erreur lors de la verification du paramétrage'||Sqlerrm;
  End check_param;

---------------------------------------------------------------------------------------------------------------
--  Nom           : Get_Rec_Header_id
--  Description   : Fonction récupérant l'identifiant de la pièce répétitive pour la société passée en paramètre
--                  Déclenchement de l'exception error_data dans le cas où il est impossible de récupérer le
--                  nom de la pièce répétitive (plusieurs pièces pour la même société)
--
--  soc                       Entrée             Société pour laquelle il faut récupérer la pièce répétitive

--  VALEUR RETOURNEE :
--     Identifiant de la pièce répétitive ainsi que le lot
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

  Procedure Get_Rec_Header_id (pv_soc in varchar2, pv_rec_batch_id out number, pv_rec_header_id out number)  Is

    rec_header_id              gl_recurring_headers.recurring_header_id%TYPE;
    --vv_je_category_name        gl_je_categories_tl.je_category_name%TYPE;
    vv_rec_batch_id            gl_recurring_batches.recurring_batch_id%TYPE;
    vv_Rowid                   ROWID;
    -- JPE 18/05/2016 MIGRATION R12 : Champs Chart_of_Accounts_ID, Period_Set_Name, Accounted_Period_Type ajoutés dans la R12
    vv_Chart_Of_Accounts_Id    gl_recurring_batches.Chart_Of_Accounts_Id %TYPE;
    vv_Period_Set_Name         gl_recurring_batches.Period_Set_Name%TYPE;
    vv_Accounted_Period_Type   gl_recurring_batches.Accounted_Period_Type%TYPE;

  Begin

       dka_tools_pkg.put_debug_message ('Exists_Headers(+)');


       rec_header_id := '';
       vv_rec_batch_id := '';

       Select distinct
              grh.recurring_header_id,
              grh.recurring_batch_id
       Into   rec_header_id,
              vv_rec_batch_id
       From   gl_recurring_headers grh,
              gl_recurring_batches grb--,
              --dka_parameters dp --RBE artf2199612
       Where  1 = 1
       and    grh.recurring_batch_id  = grb.recurring_batch_id
       --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
       -- JPE 18/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
         --And    grh.ledger_id = grb.ledger_id
       and    grh.ledger_id = gv_set_of_book_id
       --and    grb.name like pv_soc || '%'
       and    grh.name like pv_soc || '%'
       and    grb.recurring_batch_type = 'M'
       and    grh.je_category_name = gv_je_category
       ;

       pv_rec_batch_id := vv_rec_batch_id;
       pv_rec_header_id := rec_header_id;
       dka_tools_pkg.put_debug_message ('Exists_Headers(-)');

  Exception

      when no_data_found then -- pas de pièces pour cette societe

              dka_tools_pkg.put_outdebug_message ('Piece inexistante pour la societe '|| pv_soc
                                                   || ' ==> Creation');
        -- Insertion
              SELECT CHART_OF_ACCOUNTS_ID,
                PERIOD_SET_NAME,
                ACCOUNTED_PERIOD_TYPE
                into vv_Chart_Of_Accounts_Id,
                     vv_Period_Set_Name,
                     vv_Accounted_Period_Type
                FROM GL_LEDGERS
                WHERE LEDGER_ID = gv_set_of_book_id;

              dka_tools_pkg.put_outdebug_message ('vv_Chart_Of_Accounts_Id : '|| vv_Chart_Of_Accounts_Id);

              GL_RECURRING_BATCHES_PKG.Insert_Row(
                                                    X_Rowid                             => vv_Rowid,
                                                    X_Recurring_Batch_Id             => vv_rec_batch_id,
                                                    X_Last_Update_Date               => SYSDATE,
                                                    X_Last_Updated_By                => fnd_global.USER_ID,
                                                    X_Ledger_Id                      => gv_set_of_book_id,
                                                    X_Chart_Of_Accounts_Id           => vv_Chart_Of_Accounts_Id,
                                                    X_Period_Set_Name                => vv_Period_Set_Name,
                                                    X_Accounted_Period_Type          => vv_Accounted_Period_Type,
                                                    X_Recurring_Batch_Type           => 'S',
                                                    X_Security_Flag                  => 'N',
                                                    X_Name                           => gv_header_name, -- JPE 12/05/2016 Migration R12 : RG7 : Le nom du lot généré sera "REGUL EQUILIBRE CDG"
                                                    X_Budget_Flag                    => 'N',
                                                    X_Allocation_Flag                => 'N',
                                                    X_Creation_Date                  => SYSDATE,
                                                    X_Created_By                     => fnd_global.USER_ID,
                                                    X_Last_Update_Login              => fnd_global.USER_ID,
                                                    X_Budget_In_Formula_Flag         => '',
                                                    X_Description                    => '',
                                                    X_Period_Type                    => '',
                                                    X_Last_Executed_Period_Name      => '',
                                                    X_Last_Executed_Date             => '',
                                                    X_Attribute1                     => '',
                                                    X_Attribute2                     => '',
                                                    X_Attribute3                     => '',
                                                    X_Attribute4                     => '',
                                                    X_Attribute5                     => '',
                                                    X_Attribute6                     => '',
                                                    X_Attribute7                     => '',
                                                    X_Attribute8                     => '',
                                                    X_Attribute9                     => '',
                                                    X_Attribute10                    => '',
                                                    X_Context                        => ''
                                                );

             dka_tools_pkg.put_outdebug_message ('Après GL_RECURRING_BATCHES_PKG.Insert_Row');

             gl_recurring_headers_pkg.insert_row(
                        vv_Rowid,
                        rec_header_id,
                        trunc(SYSDATE),
                        fnd_global.USER_ID,
                        gv_set_of_book_id,
                        pv_soc || ' ' ||  gv_header_name, -- JPE 12/05/2016 Migration R12 : RG3 : Une pièce sera générée pour chaque société segmentée. Son nom sera de la forme "REGUL EQUILIBRE CDG"
                        gv_je_category, --x_je_category_name
                        'Y', --enabled_flag,
                        'N', --allocation_flag,
                        gv_currency_code, --Rec_LOTS_PIECES.currency_code,
                        '',
                        trunc(SYSDATE),
                        fnd_global.USER_ID,
                        Fnd_Profile.VALUE ('LOGIN_ID'),
                        vv_rec_batch_id,
                        '', -- Period_type ,
                        '',
                        '',
                        '', -- start_date_active
                        '', -- end_date_active,
                        '', -- x_attribute1
                        '', -- x_attribute2
                        '', -- x_attribute3
                        '', -- x_attribute4
                        '', -- x_attribute5
                        '', -- x_attribute6
                        '', -- x_attribute7
                        '', -- x_attribute8
                        '', -- x_attribute9
                        '', -- x_attribute10
                        '' -- x_context => context_
                        );

           dka_tools_pkg.put_outdebug_message ('Après gl_recurring_headers_pkg.insert_row');



           pv_rec_batch_id := vv_rec_batch_id;
           pv_rec_header_id := rec_header_id;

           dka_tools_pkg.put_outdebug_message ('*** Creation de pièce OK pour la soc ' || pv_soc);

           dka_tools_pkg.put_debug_message ('Exists_Headers(-)');

    when others -- plusieurs pièces pour la même société ou Pb lors de l'insertion --> Erreur

      then
      dka_tools_pkg.put_debug_message ('Get_Rec_Header_id : ' || SQLERRM);
      raise error_data ;

  End Get_Rec_Header_id;


---------------------------------------------------------------------------------------------------------------
--  Nom           : Get_line_num
--  Description   : Fonction récupérant le numéro de la ligne de la pièce répétitive dans laquelle il faudra insérer
--                 le paramétrage manquant ceci pour le triplet (société, cdg, classe) passé en paramètre
--                  Déclenchement de l'exception error_data dans le cas où il est impossible de récupérer le
--                  nom de la pièce répétitive (plusieurs pièces pour la même société)
--
--  soc                       Entrée             Société pour laquelle il faut récupérer la pièce répétitive

--  VALEUR RETOURNEE :
--     Identifiant de la pièce répétitive
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------
 Function Get_line_num (rec_header_id NUMBER,
                        soc           VARCHAR2,
                        cdg           VARCHAR2,
                        classe        VARCHAR2) Return NUMBER IS

    rec_line_num       gl_recurring_lines.recurring_line_num%TYPE;
    vn_ccid            gl_code_combinations.code_combination_id%TYPE;
    vv_errbuf          VARCHAR2(1000);
    vn_retcode         NUMBER;
    vv_cpte_local      VARCHAR2(50);
    vv_cpte_gpe        VARCHAR2(50);


    Begin

     dka_tools_pkg.put_debug_message ('Exists_Lines(+)');
     dka_tools_pkg.put_debug_message('soc : ' || soc);
     dka_tools_pkg.put_debug_message('cdg : ' || cdg);
     dka_tools_pkg.put_debug_message('classe : ' || classe);

     rec_line_num := -1;

     Select distinct
            grl.recurring_line_num
     Into   rec_line_num
     From   gl_recurring_headers grh,
            gl_recurring_lines grl,
            gl_code_combinations gcc
     Where  1 = 1
     and    grh.recurring_header_id = grl.recurring_header_id
     and    grh.recurring_header_id = rec_header_id
     and    grl.code_combination_id = gcc.code_combination_id
     -- JPE 18/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
     and    grh.ledger_id = gv_set_of_book_id
     and    grh.je_category_name = gv_je_category
     and    gcc.segment1 = soc
     and    gcc.segment2 = cdg
     and    decode (classe , 'CL8', gv_cpte_equil_8,
                             'CL9', gv_cpte_equil_9, gv_cpte_equil_1_7) = gcc.segment3
                                 ;
     dka_tools_pkg.put_outdebug_message('L''insertion s''effectuera sur la ligne : '|| rec_line_num);

     dka_tools_pkg.put_debug_message ('Exists_Lines(-)');

     return rec_line_num;

    Exception

        --when others then
        when no_data_found then

        ------------ creation de la ligne

        -- 1 . Recuperation du max
        -- 2.  Recuperation du ccid
        -- 3.  Insertion

        dka_tools_pkg.put_outdebug_message ('La ligne doit etre créée pour permettre l''insertion du triplet :'
                                            ||soc||'-'||cdg||'-'|| classe);

        -- Récupération du plus grand numéro de ligne
        Select Nvl(Max (grl.recurring_line_num),0) + 1
        Into   rec_line_num
        From   gl_recurring_headers grh,
            gl_recurring_lines grl
        Where 1 = 1
        and   grh.recurring_header_id = grl.recurring_header_id
        and   grh.recurring_header_id = rec_header_id
        ;

        dka_tools_pkg.put_debug_message('num_ligne :'|| rec_line_num);

        IF classe = 'CL8' THEN
        vv_cpte_local := gv_cpte_equil_8;
        vv_cpte_gpe   := gv_cpte_gpe_equil_8;

        ELSIF classe = 'CL9' THEN
        vv_cpte_local := gv_cpte_equil_9;
        vv_cpte_gpe   := gv_cpte_gpe_equil_9;

        ELSE
        vv_cpte_local := gv_cpte_equil_1_7;
        vv_cpte_gpe   := gv_cpte_gpe_equil_1_7;
        END IF;

        dka_tools_pkg.put_outdebug_message ('Vérification de la clé :' || soc||'.'||cdg||'.'||vv_cpte_local
                                      ||'.'||vv_cpte_gpe||'.0.0.0.0.0.0.0.0 ...');

        vv_errbuf := '';

        -- JPE 12/05/2016 Migration R12 : RG2 : Ajout des segments 11 et 12
        --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
        --  18/05/2018 NBO artf2650476 - INC0204377 - Société 0804 / GL : absence d'équilibrage par Centre de Gestion
        Dka_Tools_Pkg.get_code_combination_id (pv_segment1 => soc,
        --get_code_combination_id (pv_segment1 => soc,
                                pv_segment2 => cdg,
                                pv_segment3 => vv_cpte_local,
                                pv_segment4 => vv_cpte_gpe,
                                pv_segment5 =>  '0',
                                pv_segment6 =>  '0',
                                pv_segment7 =>  '0',
                                pv_segment8 =>  '0',
                                pv_segment9 =>  '0',
                                pv_segment10 => '0',
                                pv_segment11 => '0',
                                pv_segment12 => '0',
                                pn_code_combination_id => vn_ccid,
                                pv_errbuf => vv_errbuf,
                                pn_retcode => vn_retcode
                                );
        --  18/05/2018 NBO artf2650476 - INC0204377 - Société 0804 / GL : absence d'équilibrage par Centre de Gestion
         dka_tools_pkg.put_debug_message ('vv_errbuf:'||vv_errbuf);
         dka_tools_pkg.put_debug_message ('vn_retcode:'||vn_retcode);

         IF vn_retcode != 2 THEN
               dka_tools_pkg.put_outdebug_message ('Creation de la ligne num ' ||rec_line_num||' pour la clé '||
                                                  soc||'.'||cdg||'.'||vv_cpte_local
                                                 ||'.'||vv_cpte_gpe||'.0.0.0.0.0.0.0.0');
               --  18/05/2018 NBO artf2650476 - INC0204377 - Société 0804 / GL : absence d'équilibrage par Centre de Gestion
               dka_tools_pkg.put_debug_message ('vn_ccid:'||vn_ccid);
               Insert Into
               Gl_Recurring_Lines grl
                   (RECURRING_HEADER_ID,
                    RECURRING_LINE_NUM,
                    LAST_UPDATE_DATE,
                    LAST_UPDATED_BY,
                    CODE_COMBINATION_ID,
                    ENTERED_CURRENCY_CODE,
                    CREATION_DATE,
                    CREATED_BY,
                    LAST_UPDATE_LOGIN)
                Values
                    (rec_header_id,
                     rec_line_num,
                     Sysdate,
                     fnd_global.USER_ID,
                     vn_ccid,
                     gv_currency_code,
                     Sysdate,
                     fnd_global.USER_ID,
                     Fnd_Profile.VALUE ('LOGIN_ID')
                     );

              dka_tools_pkg.put_outdebug_message ('Creation de la ligne num ' ||rec_line_num||' OK pour la clé '||
                                                  soc||'.'||cdg||'.'||vv_cpte_local
                                                 ||'.'||vv_cpte_gpe||'.0.0.0.0.0.0.0.0');

              dka_tools_pkg.put_outdebug_message ('Exists_Lines(-)');

              return rec_line_num ;
         ELSE
            -- erreur lors de l'insertion car impossibilité de déterminer la cle

            dka_tools_pkg.put_outdebug_message ('Erreur lors du calcul de la clé :'|| soc ||'.'|| cdg ||
                                                '.'||vv_cpte_local ||'.'||vv_cpte_gpe||'0.0.0.0.0.0.0.0');

            dka_tools_pkg.put_outdebug_message (vv_errbuf);
            raise incorrect_key;

         END IF;

        when others
             then
             dka_tools_pkg.put_debug_message('When others : ' || SQLERRM);
             raise error_data ;

    End Get_line_num;

--  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
----------------------------------------------------------------------------------------
--  Nom           : GET_CODE_COMBINATION_ID
--  Description   : Procédure permettant de déterminer le code_combination_id
--                  correspondant a la combinaison passée en parametre
--                  Si la combinaison n'existe pas, elle est créée
--                  Si la combinaison n'existe pas, elle est créée
--  PARAMETRES :
--    pv_segment1       Entrée
--    pv_segment2       Entrée
--    pv_segment3       Entrée
--    pv_segment4       Entrée
--    pv_segment5       Entrée
--    pv_segment6       Entrée
--    pv_segment7       Entrée
--    pv_segment8       Entrée
--    pv_segment9       Entrée
--    pv_segment10      Entrée
--    pv_segment11      Entrée
--    pv_segment12      Entrée
--
--    pn_ccid           Sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal
--                         2: erreur
----------------------------------------------------------------------------------------
 PROCEDURE get_code_combination_id(pv_segment1            IN VARCHAR2,
                                   pv_segment2            IN VARCHAR2,
                                   pv_segment3            IN VARCHAR2,
                                   pv_segment4            IN VARCHAR2,
                                   pv_segment5            IN VARCHAR2,
                                   pv_segment6            IN VARCHAR2,
                                   pv_segment7            IN VARCHAR2,
                                   pv_segment8            IN VARCHAR2,
                                   pv_segment9            IN VARCHAR2,
                                   pv_segment10           IN VARCHAR2,
                                   pv_segment11           IN VARCHAR2,
                                   pv_segment12           IN VARCHAR2,
                                   pn_code_combination_id OUT NUMBER,
                                   pv_errbuf              OUT VARCHAR2,
                                   pn_retcode             OUT NUMBER,
                                   pv_validation_flag     IN VARCHAR2 DEFAULT 'Y') IS

 BEGIN
   dka_tools_pkg.put_outdebug_message('Debut get_code_combination_id ');
   SELECT a.code_combination_id
     INTO pn_code_combination_id
     FROM gl_code_combinations a --, gl_summary_templates b, gl_ledgers c
    WHERE 1=1--a.summary_flag = 'Y'
      --AND a.template_id = b.template_id
      --AND c.short_name = a.segment1  --RBE artf2199612
      AND a.segment1 = pv_segment1 and a.segment2 = pv_segment2 and a.segment3 = pv_segment3
      AND a.segment4 = pv_segment4 and a.segment5 = pv_segment5 and a.segment6 = pv_segment6
      AND a.segment7 = pv_segment7 and a.segment8 = pv_segment8 and a.segment9 = pv_segment9
      AND a.segment10 = pv_segment10 and a.segment11 = pv_segment11 and a.segment12 = pv_segment12
      --AND c.ledger_id = b.ledger_id
      ;
      dka_tools_pkg.put_outdebug_message('Fin get_code_combination_id ');
      pn_retcode := 0;

 EXCEPTION
   WHEN OTHERS THEN
     pv_errbuf  := 'GET_CODE_COMBINATION_ID - ' || SQLERRM;
     pn_retcode := SQLCODE;
 END get_code_combination_id;

---------------------------------------------------------------------------------------------------------------
--  Nom           : insert_param
--  Description   : Procédure insérant automatiquement le paramétrage manquant
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

 Procedure insert_param (Pn_Period        IN       VARCHAR2,
                         pv_errbuf    IN OUT   VARCHAR2,
                         Pv_Retcode   OUT      NUMBER) is

   Cursor Cur_ecrit_equil is
   Select  distinct
           segment1 soc,
           segment2 cdg,
           segment3 classe
   From    gl_code_combinations_kfv gcc,
           gl.gl_summary_templates gst,
           gl_period_statuses gps
   Where   1 = 1
    and    gst.template_id =  gcc.template_id
    --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
    and    gcc.segment1 = get_first_char || SUBSTR(gv_sob_name,2) --RBE artf2199612
    and    gst.template_id = gv_template_id
    and    gps.set_of_books_id = gv_set_of_book_id
    and    (gcc.enabled_flag = 'Y'
            or
            nvl(gcc.end_date_active,gps.end_date) >= gps.end_date
            )
    and    gps.period_name = Pn_Period
    and    not  exists
           (
            select 'X'
            from    GL_RECURRING_LINE_CALC_RULES grlc,
                    GL_RECURRING_LINES GRL,
                    gl_recurring_headers grh,
                    --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                    gl_recurring_batches grb--,
                    --dka_parameters dp
            where   1 = 1
            and     grlc.assigned_code_combination = gcc.code_combination_id

            and     grl.RECURRING_HEADER_ID = grlc.recurring_header_id
            and     grh.recurring_header_id = grl.recurring_header_id
            and     grl.recurring_line_num = grlc.recurring_line_num
            and     grh.recurring_batch_id = grb.recurring_batch_id
            --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
            and     grb.recurring_batch_type = 'M'
            -- JPE 18/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
            --and     grh.ledger_id = grb.ledger_id
            and     gps.set_of_books_id = grh.ledger_id
            and     grh.je_category_name = gv_je_category
           )
    and    exists
           ( select 'X'
            FROM FND_FLEX_VALUES_VL FFVV, FND_FLEX_VALUESET_V FFVSV
            WHERE FFVV.FLEX_VALUE_SET_ID =
            FFVSV.FLEX_VALUE_SET_ID
            AND FFVSV.FLEX_VALUE_SET_NAME = 'DAOPCCF_STE'
            AND FFVV.FLEX_VALUE = segment1
           )
    -->>debut JWY artf07249170
    AND EXISTS (SELECT 1 FROM hr_operating_units hou, gl_periods gp WHERE gp.period_name = gps.period_name and nvl(hou.date_to, to_date('31/12/4712', 'DD/MM/YYYY'))
     > gp.end_date AND substr(hou.name, 1, 3) = gcc.segment2 AND substr(hou.name, 5, 3) = substr(gcc.segment1,2,3))
    --<<fin JWY artf07249170
    order by segment1,
             segment2,
             segment3;

 Begin

 dka_tools_pkg.put_debug_message  ('insert_param (+)');

 FOR ligne in Cur_ecrit_equil LOOP

         dka_tools_pkg.put_outdebug_message (' ');
         dka_tools_pkg.put_outdebug_message ('Paramétrage manquant pour le triplet suivant : ' ||
                                             ligne.soc ||'-'|| ligne.cdg || '-'||ligne.classe) ;

        BEGIN

          vn_ccid    := 0 ;
          vv_errbuf  := '';
          vn_retcode := 0 ;

          -- Recherche de l'identifiant du lot et de la piece dans laquelle il faut insérer le paramétrage
          -- Exception si plusieurs pieces pour la même société
          Get_Rec_Header_id (gv_sob_name, vv_rec_batch_id, vv_rec_header_id); --RBE artf2199612
          dka_tools_pkg.put_debug_message ('Identifiant de la pièce ... trouvé :  batch_id'
                                           ||vv_rec_batch_id||' header_id : '||vv_rec_header_id);

          -- Recherche du numero de la ligne dans laquelle il faut insérer la ligne manquante
          vv_rec_line_num := Get_line_num (vv_rec_header_id, gv_sob_name, ligne.cdg, ligne.classe); -- voir pour ajouter errbuf et retcode --RBE artf2199612
          dka_tools_pkg.put_debug_message ('Numéro de la ligne dans laquelle l''insertion sera effectuée ... trouvé : ' ||vv_rec_line_num);

          -- Réxupération du max des numéros de formules
          Select     NVL(MAX(Grlcr.Rule_Num),0)
          Into       vv_rule_num
          From       GL_RECURRING_LINE_CALC_RULES  Grlcr
          Where      Grlcr.Recurring_Header_Id = vv_rec_header_id
          And        Grlcr.Recurring_Line_Num = vv_rec_line_num
          ;

          dka_tools_pkg.put_debug_message ('vv_rule_num : ' ||vv_rule_num);

          -- JPE 12/05/2016 Migration R12 : RG2 : Ajout des segments 11 et 12
          --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
          --Dka_Tools_Pkg.get_code_combination_id
          get_code_combination_id
                             (pv_segment1 => ligne.soc,
                              pv_segment2 => ligne.cdg,
                              pv_segment3 => ligne.classe,
                              pv_segment4 =>  'T',
                              pv_segment5 =>  'T',
                              pv_segment6 =>  'T',
                              pv_segment7 =>  'T',
                              pv_segment8 =>  'T',
                              pv_segment9 =>  'T',
                              pv_segment10 => 'T',
                              pv_segment11 => 'T',
                              pv_segment12 => 'T',
                              pn_code_combination_id => vn_ccid,
                              pv_errbuf => vv_errbuf,
                              pn_retcode => vn_retcode
                              );

        dka_tools_pkg.put_debug_message ('vn_ccid : ' ||vn_ccid);

        --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
        IF vn_retcode = 0 THEN
          -- JPE 12/05/2016 Migration R12 : RG2 : Ajout des segments 11 et 12
          dka_tools_pkg.put_debug_message ('Recupération de la clé OK : '|| ligne.soc||'.' || ligne.cdg || '.' ||
                                                  ligne.classe || '.T.T.T.T.T.T.T.T.T'
                                                  );

                  IF vv_rule_num = 0 THEN

                     -- Aucune ligne de formule n'existe ==> Insertion de la multiplication par -1

                             IF vn_retcode != 2 THEN
                                   INSERT INTO
                                   GL_RECURRING_LINE_CALC_RULES
                                         (RECURRING_HEADER_ID,
                                          RECURRING_LINE_NUM,
                                          RULE_NUM,
                                          LAST_UPDATE_DATE,
                                          LAST_UPDATED_BY,
                                          OPERATOR,
                                          CREATION_DATE,
                                          CREATED_BY,
                                          LAST_UPDATE_LOGIN,
                                          AMOUNT,
                                          ACTUAL_FLAG,
                                          -- JPE 12/05/2016 Migration R12 : Champ currency_code renommé par currency_code_11i
                                          CURRENCY_CODE_11I,
                                          RELATIVE_PERIOD_CODE,
                                          AMOUNT_TYPE,
                                          ASSIGNED_CODE_COMBINATION,
                                          TEMPLATE_ID,
                                          SEGMENT1,
                                          SEGMENT2,
                                          SEGMENT3,
                                          SEGMENT4,
                                          SEGMENT5,
                                          SEGMENT6,
                                          SEGMENT7,
                                          SEGMENT8,
                                          SEGMENT9,
                                          SEGMENT10,
                                          SEGMENT11, -- JPE 12/05/2016 Migration R12 : RG2 : Ajout des segments 11 et 12
                                          SEGMENT12,
                                          LEDGER_CURRENCY,
                                          CURRENCY_TYPE,
                                          --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                                          LEDGER_ID
                                          )
                                   VALUES
                                         (vv_rec_header_id,
                                          vv_rec_line_num,
                                          vv_rule_num + 1, --rule_line_num
                                          sysdate,
                                          fnd_global.USER_ID,
                                          'E', -- Saisie
                                          sysdate,
                                          fnd_global.USER_ID,
                                          Fnd_Profile.VALUE ('LOGIN_ID'),
                                          '', --amount null
                                          'A', --actual_flag
                                          gv_currency_code,
                                          'C', -- Periode en cours
                                          gv_amount_type, --'YTD', --Type de montant Exercice -- mettre dans dka_parameters
                                          vn_ccid,
                                          gv_template_id,
                                          ligne.soc,
                                          ligne.cdg,
                                          ligne.classe,
                                          'T',
                                          'T',
                                          'T',
                                          'T',
                                          'T',
                                          'T',
                                          'T',
                                          'T',
                                          'T',
                                          gv_currency_code,
                                          'T',
                                           --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                                           gv_set_of_book_id);


                                   INSERT INTO
                                   GL_RECURRING_LINE_CALC_RULES
                                         (RECURRING_HEADER_ID,
                                          RECURRING_LINE_NUM,
                                          RULE_NUM,
                                          LAST_UPDATE_DATE,
                                          LAST_UPDATED_BY,
                                          OPERATOR,
                                          CREATION_DATE,
                                          CREATED_BY,
                                          LAST_UPDATE_LOGIN,
                                          AMOUNT,
                                           --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                                          LEDGER_ID
                                          )
                                   VALUES
                                         (vv_rec_header_id,
                                          vv_rec_line_num,
                                          vv_rule_num + 2, --rule_line_num
                                          sysdate,
                                          fnd_global.USER_ID,
                                          '*', -- Multiplication
                                          sysdate,
                                          fnd_global.USER_ID,
                                          Fnd_Profile.VALUE ('LOGIN_ID'),
                                          -1, --amount null
                                           --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                                          gv_set_of_book_id);
                             END IF;
                  ELSE

                     -- Il existe déjà des lignes ==> Ajout d'une nouvelle ligne

                                  -- On deplace la ligne de multiplication par -1 (elle doit tjs être la dernière)
                                  UPDATE    GL_RECURRING_LINE_CALC_RULES grlcr
                                  SET       RULE_NUM = vv_rule_num + 1,
                                            grlcr.last_update_date = sysdate,
                                            grlcr.last_updated_by = fnd_global.USER_ID
                                  WHERE     grlcr.recurring_header_id = vv_rec_header_id
                                  And       grlcr.recurring_line_num = vv_rec_line_num
                                  AND       grlcr.rule_num = vv_rule_num
                                  ;


                                  -- On insere la ligne manquante pour le paramétrage
                                  INSERT INTO
                                             GL_RECURRING_LINE_CALC_RULES
                                                   (RECURRING_HEADER_ID,
                                                    RECURRING_LINE_NUM,
                                                    RULE_NUM,
                                                    LAST_UPDATE_DATE,
                                                    LAST_UPDATED_BY,
                                                    OPERATOR,
                                                    CREATION_DATE,
                                                    CREATED_BY,
                                                    LAST_UPDATE_LOGIN,
                                                    AMOUNT,
                                                    ACTUAL_FLAG,
                                                    -- JPE 12/05/2016 Migration R12 : Champ currency_code renommé par currency_code_11i
                                                    CURRENCY_CODE_11I,
                                                    RELATIVE_PERIOD_CODE,
                                                    AMOUNT_TYPE,
                                                    ASSIGNED_CODE_COMBINATION,
                                                    TEMPLATE_ID,
                                                    SEGMENT1,
                                                    SEGMENT2,
                                                    SEGMENT3,
                                                    SEGMENT4,
                                                    SEGMENT5,
                                                    SEGMENT6,
                                                    SEGMENT7,
                                                    SEGMENT8,
                                                    SEGMENT9,
                                                    SEGMENT10,
                                                    SEGMENT11, -- JPE 12/05/2016 Migration R12 : RG2 : Ajout des segments 11 et 12
                                                    SEGMENT12,
                                                    LEDGER_CURRENCY,
                                                    CURRENCY_TYPE,
                                                    --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                                                    LEDGER_ID
                                                    )
                                             VALUES
                                                   (vv_rec_header_id,
                                                    vv_rec_line_num,
                                                    vv_rule_num, --rule_line_num
                                                    sysdate,
                                                    fnd_global.USER_ID,
                                                    '+', -- Addition
                                                    sysdate,
                                                    fnd_global.USER_ID,
                                                    Fnd_Profile.VALUE ('LOGIN_ID'),
                                                    '', --amount null
                                                    'A', --actual_flag
                                                    gv_currency_code,
                                                    'C', -- Periode en cours
                                                    gv_amount_type, --'YTD', --Type de montant Exercice -- mettre dans dka_parameters
                                                    vn_ccid,
                                                    gv_template_id,
                                                    ligne.soc,
                                                    ligne.cdg,
                                                    ligne.classe,
                                                    'T',
                                                    'T',
                                                    'T',
                                                    'T',
                                                    'T',
                                                    'T',
                                                    'T',
                                                    'T',
                                                    'T',
                                                    gv_currency_code,
                                                    'T',
                                                    --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
                                                    gv_set_of_book_id);


                  END IF;

           --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
           ELSE
              dka_tools_pkg.put_debug_message ('ccid vn_retcode : ' ||vn_retcode);
              dka_tools_pkg.put_debug_message ('ccid vv_errbuf : ' ||vv_errbuf);
              pv_errbuf := vv_errbuf;
              Pv_Retcode := 2;
              RAISE Erreur_Prog_E;
           END IF; --vn_retcode != 2

         dka_tools_pkg.put_outdebug_message (' **** Insertion terminée pour le triplet : ' ||
                                             ligne.soc ||'-'|| ligne.cdg || '-'||ligne.classe);

       EXCEPTION
           WHEN error_data then
              dka_tools_pkg.put_debug_message ('Erreur de récupération des lignes de pièce répétitive');
              Pv_Retcode := 2;
              RETURN;
           WHEN others then -- Exception possible pb lors de la création/recuperation de l'entete de la piece .. On ne fait rien pour ce triplet
             Pv_Retcode := 1;
        END;

    END LOOP;

    COMMIT;

 Exception
  When others then
    pv_errbuf := 'Erreur dans insert_param';
    Pv_Retcode := 1;
    ROLLBACK;
 End insert_param;



---------------------------------------------------------------------------------------------------------------
--  Nom           : update_num_line
--  Description   : Procédure mettant à jour les numéros de lignes (réorganisation des numéros de lignes
--                  dans les pièces
--
--  pv_errbuf                 Entrée/Sortie      message d'erreur
--  pn_retcode                Entree/Sortie      code de retour: 'o=normal', '1=warning', '2=erreur'
--  VALEUR RETOURNEE :
--     N/A
--     Description       :
--     Valeurs possibles :
---------------------------------------------------------------------------------------------------------------

 Procedure update_num_line (Pv_errbuf    IN OUT   VARCHAR2,
                            Pv_Retcode   OUT      NUMBER) is


  CURSOR Couple_soc_cdg IS
  SELECT     distinct
             gcc.segment1 soc,
             gcc.segment2 cdg,
             gcc.segment3 classe,
             grl.recurring_line_num num_line,
             grh.recurring_header_id,
             grh.recurring_batch_id,
             grh.ledger_id
  FROM       gl_recurring_headers grh,
             gl_recurring_batches grb,
             gl_recurring_lines grl,
             dka_parameters dp,
             gl_code_combinations gcc
  Where      1 = 1
  And        gcc.code_combination_id = grl.code_combination_id
  And        grl.recurring_header_id = grh.recurring_header_id
  And        grh.recurring_batch_id  = grb.recurring_batch_id
  -- JPE 18/05/2016 MIGRATION R12 :  Champ set_of_books_id renommé par ledger_id
  And         grh.ledger_id = grb.ledger_id
  And        grh.ledger_id = gv_set_of_book_id
--  And        grb.name = gv_batch_name
  And        grh.je_category_name = gv_je_category
  Order by   gcc.segment1,
             gcc.segment2,
             gcc.segment3;

 cpt                      NUMBER := 0;
 old_soc                  VARCHAR2(30);
 nb_rec                   NUMBER := 0;

 Begin

      -- Remise à jour des numéros de formules (pour l'affichage dans l'ordre par société, cdg, puis classe)

    FOR rec in Couple_soc_cdg LOOP

        select count(*)
        into   nb_rec
        from   gl_recurring_lines g
        where  1 = 1
        and    g.recurring_header_id = rec.recurring_header_id
        ;

        update gl_recurring_lines g
        set    g.recurring_line_num = g.recurring_line_num + nb_rec
        where  g.recurring_header_id = rec.recurring_header_id
        and    g.recurring_line_num = rec.num_line
        ;

        update gl_recurring_line_calc_rules grlcr
        Set    grlcr.recurring_line_num = grlcr.recurring_line_num + nb_rec
        Where  grlcr.recurring_header_id = rec.recurring_header_id
        and    grlcr.recurring_line_num = rec.num_line
        ;

    END LOOP;

    cpt := 1;
    old_soc := '';

    FOR rec in Couple_soc_cdg LOOP

        IF nvl(old_soc,'KO') != rec.soc THEN
           cpt := 1;
        END IF;

        select count(*)
        into   nb_rec
        from   gl_recurring_lines g
        where  1 = 1
        and    g.recurring_header_id = rec.recurring_header_id
        ;

        update gl_recurring_lines g
        set    g.recurring_line_num = cpt
        where  g.recurring_header_id = rec.recurring_header_id
        and    g.recurring_line_num = rec.num_line ; -- l'ancienne valeur de la ligne est stockée dans le curseur

        update gl_recurring_line_calc_rules grlcr
        Set    grlcr.recurring_line_num = cpt
        Where  grlcr.recurring_header_id = rec.recurring_header_id
        and    grlcr.recurring_line_num = rec.num_line
        ;

        cpt := cpt + 1;
        old_soc := rec.soc;

    END LOOP;

    COMMIT;

 Exception
   when others then
      Pv_errbuf := 'Pb dans la reorganisation des lignes procedure update_num_line';
      Pv_Retcode := 1;
      ROLLBACK;
 End update_num_line;


---------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : procédure principale du traitement qui enchaînera l'ensemble
--                  des autres procèdures.
--
--  PARAMETRES    : pv_errbuf              Entrée/Sortie    message d'erreur
--                  pn_retcode             Sortie           code de retour: 'O=normal', '1=warning', '2=erreur'
--            pv_p_payment_patch       Entrée
--            pv_type_enregistrement Entrée     type_enregistrement  'C= lettre chèque',
--                            type_enregistrement  'B= LCR',
--                            type_enregistrement  'W =Virement',
--
--  VALEUR RETOURNEE :
--     Description       : ************************
--     Valeurs possibles : ************************
---------------------------------------------------------------------------------------------------------------
PROCEDURE main(Pv_Errbuf            IN OUT VARCHAR2,
               Pn_Retcode               OUT NUMBER,
               Pn_Period               IN VARCHAR2
               ) IS
    CURSOR  Liste_Ledger IS
    select     gl.ledger_id, gl.short_name
    from       gl_access_set_assignments gasa,
               gl_ledgers gl,
         -->>debut AAM artf07249170
             GL_RECURRING_HEADERS grh,
         gl_recurring_batches grb
         --<<fin AAM artf07249170
    where      access_set_id = gv_access_set_id
    and        gl.ledger_id  = gasa.ledger_id
    and        gl.ledger_category_code = 'PRIMARY'
  -->>debut AAM artf07249170
  and        gl.ledger_id = grh.ledger_id
  and        grb.name = 'REGUL EQUILIBRE CDG'
  and        grb.recurring_batch_id = grh.recurring_batch_id;
  --<<fin AAM artf07249170

    vb_idtemplate      BOOLEAN;

BEGIN

    Pn_Retcode := 0;
    gv_nb_ko_nb := 0;

    dka_tools_pkg.put_outdebug_message ('******************************** ');
    dka_tools_pkg.put_outdebug_message ('    Execution du traitement');
    dka_tools_pkg.put_outdebug_message ('******************************** ');

    dka_tools_pkg.put_outdebug_message (' Periode : '|| pn_period);

    dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
    dka_tools_pkg.put_outdebug_message ( '=> Phase 1 : Récupération des paramètres et connexion à la responsabilité');
    dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');

    /* Phase de récupération des paramètres*/
    Init (pn_period, pv_errbuf, pn_retcode);

    IF pn_retcode = 2
    THEN
      RAISE Erreur_Prog_E;
    END IF;

    dka_tools_pkg.put_outdebug_message ( '====> OK pour la phase 1');

       FOR rec in Liste_Ledger LOOP

        gv_set_of_book_id := rec.ledger_id;
        --  16/03/2017 NBO artf2080408 - SPE084- Equilibrage par centre de gestion - Le programme se termine en erreur
        gv_sob_name := rec.short_name;
        vb_idtemplate := true;

        dka_tools_pkg.put_outdebug_message ( 'gv_set_of_book_id : ' || gv_set_of_book_id);
        dka_tools_pkg.put_outdebug_message ( 'gv_cle_synthese : ' || REPLACE(gv_cle_synthese,'XSSSS',get_first_char||gv_sob_name)); --RBE artf2199612

        BEGIN
            select  gst.template_id
            into    gv_template_id
            -- JPE 17/05/2016 Migration R12 : VUE EN R12
            from    gl_summary_templates_v gst
            where   gst.concatenated_description = REPLACE(gv_cle_synthese,'XSSSS',get_first_char||gv_sob_name) --10/05/2007  --RBE artf2199612
            -- JPE 17/05/2016 MIGRATION R12 : Champ set_of_books_id renommé par ledger_id
            and     ledger_id = gv_set_of_book_id;

      dka_tools_pkg.put_outdebug_message ( 'gv_template_id : ' ||gv_template_id);
        EXCEPTION when no_data_found then -- pas d'id template pour cette societe
            pn_retcode := 1;
            dka_tools_pkg.put_outdebug_message ('pas d''id template pour le couple gv_set_of_book_id : ' || gv_set_of_book_id || ' et gv_cle_synthese : ' || REPLACE(gv_cle_synthese,'XSSSS',get_first_char||gv_sob_name)) ; --RBE artf2199612
            vb_idtemplate := false;
        END;

        IF vb_idtemplate THEN
            dka_tools_pkg.put_outdebug_message (' ');
            dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
            dka_tools_pkg.put_outdebug_message ( '=> Phase 2 : Vérification du paramétrage');
            dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
            dka_tools_pkg.put_outdebug_message (' ');

            check_param(pv_errbuf, pn_retcode);

            IF pn_retcode = 2
            THEN
              RAISE Erreur_Prog_E;
            END IF;

            dka_tools_pkg.put_outdebug_message (' ');
            dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
            dka_tools_pkg.put_outdebug_message ( '=> Phase 3 : Insertion du paramétrage');
            dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
            dka_tools_pkg.put_outdebug_message (' ');

            insert_param(gv_period_name, pv_errbuf, pn_retcode);

            IF pn_retcode = 2
            THEN
              RAISE Erreur_Prog_E;
            END IF;

            update_num_line(pv_errbuf, pn_retcode);

            IF pn_retcode = 1
            THEN
              dka_tools_pkg.put_outdebug_message (pv_errbuf);
            END IF;

            dka_tools_pkg.put_debug_message ('gv_period_name :' || gv_period_name);
            dka_tools_pkg.put_debug_message ('gv_set_of_book_id :' || gv_set_of_book_id);

        END IF;
    END LOOP;

  dka_tools_pkg.put_outdebug_message (' ');
  dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
  dka_tools_pkg.put_outdebug_message ( '=> Phase 4 : Pièces répétitives - Génération');
  dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
  dka_tools_pkg.put_outdebug_message (' ');

  launch_request (pv_errbuf, pv_retcode => pn_retcode);

  IF pn_retcode = 2
  THEN
    RAISE Erreur_Prog_E;
  END IF;


   IF Vn_nb_traitement >= 1 THEN

         wait_GLPRJE(pv_errbuf,pn_retcode);

         IF pn_retcode = 2
         THEN
            RAISE Erreur_Prog_E;
         END IF;
         dka_tools_pkg.put_outdebug_message (' ');
         dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
         dka_tools_pkg.put_outdebug_message ( '=> Phase 5 : Contrôles et Suppression');
         dka_tools_pkg.put_outdebug_message ('************************************************************************************ ');
         dka_tools_pkg.put_outdebug_message (' ');

         check_data (pv_errbuf, pn_retcode);

         IF pn_retcode = 2
         THEN
            RAISE Erreur_Prog_E;
         END IF;

   END IF;

   dka_tools_pkg.put_outdebug_message ( '====> OK ');

   IF gv_nb_ko_nb > 0 OR Gv_nb_KO >= 1 THEN--Warning
     pn_retcode := 1;
   END IF;


Exception
    WHEN Erreur_Prog_E
    THEN
       ROLLBACK;
       pn_retcode := 2;
       dka_tools_pkg.put_debug_message(pv_errbuf);

    WHEN OTHERS
    THEN
       ROLLBACK;
       pv_errbuf     := 'sortie de main avec erreur EXCEPTION OTHERS:' || SQLERRM;
       pn_retcode    := 2;

End main;


End DKA_SGLEQUILIB_PKG;
/
SHOW ERROR
EXIT;
