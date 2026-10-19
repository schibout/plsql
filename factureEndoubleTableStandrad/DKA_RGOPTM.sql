CREATE OR REPLACE PACKAGE BODY APPS.DKA_SGLCLOTURE_EXCEPT_PKG
AS
  ---------------------------------------------------------------------------------------------------------------
  -- CAP GEMINI ERNST AND YOUNG
  -- PROJET            : DALKIA Oracle Applications
  -- NOM               : DKA_SGLCLOTURE_EXCEPT_PKG.pkb
  -- DESCRIPTION       : traitement de fermeture exceptionnelle de GL
  ---
  --- AUTEUR           : Guillaume LEBLON
  --- DATE DE CREATION : 20/01/2004
  --- DOC. ASSOCIEE    :
  --  COMMENTAIRE      :
  ---------------------------------------------------------------------------------------------------------------
  --- HISTORIQUE DES MODIFICATIONS
  --- Date       Qui Description
  --- ---------- --- --------------------------------------------------------------------------------------------
  --- 10/02/2004 XD  period_gl_courante : Correction de la requête dans le cas où attribute1 est Null
  --- 06/04/2006 FM  Apres le traitement4 : 'REGUL EQUILIBRE CDG', ajout traitement5 : Equilibrage par centre de gestion
  --- 21/07/2006 SL  main : Modification de la période de lancement du traitement de contrepassation
  --- 01/09/2006 AC Dans "Controle : periode courante est la suivante de periode à fermer ?"
  ---               -->update qui rend nulles les informations projet sur les lignes de contrepassation avec compte de bilan
  --- 14/10/2009 GV main: correction des paramètres de lancement du traitement d'équilibre par centre de gestion
  --- 27/10/2016 HDE Projet Helios
  --- 18/06/2018 JWY Correctif problème recherche periode suivante si la période ré-ouverte est antérieure à la période M-1
  ---------------------------------------------------------------------------------------------------------------

  ---------------------------------------------------------------------------------------------------------------
  -- Exceptions
  failed  EXCEPTION;
  pragma exception_init(failed, -20001);

  ---------------------------------------------------------------------------------------------------------------
  -- Constantes
  K_AUTOPOST_SET_NAME constant varchar2(30) := 'DKA_MOIS_GL_A_REFERMER';

  ---------------------------------------------------------------------------------------------------------------
  -- Curseurs
  CURSOR cur_autoposting_set(p_autopost_set_name in gl_automatic_posting_sets.autopost_set_name%type) is
  SELECT distinct ps.autopost_set_id, ps.autopost_set_name, ps.enabled_flag, po.period_name
  FROM gl_automatic_posting_sets     ps
  JOIN gl_automatic_posting_options  po on (po.autopost_set_id = ps.autopost_set_id)
  WHERE ps.autopost_set_name = p_autopost_set_name;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : Check_setup
  --  Description   : vérification du paramétrage nécessaire au traitement
  --
  --  PARAMETRES    :
  ---------------------------------------------------------------------------------------------------------------
  procedure check_setup is
    vn_access_set_id    number;
    l_access_set        gl_access_sets%rowtype;
    l_autoposting_set   cur_autoposting_set%rowtype;
  begin
    -- Responsabilité courante = GL
    dka_tools_pkg.put_debug_message ('RESP_APPL_ID=' || Fnd_Global.RESP_APPL_ID);
    if Fnd_Global.RESP_APPL_ID != 101 then
      raise_application_error (-20000, 'Ce programme doit être lancé dépuis une responsabilité GL');
    end if;

    -- option de profil « Jeu d'accès aux données »
    vn_access_set_id := Fnd_Profile.VALUE ('GL_ACCESS_SET_ID');
    dka_tools_pkg.put_debug_message ('GL_ACCESS_SET_ID=' || vn_access_set_id);
    if vn_access_set_id is null then
      raise_application_error (-20000, 'L''option de profil « Jeu d''accès aux données » n''est pas valorisé dans la responsabilité courante');
    end if;

    -- Le jeu d'accès aux données doit pointer vers OPERATIONNEL, LEGAL ou RESTITUTION (TODO : ceci devrait être paramétrable (CUF O/N au niveau du Jeux d'accès aux données))
    begin
      select * into l_access_set
      from gl_access_sets
      where access_set_id = vn_access_set_id;
      dka_tools_pkg.put_debug_message ('GL_ACCESS_SET=' || l_access_set.name);
      if l_access_set.name not in ('OPERATIONNEL', 'LEGAL', 'RESTITUTION') then
        raise_application_error (-20000, 'Ce programme ne peut traiter que les jeux d''accès au données OPERATIONNEL, LEGAL ou RESTITUTION. Vérifier l''option de profil « Jeu d''accès aux données ».');
      end if;
    exception
      when no_data_found then
        raise_application_error (-20000, 'L''option de profil « Jeu d''accès aux données » a une valeur invalide');
    end;

    -- jeu d'auto-imputation DKA_MOIS_GL_A_REFERMER
    open cur_autoposting_set(K_AUTOPOST_SET_NAME);
    fetch cur_autoposting_set into l_autoposting_set;
    dka_tools_pkg.put_debug_message ('AUTOPOSTING_SET=' || l_autoposting_set.autopost_set_name || ' ; période=' || l_autoposting_set.period_name);
    if cur_autoposting_set%notfound then
      close cur_autoposting_set;
      raise_application_error (-20000, 'Le jeu d''auto-imputation "' || K_AUTOPOST_SET_NAME || ' n''existe pas ou n''est pas configuré.');
    end if;

    -- une seule période définie dans le jeu d'auto-imputation
    fetch cur_autoposting_set into l_autoposting_set;
    if cur_autoposting_set%found then
      close cur_autoposting_set;
      raise_application_error (-20000, 'Le jeu d''auto-imputation "' || K_AUTOPOST_SET_NAME || ' ne doit contenir qu''une seule période');
    end if;

    close cur_autoposting_set;
  end check_setup;

  ---------------------------------------------------------------------------------------------------------------
  --  Nom           : get_autoposting_set
  --  Description   : retroune les informations sur le jeu d'auto-imputation DKA_MOIS_GL_A_REFERMER
  --
  --  PARAMETRES    :
  ------------------------------------------------------------------------------------------------------------
  function get_autoposting_set(p_autopost_set_name in gl_automatic_posting_sets.autopost_set_name%type) return cur_autoposting_set%rowtype
  is
    l_result cur_autoposting_set%rowtype;
  begin
    open cur_autoposting_set(p_autopost_set_name);
    fetch cur_autoposting_set into l_result;
    close cur_autoposting_set;

    return l_result;
  end;

  -------------------------------------------------------------------------------------------------------------------
  --  Nom           : get_period
  --  Description   : Retourne les information sur une période GL
  --
  --  PARAMETRES    :
  --     pn_ledger_id
  --     p_period_name
  -------------------------------------------------------------------------------------------------------------------
function get_period(pn_ledger_id IN gl_ledgers.ledger_id%type, p_period_name in gl_period_statuses.period_name%type) return gl_period_statuses%rowtype
  IS
    CURSOR cur_period(p_ledger_id in gl_ledgers.ledger_id%type, p_period_name in gl_period_statuses.period_name%type) is
    SELECT gps.*
    FROM gl_period_statuses        gps
    WHERE application_id = 101 --GL
    AND ledger_id        = p_ledger_id
    AND period_name      = p_period_name;

    l_result gl_period_statuses%rowtype;
  BEGIN
    open cur_period(pn_ledger_id, p_period_name);
    fetch cur_period into l_result;
    close cur_period;

    return l_result;
  END get_period;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : PERIOD_GL_COURANTE
--  Description   : Recherche la 1ère période GL ouverte qui n'est pas en ouverture spéciale
--
--  PARAMETRES    :
--     pn_ledger_id  number
-------------------------------------------------------------------------------------------------------------------
  function period_gl_courante(pn_ledger_id IN gl_ledgers.ledger_id%type) return gl_period_statuses%rowtype
  IS
    CURSOR cur_period(pn_ledger_id IN gl_ledgers.ledger_id%type) is
    SELECT gps.*
    FROM gl_period_statuses        gps
    WHERE application_id       = 101 --GL
      AND ledger_id              = pn_ledger_id
      AND closing_status         = 'O' --OPEN
      AND NVL (gps.Attribute1, 'N') != 'Y'
    ORDER BY start_date, period_name;

    l_result gl_period_statuses%rowtype;
  BEGIN
    open cur_period(pn_ledger_id);
    fetch cur_period into l_result;
    close cur_period;

    return l_result;
  END period_gl_courante;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : my_wait_for_request
--  Description   : Attente de la fin d'un traitement
--
--  PARAMETRES    :
--     p_request_id     identifiant du traitement retourné par fnd_request.submit_request
--     p_description   libellé du traitement
--     pv_errbuf        message d'erreur
--     p_timeout        durée maxi autorisée en secondes (0=infini)
-------------------------------------------------------------------------------------------------------------------
procedure my_wait_for_request(
    p_request_id                    in FND_CONCURRENT_REQUESTS.request_id%type,
    p_description                  in varchar2,
    pv_errbuf                       in out varchar2,
    p_timeout                       in number default 0)
  is
    vb_status                      BOOLEAN;
    vv_phase                       VARCHAR2 (100);
    vv_status                      VARCHAR2 (100);
    vv_dev_phase                   VARCHAR2 (100);
    vv_dev_status                  VARCHAR2 (100);
    vv_message                     VARCHAR2 (100);
  begin
    vb_status := fnd_concurrent.wait_for_request (
      request_id   => p_request_id,
      interval     => 10,
      max_wait     => nvl(p_timeout, 0),
      phase        => vv_phase,
      status       => vv_status,
      dev_phase    => vv_dev_phase,
      dev_status   => vv_dev_status,
      message      => vv_message);

    dka_tools_pkg.put_debug_message ('--> Traitement [' || p_request_id || '] : ' || vv_dev_phase || '/' || vv_dev_status || ' : ' || vv_message);
    IF NOT vb_status THEN
      pv_errbuf := '--> Traitement ' || p_description || ' trop long : ['|| TO_CHAR (p_request_id) || ']';
      dka_tools_pkg.put_debug_message (pv_errbuf);
      RAISE failed;
    ELSIF ( vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'ERROR') THEN
      pv_errbuf := '--> ERREUR du Traitement ' || p_description || ' [' || TO_CHAR (p_request_id) || '] : ' || vv_message;
      dka_tools_pkg.put_debug_message (pv_errbuf);
      RAISE failed;
    ELSIF (vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'NORMAL') THEN
      dka_tools_pkg.put_debug_message ('--> Exécution du Traitement ' || p_description || ' [' || TO_CHAR (p_request_id)|| '] : OK');
    ELSIF ( vv_dev_phase = 'COMPLETE' AND vv_dev_status = 'WARNING') THEN
      pv_errbuf := '--> AVERTISSEMENT du Traitement ' || p_description || ' [' || TO_CHAR (p_request_id) || '] : ' || vv_message;
    END IF; -- fin IF NOT
  end my_wait_for_request;


-------------------------------------------------------------------------------------------------------------------
--  Nom           : my_submit_request
--  Description   : Lancement d'un traitement
--
--  PARAMETRES    :
--     p_application_short_name     Nom de l'application
--     p_program_name               Nom du programme
--     p_description                libellé du traitement
--     pv_errbuf                    message d'erreur
--     p_timeout                    durée maxi autorisée en secondes (0=infini)
--     p_argument1..6               Argument du traitement
-------------------------------------------------------------------------------------------------------------------
  procedure my_submit_request(
    p_application_short_name      in fnd_application.application_short_name%type,
    p_program_name                in fnd_concurrent_programs.concurrent_program_name%type,
    p_description                 in varchar2 default null,
    pv_errbuf                     in out varchar2,
    p_argument1                   in varchar2 default chr(0),
    p_argument2                   in varchar2 default chr(0),
    p_argument3                   in varchar2 default chr(0),
    p_argument4                   in varchar2 default chr(0),
    p_argument5                   in varchar2 default chr(0),
    p_argument6                   in varchar2 default chr(0),
    p_argument7                   in varchar2 default chr(0),
    p_argument8                   in varchar2 default chr(0),
    p_timeout                     in number default 0)
  is
    l_req_id   fnd_concurrent_requests.request_id%type;
  begin
    l_req_id := fnd_request.submit_request (
      application  => p_application_short_name,             --APPLICATION PROPRIETAIRE DU TRAITEMENT
      program      => p_program_name,                       --SHORT NAME du Traitement
      description  => '',                                   --PROGRAM_NAME
      start_time   => '',                                   --START
      sub_request  => FALSE,                                --SUB_REQUEST
      argument1    => p_argument1,
      argument2    => p_argument2,
      argument3    => p_argument3,
      argument4    => p_argument4,
      argument5    => p_argument5,
      argument6    => p_argument6,
      argument7    => p_argument7,
      argument8    => p_argument8);
    if nvl(l_req_id, 0) <= 0 then
      pv_errbuf := 'ERREUR : impossible de lancer le programme ' || p_application_short_name || '/' || p_program_name;
      dka_tools_pkg.put_debug_message ('--> ' || pv_errbuf);
      raise_application_error (-20000, pv_errbuf);
    else
      COMMIT;
      my_wait_for_request (
        p_request_id   => l_req_id,
        p_description  => case p_description when null then p_program_name else p_program_name || '(' || p_description || ')' end,
        pv_errbuf      => pv_errbuf,
        p_timeout      => p_timeout);
    end if;
  exception
    when failed then
      raise_application_error (-20000, 'Erreur lors de l''exécution du traitement "' || case p_description when null then p_program_name else p_program_name || '(' || p_description || ')' end || '"');
  end my_submit_request;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : Close_GL_Period
--  Description   : Clôture GL suite ré-ouverture exceptionnelle (pour un livre)
--
--  PARAMETRES    :
--     p_ledger_id      identifiant du livre
--     p_auto_post_set  information du jeu d'auto-imputation
-------------------------------------------------------------------------------------------------------------------
  procedure Close_GL_Period(
    p_access_set_id                in gl_access_sets.access_set_id%type,
    p_ledger_id                    in gl_ledgers.ledger_id%type,
    p_auto_post_set                in cur_autoposting_set%rowtype,
    pv_errbuf                      in out varchar2)
  is
    l_period_to_close   gl_period_statuses%rowtype;
    l_current_period    gl_period_statuses%rowtype;
    l_next_period_name  gl_period_statuses.period_name%type;
    l_req_id            fnd_concurrent_requests.request_id%type;
  begin
    dka_tools_pkg.put_debug_message ('Livre ' || p_ledger_id || '. Cloture de la période : ' || p_auto_post_set.period_name);
    dka_tools_pkg.put_debug_message ('------------------------------------------------------------------------------------');

    -- vérification du statut de la période (2)
    l_period_to_close := get_period(p_ledger_id, p_auto_post_set.period_name);
    dka_tools_pkg.put_debug_message ('Période à fermer = ' || l_period_to_close.period_name || ' - statut = ' || l_period_to_close.closing_status ||
      ' - ouverture spéciale=' || l_period_to_close.attribute1);
    if l_period_to_close.period_name is null then
      raise_application_error (-20000, 'Le mois GL à fermer '|| p_auto_post_set.period_name||' n''est pas définie');
    elsif l_period_to_close.closing_status != 'O' or l_period_to_close.attribute1 != 'Y' then
      dka_tools_pkg.put_debug_message('Le mois GL à fermer '|| p_auto_post_set.period_name||' n''est pas ouvert avec le mode Ouverture spéciale');
      RETURN;  -- non bloquant => on passe aux livres suivants
    end if;

    -- Vérfication de la période courante (11)
    l_current_period := period_gl_courante(p_ledger_id);
    dka_tools_pkg.put_debug_message ('Période courante = ' || l_current_period.period_name || ' - statut = ' || l_current_period.closing_status);
    if l_current_period.period_name is null then
      dka_tools_pkg.put_debug_message('Attention : Aucune période ouverte en mode d''ouverture normal');
    end if;

    -- Vérification de la période suivante (celle sui suit la période à fermer)
    gl_period_statuses_pkg.get_next_period(p_ledger_id, l_period_to_close.period_name, l_next_period_name);
    dka_tools_pkg.put_debug_message ('Période suivante = ' || l_next_period_name);
    if l_next_period_name is null then
      dka_tools_pkg.put_debug_message('Attention : Impossible de déterminer la période suivante du livre GL');
      -- RETURN;   -- JWY
    end if;

    -- Lancement du traitement spécifique « DKA : Transfert d'écritures GL vers PA » (DKA_SPACUTOFF_TRANSFER) (5, 6)
    /*dka_tools_pkg.put_debug_message ( 'Lancement DKA : Transfert d''écritures GL vers PA sans paramètre' );
    my_submit_request(
      p_application_short_name  => 'DKA',
      p_program_name            => 'DKA_SPACUTOFF_TRANSFER',
      p_description             => 'Transfert d écritures GL vers PA',
      pv_errbuf                 => pv_errbuf);
    */
    /*
    -- Lancement du traitement spécifique « DKA : Transfert des quantités de PA vers GL » (DKA_SPAQUANTITE) (7, 8)
    dka_tools_pkg.put_debug_message ( 'Lancement DKA : Transfert des quantités de PA vers GL  sans paramètre' );
    my_submit_request(
      p_application_short_name  => 'DKA',
      p_program_name            => 'DKA_SPAQUANTITE',
      p_description             => 'Transfert d écritures GL vers PA',
      pv_errbuf                 => pv_errbuf);
    */
    -- Lancement du traitement standard « Programme - Imputation automatique » (GLPAUTOP) (9, 10)
    dka_tools_pkg.put_debug_message ( 'Lancement Programme - Imputation automatique' );
    my_submit_request(
      p_application_short_name  => 'SQLGL',
      p_program_name            => 'GLPAUTOP',
      p_description             => 'Imputation automatique (deuxième imputations)',
      pv_errbuf                 => pv_errbuf,
      p_argument1               => p_access_set_id,
      p_argument2               => p_auto_post_set.autopost_set_id);

    -- Contrôle du positionnement de la période à fermer par rapport à la période courante (12)

    --if l_current_period.period_name = l_next_period_name THEN
    if l_current_period.period_name = nvl(l_next_period_name, 'NULL') THEN -- JWY
      -- Mise à jour des attributs relatifs aux projets dans les lignes GL
      dka_tools_pkg.put_debug_message ( 'Réinitialisation des attributs relatifs aux projets dans les lignes GL' );
      --attribute relatifs au projet mis à jour pour les lignes avec un compte de bilan / AC le 01/09/2006
      update gl_je_lines gll
      set attribute11 = null, attribute12 = null, attribute13 = null, attribute14 = null
      where period_name = l_period_to_close.period_name
        and gll.attribute11 is not null
        and gll.code_combination_id in (select code_combination_id from gl_code_combinations where account_type not in ('R', 'E'))
        and ledger_id = p_ledger_id;
      dka_tools_pkg.put_debug_message ( 'Nb de lignes mises à jour : ' || SQL%ROWCOUNT);

      -- lancement du traitement standard « Programme - Contrepassation automatique » (12, 13)
      dka_tools_pkg.put_debug_message ( 'Lancement Programme - Contrepassation automatique' );
      my_submit_request(
        p_application_short_name  => 'SQLGL',
        p_program_name            => 'GLPARV',
        p_description             => 'Contrepassation automatique',
        pv_errbuf                 => pv_errbuf,
        p_argument1               => p_ledger_id,
        p_argument2               => l_next_period_name,
        p_argument3               => p_access_set_id);
    end if;

    -- Fermeture de la période GL : Mois M (14)
    dka_tools_pkg.put_debug_message ( 'Lancement Programme - Périodes - Fermer une période' );
    my_submit_request (
      p_application_short_name  => 'SQLGL',                              --APPLICATION PROPRIETAIRE DU TRAITEMENT
      p_program_name   => 'GLOCPP',                             --SHORT NAME du Traitement
      p_description    => 'Fermeture de la période GL',         --PROGRAM_NAME
      pv_errbuf        => pv_errbuf,
      p_argument1      => '',                                   --Nom abrégé du livre
      p_argument2      => p_access_set_id,                      --ID jeu d'accès
      p_argument3      => p_ledger_id,                          --ID livre
      p_argument4      => l_period_to_close.period_name,        --nom de la période
      p_argument5      => 'N',                                  --Fermeture de périodes consécutives
      p_argument6      => 'C',                                  -- Statut de clôture
      p_argument7      => 101                                   -- ID application
    );


    -- Vérification du nouveau statut de la période :
    l_period_to_close := get_period(p_ledger_id, p_auto_post_set.period_name);
    dka_tools_pkg.put_debug_message ('Période à fermer = ' || l_period_to_close.period_name ||  '. Statut après GLOCPP =' || l_period_to_close.closing_status);

  end Close_GL_Period;

-------------------------------------------------------------------------------------------------------------------
--  Nom           : main
--  Description   : Procédure principale enchaînant l'ensemble des autres procédures
--
--  PARAMETRES    :
-- pv_errbuf                       Entrée/Sortie           retour de message eventuel
--       pn_retcode                      Sortie                  status du traitement en sortie
--
--  VALEUR RETOURNEE :
--     Description       : code retour de validité
--     Valeurs possibles : 0: normal, 1: warning, 2: erreur
-------------------------------------------------------------------------------------------------------------------
  PROCEDURE main(
      pv_errbuf  IN OUT VARCHAR2,
      pn_retcode OUT NUMBER)
  IS
    vn_access_set_id               NUMBER;
    vv_autopost_set                cur_autoposting_set%rowtype;
    l_req_id                       fnd_concurrent_requests.request_id%type;
    l_counter                      pls_integer := 0;

    CURSOR cur_ledgers(pn_access_set_id in number) IS
    SELECT gl.ledger_id, gl.name, gl.ledger_category_code
    FROM GL_ACCESS_SET_LEDGERS   gasl
    JOIN GL_LEDGERS              gl   on (gasl.ledger_id = gl.ledger_id)
    WHERE gasl.access_set_id = pn_access_set_id
    AND sysdate between nvl(gasl.START_DATE, sysdate) and nvl(gasl.END_DATE, sysdate+1)
    AND OBJECT_TYPE_CODE = 'L';   -- uniquement les livres (pas les jeux de livres)
  BEGIN
    dka_tools_pkg.put_debug_message ( 'DKA_SGLCLOTURE_EXCEPT : Clôture GL suite ré-ouverture exceptionnelle');
    dka_tools_pkg.put_debug_message ( '====================================================================');

    -- Vérification du paramétrage
    check_setup();

    -- récupération du jeu d'accès aux données et du jeu d'auto-imputation
    vn_access_set_id := Fnd_Profile.VALUE ('GL_ACCESS_SET_ID');

    vv_autopost_set := get_autoposting_set(K_AUTOPOST_SET_NAME);
    if vv_autopost_set.autopost_set_id is null then
      raise_application_error (-20000, 'Le jeu d''auto-imputation ' || K_AUTOPOST_SET_NAME || ' n''existe pas');
    elsif vv_autopost_set.enabled_flag = 'N' then
      raise_application_error (-20000, 'Le jeu d''auto-imputation ' || K_AUTOPOST_SET_NAME || ' n''est pas activé');
    end if;

    -- Lancement du traitement standard « Programme - Imputation automatique » (GLPAUTOP) (3, 4)
    dka_tools_pkg.put_debug_message ( 'Lancement  Programme - Imputation automatique' );
    dka_tools_pkg.put_debug_message ( 'Paramètres : access set id:' || vn_access_set_id || ' et jeu d''imputation id:'|| vv_autopost_set.autopost_set_id );
    my_submit_request(
      p_application_short_name  => 'SQLGL',
      p_program_name            => 'GLPAUTOP',
      p_description             => 'Imputation automatique (première imputations)',
      pv_errbuf                 => pv_errbuf,
      p_argument1               => vn_access_set_id,
      p_argument2               => vv_autopost_set.autopost_set_id);

    --Clôture sur les différents livres
    FOR c_ledger IN cur_ledgers(vn_access_set_id) LOOP
      dka_tools_pkg.put_debug_message (' ');
      dka_tools_pkg.put_debug_message (c_ledger.name ||' : ' || c_ledger.ledger_category_code);
      pv_errbuf := null;

      close_gl_period(
        p_access_set_id       => vn_access_set_id,
        p_ledger_id           => c_ledger.ledger_id,
        p_auto_post_set       => vv_autopost_set,
        pv_errbuf             => pv_errbuf);
    END LOOP;

    -- Désactivation du jeu d'auto-imputation « DKA_MOIS_GL_A_REFERMER ». (15)
    dka_tools_pkg.put_debug_message ( 'Désactivation du jeu d''auto-imputation "' || K_AUTOPOST_SET_NAME|| '"');
    UPDATE gl_automatic_posting_sets ps
    SET enabled_flag           = 'N'
    WHERE ps.autopost_set_name = K_AUTOPOST_SET_NAME;
    if SQL%ROWCOUNT <> 1 then
      raise_application_error (-20000, 'Erreur lors de la désactivation du jeu d''auto-imputation "' || K_AUTOPOST_SET_NAME|| '" : SQL%ROWCOUNT=' || SQL%ROWCOUNT);
    end if;
    COMMIT;

    dka_tools_pkg.put_debug_message ('Nombre de livres traités : ' || l_counter);
  EXCEPTION
    WHEN OTHERS THEN
      dka_tools_pkg.put_debug_message ('Erreur : '|| nvl(pv_errbuf, SQLERRM));
      if pv_errbuf is null then pv_errbuf  := SQLERRM; end if;
      pn_retcode := 2;
  END main;
--------------------------------------------------------------------------------------------------------
END DKA_SGLCLOTURE_EXCEPT_PKG; -- Package body
/
exit;
/