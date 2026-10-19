--------------------------------------------------------------------------------
-- $Header: DKA_AUTO_ETAT.sql
--
-- FICHIER       : DKA_AUTO_ETAT.sql  V1.0 
--
-- DESCRIPTION   : Creation d'index et l'insertion dans la table DKA_AUTO_ETAT
--
-- PARAMETRES    : 
--             1 : Mot de passe/Utilisateur APPS                     Entrée
--             2 : Tablespace des index pour schéma DKA              Entrée
--
-- AUTEUR        :  Roshanak GHARAGOZLOU
--
-- DATE CREATION :  07/07/2016
--
--
---------------------------- M O D I F I C A T I O N S -------------------------
-- Version             : 
-- Date                :
-- Auteur              :
-- Nature              :
--------------------------------------------------------------------------------

DROP INDEX DKA_AUTO_ETAT_U1;
PROMPT ++++++++++++++++++++++++++++++++++++
PROMPT CREATION DE INDEX DKA_AUTO_ETAT_U1
PROMPT ++++++++++++++++++++++++++++++++++++
CONNECT APPS/&&1
CREATE INDEX DKA_AUTO_ETAT_U1 ON DKA.DKA_AUTO_ETAT
(
       PROGRAM_SHORT_NAME
)
TABLESPACE &&2;

Truncate table DKA.DKA_AUTO_ETAT; 
PROMPT ++++++++++++++++++++++++
PROMPT ALIMENTATION DE LA TABLE
PROMPT ++++++++++++++++++++++++
INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AMOR_FISC',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AXXGRACCA',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AXXGRBALCA',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AXXGRBALSA',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AXXGRDJBL',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AXXGRSLRCA',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_AXXGRSLRSA',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_GLYRLBGE',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_MOUVT_ACTIF_2054AB',
       -1,
       SYSDATE
);

INSERT INTO DKA_AUTO_ETAT 
(
       PROGRAM_SHORT_NAME,
       CREATED_BY,
       CREATION_DATE
)
VALUES
(
       'DKA_SITU_IMMO_DETAIL',
       -1,
       SYSDATE
);

EXIT;

