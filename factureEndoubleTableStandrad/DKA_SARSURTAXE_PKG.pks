--------------------------------------------------------------------------------
-- $$
-- Capgemini
-- Projet           : Automatisation extraction des SQLs du matin
-- Nom              : DKA_RB_LINES.tab
-- Description      : Script de création de la table d'interface des fichiers
--                    DKA_RB_LINES
-- Auteur           : Saloua HAHIOUI (Capgemini)
-- Date de création : 23/12/2021
-- Doc. associée    :
-- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur DKA en 
--                    passant en paramètres
--                    1- Password APPS
--                    2- Password DKA
--                    3- Tablespace des données pour le schéma DKA
--------------------------------------------------------------------------------
-- Historique
-- Date       Qui Description
-- ---------- --- --------------------------------------------------------------



CONNECT DKA/&&2

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT DROP DE LA TABLE DKA_RB_LINES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
DROP TABLE DKA_RB_LINES CASCADE CONSTRAINTS;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE LA TABLE DKA_RB_LINES
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CREATE TABLE DKA_RB_LINES
(
	 line_id                   NUMBER(15) not null,
  type                      VARCHAR2(1) not null,
  line_type                 VARCHAR2(1) not null,
  bank_account_id           NUMBER(15) not null,
  application_id            NUMBER(15),
  set_of_books_id           NUMBER(15),
  je_batch_id               NUMBER(15),
  je_header_id              NUMBER(15),
  je_line_num               NUMBER(15),
  journal_sequence_id       NUMBER(15),
  sle_header_id             NUMBER(15),
  sle_line_num              NUMBER(15),
  check_id                  NUMBER(15),
  period_name               VARCHAR2(15),
  code_combination_id       NUMBER(15),
  external_reference        VARCHAR2(30),
  check_number              VARCHAR2(50),
  reference1                VARCHAR2(100),
  reference2                VARCHAR2(100),
  reference3                VARCHAR2(100),
  reference4                VARCHAR2(100),
  reference5                VARCHAR2(100),
  reference6                VARCHAR2(100),
  line_date                 DATE not null,
  bank_date                 DATE,
  amount                    NUMBER not null,
  transaction_amount        NUMBER,
  bank_transaction_code     VARCHAR2(10) not null,
  description               VARCHAR2(300),
  transaction_currency_code VARCHAR2(15),
  transaction_date          DATE,
  long_description          VARCHAR2(1000),
  currency_code             VARCHAR2(15),
  free_comment              VARCHAR2(250),
  matching_status           VARCHAR2(1) default 'N',
  pending_status            VARCHAR2(1) default 'N',
  matching_ref              VARCHAR2(30),
  matching_date             DATE,
  matching_sysdate          DATE,
  matching_type             VARCHAR2(1),
  matched_by                NUMBER(15),
  accounting_flag           VARCHAR2(1),
  generate_flag             VARCHAR2(1),
  accounting_plan_id        NUMBER(15),
  je_reference_1            VARCHAR2(240),
  org_id                    NUMBER(15),
  import_id                 NUMBER(15),
  batch_id                  NUMBER(15),
  orig_org_id               NUMBER(15),
  orig_bank_account_id      NUMBER(15),
  generated_line_id         NUMBER(15),
  unmatch_date              DATE,
  unmatched_by              NUMBER(15),
  unmatch_count             NUMBER,
  sum_flag                  VARCHAR2(1),
  sum_id                    NUMBER(15),
  created_by                NUMBER(15),
  creation_date             DATE,
  last_updated_by           NUMBER(15),
  last_update_date          DATE,
  last_update_login         NUMBER(15)
)
TABLESPACE &&3;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DES GRANTS
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
GRANT ALL ON DKA_RB_LINES TO APPS WITH GRANT OPTION;

PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
PROMPT CREATION DU SYNONYME
PROMPT +++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
CONNECT APPS/&&1

DROP SYNONYM DKA_RB_LINES;

CREATE SYNONYM DKA_RB_LINES FOR DKA.DKA_RB_LINES;

SHOW ERRORS
EXIT;