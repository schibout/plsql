CREATE OR REPLACE PACKAGE BODY DKA_FUSION_PA_PKG AS
------------------------------------------------------------------------------------
-- $Id: DKA_FUSION_PA_PKG.pkb
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_FUSION_PA_PKG.pkb
-- DESCRIPTION       : DKA_FUSION_PA_PKG package créé pour la fusion PA
---
--- AUTEUR           : F.Siham (Capgemini)
--- DATE DE CREATION : 15/07/2019
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 13/08/2019 NBO Correction suite au retour de mail de TGOMES
------------------------------------------------------------------------------------

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

    VG_NBLIGNES_OSF1       NUMBER;
    VG_NBLIGNES_PSF1       NUMBER;
    VG_NBLIGNES_TSF1       NUMBER;
    VG_NBLIGNES_OSF        NUMBER;
    VG_NBLIGNES_PSF        NUMBER;
    VG_NBLIGNES_TSF        NUMBER;
    VG_NBLIGNES_OEO1       NUMBER := 0;
    VG_NBLIGNES_OEP1       NUMBER := 0;
    VG_NBLIGNES_OET1       NUMBER := 0;
    VG_NBLIGNES_TSF1A1     NUMBER := 0;
    VG_NBLIGNES_PSF1A1     NUMBER := 0;
    VG_NBLIGNES_OSF1A1     NUMBER := 0;
    VG_NBLIGNES_OEO        NUMBER := 0;
    VG_NBLIGNES_OEP        NUMBER := 0;
    VG_NBLIGNES_OET        NUMBER := 0;
	VG_NBLIGNES_OEPR        NUMBER := 0;
    VG_NBLIGNES_OETR        NUMBER := 0;
    VG_NBLIGNES_TSFA       NUMBER := 0;
    VG_NBLIGNES_PSFA       NUMBER := 0;
    VG_NBLIGNES_OSFA       NUMBER := 0;
    VG_NOM_TABLE1_T1       VARCHAR2(60);
    VG_NOM_TABLE1_T2       VARCHAR2(60);
    VG_NOM_TABLE2_T1       VARCHAR2(60);
    VG_NOM_TABLE3_T1       VARCHAR2(60);
    VG_NB_ERROR1_T1        NUMBER := 0;
    VG_NB_ERROR2_T1        NUMBER := 0;
    VG_NB_ERROR3_T1        NUMBER := 0;
    VG_NOM_TABLE1_T7       VARCHAR2(60);
    VG_NOM_TABLE2_T7       VARCHAR2(60);
    VG_NOM_TABLE3_T7       VARCHAR2(60);
    VG_NB_ERROR1_T7        NUMBER := 0;
    VG_NB_ERROR2_T7        NUMBER := 0;
    VG_NB_ERROR3_T7        NUMBER := 0;
    VG_TACHES_FERMEES      NUMBER := 0;
    VG_PROJETS_FERMES      NUMBER := 0;
    VG_RETCODE             NUMBER;
    VG_ERRBUF              VARCHAR2(800) := '';
    VG_PROJETS             VARCHAR2(800) := '';
    VG_NBLIGNES_MODIFIES   NUMBER;
    VG_NB_ERROR_PROJET     NUMBER;
    VG_NB_ERROR_TACHE      NUMBER;
    VG_NBLIGNES_PROJET     NUMBER;
    VG_PROJETS_INSERE      NUMBER;
    VG_NB_ERROR1           NUMBER := 0;
    VG_ERROR_LISTS         VARCHAR2(1000) := '';
    VG_DATE_MAJ            VARCHAR2(1000) := '';
    VG_NB_LIGNES_INSERE    NUMBER := 0;
    VG_NB_LIGNES_PAR_PRJ   NUMBER := 0;
    VG_LIGNES_MODIFIES     VARCHAR2(1000);
    VG_NB_TACHES_MODIFIE   NUMBER := 0;
    VG_NOM_TABLE_PEC       VARCHAR2(60);
    CURSOR VG_CUR_PROJETS (
        V_CODE_UO_ABSORBE      NUMBER,
        V_CODE_UO_ABSORBANTE   NUMBER,
        V_TRANSCODIFICATION    VARCHAR2
    ) IS SELECT DISTINCT
             PA.SEGMENT1
         FROM
             PA.PA_COST_DIST_OVERRIDES PCDTO,
             PA_PROJECTS_ALL PA
         WHERE
             PA.PROJECT_ID = PCDTO.PROJECT_ID
             AND ( ( PA.ORG_ID = V_CODE_UO_ABSORBE
                     AND PCDTO.OVERRIDE_TO_ORGANIZATION_ID = V_CODE_UO_ABSORBANTE
                     AND PCDTO.END_DATE_ACTIVE IS NOT NULL
                     AND V_TRANSCODIFICATION = 'N' )
                   OR ( PA.ORG_ID IN (
                 SELECT
                     HROU.ORGANIZATION_ID
                 FROM
                     HR_ORGANIZATION_UNITS HROU,
                     DKA_STRANSCO_LINES DSTL,
                     DKA_STRANSCO_HEADERS DSTH
                 WHERE
                     DSTL.SET_ID = DSTH.SET_ID
                     AND HROU.NAME LIKE '%' || DSTL.PARAM1_VALUE
                     AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                     AND V_TRANSCODIFICATION = 'Y'
                     AND PCDTO.END_DATE_ACTIVE IS NOT NULL
             ) ) );
	--+++++++++++++++++++++++++++++++++
	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT  ==>:  DKA : Fusion PA - Etape 01 : Sauvegarde et purge des tables
 --                    d'interface des projets
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_SAUVEGARDE_ET01
  --  Description   :  procédure pour la sauvegarde et la purge des tables de sauvegarde
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_SAUVEGARDE_ET01 IS
        V_DATE_JOUR        VARCHAR2(20);
        VG_NBLIGNES_TMP1   NUMBER;
        VG_NBLIGNES_TMP2   NUMBER;
        VG_NBLIGNES_TMP3   NUMBER;
        l_step VARCHAR2(100);
    BEGIN
        SELECT
            TO_CHAR(SYSDATE,'DDMMYYHHMMSS')
        INTO V_DATE_JOUR
        FROM
            DUAL;
          ---calcul du nombre de lignes dans la table  DKA_EAI_ORG_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OSF1
        FROM
            DKA_EAI_ORG_SAUV_FUSION;
  ---calcul du nombre de lignes dans la table  DKA_EAI_PROJET_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_PSF1
        FROM
            DKA_EAI_PROJET_SAUV_FUSION;
 ---calcul du nombre de lignes dans la table  DKA_EAI_TACHE_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_TSF1
        FROM
            DKA_EAI_TACHE_SAUV_FUSION;

 ---création des tables de sauvegardes horodatées :
        l_step := 'TABLE1';
        IF NVL(VG_NBLIGNES_OSF1,0) != 0 THEN
  ---création de table 1 :
            EXECUTE IMMEDIATE 'create table DKA.DKAEAIORGSAUVFUS_'
                              || V_DATE_JOUR
                              || ' as
		        select * from DKA_EAI_ORG_SAUV_FUSION';
            VG_NOM_TABLE1_T1   := 'DKA.DKAEAIORGSAUVFUS_' || V_DATE_JOUR;
       -- calcul du nombre de lignes dans la table 1 horodatée ;
            EXECUTE IMMEDIATE 'select count(*) from  ' || VG_NOM_TABLE1_T1
            INTO VG_NBLIGNES_TMP1;
        END IF;

        l_step := 'TABLE2';
        IF NVL(VG_NBLIGNES_PSF1,0) > 0 THEN
          ---création de table 2 :
            EXECUTE IMMEDIATE 'create table DKA.DKAEAIPROSAUVFUS_'
                              || V_DATE_JOUR
                              || ' as
		        select * from DKA_EAI_PROJET_SAUV_FUSION';
            VG_NOM_TABLE2_T1   := 'DKA.DKAEAIPROSAUVFUS_' || V_DATE_JOUR;

         -- calcul du nombre de lignes dans la table 2 horodatée ;
            EXECUTE IMMEDIATE 'select count(*) from  ' || VG_NOM_TABLE2_T1
            INTO VG_NBLIGNES_TMP2;
        END IF;

        l_step := 'TABLE3';
        IF NVL(VG_NBLIGNES_TSF1,0) > 0 THEN
          ---création de la  tables 3 :
            EXECUTE IMMEDIATE 'create table DKA.DKAEAITACSAUVFUS_'
                              || V_DATE_JOUR
                              || ' as
		        select * from DKA_EAI_TACHE_SAUV_FUSION';
            VG_NOM_TABLE3_T1   := 'DKA.DKAEAITACSAUVFUS_' || V_DATE_JOUR;
          -- calcul du nombre de lignes dans la table 3 horodatée ;
            EXECUTE IMMEDIATE 'select count(*) from  ' || VG_NOM_TABLE3_T1
            INTO VG_NBLIGNES_TMP3;
        END IF;

        COMMIT;
		--purge des tables de sauvegadre avant restauration des tables d'interfaces.
        --IF VG_NBLIGNES_TMP1 = VG_NBLIGNES_OSF1 THEN
            DELETE FROM DKA_EAI_ORG_SAUV_FUSION;

            --COMMIT;
        --END IF;
        --IF VG_NBLIGNES_TMP2 = VG_NBLIGNES_PSF1 THEN
            DELETE FROM DKA_EAI_PROJET_SAUV_FUSION;

            --COMMIT;
        --END IF;
        --IF VG_NBLIGNES_TMP3 = VG_NBLIGNES_TSF1 THEN
            DELETE FROM DKA_EAI_TACHE_SAUV_FUSION;

            COMMIT;
        --END IF;
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure SAUV_TABLE_SAUVEGARDE_ET01 : ' || l_step
                                             || CHR(10)
                                             || SQLERRM);
    END SAUV_TABLE_SAUVEGARDE_ET01;

------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_INTERF_ET01
  --  Description   :  procédure pour la sauvegarde et la purge des tables d'interfaces
  --
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_INTERF_ET01 IS
    BEGIN

    ---calcul de nombre de lignes deans les tables de'interface   avant sauvegarde des tables
        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OEO1
        FROM
            DKA_EAI_ORGANISATION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OEP1
        FROM
            DKA_EAI_PROJET;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OET1
        FROM
            DKA_EAI_TACHE;

        BEGIN
            INSERT INTO DKA_EAI_ORG_SAUV_FUSION
                SELECT
                    *
                FROM
                    DKA_EAI_ORGANISATION;

        EXCEPTION
            WHEN OTHERS THEN
                VG_NB_ERROR1_T1   := VG_NB_ERROR1_T1 + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'la sauvegarde de la table DKA_EAI_ORGANISATION n''a pas pu être effectuée'
                                                 || CHR(10)
                                                 || SQLERRM);

        END;

        BEGIN
            INSERT INTO DKA_EAI_PROJET_SAUV_FUSION
                SELECT
                    *
                FROM
                    DKA_EAI_PROJET;

        EXCEPTION
            WHEN OTHERS THEN
                VG_NB_ERROR2_T1   := VG_NB_ERROR2_T1 + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'la sauvegarde de la table DKA_EAI_PROJET n''a pas pu être effectuée'
                                                 || CHR(10)
                                                 || SQLERRM);

        END;

        BEGIN
            INSERT INTO DKA_EAI_TACHE_SAUV_FUSION
                SELECT
                    *
                FROM
                    DKA_EAI_TACHE;

        EXCEPTION
            WHEN OTHERS THEN
                VG_NB_ERROR3_T1   := VG_NB_ERROR3_T1 + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'la sauvegarde de la table DKA_EAI_TACHE n''a pas pu être effectuée'
                                                 || CHR(10)
                                                 || SQLERRM);

        END;

        COMMIT;

           ---calcul de nombre de lignes dans les tables de sauvegarde
        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OSF1A1
        FROM
            DKA_EAI_ORG_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_PSF1A1
        FROM
            DKA_EAI_PROJET_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_TSF1A1
        FROM
            DKA_EAI_TACHE_SAUV_FUSION;

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure SAUV_TABLE_INTERF_ET01'
                                             || CHR(10)
                                             || SQLERRM);
    END SAUV_TABLE_INTERF_ET01;

  ------------------------------------------------------------------------------------
  --  Nom           : BILAN_ET01
  --  Description   : bilan du traitement DKA : Fusion PA - Etape 01 : Sauvegarde et purge des tables
 --                    d'interface des projets
  --
  ------------------------------------------------------------------------------------

    PROCEDURE BILAN_ET01 IS
        V_NBLIGNES_ORGI_SUP   NUMBER := 0;
        V_NBLIGNES_PRI_SUP    NUMBER := 0;
        V_NBLIGNES_TCI_SUP    NUMBER := 0;
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'                  Bilan du traitement                        ' || CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table d''interface DKA_EAI_ORGANISATION avant sauvegarde est : '
        || NVL(VG_NBLIGNES_OEO1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table d''interface DKA_EAI_PROJET avant sauvegarde est : '

        || NVL(VG_NBLIGNES_OEP1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table d''interface DKA_EAI_TACHE avant sauvegarde est : '

        || NVL(VG_NBLIGNES_OET1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_ORG_SAUV_FUSION avant sauvegarde est : '

        || NVL(VG_NBLIGNES_OSF1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_PROJET_SAUV_FUSION avant sauvegarde est : '

        || NVL(VG_NBLIGNES_PSF1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_TACHE_SAUV_FUSION avant sauvegarde est : '

        || NVL(VG_NBLIGNES_TSF1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_ORG_SAUV_FUSION après sauvegarde est : '
        || NVL(VG_NBLIGNES_OSF1A1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_PROJET_SAUV_FUSION après sauvegarde est : '

        || NVL(VG_NBLIGNES_PSF1A1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_TACHE_SAUV_FUSION après sauvegarde est : '

        || NVL(VG_NBLIGNES_TSF1A1,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        IF NVL(VG_NBLIGNES_OSF1,0) != 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'les éléments de la table DKA_EAI_ORG_SAUV_FUSION  ont été sauvegardés dans la table '
            || VG_NOM_TABLE1_T1);
        END IF;

        IF NVL(VG_NBLIGNES_PSF1,0) > 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'les éléments de la table DKA_EAI_PROJET_SAUV_FUSION ont été sauvegardés dans la table '
            || VG_NOM_TABLE2_T1);
        END IF;

        IF NVL(VG_NBLIGNES_TSF1,0) > 0 THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'les éléments de la table DKA_EAI_TACHE_SAUV_FUSION ont été sauvegardés dans la table '
            || VG_NOM_TABLE3_T1);
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
			---purge des tables d'interfaces  après sauvegarde
        IF VG_NB_ERROR1_T1 = 0 AND NVL(VG_NBLIGNES_OSF1A1,0) = NVL(VG_NBLIGNES_OEO1,0) THEN
            DELETE FROM DKA_EAI_ORGANISATION;

            V_NBLIGNES_ORGI_SUP   := V_NBLIGNES_ORGI_SUP + SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sauvegarde de la table DKA_EAI_ORGANISATION effectuée');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments supprimés depuis la table d''interface DKA_EAI_ORGANISATION '
            || NVL(V_NBLIGNES_ORGI_SUP,0) );

        END IF;

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        IF VG_NB_ERROR2_T1 = 0 AND NVL(VG_NBLIGNES_PSF1A1,0) = NVL(VG_NBLIGNES_OEP1,0) THEN
            DELETE FROM DKA_EAI_PROJET;

            V_NBLIGNES_PRI_SUP   := V_NBLIGNES_PRI_SUP + SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sauvegarde de la table DKA_EAI_PROJET effectuée');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments supprimés depuis la table d''interface DKA_EAI_PROJET ' || NVL
            (V_NBLIGNES_PRI_SUP,0) );

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        END IF;

        IF VG_NB_ERROR3_T1 = 0 AND NVL(VG_NBLIGNES_TSF1A1,0) = NVL(VG_NBLIGNES_OET1,0) THEN
            DELETE FROM DKA_EAI_TACHE;

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Sauvegarde de la table DKA_EAI_TACHE effectuée');
            V_NBLIGNES_TCI_SUP   := V_NBLIGNES_TCI_SUP + SQL%ROWCOUNT;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments supprimés depuis la table d''interface DKA_EAI_TACHE ' || NVL
            (V_NBLIGNES_TCI_SUP,0) );

        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure BILAN_ET01'
                                             || CHR(10)
                                             || SQLERRM);
    END BILAN_ET01;

  ------------------------------------------------------------------------------------
  --  Nom           : MAIN_SAUV_PURGE
  --  Description   : point d'entrée du traitement DKA : Fusion PA - Etape 01 : Sauvegarde et purge des tables
 --                    d'interface des projets
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_SAUV_PURGE (
        PV_ERRBUF    OUT NOCOPY VARCHAR2,
        PN_RETCODE   OUT NOCOPY NUMBER
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure SAUV_TABLE_SAUVEGARDE_ET01');

        SAUV_TABLE_SAUVEGARDE_ET01;
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure SAUV_TABLE_INTERF_ET01');

        SAUV_TABLE_INTERF_ET01;
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');

        BILAN_ET01;
    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_SAUV_PURGE'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_SAUV_PURGE;
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> traitement  :  « DKA : Fusion PA ¿ Etape 02: Suffixage des Projets et Taches
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  --  Nom           : fusion_pa_suffix_z_trans
  --  Description   :  procédure de mise à jour des noms et numéros des projets et tâches
  --
  ------------------------------------------------------------------------------------

    PROCEDURE FUSION_PA_SUFFIX_Z_TRANS (
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS

        P_CPT_TASK      NUMBER := 0;
        P_CPT_PROJECT   NUMBER := 0;
        L_NBLIGNES      NUMBER := 0;
        CURSOR CUR_UO_ABSOB (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBE_ID NUMBER
        ) IS SELECT
                 HROU.NAME,
                 HROU.ORGANIZATION_ID,
                 DSTL.RETURN_VALUE
             FROM
                 HR_ORGANIZATION_UNITS HROU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HROU.NAME = DSTL.PARAM1_VALUE
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                 AND ( P_TRANSCODIFICATION = 'Y'
                       OR ( P_TRANSCODIFICATION = 'N'
                            AND HROU.ORGANIZATION_ID = P_UO_ABSORBE_ID ) );

        CURSOR CUR_PROJECTS (
            P_UO_ABSORBE_ID NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 A.*
             FROM
                 PA_PROJECTS_ALL A
             WHERE
                 A.TEMPLATE_FLAG = 'N'
                 AND A.PROJECT_TYPE != 'REFAC'
                 AND A.ORG_ID = P_UO_ABSORBE_ID
                 AND DESCRIPTION NOT LIKE '%'
                                          || P_UO_ABSORBANTE
                                          || '%'
        FOR UPDATE OF A.SEGMENT1,
                      A.NAME;

        CURSOR CUR_TASKS (
            P_PROJECT_ID NUMBER
        ) IS SELECT
                 *
             FROM
                 PA_TASKS
             WHERE
                 PROJECT_ID = P_PROJECT_ID
        FOR UPDATE OF TASK_NAME,
                      TASK_NUMBER;

    BEGIN
        IF P_MODE_SIMULATION = 'Y' THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'la liste des projets et tâches par UO absorbée à suffixer et à mettre à jour par le traitement '
            || CHR(10) );
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'UO absorbeé : '
                                                    || UO.NAME
                                                    || CHR(10) );

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Modèle;Projet;Numéro de la tâche;Nom de la tâche' || CHR(10) );
                FOR REC IN CUR_PROJECTS(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                    L_NBLIGNES   := L_NBLIGNES + 1;
                    FOR TASK IN CUR_TASKS(REC.PROJECT_ID) LOOP
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,REC.NAME
                                                            || ';'
                                                            || REC.SEGMENT1
                                                            || ';'
                                                            || TASK.TASK_NUMBER
                                                            || ';'
                                                            || TASK.TASK_NAME);
                    END LOOP;

                END LOOP;

                IF L_NBLIGNES = 0 THEN
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'les projets de cette UO est déjà suffixés' || CHR(10) );
                END IF;

            END LOOP;

        ELSIF P_MODE_SIMULATION = 'N' THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Listes des projets et des tâches qui ont été mis à jour par le traitement ' || CHR
            (10) );
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'UO absorbeé : '
                                                    || UO.NAME
                                                    || CHR(10) );

                -- NBO 13/08/2019 Correction suite au retour de mail de TGOMES
                --FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Mise à jour : ' || CHR(10) );

                FOR REC IN CUR_PROJECTS(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                    /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Mise à jour du projet : '
                                                        || REC.SEGMENT1 */


                    FOR TASK IN CUR_TASKS(REC.PROJECT_ID) LOOP
                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,REC.SEGMENT1 || ' ; ' || TASK.TASK_NUMBER);
                        UPDATE PA_TASKS
                        SET
                            TASK_NUMBER = SUBSTR(TASK_NUMBER,1,24)
                                          || 'Z',
                            TASK_NAME = SUBSTR(TASK_NAME,1,19)
                                        || 'Z',
                            PM_TASK_REFERENCE = SUBSTR(TASK_NUMBER,1,24)
                                                || 'Z',
                            LAST_UPDATE_DATE = SYSDATE,
                            LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                        WHERE
                            CURRENT OF CUR_TASKS;

                        P_CPT_TASK   := P_CPT_TASK + SQL%ROWCOUNT;
                    END LOOP;

                    UPDATE PA_PROJECTS_ALL
                    SET
                        SEGMENT1 = SEGMENT1 || 'Z',
                        NAME = SUBSTR(SUBSTR(NAME,INSTR(NAME,SEGMENT1),LENGTH(SEGMENT1) )
                                        || 'Z'
                                        || SUBSTR(NAME,LENGTH(SEGMENT1) + 1),1,30),
                        PM_PROJECT_REFERENCE = PM_PROJECT_REFERENCE || 'Z',
                        LONG_NAME = SUBSTR(LONG_NAME,INSTR(LONG_NAME,SEGMENT1),LENGTH(SEGMENT1) )
                                    || 'Z'
                                    || SUBSTR(LONG_NAME,LENGTH(SEGMENT1) + 1),
                        DESCRIPTION = UO.RETURN_VALUE
                                      || '_'
                                      || DESCRIPTION,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                    WHERE
                        CURRENT OF CUR_PROJECTS;

                    P_CPT_PROJECT   := P_CPT_PROJECT + SQL%ROWCOUNT;
                END LOOP;

            --    END LOOP;

                IF P_CPT_PROJECT = 0 THEN
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'les projets de cette UO est déjà suffixés' || CHR(10) );
                END IF;

            END LOOP;

            COMMIT;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'le nombre  des projets et tâches modifiés par le traitement' || CHR(10) );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de projets mis à jour dans l''unité absorbée : ' || P_CPT_PROJECT);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de tâches mises à jour dans l''unité absorbée : ' || P_CPT_TASK);
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure FUSION_PA_SUFFIX_Z_TRANS'
                                             || CHR(10)
                                             || SQLERRM);
    END FUSION_PA_SUFFIX_Z_TRANS;
  ------------------------------------------------------------------------------------
  --  Nom           : main_suffix_projet
  --  Description   : point d'entrée du traitement  DKA : Fusion PA ¿ Etape 02: Suffixage des Projets et Taches
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_SUFFIX_PROJET (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FUSION_PA_SUFFIX_Z_TRANS(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE,P_MODE_SIMULATION);
    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure main_suffix_projet'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_SUFFIX_PROJET;

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA - Etape 03: Récupération de l''historique
--                                    de rattachement des projets aux centres finances
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : FERMETURE_PROJET_TACHE
   --  Description   :  procédure pour mise à jour des projets et des tâches
  --
  ------------------------------------------------------------------------------------

    PROCEDURE RATTACHEMENT_PROJET_FINANCE (
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS

        VG_NB_PROJET_AMODIF   NUMBER;
        V_PROJECT_ID          NUMBER;
        L_EXIST_LHIST         VARCHAR2(1);
        L_ORGANIZATION        VARCHAR2(100);
        l_ORG_NAME_OLD        VARCHAR2(100);

        CURSOR CUR_PROJECTS (
            P_TRANSCODIFICATION VARCHAR2,
            P_CODE_UO_ABSORBE NUMBER
        ) IS SELECT
                 PA.PROJECT_ID,
                 PA.SEGMENT1
             FROM
                 PA_PROJECTS_ALL PA,
                 PA.PA_COST_DIST_OVERRIDES PCDTO
             WHERE
                 PA.PROJECT_ID = PCDTO.PROJECT_ID
                 AND SUBSTR(PA.SEGMENT1,11,1) = 'Z'
        --       AND  pa.segment1 like 'FA0060247M%'
                 AND ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU,
                         DKA_STRANSCO_LINES DSTL,
                         DKA_STRANSCO_HEADERS DSTH
                     WHERE
                         DSTL.SET_ID = DSTH.SET_ID
                         AND HROU.NAME = DSTL.PARAM1_VALUE
                         AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                         AND DSTL.ENABLE = 'Y'
                         AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                         AND ( P_TRANSCODIFICATION = 'Y'
                               OR ( P_TRANSCODIFICATION = 'N'
                                    AND HROU.ORGANIZATION_ID = P_CODE_UO_ABSORBE ) )
                 )
             GROUP BY
                 PA.PROJECT_ID,
                 PA.SEGMENT1
             HAVING
                 COUNT(PCDTO.OVERRIDE_TO_ORGANIZATION_ID) > 1;

        CURSOR CUR_PROJECTS_DT (
            P_PROJECT_ID NUMBER
        ) IS SELECT
                 PA.PROJECT_ID,
                 PA.SEGMENT1,
                 OVERRIDE_TO_ORGANIZATION_ID,
                 PCDTO.START_DATE_ACTIVE,
                 PCDTO.END_DATE_ACTIVE,
                 PCDTO.OVERRIDE_FROM_ORGANIZATION_ID
             FROM
                 PA_PROJECTS_ALL PA,
                 PA.PA_COST_DIST_OVERRIDES PCDTO
             WHERE
                 PA.PROJECT_ID = PCDTO.PROJECT_ID
                 AND PA.PROJECT_ID = P_PROJECT_ID
                 AND SUBSTR(PA.SEGMENT1,11,1) = 'Z'
             --  AND  pa.segment1 like 'FA0060247M%'
                 AND ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU,
                         DKA_STRANSCO_LINES DSTL,
                         DKA_STRANSCO_HEADERS DSTH
                     WHERE
                         DSTL.SET_ID = DSTH.SET_ID
                         AND HROU.NAME = DSTL.PARAM1_VALUE
                         AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                         AND DSTL.ENABLE = 'Y'
                         AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                         AND ( P_TRANSCODIFICATION = 'Y'
                               OR ( P_TRANSCODIFICATION = 'N'
                                    AND HROU.ORGANIZATION_ID = P_CODE_UO_ABSORBE ) )
                 );

        CURSOR CUR_NB_LIGNE_PROJ (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBEE NUMBER
        ) IS SELECT
                 PA.PROJECT_ID,
                 PA.SEGMENT1,
                 COUNT(PCDTO.COST_DISTRIBUTION_OVERRIDE_ID) NB_LIGNES_HIST
             FROM
                 PA_PROJECTS_ALL PA,
                 PA.PA_COST_DIST_OVERRIDES PCDTO
             WHERE
                 PA.PROJECT_ID = PCDTO.PROJECT_ID
                 AND SUBSTR(PA.SEGMENT1,11,1) = 'Z'
           --    AND  pa.segment1 like 'FA0060247M%'
                 AND ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU,
                         DKA_STRANSCO_LINES DSTL,
                         DKA_STRANSCO_HEADERS DSTH
                     WHERE
                         DSTL.SET_ID = DSTH.SET_ID
                         AND HROU.NAME = DSTL.PARAM1_VALUE
                         AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                         AND DSTL.ENABLE = 'Y'
                         AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                         AND ( P_TRANSCODIFICATION = 'Y'
                               OR ( P_TRANSCODIFICATION = 'N'
                                    AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )
                 )
             GROUP BY
                 PA.PROJECT_ID,
                 PA.SEGMENT1
             HAVING
                 COUNT(PCDTO.OVERRIDE_TO_ORGANIZATION_ID) > 1;

    BEGIN


        /*IF P_MODE_SIMULATION = 'Y' THEN  */

	---calcul le nombre de projet à modifier
            SELECT COUNT(1)
            INTO VG_NB_PROJET_AMODIF
            FROM (
             SELECT
                PA.PROJECT_ID, COUNT(PCDTO.OVERRIDE_TO_ORGANIZATION_ID)

            FROM
                PA_PROJECTS_ALL PA,
                PA.PA_COST_DIST_OVERRIDES PCDTO
            WHERE
                PA.PROJECT_ID = PCDTO.PROJECT_ID
                AND SUBSTR(PA.SEGMENT1,11,1) = 'Z'
             --  AND  pa.segment1 like 'FA0060247M%'
                AND ORG_ID IN (
                    SELECT
                        HROU.ORGANIZATION_ID
                    FROM
                        HR_ORGANIZATION_UNITS HROU,
                        DKA_STRANSCO_LINES DSTL,
                        DKA_STRANSCO_HEADERS DSTH
                    WHERE
                        DSTL.SET_ID = DSTH.SET_ID
                        AND HROU.NAME = DSTL.PARAM1_VALUE
                        AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                         --AND :P_TRANSCODIFICATION = 'Y'
                        AND DSTL.ENABLE = 'Y'
                        AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                        AND ( P_TRANSCODIFICATION = 'Y'
                              OR ( P_TRANSCODIFICATION = 'N'
                                   AND HROU.ORGANIZATION_ID = P_CODE_UO_ABSORBE ) )
                ) HAVING
                 COUNT(PCDTO.OVERRIDE_TO_ORGANIZATION_ID) > 1
                 GROUP BY PA.PROJECT_ID);

			----listes des projets à modifier
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre de projet ayant un historique à reprendre : ' || VG_NB_PROJET_AMODIF);

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Liste des projets ayant un historique à reprendre : ');
            FOR IC IN CUR_PROJECTS(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
              FND_FILE.PUT_LINE(FND_FILE.OUTPUT,IC.SEGMENT1);
            END LOOP;

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de lignes d''historique à reprendre pour chaque projets');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Projet ; Nombre de lignes à reprendre ' || CHR(10) );
            FOR IC1 IN CUR_NB_LIGNE_PROJ(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,IC1.SEGMENT1
                                                    || ' ; '
                                                    || IC1.NB_LIGNES_HIST);
            END LOOP;

        /*ELS*/ IF P_MODE_SIMULATION = 'N' THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' ');
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Détail des modifications effectuées pour les dates de validité sur les lignes d''historique :');
            FOR IC IN CUR_PROJECTS(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                VG_NB_LIGNES_PAR_PRJ   := 0;
                BEGIN
                    SELECT DISTINCT
                        PROJECT_ID
                    INTO V_PROJECT_ID
                    FROM
                        PA_PROJECTS_ALL
                    WHERE
                        SEGMENT1 = SUBSTR(IC.SEGMENT1,1,10);

                    FOR OG IN CUR_PROJECTS_DT(IC.PROJECT_ID) LOOP
                        BEGIN
                            SELECT
                                'Y'
                            INTO L_EXIST_LHIST
                            FROM
                                PA.PA_COST_DIST_OVERRIDES
                            WHERE
                                PROJECT_ID = V_PROJECT_ID
                                AND OVERRIDE_TO_ORGANIZATION_ID = OG.OVERRIDE_TO_ORGANIZATION_ID;

                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                L_EXIST_LHIST   := 'N';
                        END;

                        IF L_EXIST_LHIST = 'N' THEN
                            IF OG.END_DATE_ACTIVE IS NULL THEN

                               --	Le nombre et le détail des modifications effectuées pour les dates de validité sur les
                               -- lignes d¿historique les plus récentes  en mode simulation : N
                                SELECT
                                HOU.NAME
                                INTO l_ORG_NAME_OLD
                                FROM
                                    HR_ORGANIZATION_UNITS HOU, PA_PROJECTS_ALL PPA
                                WHERE
                                    PROJECT_ID = V_PROJECT_ID
                                AND HOU.organization_id = CARRYING_OUT_ORGANIZATION_ID;

                                BEGIN
                                    UPDATE PA_PROJECTS_ALL
                                    SET
                                        CARRYING_OUT_ORGANIZATION_ID = OG.OVERRIDE_TO_ORGANIZATION_ID,
                                        LAST_UPDATE_DATE = SYSDATE,
                                        LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                                    WHERE
                                        PROJECT_ID = V_PROJECT_ID;

                                    COMMIT;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur lors de la mise à jour du champ CARRYING_OUT_ORGANIZATION_ID'
                                                                         || CHR(10)
                                                                         || SQLERRM);
                                END;

                                BEGIN
                                    UPDATE PA_TASKS
                                    SET
                                        CARRYING_OUT_ORGANIZATION_ID = OG.OVERRIDE_TO_ORGANIZATION_ID,
                                        LAST_UPDATE_DATE = SYSDATE,
                                        LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                                    WHERE
                                        PROJECT_ID = V_PROJECT_ID;

                                    COMMIT;
                                EXCEPTION
                                    WHEN OTHERS THEN
                                        FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur lors de la mise à jour du champ CARRYING_OUT_ORGANIZATION_ID'
                                                                         || CHR(10)
                                                                         || SQLERRM);
                                END;

                            END IF;

                            SELECT
                                NAME
                            INTO L_ORGANIZATION
                            FROM
                                HR_ORGANIZATION_UNITS
                            WHERE
                                ORGANIZATION_ID = OG.OVERRIDE_TO_ORGANIZATION_ID;

                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,OG.SEGMENT1||'|'||l_ORG_NAME_OLD||'|'||L_ORGANIZATION);


                -----insertion des nouvelles lignes dans la table PA_COST_DIST_OVERRIDES

                            FND_FILE.PUT_LINE(FND_FILE.LOG,'insertion dans la table PA.PA_COST_DIST_OVERRIDES');
                            BEGIN
                                INSERT INTO PA.PA_COST_DIST_OVERRIDES (
                                    COST_DISTRIBUTION_OVERRIDE_ID,
                                    PROJECT_ID,
                                    OVERRIDE_TO_ORGANIZATION_ID,
                                    START_DATE_ACTIVE,
                                    END_DATE_ACTIVE,
                                    OVERRIDE_FROM_ORGANIZATION_ID,
                                    LAST_UPDATE_DATE,
                                    LAST_UPDATED_BY,
                                    CREATION_DATE,
                                    CREATED_BY,
                                    LAST_UPDATE_LOGIN
                                ) VALUES (
                                    PA_COST_DIST_OVERRIDES_S.NEXTVAL,
                                    V_PROJECT_ID,
                                    OG.OVERRIDE_TO_ORGANIZATION_ID,
                                    OG.START_DATE_ACTIVE,
                                    OG.END_DATE_ACTIVE,
                                    OG.OVERRIDE_FROM_ORGANIZATION_ID,
                                    SYSDATE,
                                    FND_GLOBAL.USER_ID,
                                    SYSDATE,
                                    FND_GLOBAL.USER_ID,
                                    FND_GLOBAL.LOGIN_ID
                                );

                                VG_NB_LIGNES_INSERE    := VG_NB_LIGNES_INSERE + 1;
                                VG_NB_LIGNES_PAR_PRJ   := VG_NB_LIGNES_PAR_PRJ + 1;
                                COMMIT;
                            EXCEPTION
                                WHEN OTHERS THEN
                                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur lors de l''insertion dans la table PA_COST_DIST_OVERRIDES'
                                                                     || CHR(10)
                                                                     || SQLERRM);
                            END;

                        END IF;

                        BEGIN
                            UPDATE PA.PA_COST_DIST_OVERRIDES
                            SET
                                END_DATE_ACTIVE = OG.END_DATE_ACTIVE,
                                LAST_UPDATE_DATE = SYSDATE,
                                LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                            WHERE
                                PROJECT_ID = V_PROJECT_ID
                                AND OVERRIDE_TO_ORGANIZATION_ID = OG.OVERRIDE_TO_ORGANIZATION_ID
                                AND OG.END_DATE_ACTIVE IS NOT NULL;

                            COMMIT;
                        EXCEPTION
                            WHEN NO_DATA_FOUND THEN
                                NULL;
                            WHEN OTHERS THEN
                                VG_NB_ERROR1     := VG_NB_ERROR1 + 1;
                                VG_ERROR_LISTS   := VG_ERROR_LISTS
                                                  || 'Erreur lors de la mise à jour de la date de fin de validité de l''orgnaisation '
                                                  || L_ORGANIZATION
                                                  || ' dans la table d''historique'
                                                  || CHR(10);

                        END;

                    END LOOP;

                    IF ( VG_NB_LIGNES_INSERE != 0 ) AND ( VG_NB_LIGNES_PAR_PRJ != 0 ) THEN
                        VG_NB_LIGNES_INSERE   := VG_NB_LIGNES_INSERE + 1;
                    END IF;

                END;

            END LOOP;
        END IF;
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure RATTACHEMENT_PROJET_FINANCE'
                                             || CHR(10)
                                             || SQLERRM);
    END RATTACHEMENT_PROJET_FINANCE;

  ------------------------------------------------------------------------------------
  --  Nom           : MAIN_REC_HIST
  --  Description   : point d'entrée du traitement DKA : Fusion PA - Etape 03: Récupération de l'historique de rattachement des projets aux centres finances
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_REC_HIST (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure RATTACHEMENT_PROJET_FINANCE');

        RATTACHEMENT_PROJET_FINANCE(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE,P_MODE_SIMULATION);
        IF P_MODE_SIMULATION = 'N' THEN
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bilan du traitement');
          --  FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_DATE_MAJ);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de lignes insérées ou modifiees dans la table PA_COST_DIST_OVERRIDES est :'
            || VG_NB_LIGNES_INSERE);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_ERROR_LISTS);
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'le nombre d''erreur lors de la modification de la date de validité est  : ' || VG_NB_ERROR1
            );
        END IF;

    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_REC_HIST'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_REC_HIST;




	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Etape 07 : Restauration des tables d''interface
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_SAUVEGARDE_ET07
  --  Description   :  procédure pour la sauvegarde des tables d'interfaces
  --
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_SAUVEGARDE_ET07 (
											P_TRANSCODIFICATION VARCHAR2,
											P_UO_ABSORBEE NUMBER
										) IS
        V_DATE_JOUR        VARCHAR2(20);
        VG_NBLIGNES_TMP1   NUMBER;
        VG_NBLIGNES_TMP2   NUMBER;
        VG_NBLIGNES_TMP3   NUMBER;
    BEGIN
        SELECT
            TO_CHAR(SYSDATE,'DDMMYYHHMMSS')
        INTO V_DATE_JOUR
        FROM
            DUAL;

        EXECUTE IMMEDIATE 'create table DKA.DKAEAIORGSAUVFUS_'
                          || V_DATE_JOUR
                          || ' as
		select * from DKA_EAI_ORG_SAUV_FUSION';
        VG_NOM_TABLE1_T7   := 'DKA.DKAEAIORGSAUVFUS_' || V_DATE_JOUR;
        EXECUTE IMMEDIATE 'select count(*) from  ' || VG_NOM_TABLE1_T7
        INTO VG_NBLIGNES_TMP1;
        EXECUTE IMMEDIATE 'create table DKA.DKAEAIPROSAUVFUS_'
                          || V_DATE_JOUR
                          || ' as
		select * from DKA.DKA_EAI_PROJET_SAUV_FUSION';
        VG_NOM_TABLE2_T7   := 'DKA.DKAEAIPROSAUVFUS_' || V_DATE_JOUR;
        EXECUTE IMMEDIATE 'select count(*) from  ' || VG_NOM_TABLE2_T7
        INTO VG_NBLIGNES_TMP2;
        EXECUTE IMMEDIATE 'create table DKA.DKAEAITACSAUVFUS_'
                          || V_DATE_JOUR
                          || ' as
		select * from DKA.DKA_EAI_TACHE_SAUV_FUSION';
        VG_NOM_TABLE3_T7   := 'DKA.DKAEAITACSAUVFUS_' || V_DATE_JOUR;
        EXECUTE IMMEDIATE 'select count(*) from  ' || VG_NOM_TABLE3_T7
        INTO VG_NBLIGNES_TMP3;
        COMMIT;

		----purge des tables de sauvgardes
        DELETE FROM DKA_EAI_ORG_SAUV_FUSION;

        --VG_NBLIGNES_OSF    := VG_NBLIGNES_OSF + SQL%ROWCOUNT;
		VG_NBLIGNES_OSF    := SQL%ROWCOUNT; -- SELO
        COMMIT;
        DELETE FROM DKA_EAI_PROJET_SAUV_FUSION;

        --VG_NBLIGNES_PSF    := VG_NBLIGNES_PSF + SQL%ROWCOUNT;
		VG_NBLIGNES_PSF    := SQL%ROWCOUNT; -- SELO
        COMMIT;
        DELETE FROM DKA_EAI_TACHE_SAUV_FUSION;


        -- VG_NBLIGNES_TSF    := VG_NBLIGNES_TSF + SQL%ROWCOUNT;
		VG_NBLIGNES_TSF    := SQL%ROWCOUNT; --SELO
        COMMIT;
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure SAUV_TABLE_SAUVEGARDE_ET07'
                                             || CHR(10)
                                             || SQLERRM);
    END SAUV_TABLE_SAUVEGARDE_ET07;
------------------------------------------------------------------------------------
  --  Nom           : SAUV_TABLE_INTERF_ET07
  --  Description   :  procédure pour la sauvegarde et la purge des tables d'interfaces
  --
  ------------------------------------------------------------------------------------

    PROCEDURE SAUV_TABLE_INTERF_ET07 (
        P_TRANSCODIFICATION VARCHAR2,
        P_UO_ABSORBEE NUMBER
    ) IS
    BEGIN

	    ---calcul de nombre de lignes dans les tables des sauvergarde avant purge  et restauration
        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OSFA
        FROM
            DKA_EAI_ORG_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_PSFA
        FROM
            DKA_EAI_PROJET_SAUV_FUSION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_TSFA
        FROM
            DKA_EAI_TACHE_SAUV_FUSION;

        -----Sauvegarde des tables d'interfaces

        BEGIN
            INSERT INTO DKA_EAI_ORGANISATION
                SELECT
                    *
                FROM
                    DKA_EAI_ORG_SAUV_FUSION;

			VG_NBLIGNES_OEO:=SQL%ROWCOUNT; -- SELO
        EXCEPTION
            WHEN OTHERS THEN
                VG_NB_ERROR1_T7   := VG_NB_ERROR1_T7 + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Problème de sauvegarde des données de la table DKA_EAI_ORG_SAUV_FUSION dans la table DKA_EAI_ORGANISATION'
                                                 || CHR(10)
                                                 || SQLERRM);

        END;

        BEGIN
            INSERT INTO DKA_EAI_PROJET
            SELECT
                  *
                FROM
                    DKA_EAI_PROJET_SAUV_FUSION SAV
                WHERE sav.PROJECT_CODE not in
                      (
                        SELECT sav2.PROJECT_CODE
                        FROM
                            HR_OPERATING_UNITS HROU,
                            DKA_STRANSCO_LINES DSTL,
                            DKA_STRANSCO_HEADERS DSTH,
                             DKA_EAI_PROJET_SAUV_FUSION SAV2
                        WHERE
                            DSTL.SET_ID = DSTH.SET_ID
                            AND HROU.NAME = DSTL.PARAM1_VALUE
                            AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                            AND DSTL.ENABLE = 'Y'
                            AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                            AND ( P_TRANSCODIFICATION = 'Y'
                                  OR ( P_TRANSCODIFICATION = 'N'
                                       AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )
                            AND SAV2.OPERATING_UNIT = HROU.NAME
                            AND SAV2.OA_STATUS = 'REJECT'
                    )
          ;

			VG_NBLIGNES_OEP:=SQL%ROWCOUNT; -- SELO

        EXCEPTION
            WHEN OTHERS THEN
                VG_NB_ERROR2_T7   := VG_NB_ERROR2_T7 + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Problème de sauvegarde des données de la table de la table DKA_EAI_PROJET_SAUV_FUSION dans la table DKA_EAI_PROJET'
                                                 || CHR(10)
                                                 || SQLERRM);

        END;


-- SELO
        BEGIN
                SELECT
                    count(*) into VG_NBLIGNES_OEPR
                FROM
                    DKA_EAI_PROJET_SAUV_FUSION SAV
                WHERE sav.PROJECT_CODE  in
                      (
                        SELECT sav2.PROJECT_CODE
                        FROM
                            HR_OPERATING_UNITS HROU,
                            DKA_STRANSCO_LINES DSTL,
                            DKA_STRANSCO_HEADERS DSTH,
                             DKA_EAI_PROJET_SAUV_FUSION SAV2
                        WHERE
                            DSTL.SET_ID = DSTH.SET_ID
                            AND HROU.NAME = DSTL.PARAM1_VALUE
                            AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                            AND DSTL.ENABLE = 'Y'
                            AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                            AND ( P_TRANSCODIFICATION = 'Y'
                                  OR ( P_TRANSCODIFICATION = 'N'
                                       AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )
                            AND SAV2.OPERATING_UNIT = HROU.NAME
                            AND SAV2.OA_STATUS = 'REJECT'
                    )
          ;

		--	VG_NBLIGNES_OEPR:=SQL%ROWCOUNT; -- SELO

        EXCEPTION
            WHEN OTHERS THEN
               null;

        END;


        BEGIN
            INSERT INTO DKA_EAI_TACHE
             SELECT *
              FROM dka_eai_tache_sauv_fusion sav 
             WHERE sav.rowid  not IN
                   (SELECT tache.rowid
                      FROM hr_operating_units         hrou,
                           dka_stransco_lines         dstl,
                           dka_stransco_headers       dsth,
                           pa_projects_all sav2,
                           dka_eai_tache_sauv_fusion  tache
                     WHERE dstl.set_id = dsth.set_id
                       AND hrou.name = dstl.param1_value
                       AND dsth.set_name LIKE
                           'FUSION_SOCIETE_VERS_SOCIETE'
                       AND dstl.enable = 'Y'
                       AND nvl(dstl.end_date, trunc(SYSDATE)) >=
                           trunc(SYSDATE)
                       AND ( P_TRANSCODIFICATION = 'Y'
                                  OR ( P_TRANSCODIFICATION = 'N'
                                       AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )
                       AND sav2.org_id = hrou.ORGANIZATION_ID
                       AND tache.oa_status != 'PROCESSED'
                       AND sav2.segment1 = tache.project_code || 'Z');
          

			VG_NBLIGNES_OET:=SQL%ROWCOUNT; -- SELO
        EXCEPTION
            WHEN OTHERS THEN
                VG_NB_ERROR3_T7   := VG_NB_ERROR3_T7 + 1;
                FND_FILE.PUT_LINE(FND_FILE.LOG,'Problème de sauvegarde des données de la table DKA_EAI_TACHE_SAUV_FUSION dans la table DKA_EAI_TACHE'
                                                 || CHR(10)
                                                 || SQLERRM);

        END;

        COMMIT;

-- SELO
        BEGIN
             select count(*) into VG_NBLIGNES_OETR
              FROM dka_eai_tache_sauv_fusion sav 
             WHERE sav.rowid   IN
                   (SELECT tache.rowid
                      FROM hr_operating_units         hrou,
                           dka_stransco_lines         dstl,
                           dka_stransco_headers       dsth,
                           pa_projects_all sav2,
                           dka_eai_tache_sauv_fusion  tache
                     WHERE dstl.set_id = dsth.set_id
                       AND hrou.name = dstl.param1_value
                       AND dsth.set_name LIKE
                           'FUSION_SOCIETE_VERS_SOCIETE'
                       AND dstl.enable = 'Y'
                       AND nvl(dstl.end_date, trunc(SYSDATE)) >=
                           trunc(SYSDATE)
                       AND ( P_TRANSCODIFICATION = 'Y'
                                  OR ( P_TRANSCODIFICATION = 'N'
                                       AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )
                       AND sav2.org_id = hrou.ORGANIZATION_ID
                       AND tache.oa_status != 'PROCESSED'
                       AND sav2.segment1 = tache.project_code || 'Z');
				  /* SELO */

	--		VG_NBLIGNES_OETR:=SQL%ROWCOUNT; -- SELO
        EXCEPTION
            WHEN OTHERS THEN
                null;

        END;

-- SELO
         ---calcul de nombre de lignes dans les tables d'interface  aprés  sauvegarde
    /*    SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OEO
        FROM
            DKA_EAI_ORGANISATION;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OEP
        FROM
            DKA_EAI_PROJET;

        SELECT
            COUNT(*)
        INTO VG_NBLIGNES_OET
        FROM
            DKA_EAI_TACHE;*/ -- SELO

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure SAUV_TABLE_INTERF_ET07'
                                             || CHR(10)
                                             || SQLERRM);
    END SAUV_TABLE_INTERF_ET07;

  ------------------------------------------------------------------------------------
  --  Nom           : BILAN_ET07
  --  Description   : bilan du traitement DKA : Fusion PA ¿ Etape 07 : Restauration des tables d''interface
  --
  ------------------------------------------------------------------------------------

    PROCEDURE BILAN_ET07 IS
        V_NBLIGNES_ORGI_SUP   NUMBER := 0;
        V_NBLIGNES_PRI_SUP    NUMBER := 0;
        V_NBLIGNES_TCI_SUP    NUMBER := 0;
    BEGIN


        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bilan du traitement' || CHR(10) );


        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_ORG_SAUV_FUSION est : '
        || NVL(VG_NBLIGNES_OSFA,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_PROJET_SAUV_FUSION est : '

        || NVL(VG_NBLIGNES_PSFA,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments présents dans la table de sauvegarde DKA_EAI_TACHE_SAUV_FUSION est : '

        || NVL(VG_NBLIGNES_TSFA,0) );

		FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Les éléments de la table DKA_EAI_ORG_SAUV_FUSION  ont été sauvegardés dans la table ' || VG_NOM_TABLE1_T7);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Les éléments de la table DKA_EAI_PROJET_SAUV_FUSION ont été sauvegardés dans la table '
        || VG_NOM_TABLE2_T7);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Les éléments de la table DKA_EAI_TACHE_SAUV_FUSION ont été sauvegardés dans la table '
        || VG_NOM_TABLE3_T7);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );


        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments inserés dans la table d''interface DKA_EAI_ORGANISATION est : '
        || NVL(VG_NBLIGNES_OEO,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments inserés dans la table d''interface DKA_EAI_PROJET est : '
        || NVL(VG_NBLIGNES_OEP,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments inserés dans la table d''interface DKA_EAI_TACHE est : '
        || NVL(VG_NBLIGNES_OET,0) );


        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments non inserés dans la table d''interface DKA_EAI_PROJET est : '
        || NVL(VG_NBLIGNES_OEPR,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments non inserés dans la table d''interface DKA_EAI_TACHE est : '
        || NVL(VG_NBLIGNES_OETR,0) );


        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments purgés dans la table de sauvegarde DKA_EAI_ORG_SAUV_FUSION est : '
        || NVL(VG_NBLIGNES_OSF,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments purgés dans la table de sauvegarde DKA_EAI_PROJET_SAUV_FUSION est : '

        || NVL(VG_NBLIGNES_PSF,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre d''éléments purgés dans la table de sauvegarde DKA_EAI_TACHE_SAUV_FUSION est : '

        || NVL(VG_NBLIGNES_TSF,0) );




    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure bilan'
                                             || CHR(10)
                                             || SQLERRM);
    END BILAN_ET07;
  ------------------------------------------------------------------------------------
  --  Nom           : main_rest_TAB_INT
  --  Description   : point d'entrée du traitement DKA : Fusion PA ¿ Etape 07 : Restauration des tables d''interface
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_REST_TAB_INT (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   VARCHAR2,
        P_UO_ABSORBEE         NUMBER
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure SAUV_TABLE_INTERF');

        SAUV_TABLE_INTERF_ET07(P_TRANSCODIFICATION,P_UO_ABSORBEE);
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure SAUV_TABLE_SAUVEGARDE_ET07');

        SAUV_TABLE_SAUVEGARDE_ET07 (P_TRANSCODIFICATION,P_UO_ABSORBEE);
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');

        BILAN_ET07;
    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_REST_TAB_INT'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_REST_TAB_INT;

--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> DKA ¿ Etape 08  Fusion PA : Fermeture des Projets/Tâches suffixés
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

 --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
------------------------------------------------------------------------------------
  --  Nom           : FERMETURE_PROJET_TACHE
   --  Description   :  procédure pour mise à jour des projets et des tâches
  --
  ------------------------------------------------------------------------------------

    PROCEDURE FERMETURE_PROJET_TACHE (
        P_TRANSCODIFICATION   VARCHAR2,
        P_DATE_FIN_PROJET     VARCHAR2,
        P_DATE_FIN_TACHE      VARCHAR2,
        P_UO_ABSORBEE         NUMBER
    ) IS

        CURSOR LISTEPROJETS (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBEE NUMBER
        ) IS SELECT
                 PROJECT_ID,
                 SEGMENT1
             FROM
                 PA_PROJECTS_ALL
             WHERE
                 SUBSTR(SEGMENT1,11,1) = 'Z'
                 AND PROJECT_STATUS_CODE != 'CLOSED'
                 AND ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU,
                         DKA_STRANSCO_LINES DSTL,
                         DKA_STRANSCO_HEADERS DSTH
                     WHERE
                         DSTL.SET_ID = DSTH.SET_ID
                         AND HROU.NAME = DSTL.PARAM1_VALUE
                         AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                         AND DSTL.ENABLE = 'Y'
                         AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                         AND ( P_TRANSCODIFICATION = 'Y'
                               OR ( P_TRANSCODIFICATION = 'N'
                                    AND HROU.ORGANIZATION_ID = P_UO_ABSORBEE ) )
                 );

        VD_DATE_FIN      DATE;
        VD_DATE_FIN2     DATE;
        VD_DATE_FIN_TC   DATE;
        VD_COMPLETION_DATE DATE;
    BEGIN
        BEGIN
            SELECT
                TO_DATE(P_DATE_FIN_PROJET,'DD/MM/YYYY')
            INTO VD_DATE_FIN
            FROM
                DUAL;

        EXCEPTION
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'la date que vous avez saisi dans le paramètre date fin projet n''est pas valide '
                || SQLERRM);
        END;

        BEGIN
            SELECT
                TO_DATE(P_DATE_FIN_TACHE,'DD/MM/YYYY')
            INTO VD_DATE_FIN_TC
            FROM
                DUAL;

        EXCEPTION
            WHEN OTHERS THEN
                FND_FILE.PUT_LINE(FND_FILE.LOG,'la date que vous avez saisi dans le paramètre date fin tâche n''est pas valide ' || SQLERRM);
        END;

        FOR IC IN LISTEPROJETS(P_TRANSCODIFICATION,P_UO_ABSORBEE) LOOP
            BEGIN
                UPDATE PA_TASKS
                SET
                    COMPLETION_DATE = VD_DATE_FIN_TC,
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                WHERE
                    PROJECT_ID = IC.PROJECT_ID
                    AND ( COMPLETION_DATE IS NULL
                          OR COMPLETION_DATE > VD_DATE_FIN_TC );

                VG_TACHES_FERMEES   := VG_TACHES_FERMEES + SQL%ROWCOUNT;

                SELECT COMPLETION_DATE INTO VD_COMPLETION_DATE
                FROM PA_PROJECTS_ALL
                WHERE
                    PROJECT_ID = IC.PROJECT_ID;

                IF VD_COMPLETION_DATE IS NULL OR VD_COMPLETION_DATE > VD_DATE_FIN THEN
                   UPDATE PA_PROJECTS_ALL
                SET
                    PROJECT_STATUS_CODE = 'CLOSED',
                    COMPLETION_DATE = VD_DATE_FIN,
                    CLOSED_DATE = VD_DATE_FIN,
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                WHERE
                    PROJECT_ID = IC.PROJECT_ID;
                ELSE

                UPDATE PA_PROJECTS_ALL
                SET
                    PROJECT_STATUS_CODE = 'CLOSED',
                    CLOSED_DATE = VD_DATE_FIN,
                    LAST_UPDATE_DATE = SYSDATE,
                    LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                WHERE
                    PROJECT_ID = IC.PROJECT_ID;
                END IF;

                VG_PROJETS_FERMES   := VG_PROJETS_FERMES + SQL%ROWCOUNT;
            EXCEPTION
                WHEN OTHERS THEN
                    FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur sur le projet '
                                                     || IC.SEGMENT1
                                                     || ' - '
                                                     || SQLERRM);
                    RAISE;
            END;
        END LOOP;

        COMMIT;
    END FERMETURE_PROJET_TACHE;

  ------------------------------------------------------------------------------------
  --  Nom           : BILAN_ET08
  --  Description   : bilan du traitement DKA ¿ Etape 08  Fusion PA : Fermeture des Projets/Tâches suffixés
  --
  ------------------------------------------------------------------------------------

    PROCEDURE BILAN_ET08 IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Bilan du traitement' || CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de lignes mis à jour par le traitement' || CHR(10) );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Tâches fermées : ' || NVL(VG_TACHES_FERMEES,0) );

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Projets fermes : ' || NVL(VG_PROJETS_FERMES,0) );

    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure BILAN_ET08'
                                             || CHR(10)
                                             || SQLERRM);
    END BILAN_ET08;

  ------------------------------------------------------------------------------------
  --  Nom           : main_ferm_projet
  --  Description   : point d'entrée du traitement traitement  DKA ¿ Etape 08  Fusion PA : Fermeture des Projets/Tâches suffixés
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_FERM_PROJET (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   VARCHAR2,
        P_DATE_FIN_PROJET     VARCHAR2,
        P_DATE_FIN_TACHE      VARCHAR2,
        P_UO_ABSORBEE         NUMBER
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure FERMETURE_PROJET_TACHE');

        FERMETURE_PROJET_TACHE(P_TRANSCODIFICATION,P_DATE_FIN_PROJET,P_DATE_FIN_TACHE,P_UO_ABSORBEE);
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');

        BILAN_ET08;
    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_FERM_PROJET'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_FERM_PROJET;

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Correction des organisations des projets
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  ------------------------------------------------------------------------------------
  --  Nom           : CORREECTION_ORG_PROJET
  --  Description   :  procédure de mise à jour des des projets
  ------------------------------------------------------------------------------------

    PROCEDURE CORRECTION_ORG_PROJET (
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS

        --P_CPT_TASK      NUMBER := 0;
        P_CPT_PROJECT   NUMBER := 0;
        P_CPT_DATE      NUMBER := 0;
        P_CPT_ORG       NUMBER := 0;
        L_NBLIGNES      NUMBER := 0;
        l_count_date    NUMBER;
        l_count_org     NUMBER;

        CURSOR CUR_UO_ABSOB (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBE_ID NUMBER
        ) IS SELECT
                 HROU.NAME,
                 HROU.ORGANIZATION_ID,
                 DSTL.RETURN_VALUE
             FROM
                 HR_ORGANIZATION_UNITS HROU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HROU.NAME = DSTL.PARAM1_VALUE
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                 AND ( P_TRANSCODIFICATION = 'Y'
                       OR ( P_TRANSCODIFICATION = 'N'
                            AND HROU.ORGANIZATION_ID = P_UO_ABSORBE_ID ) );

        CURSOR CUR_PROJECTS (
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 A.*, A.rowid rid
             FROM
                 DKA_EAI_PROJET A
             WHERE
                 A.OPERATING_UNIT = (
                     SELECT
                         HROU.NAME
                     FROM
                         HR_ORGANIZATION_UNITS HROU
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )
                 AND A.OA_STATUS = 'REJECT'
                 AND A.OA_REJECTION_REASON = 'La date de début de validité de l''organisation est différente de la date de début de projet'
        FOR UPDATE OF ORGANIZATION_START_DATE,
                      ORGANIZATION_NAME;

        CURSOR CUR_ORG_DATE (
            P_PROJECT_CODE VARCHAR2
        ) IS SELECT
                 PCDTO.START_DATE_ACTIVE   START_DATE_ACTIVE,
                 HOU.NAME                  ORGANIZATION_NAME
             FROM
                 PA_PROJECTS_ALL PPA,
                 PA_COST_DIST_OVERRIDES PCDTO,
                 HR_ALL_ORGANIZATION_UNITS HOU
             WHERE
                 HOU.ORGANIZATION_ID = PCDTO.OVERRIDE_TO_ORGANIZATION_ID
                 AND START_DATE_ACTIVE = (
                     SELECT
                         MIN(PCDTO1.START_DATE_ACTIVE)
                     FROM
                         PA_COST_DIST_OVERRIDES PCDTO1
                     WHERE
                         PCDTO1.PROJECT_ID = PPA.PROJECT_ID
                 )
                 AND PPA.PROJECT_ID = PCDTO.PROJECT_ID
                 AND PPA.SEGMENT1 LIKE P_PROJECT_CODE || '%';

    BEGIN
        /*IF P_MODE_SIMULATION = 'Y' THEN*/
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,' Bilan du traitement : ' || CHR(10) );
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'UO absorbée : ' || UO.NAME);
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Code Projet;Ancienne valeur du nom de l''organisation;Nouvelle valeur de l''organisation;Anciennce valeur de date de début de l''organisation;Nouvelle valeur de date de début de l''organisation'
                || CHR(10) );
                FOR REC IN CUR_PROJECTS(UO.RETURN_VALUE) LOOP
                    FOR OG IN CUR_ORG_DATE(REC.PROJECT_CODE) LOOP
                        IF OG.START_DATE_ACTIVE = REC.PROJECT_START_DATE THEN

                        SELECT COUNT(1)
                        INTO l_count_date
                        FROM DKA_EAI_PROJET dep
                        WHERE ORGANIZATION_START_DATE != OG.START_DATE_ACTIVE
                        AND dep.ROWID = REC.RID;

                        SELECT COUNT(1)
                        INTO l_count_org
                        FROM DKA_EAI_PROJET dep
                        WHERE ORGANIZATION_NAME != OG.ORGANIZATION_NAME
                        AND dep.ROWID = REC.RID;

                        IF l_count_date > 0 THEN
                          P_CPT_DATE := P_CPT_DATE + 1;
                        END IF;

                        IF l_count_org > 0 THEN
                          P_CPT_ORG := P_CPT_ORG + 1;
                        END IF;

                        IF l_count_date > 0 OR l_count_org > 0 THEN
                          P_CPT_PROJECT := P_CPT_PROJECT + 1;
                        END IF;

                        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,REC.PROJECT_CODE
                                                                || ';'
                                                                || REC.ORGANIZATION_NAME
                                                                || ';'
                                                                || OG.ORGANIZATION_NAME
                                                                || ';'
                                                                || TO_CHAR(REC.ORGANIZATION_START_DATE,'DD/MM/YYYY')
                                                                || ';'
                                                                || TO_CHAR(OG.START_DATE_ACTIVE,'DD/MM/YYYY') );

                        END IF;
                    END LOOP;
                END LOOP;

            END LOOP;

        /*ELS*/IF P_MODE_SIMULATION = 'N' THEN
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'UO absorbée : '
                                                    || UO.NAME
                                                    || CHR(10) );
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Code Projet;Ancienne valeur du nom de l''organisation;Nouvelle valeur de l''organisation;Anciennce valeur de date de début de l''organisation;Nouvelle valeur de date de début de l''organisation'
                || CHR(10) );*/


                FOR REC IN CUR_PROJECTS(UO.RETURN_VALUE) LOOP
                    FOR OG IN CUR_ORG_DATE(REC.PROJECT_CODE) LOOP
                        IF OG.START_DATE_ACTIVE = REC.PROJECT_START_DATE THEN
                            /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Détail de la mise à jour du projet : ' || REC.PROJECT_CODE);
                            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Organisation :'
                                                                || REC.ORGANIZATION_NAME
                                                                || ' => '
                                                                || OG.ORGANIZATION_NAME
                                                                || ' en date du '
                                                                || TO_CHAR(OG.START_DATE_ACTIVE,'DD/MM/YYYY')
                                                                || ' date eai '
                                                                || REC.ORGANIZATION_START_DATE );*/
                            UPDATE DKA_EAI_PROJET
                            SET
                                ORGANIZATION_START_DATE = OG.START_DATE_ACTIVE,
                                ORGANIZATION_NAME = OG.ORGANIZATION_NAME,
                                LAST_UPDATE_DATE = SYSDATE,
                                LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                            WHERE
                                CURRENT OF CUR_PROJECTS;

                        END IF;
                    END LOOP;

                    --P_CPT_PROJECT   := P_CPT_PROJECT + SQL%ROWCOUNT;
                END LOOP;

            END LOOP;

        END IF;

      -- un comptage des modifications effectuée/à effectuer qui fonctionne.
      -- (9 projets ciblés, X modifications d¿organisation, Y modifications de dates)
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre  des projets modifiés par le traitement dans la table d''interface : '
                                          || P_CPT_PROJECT
                                          || CHR(10) );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre  de lignes modifiés de date par le traitement dans la table d''interface : '
                                          || P_CPT_DATE
                                          || CHR(10) );
      FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Le nombre  de lignes modifiés pour l''organisation par le traitement dans la table d''interface : '
                                          || P_CPT_ORG
                                          || CHR(10) );
    EXCEPTION
        WHEN OTHERS THEN
            FND_FILE.PUT_LINE(FND_FILE.LOG,'Erreur procedure CORRECTION_ORG_PROJET'
                                             || CHR(10)
                                             || SQLERRM);
    END CORRECTION_ORG_PROJET;

    PROCEDURE MAIN_CORREC_PROJET (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure CORRECTION_ORG_PROJET');

        CORRECTION_ORG_PROJET(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE,P_MODE_SIMULATION);
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');

    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure CORRECTION_ORG_PROJET'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_CORREC_PROJET;

		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA  - Etape 04 : Reprise des indicateurs TEC et PCA
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  ------------------------------------------------------------------------------------
  --  Nom           : REPRISE_INDICATEUR
  --  Description   :  procédure de mise à jour des des projets
  ------------------------------------------------------------------------------------

    PROCEDURE REPRISE_INDICATEUR (
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS

        CURSOR CUR_UO_ABSOB (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBE_ID NUMBER
        ) IS SELECT
                 HROU.NAME,
                 HROU.ORGANIZATION_ID,
                 DSTL.RETURN_VALUE
             FROM
                 HR_ORGANIZATION_UNITS HROU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HROU.NAME = DSTL.PARAM1_VALUE
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                 AND ( P_TRANSCODIFICATION = 'Y'
                       OR ( P_TRANSCODIFICATION = 'N'
                            AND HROU.ORGANIZATION_ID = P_UO_ABSORBE_ID ) );

        CURSOR CUR_PROJECTS (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT          --- Absorbe
                 'Absorbe',
                 A1.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A1.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT1.TASK_NUMBER   TACHE_ABSORBE,
                 PT1.TASK_ID       ID_TACHE_ABSORBE,
                 PT1.ATTRIBUTE3    ANCIEN_IND,
                --- Absorbante
                 'Absorbante',
                 A.PROJECT_ID      ID_PRJ_ABSORBANTE,
                 A.SEGMENT1        NAME_PRJ_ABSORBANTE,
                 PT.TASK_NUMBER    TACHE_ABSORBANTE,
                 PT.TASK_ID        ID_TACHE_ABSORBANTE,
                 PT.ATTRIBUTE3     INDICATEUR
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT, --       absorbante
                 PA_PROJECTS_ALL A1,
                 PA_TASKS PT1 --       absorbe
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND A.ORG_ID = (
                     SELECT
                         ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )
                 AND PT1.PROJECT_ID = A1.PROJECT_ID
                 AND A1.ORG_ID = P_UO_ABSORBEE
                 AND SUBSTR(A1.SEGMENT1,1,10) = SUBSTR(A.SEGMENT1,1,10)
                 AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10)
                 AND NVL(PT1.ATTRIBUTE3,'X') <> NVL(PT.ATTRIBUTE3,'X');

        CURSOR CUR_PROJ_TC_ABS (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbe',
                 A.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT.TASK_NUMBER   TACHE_ABSORBE,
                 PT.TASK_ID       ID_TACHE_ABSORBE
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND A.ORG_ID = P_UO_ABSORBEE
                 AND substr(PT.TASK_NUMBER,1,2) IN ('GX', 'GL', 'GK')
                 AND NOT EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10)

                         AND A1.ORG_ID = (
                             SELECT
                                 ORGANIZATION_ID
                             FROM
                                 HR_ORGANIZATION_UNITS
                             WHERE
                                 NAME = P_UO_ABSORBANTE
                         )
                 );

        CURSOR CUR_PROJ_TC_ABSORBT (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbante',
                 A.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT.TASK_NUMBER   TACHE_ABSORBE,
                 PT.TASK_ID       ID_TACHE_ABSORBE
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND A.ORG_ID = (
                     SELECT
                         ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )

                 AND substr(PT.TASK_NUMBER,1,2) IN ('GX', 'GL', 'GK')
                 AND NOT EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) || 'Z' = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND SUBSTR(PT.TASK_NUMBER,1,10)
                             || 'Z' = SUBSTR(PT1.TASK_NUMBER,1,10)
                         AND A1.ORG_ID = P_UO_ABSORBEE
                 );

    BEGIN
        VG_LIGNES_MODIFIES   := 'Liste Projet Traité ; tâches mis à jour ; Ancienne valeur de l''indicateur TEC et PCA ; nouvelle valeur de l''indicateur TEC et PCA '
        || CHR(10);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_LIGNES_MODIFIES);
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR REC IN CUR_PROJECTS(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP --P_CODE_UO_ABSORBE
                IF P_MODE_SIMULATION = 'N' THEN
                    UPDATE PA.PA_TASKS
                    SET
                        ATTRIBUTE3 = REC.ANCIEN_IND,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                    WHERE
                        TASK_ID = REC.ID_TACHE_ABSORBANTE
                        AND PROJECT_ID = REC.ID_PRJ_ABSORBANTE;

                    COMMIT;
                END IF;

                VG_NB_TACHES_MODIFIE   := VG_NB_TACHES_MODIFIE + 1;
                VG_LIGNES_MODIFIES     := REC.NAME_PRJ_ABSORBANTE
                                      || ';'
                                      || REC.TACHE_ABSORBANTE
                                      || ';'
                                      || REC.INDICATEUR
                                      || ';'
                                      || REC.ANCIEN_IND;

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_LIGNES_MODIFIES);
            END LOOP;
        END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Liste des projets/tâches de l''absorbée absente dans l''absorbante' || CHR(10) );
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR ABSOR IN CUR_PROJ_TC_ABS(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,ABSOR.NAME_PRJ_ABOSRBE
                                                    || '/'
                                                    || ABSOR.TACHE_ABSORBE);
            END LOOP;
        END LOOP;

        /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Liste des projets/tâches de l''absorbante absente dans l''absorbée');
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR ABSORT IN CUR_PROJ_TC_ABSORBT(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,ABSORT.NAME_PRJ_ABOSRBE
                                                    || '/'
                                                    || ABSORT.TACHE_ABSORBE);
            END LOOP;
        END LOOP;*/

    END REPRISE_INDICATEUR;

	 ------------------------------------------------------------------------------------
  --  Nom           : MAIN_REPRISE_INDIC
  --  Description   : point d'entrée du traitement DKA : Fusion PA  - Etape 04 : Reprise des indicateurs TEC et PCA
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_REPRISE_INDIC (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure REPRISE_INDICATEUR');

        REPRISE_INDICATEUR(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE,P_MODE_SIMULATION);
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');

    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_REPRISE_INDIC'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_REPRISE_INDIC;

		--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Etape 05 : Mise à jour des projets et tâches pour les TEC et PCA
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  ------------------------------------------------------------------------------------
  --  Nom           : REPRISE_INDICATEUR
  --  Description   :  procédure de mise à jour des des projets  et tâches pour TEC et PCA
  ------------------------------------------------------------------------------------

    PROCEDURE MAJ_PR_TEC_PCA (
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS

        V_DATE_JOUR   VARCHAR2(20);
        CURSOR CUR_UO_ABSOB (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBE_ID NUMBER
        ) IS SELECT
                 HROU.NAME,
                 HROU.ORGANIZATION_ID,
                 DSTL.RETURN_VALUE,
                 HROU2.ORGANIZATION_ID ORG_ID_ABSORBANTE
             FROM
                 HR_ORGANIZATION_UNITS HROU,
                 HR_ORGANIZATION_UNITS HROU2,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HROU.NAME = DSTL.PARAM1_VALUE
                 AND HROU2.NAME = DSTL.RETURN_VALUE
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                 AND ( NVL(P_TRANSCODIFICATION,'N') = 'Y'
                       OR ( NVL(P_TRANSCODIFICATION, 'N') = 'N'
                            AND HROU.ORGANIZATION_ID = P_UO_ABSORBE_ID ) );

        CURSOR CUR_PROJECTS (
            P_UO_ABSORBEE VARCHAR2
        ) IS SELECT pa.segment1,
       pt.task_number,
       pa.project_id  old_id_prj,
       pa2.project_id  new_id_prj,
       pt.task_id     old_id_ptsk,
       pt2.task_id     new_id_ptsk
  FROM pa_projects_all      pa,
       pa_tasks             pt,
       pa_projects_all      pa2,
       pa_tasks             pt2
 WHERE (pa.project_id, pt.task_id) IN (select tm.project_id, tm.task_id from dka_spatravcours_tmp tm)
  AND substr(pt2.task_number, 1, 10) =
       substr(pt.task_number, 1, 10)
  AND pt2.rowid != pt.rowid
   AND substr(pa.segment1,1,10) = substr(pa2.segment1,1,10)
   AND pa.rowid != pa2.rowid
   AND pa2.project_id = pt2.project_id
   AND pa.org_id IN (SELECT hrou.organization_id
                       FROM hr_organization_units hrou
                      WHERE hrou.name  = P_UO_ABSORBEE
                     );

        CURSOR CUR_PROJ_TC_ABS (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbe',
                 A.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT.TASK_NUMBER   TACHE_ABSORBE,
                 PT.TASK_ID       ID_TACHE_ABSORBE
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND (a.project_id, pt.task_id) IN (select tm.project_id, tm.task_id from dka_spatravcours_tmp tm)
                 AND A.ORG_ID = P_UO_ABSORBEE
                 AND NOT EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10)

                         AND A1.ORG_ID = (
                             SELECT
                                 ORGANIZATION_ID
                             FROM
                                 HR_ORGANIZATION_UNITS
                             WHERE
                                 NAME = P_UO_ABSORBANTE
                         )
                 );

        CURSOR CUR_PROJ_TC_ABSORBT (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbante',
                 A.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT.TASK_NUMBER   TACHE_ABSORBE,
                 PT.TASK_ID       ID_TACHE_ABSORBE
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND (a.segment1, pt.task_number) IN
                          (SELECT tm.segment1, tm.task_number FROM dka_spatravcours_tmp tm)  
                 AND A.ORG_ID = (
                     SELECT
                         ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )
                 AND NOT EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10)  = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND (a1.project_id, pt1.task_id) IN (select tm.project_id, tm.task_id from dka_spatravcours_tmp tm)
                         AND SUBSTR(PT.TASK_NUMBER,1,10)
                              = SUBSTR(PT1.TASK_NUMBER,1,10)
                         AND A1.ORG_ID = P_UO_ABSORBEE
                 );

        CURSOR CUR_PROJ_ABS_ABST (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbante',
                 A.PROJECT_ID     ID_PRJ,
                 A.SEGMENT1       NAME_PRJ,
                 PT.TASK_NUMBER   TACHE,
                 PT.TASK_ID       ID_TACHE_
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND A.ORG_ID = (
                     SELECT
                         ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )
                 AND EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10)
                         AND A1.ORG_ID = P_UO_ABSORBEE
                         AND (a1.project_id, pt1.task_id) IN (select tm.project_id, tm.task_id from dka_spatravcours_tmp tm)
                 );

        CURSOR CUR_MAJ_ECHEC_PROJET (
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 TM.SEGMENT1,
                 TM.PROJECT_ID   OLD_ID_PRJ
             FROM
                 PA_PROJECTS_ALL PA,
                 DKA_SPATRAVCOURS_TMP TM
             WHERE
                 PA.SEGMENT1 = TM.SEGMENT1
                ---  and pa.segment1 like 'FA0001766G'
                 AND TM.PROJECT_ID != PA.PROJECT_ID
                 AND PA.ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU
                     WHERE
                         HROU.NAME = P_UO_ABSORBANTE
                 );

          CURSOR CUR_MAJ_ECHEC_TACHE (
            P_UO_ABSORBANTE VARCHAR2
        ) IS
             SELECT
                 TM.TASK_NUMBER,
                 TM.TASK_ID      OLD_ID_TSK
             FROM
                 PA_PROJECTS_ALL PA,
                 PA_TASKS PT,
                 DKA_SPATRAVCOURS_TMP TM
             WHERE
                 PA.SEGMENT1 = TM.SEGMENT1
                 AND PT.TASK_NUMBER = TM.TASK_NUMBER
                ---  and pa.segment1 like 'FA0001766G'
                 AND TM.PROJECT_ID = PA.PROJECT_ID
                 AND PA.PROJECT_ID = PT.PROJECT_ID
                 AND TM.TASK_ID != PT.TASK_ID
                  AND PA.ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU
                     WHERE
                         HROU.NAME = P_UO_ABSORBANTE
                 );

    BEGIN
        SELECT
            TO_CHAR(SYSDATE,'DDMMYYHHMMSS')
        INTO V_DATE_JOUR
        FROM
            DUAL;

        IF P_MODE_SIMULATION = 'N' THEN

		 ---création de table de sauvegarde pour dka_spatravcours_tmp :
            EXECUTE IMMEDIATE 'create table DKA.dka_spatrv_tmp_'
                              || V_DATE_JOUR
                              || ' as
		        select * from dka_spatravcours_tmp';
            VG_NOM_TABLE1_T1   := 'dka_spatrv_tmp_' || V_DATE_JOUR;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'La table dka_spatravcours_tmp a été sauvegardée dans la table ' || VG_NOM_TABLE1_T1
            );
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) || 'Liste des projets/tâches existant dans l''absorbée  et dans l''absorbante' || CHR(10)

        );
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR AB IN CUR_PROJ_ABS_ABST(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' ||
                AB.NAME_PRJ
                                                    || '/'
                                                    || AB.TACHE);
            END LOOP;
        END LOOP;

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) || 'Liste des projets/tâches absent dans l''absorbée  et dans l''absorbante' || CHR(10)
        );

        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR ABSOR IN CUR_PROJ_TC_ABS(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || ABSOR.NAME_PRJ_ABOSRBE
                                                    || '/'
                                                    || ABSOR.TACHE_ABSORBE);
            END LOOP;
        END LOOP;

        VG_NBLIGNES_MODIFIES := 0;

        VG_LIGNES_MODIFIES   := CHR(10) || 'Liste des Projets à mettre à jour ;Tâches à mettre à jour ;Ancienne valeur de l''id du projet;Nouvelle valeur de l''id du projet;Ancienne valeur de l''id du tâche;Nouvelle valeur de l''id du tâche '

        || CHR(10);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_LIGNES_MODIFIES);
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP

            FOR REC IN CUR_PROJECTS(UO.NAME) LOOP
                IF P_MODE_SIMULATION = 'N' THEN

					--mise à jour des projets et tâches:
                    UPDATE DKA_SPATRAVCOURS_TMP
                    SET
                        PROJECT_ID = REC.NEW_ID_PRJ,
                        TASK_ID = REC.NEW_ID_PTSK,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                    WHERE
                        PROJECT_ID = REC.OLD_ID_PRJ
                        AND TASK_ID = REC.OLD_ID_PTSK;

                     VG_NBLIGNES_MODIFIES := VG_NBLIGNES_MODIFIES + 1;

                END IF;

                COMMIT;
                VG_LIGNES_MODIFIES   := UO.NAME || ';' || UO.RETURN_VALUE || ';'
                                      || REC.SEGMENT1
                                      || ';'
                                      || REC.TASK_NUMBER
                                      || ';'
                                      || REC.OLD_ID_PRJ
                                      || ';'
                                      || REC.NEW_ID_PRJ
                                      || ';'
                                      || REC.OLD_ID_PTSK
                                      || ';'
                                      || REC.NEW_ID_PTSK;

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_LIGNES_MODIFIES);
            END LOOP;
        END LOOP;

        /*FND_FILE.PUT_LINE(FND_FILE.OUTPUT,  CHR(10) || 'Liste des projets/tâches de l''absorbante absente dans l''absorbée' || CHR(10));
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR ABSORT IN CUR_PROJ_TC_ABSORBT(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || ABSORT.NAME_PRJ_ABOSRBE
                                                    || '/'
                                                    || ABSORT.TACHE_ABSORBE);
            END LOOP;
        END LOOP;*/

        VG_NB_ERROR_PROJET := 0;
        VG_NB_ERROR_TACHE := 0;
        IF P_MODE_SIMULATION = 'N' THEN

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) ||'Liste des échecs projet : ');
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FOR EC IN CUR_MAJ_ECHEC_PROJET(UO.RETURN_VALUE) LOOP
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || EC.SEGMENT1);
                    VG_NB_ERROR_PROJET := VG_NB_ERROR_PROJET + 1;
                END LOOP;
            END LOOP;

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) ||'Liste des échecs tâche : ');
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FOR EC IN CUR_MAJ_ECHEC_TACHE(UO.RETURN_VALUE) LOOP
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || EC.TASK_NUMBER);
                    VG_NB_ERROR_TACHE := VG_NB_ERROR_TACHE + 1;
                END LOOP;
            END LOOP;

        END IF;

    END MAJ_PR_TEC_PCA;
	 ------------------------------------------------------------------------------------
  --  Nom           : MAIN_MAJ_PR_TEC_PCA
  --  Description   : point d'entrée du traitement DKA : Fusion PA ¿ Etape 05 : Mise à jour des projets et tâches pour les TEC et PCA
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_MAJ_PR_TEC_PCA (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure MAJ_PR_TEC_PCA');

        MAJ_PR_TEC_PCA(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE,P_MODE_SIMULATION);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de mises à jour réussi : ' || VG_NBLIGNES_MODIFIES );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de mises à jour de projet en échec : ' || VG_NB_ERROR_PROJET );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de mises à jour de tâche en échec : ' || VG_NB_ERROR_TACHE );

    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_MAJ_PR_TEC_PCA'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_MAJ_PR_TEC_PCA;
    --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- TRAITEMENT :  ==> « DKA : Fusion PA ¿ Etape 06 : Mise à jour des projets et tâches pour les CCA sur sinistres
--
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

	--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
	  ------------------------------------------------------------------------------------
  --  Nom           : MAJ_PR_CCA
  --  Description   :  procédure de mise à jour des des projets  et tâches pour CCA
  ------------------------------------------------------------------------------------

    PROCEDURE MAJ_PR_CCA (
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS

        V_DATE_JOUR   VARCHAR2(20);
        CURSOR CUR_UO_ABSOB (
            P_TRANSCODIFICATION VARCHAR2,
            P_UO_ABSORBE_ID NUMBER
        ) IS SELECT
                 HROU.NAME,
                 HROU.ORGANIZATION_ID,
                 DSTL.RETURN_VALUE
             FROM
                 HR_ORGANIZATION_UNITS HROU,
                 DKA_STRANSCO_LINES DSTL,
                 DKA_STRANSCO_HEADERS DSTH
             WHERE
                 DSTL.SET_ID = DSTH.SET_ID
                 AND HROU.NAME = DSTL.PARAM1_VALUE
                 AND DSTH.SET_NAME LIKE 'FUSION_SOCIETE_VERS_SOCIETE'
                 AND DSTL.ENABLE = 'Y'
                 AND NVL(DSTL.END_DATE,TRUNC(SYSDATE) ) >= TRUNC(SYSDATE)
                 AND ( P_TRANSCODIFICATION = 'Y'
                       OR ( P_TRANSCODIFICATION = 'N'
                            AND HROU.ORGANIZATION_ID = P_UO_ABSORBE_ID ) );

        CURSOR CUR_PROJECTS (
            P_UO_ABSORBEE VARCHAR2
        ) IS SELECT
                 PA.SEGMENT1,
                 PT.TASK_NUMBER,
                 PA.PROJECT_ID   OLD_ID_PRJ,
                 PA2.PROJECT_ID   NEW_ID_PRJ,
                 PT.TASK_ID      OLD_ID_PTSK,
                 PT2.TASK_ID      NEW_ID_PTSK
             FROM
                 PA_PROJECTS_ALL PA,
                 PA_TASKS PT,
                 pa_projects_all      pa2,
                 pa_tasks             pt2
             WHERE
                 (pa.project_id, pt.task_id) IN (select tm.project_id, tm.task_id from dka_spasinistre_tmp tm)
  AND substr(pt2.task_number, 1, 10) =
       substr(pt.task_number, 1, 10)
  AND pt2.rowid != pt.rowid
   AND substr(pa.segment1,1,10) = substr(pa2.segment1,1,10)
   AND pa.rowid != pa2.rowid
   AND pa2.project_id = pt2.project_id
                 AND PA.ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU
                     WHERE
                         HROU.NAME = P_UO_ABSORBEE
                 );

        CURSOR CUR_PROJ_TC_ABS (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbe',
                 A.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT.TASK_NUMBER   TACHE_ABSORBE,
                 PT.TASK_ID       ID_TACHE_ABSORBE
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND (a.project_id, pt.task_id) IN (select tm.project_id, tm.task_id from dka_spasinistre_tmp tm)
                 AND A.ORG_ID = P_UO_ABSORBEE
                 AND NOT EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10)
                         AND A1.ORG_ID = (
                             SELECT
                                 ORGANIZATION_ID
                             FROM
                                 HR_ORGANIZATION_UNITS
                             WHERE
                                 NAME = P_UO_ABSORBANTE
                         )
                 );

        CURSOR CUR_PROJ_TC_ABSORBT (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbante',
                 A.PROJECT_ID     ID_PRJ_ABOSRBE,
                 A.SEGMENT1       NAME_PRJ_ABOSRBE,
                 PT.TASK_NUMBER   TACHE_ABSORBE,
                 PT.TASK_ID       ID_TACHE_ABSORBE
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND (a.project_id, pt.task_id) IN (select tm.project_id, tm.task_id from dka_spasinistre_tmp tm)
                 AND A.ORG_ID = (
                     SELECT
                         ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )
                 AND NOT EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) = SUBSTR(A1.SEGMENT1,1,10)
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND (a1.segment1, pt1.task_number) IN
                          (SELECT tm.segment1, tm.task_number FROM dka_spatravcours_tmp tm)   
                         AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10)
                         AND A1.ORG_ID = P_UO_ABSORBEE
                 );

        CURSOR CUR_PROJ_ABS_ABST (
            P_UO_ABSORBEE NUMBER,
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 'Absorbante',
                 A.PROJECT_ID     ID_PRJ,
                 A.SEGMENT1       NAME_PRJ,
                 PT.TASK_NUMBER   TACHE,
                 PT.TASK_ID       ID_TACHE_
             FROM
                 PA_PROJECTS_ALL A,
                 PA_TASKS PT
             WHERE
                 PT.PROJECT_ID = A.PROJECT_ID
                 AND A.ORG_ID = (
                     SELECT
                         ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS
                     WHERE
                         NAME = P_UO_ABSORBANTE
                 )
                 AND EXISTS (
                     SELECT DISTINCT
                         1
                     FROM
                         PA_PROJECTS_ALL A1,
                         PA_TASKS PT1
                     WHERE
                         SUBSTR(A.SEGMENT1,1,10) = SUBSTR(A1.SEGMENT1,1,10) -- JWYC
                         AND PT1.PROJECT_ID = A1.PROJECT_ID
                         AND SUBSTR(PT.TASK_NUMBER,1,10) = SUBSTR(PT1.TASK_NUMBER,1,10) -- JWYC
                         AND A1.ORG_ID = P_UO_ABSORBEE
                         AND (a1.project_id, pt1.task_id) IN (select tm.project_id, tm.task_id from dka_spasinistre_tmp tm)
                 );

        CURSOR CUR_MAJ_ECHEC_PROJET (
            P_UO_ABSORBANTE VARCHAR2
        ) IS SELECT
                 TM.SEGMENT1,
                 TM.PROJECT_ID   OLD_ID_PRJ
             FROM
                 PA_PROJECTS_ALL PA,
                 dka_spasinistre_tmp TM
             WHERE
                 PA.SEGMENT1 = TM.SEGMENT1
                ---  and pa.segment1 like 'FA0001766G'
                 AND TM.PROJECT_ID != PA.PROJECT_ID
                 AND PA.ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU
                     WHERE
                         HROU.NAME = P_UO_ABSORBANTE
                 );

          CURSOR CUR_MAJ_ECHEC_TACHE (
            P_UO_ABSORBANTE VARCHAR2
        ) IS
             SELECT
                 TM.TASK_NUMBER,
                 TM.TASK_ID      OLD_ID_TSK
             FROM
                 PA_PROJECTS_ALL PA,
                 PA_TASKS PT,
                 dka_spasinistre_tmp TM
             WHERE
                 PA.SEGMENT1 = TM.SEGMENT1
                 AND PT.TASK_NUMBER = TM.TASK_NUMBER
                ---  and pa.segment1 like 'FA0001766G'
                 AND TM.PROJECT_ID = PA.PROJECT_ID
                 AND PA.PROJECT_ID = PT.PROJECT_ID
                 AND TM.TASK_ID != PT.TASK_ID
                  AND PA.ORG_ID IN (
                     SELECT
                         HROU.ORGANIZATION_ID
                     FROM
                         HR_ORGANIZATION_UNITS HROU
                     WHERE
                         HROU.NAME = P_UO_ABSORBANTE
                 );

    BEGIN
        SELECT
            TO_CHAR(SYSDATE,'DDMMYYHHMMSS')
        INTO V_DATE_JOUR
        FROM
            DUAL;

        IF P_MODE_SIMULATION = 'N' THEN

		 ---création de table de sauvegarde pour dka_spasinistre_tmp :
            EXECUTE IMMEDIATE 'create table DKA.dka_spasin_tmp_'
                              || V_DATE_JOUR
                              || ' as
		        select * from dka_spasinistre_tmp';
            VG_NOM_TABLE1_T2   := 'dka_spasin_tmp_' || V_DATE_JOUR;
            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'La table dka_spasinistre_tmp a été sauvegardée dans la table ' || VG_NOM_TABLE1_T2)
            ;
        END IF;

        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) || 'Liste des projets/tâches existant dans l''absorbée  et dans l''absorbante' || CHR(10)

        );
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR AB IN CUR_PROJ_ABS_ABST(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' ||AB.NAME_PRJ
                                                    || '/'
                                                    || AB.TACHE);
            END LOOP;
        END LOOP;
        
         FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) || 'Liste des projets/tâches absent dans l''absorbée  et dans l''absorbante' || CHR(10)
        );

        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR ABSOR IN CUR_PROJ_TC_ABS(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || ABSOR.NAME_PRJ_ABOSRBE
                                                    || '/'
                                                    || ABSOR.TACHE_ABSORBE);
            END LOOP;
        END LOOP;

        VG_NBLIGNES_MODIFIES := 0;
        VG_LIGNES_MODIFIES   := CHR(10) || 'Liste des Projets à mettre à jour ;Tâches à mettre à jour ;Ancienne valeur de l''id du projet;Nouvelle valeur de l''id du projet;Ancienne valeur de l''id du tâche;Nouvelle valeur de l''id du tâche '

        || CHR(10);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_LIGNES_MODIFIES);
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR REC IN CUR_PROJECTS(UO.NAME) LOOP
                IF P_MODE_SIMULATION = 'N' THEN

					--mise à jour des projets et tâches:
                    UPDATE DKA_SPASINISTRE_TMP
                    SET
                        PROJECT_ID = REC.NEW_ID_PRJ,
                        TASK_ID = REC.NEW_ID_PTSK,
                        LAST_UPDATE_DATE = SYSDATE,
                        LAST_UPDATED_BY = FND_GLOBAL.USER_ID
                    WHERE
                        PROJECT_ID = REC.OLD_ID_PRJ
                        AND TASK_ID = REC.OLD_ID_PTSK;

                    VG_NBLIGNES_MODIFIES := VG_NBLIGNES_MODIFIES + 1;
                END IF;

                COMMIT;
                VG_LIGNES_MODIFIES   := UO.NAME || ';' || UO.RETURN_VALUE || ';'
                                      || REC.SEGMENT1
                                      || ';'
                                      || REC.TASK_NUMBER
                                      || ';'
                                      || REC.OLD_ID_PRJ
                                      || ';'
                                      || REC.NEW_ID_PRJ
                                      || ';'
                                      || REC.OLD_ID_PTSK
                                      || ';'
                                      || REC.NEW_ID_PTSK;

                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,VG_LIGNES_MODIFIES);
            END LOOP;
        END LOOP;

     /*   FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) || 'Liste des projets/tâches de l''absorbante absente dans l''absorbée');
        FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
            FOR ABSORT IN CUR_PROJ_TC_ABSORBT(UO.ORGANIZATION_ID,UO.RETURN_VALUE) LOOP
                FND_FILE.PUT_LINE(FND_FILE.OUTPUT,ABSORT.NAME_PRJ_ABOSRBE
                                                    || '/'
                                                    || ABSORT.TACHE_ABSORBE);
            END LOOP;
        END LOOP;*/

        VG_NB_ERROR_PROJET := 0;
        VG_NB_ERROR_TACHE := 0;
        IF P_MODE_SIMULATION = 'N' THEN

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) || 'Liste des échecs projet : '
            );
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FOR EC IN CUR_MAJ_ECHEC_PROJET(UO.RETURN_VALUE) LOOP
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || EC.SEGMENT1);
                    VG_NB_ERROR_PROJET := VG_NB_ERROR_PROJET + 1;
                END LOOP;
            END LOOP;

            FND_FILE.PUT_LINE(FND_FILE.OUTPUT,CHR(10) || 'Liste des échecs tâche : '
            );
            FOR UO IN CUR_UO_ABSOB(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE) LOOP
                FOR EC IN CUR_MAJ_ECHEC_TACHE(UO.RETURN_VALUE) LOOP
                    FND_FILE.PUT_LINE(FND_FILE.OUTPUT,UO.NAME || '/' || UO.RETURN_VALUE || '/' || EC.TASK_NUMBER);
                    VG_NB_ERROR_TACHE := VG_NB_ERROR_TACHE + 1;
                END LOOP;
            END LOOP;

        END IF;

    END MAJ_PR_CCA;
	 ------------------------------------------------------------------------------------
  --  Nom           : MAIN_MAJ_PR_CCA
  --  Description   : point d'entrée du traitement DKA : Fusion PA ¿ Etape 06 : Mise à jour des projets et tâches pour les CCA sur sinistres
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------

    PROCEDURE MAIN_MAJ_PR_CCA (
        PV_ERRBUF             OUT NOCOPY VARCHAR2,
        PN_RETCODE            OUT NOCOPY NUMBER,
        P_TRANSCODIFICATION   IN VARCHAR2,
        P_CODE_UO_ABSORBE     IN NUMBER,
        P_MODE_SIMULATION     IN VARCHAR2
    ) IS
    BEGIN
        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'DEBUT DU TRAITEMENT');

        FND_FILE.PUT_LINE(FND_FILE.LOG,TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Lancement de la procédure MAIN_MAJ_PR_CCA');

        MAJ_PR_CCA(P_TRANSCODIFICATION,P_CODE_UO_ABSORBE,P_MODE_SIMULATION);
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT, CHR(10) || TO_CHAR(SYSDATE,'DD/MM/YYYY HH24:MI:SS')
                                         || ' - '
                                         || 'Bilan');
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de mises à jour réussi : ' || VG_NBLIGNES_MODIFIES );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de mises à jour de projet en échec : ' || VG_NB_ERROR_PROJET );
        FND_FILE.PUT_LINE(FND_FILE.OUTPUT,'Nombre de mises à jour de tâche en échec : ' || VG_NB_ERROR_TACHE );

    EXCEPTION
        WHEN OTHERS THEN
            PV_ERRBUF    := 'Erreur procedure MAIN_MAJ_PR_CCA'
                         || CHR(10)
                         || SQLERRM;
            PN_RETCODE   := 2;
    END MAIN_MAJ_PR_CCA;

END DKA_FUSION_PA_PKG;
/
SHOW ERRORS;
EXIT;