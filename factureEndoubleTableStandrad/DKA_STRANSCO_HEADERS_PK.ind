  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_PERIOD_MAIL_CMD.VUE
  -- Nom              : DKA_PERIOD_MAIL_CMD.VUE
  -- Description      : Création des vues
  -- Auteur           : Anas RAOUF
  -- Date de création : 06/05/2021
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 
CREATE OR REPLACE VIEW DKA_PERIOD_MAIL_CMD AS
 SELECT period_name
 --    INTO Dka_Tools_Pkg.tab_request_params(3)
   FROM gl_periods
  WHERE period_set_name = 'GROUPE'
    AND start_date = (SELECT min(start_date)
           FROM gl_period_statuses
          WHERE application_id = 200
            AND ledger_id in
                (select distinct set_of_books_id
                   FROM hr_operating_units
                  where organization_id in
                        (SELECT organization_id
                           FROM PER_SECURITY_ORGANIZATIONS
                          WHERE SECURITY_PROFILE_ID = FND_PROFILE.VALUE('XLA_MO_SECURITY_PROFILE_LEVEL')))
            AND closing_status = 'O');
EXIT;
/