create or replace PACKAGE BODY DKA_IAPEMPLNOT_PKG AS
  --------------------------------------------------------------------------------
  -- $
  -- Capgemini
  -- Projet           : DALKIA Oracle Applications
  -- Nom              : DKA_IAPEMPLNOT_PKG
  -- Description      : Body du package DKA_IAPEMPLNOT_PKG
  -- Auteur           : F.DOUTRIAUX
  -- Date de création : 23/11/2011
  -- Doc. associée    :
  -- Commentaires     : À exécuter sous SQLPLUS avec l'utilisateur APPS
  --------------------------------------------------------------------------------
  -- Historique
  -- Date       Qui Description
  -- ---------- --- --------------------------------------------------------------
  -- 26/04/2012 JJA Correction suite validation de la recette
  -- 23/05/2012 JJA Demande de modification M1 : superviseur PO
  -- 15/03/2016 MTIA Demande de modification M1 : superviseur AP - OGE 6773
  -- 06/02/2016 YWA artf2095151 Evolution EDB040 Interface des employés vers Notilus
  -- 22/02/2017 YWA artf2105171
  -- 04/07/2017 OBE artf2149317 : INT068 : Exportation des employés vers NOTILUS : Logs du traitement
  -- 25/01/2018 OBE artf2326780 : INT068 - erreur sélection sur les tables PER_ALL_PEOPLE_F
  -- 28/03/2018 OBE artf2423916 : DPE20180016_Extractions des employés pour Notilus - correction critères et centre finance
  -- 09/12/2021 SHA artf07488913 : EDB324 - DPE20210036 - Export des employés vers Notilus
--------------------------------------------------------------------------------

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- CONSTANTES ET VARIABLES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
  -- FONCTIONS ET PROCEDURES PRIVEES
  --++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- SHA - EDB324
  -----------------------------------------------------------------
  --  Nom           : CALCUL_DATE_SITUATION
  --  Description   :PROCEDURE pour calculer la date de situation.
  --
  --  PARAMETRES :

  --   date_situation   OUT NOCOPY DATE
  -----------------------------------------------------------------

  PROCEDURE  CALCUL_DATE_SITUATION( pv_date  in out date) is

  BEGIN

	pv_date := pv_date +( 1-(19/24)); -- Date situation = sysdate - 19H +1 jour

	---  si la date de situation tombe un samedi ou un dimanche alors celle-ci sera égale au lundi
	if TO_CHAR (pv_date, 'D') = 6 then
	    pv_date := pv_date + 2;
	elsif TO_CHAR (pv_date, 'D') = 7 then
	    pv_date := pv_date + 1;

	end if ;
  END;
  ------------------------------------------------------------------------------------
  -- Nom              : Main
  -- Description      : Procédure principale du traitement
  --
  -- PARAMETRES       : Pv_Errbuf         Sortie Message d'erreur
  --                    Pn_Retcode        Sortie Code Retour de la procédure
  --                                             '0' : Normal
  --                                             '1' : Avertissement
  --                                             '2' : Erreur
  --
  -- VALEUR RETOURNEE :
  --     Description       :
  --     Valeurs possibles :
  ------------------------------------------------------------------------------------
  PROCEDURE Main(Pv_Errbuf OUT VARCHAR2, Pn_Retcode OUT NUMBER) IS
    CURSOR cur_empl (p_date_situation date) IS
      SELECT papf.person_id ,
             --pv.segment1,                                        --- RGH : Remplacer le table po_vendors par AP_SUPPLIERS
             aps.segment1,           --CODE_FOURNISSEUR_EMPLOYE
             papf.employee_number,   --MATRICULE
             papf.last_name,         --Nom
             papf.first_name,        --prenom
             paaf.ass_attribute1,    --SOCIETE            --- RGH : renommer le champ Entité à Société
             --haou_name.name,         --Organisation HR  --- RGH : Ajouter Tâche du projet organique -- OBE artf2423916
			 haou_name.name,                                                                    -- OBE artf2423916
             papf.attribute2,        --region
             paaf.ass_attribute5,    --Tâche du projet organique      --- RGH : Ajouter Tâche du projet organique
             replace(pt.description,chr(10),'')description ,--DESCRIPTION_TACHE --YWA artf2095151
             --papf.effective_end_date,--Date fin
             (
             select MAX(effective_end_date)
             from per_all_people_f papf2
             where papf2.PERSON_ID=papf.PERSON_ID
             AND person_type_id='6'             
             ) effective_end_date,
             REPLACE(papf.email_address,';','') email_address, --Adresse mail           --26/04/2012
			 --< OBE artf2326780
             --papf_s.employee_number employee_number_s,         --supérieur hiérarchique --26/04/2012
             (SELECT papf_s.employee_number
              FROM per_all_assignments_f paa,per_all_people_f papf_s
              WHERE papf_s.PERSON_ID=paa.ass_attribute3
              AND paa.PERSON_ID=papf.PERSON_ID
              AND papf_s.person_type_id  in('6','9')
              AND papf_s.effective_start_date =
                         (SELECT MAX(effective_start_date)
                            FROM per_all_people_f papf3
                           WHERE papf3.person_id = papf_s.person_id)
              AND paa.EFFECTIVE_START_DATE = (SELECT MAX (paaf2.EFFECTIVE_START_DATE)
                                 FROM per_all_assignments_f paaf2
                                 WHERE paaf2.PERSON_ID=paa.PERSON_ID)
               ) employee_number_s,
			 --> OBE artf2326780
             dsl.return_value COLLEGE,                         --collège
			 'NON' OPERATIONNEL, -- SHA - EDB324
             papf.attribute10
        FROM per_all_people_f      papf,
             per_all_assignments_f paaf,
             ap_suppliers          aps,
             dka_stransco_headers  dsh,
             dka_stransco_lines    dsl,
             hr_all_organization_units haou_name,
             pa_tasks pt,
             pa_project_classes ppc
			 --< OBE artf2423916
			 /*fnd_flex_values_vl          ffvv,
             fnd_flex_value_sets         ffvs,
	         fnd_flex_values_vl          ffvv2,
             fnd_flex_value_sets         ffvs2*/
			 --> OBE artf2423916
       WHERE 1 = 1

         AND papf.person_id = paaf.person_id
         AND haou_name.organization_id = paaf.ORGANIZATION_ID
         AND Papf.Person_Type_Id in (6, 9)
         AND paaf.effective_end_date =
             (select MAX(effective_end_date)
                from per_all_assignments_f
               where person_id = paaf.person_id
               and effective_start_date<=p_date_situation) --AFE

         AND papf.employee_number = aps.segment1
		 --< OBE artf2326780
         AND papf.effective_start_date =
             (select MAX(effective_start_date)
              from per_all_people_f papf2
              where papf2.person_id = papf.person_id)
		 --> OBE artf2326780
         AND paaf.effective_start_date =
             (select MAX(effective_start_date)
                from per_all_assignments_f paaf2
               where paaf.assignment_id = paaf2.assignment_id
               and effective_start_date<=p_date_situation) --AFE
         AND (papf.attribute10 IS NULL -- Soit l'attribut10 est null (jamais exporté)
             OR papf.attribute10 <
              to_char(papf.last_update_date, 'YYYY/MM/DD HH24:Mi:ss') -- Soit la ligne de l'employé a été modifié après la dernière exportation
             OR Papf.Attribute10 <
             To_Char(Paaf.Last_Update_Date, 'YYYY/MM/DD HH24:Mi:ss') -- Soit l'affectation de l'employé a été modifié
             --OR papf.attribute10 <
            --to_char(ffvt.last_update_date, 'YYYY/MM/DD HH24:Mi:ss') -- Soit la ligne de l'appartenance a été modifié depuis la dernière exportation (la description par exemple)
             OR paaf.effective_end_date = p_date_situation  -- SHA - RG4 l'orsque la date de sortie est égale à la date de situation.
			 OR paaf.effective_start_date = p_date_situation )--- SHA - RG4 ou la date de début d¿affectation ouest égale à la date de situation.
         --2015/10/07
         --COLLEGE
         AND dsh.set_name = 'DKA_EMP_COLLEGE'
         AND dsh.set_id = dsl.set_id
         AND nvl(paaf.ass_attribute4,'NULL') = dsl.param1_value
         --OPERATIONNEL
         --AND haou.name (+) = nvl(papf.attribute3,'#')  --RGH : notion de centre a disparu en R12
         --AND haou.organization_id  = paaf.organization_id --YWA artf2095151
         AND pt.task_number(+) = paaf.ass_attribute5 --YWA artf2095151
         AND ppc.project_id(+) = pt.project_id --YWA artf2095151
         AND ppc.class_category='FILIERE'--YWA artf2095151

         ;
    vn_compteur_ajout NUMBER;
    vn_compteur_refus NUMBER;
    -- fichier de sortie
    Pv_FicOUTptr    UTL_FILE.FILE_TYPE;
    Pv_Dir_out      VARCHAR2(120);
    Pv_Fic_out_name VARCHAR2(80);

    vv_matricule_sup      VARCHAR2(30);
    vv_end_effective_date VARCHAR(10);
    vv_date_situation     DATE;
	vv_date_fin           DATE;
  BEGIN
    Pv_Errbuf  := NULL;
    Pn_Retcode := 0;

    -- Initialisation des compteurs
    vn_compteur_ajout := 0;
    vn_compteur_refus := 0;

    -- Truncate de la table
    EXECUTE IMMEDIATE 'TRUNCATE TABLE DKA.DKA_IAPEMPLNOT_INTERFACE';

    -- Ouverture fichier de sortie
    --Pv_Fic_out_name := 'DALKI_OAAP_NOTI_EM_' ||to_char(SYSDATE, 'YYMMDDHH24MiSS') || '.csv'; --YWA artf2105171
    Pv_Fic_out_name := 'EMPLOYES_' ||to_char(SYSDATE, 'YYYYMMDD') || '.csv'; --YWA artf2105171
    Pv_Dir_out      := 'DKA_OUT_DIR';
    Pv_FicOUTptr    := UTL_FILE.FOPEN(Pv_Dir_out,
                                      Pv_Fic_out_name,
                                      'W',
                                      32764);

    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Log des traitements DKA : Export du référentiel employé vers NOTILUS');
    Dka_Tools_Pkg.Put_Outdebug_Message('    Fichier de sortie : ' ||
                                       Pv_Fic_out_name);
    Dka_Tools_Pkg.Put_Outdebug_Message('    Date et Heure : ' ||
                                       to_char(SYSDATE,
                                               'DD-MON-YYYY HH24:MI:SS'));
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('');

    vv_date_situation := sysdate ;
    CALCUL_DATE_SITUATION( vv_date_situation );

    vv_date_situation :=TRUNC(vv_date_situation);

        dka_tools_pkg.put_debug_message('vv_date_situation : ' ||
                                        vv_date_situation);

    -- Début des traitements
    FOR ligne_empl IN cur_empl (vv_date_situation) LOOP
      BEGIN
        dka_tools_pkg.put_debug_message('Mise à jour de l''employé : ' ||
                                        ligne_empl.employee_number);
        ------------------------------------------------------
        -- Insertion de l'employé dans la table d'interface --
        ------------------------------------------------------
        dka_tools_pkg.put_debug_message('Insertion de l''employé : ' ||
                                        ligne_empl.employee_number ||
                                        ' dans la table d''interface');

        ---------------------------------------------------------
        -- Récuperation du matricule du supérieur hierarchique --
        ---------------------------------------------------------
        /*BEGIN --26/04/2012
          SELECT papf.employee_number
            into vv_matricule_sup
            FROM per_all_people_f papf
           WHERE ligne_empl.ass_attribute3 = papf.person_id
             AND papf.person_type_id <> 9
             AND papf.person_type_id <> 10; -- sauf ancien employés
        EXCEPTION
          WHEN NO_DATA_FOUND THEN
            vv_matricule_sup := null;
            --Pn_Retcode := 1;
          --dka_tools_pkg.put_debug_message('Matricule du supérieur hierarchique non trouvé.');
        END;*/

		--debut SHA - EDB324 --le champ DATE_FIN est renseigné lorsque la date de situation est égale à la date de fin si non on le force à null
    

		IF (vv_date_situation >= ligne_empl.effective_end_date) then
		  vv_date_fin := ligne_empl.effective_end_date;

		ELSE
	      vv_date_fin := NULL;	  
		END IF;

        --fin SHA - EDB324
        INSERT INTO DKA_IAPEMPLNOT_INTERFACE
          (CODE_FOURNISSEUR_EMPLOYE,
           MATRICULE,
           NOM,
           PRENOM,
           SOCIETE,
           CENTRE_FINANCE,
           REGION,
           TACHE_PROJET_ORGANIQUE,
           DESCRIPTION_TACHE,--YWA artf2095151
           DATE_FIN,
           ADRESSE_MAIL,
           SUPERIEUR_HIERARCHIQUE,
           COLLEGE,
           OPERATIONNEL)
        VALUES
          (ligne_empl.segment1,
           ligne_empl.employee_number,
           ligne_empl.last_name,
           ligne_empl.first_name,
           ligne_empl.ass_attribute1,
           ligne_empl.name,
           ligne_empl.attribute2,
           ligne_empl.ass_attribute5,
           ligne_empl.description,--YWA artf2095151
           vv_date_fin ,--SHA - EDB324 -- effective_end_date,
           ligne_empl.email_address,
           ligne_empl.employee_number_s,
           ligne_empl.college,
           ligne_empl.operationnel
           ); --26/04/2012




        -------------------------------------------------------------------
        -- Mise à jour du CUF (ATTRIBUTE10) de la table PER_ALL_PEOPLE_F --
        -------------------------------------------------------------------
        UPDATE per_all_people_f
			-- On ajoute 2 secondes à la date SYSDATE pour ne pas que
			-- la date LAST_UPDATE_DATE (mise à jour via un trigger)
			-- soit strictement supérieure à la date de l'ATTRIBUTE10
           SET attribute10 = to_char(SYSDATE + (2/86400), 'YYYY/MM/DD HH24:Mi:SS')
         WHERE person_id = ligne_empl.person_id;

        -- Insertion de la ligne dans le fichier de sortie
        IF to_char(vv_date_fin , -- SHA -EDB 324ligne_empl.effective_end_date,
		  'YYYY') >= '4712' THEN
          vv_end_effective_date := NULL;
        ELSE
          vv_end_effective_date := to_char(vv_date_fin ,-- SHA -EDB 324 ligne_empl.effective_end_date,
                                            'YYYYMMDD');
                                            --'DD/MM/YYYY');
        END IF;
        UTL_FILE.PUT_LINE(Pv_FicOUTptr,
                          ligne_empl.segment1          || ';' ||
                          ligne_empl.employee_number   || ';' ||
                          ligne_empl.last_name         || ';' ||
                          ligne_empl.first_name        || ';' ||
                          ligne_empl.ass_attribute1    || ';' ||
                          ligne_empl.name              || ';' ||
                          ligne_empl.attribute2        || ';' ||
                          ligne_empl.ass_attribute5    || ';' ||
                          REPLACE(ligne_empl.description,';','')       || ';' ||--YWA artf2095151
                          vv_end_effective_date        || ';' ||
                          ligne_empl.email_address     || ';' ||
                          ligne_empl.employee_number_s || ';' ||
                          ligne_empl.college           || ';' ||
                          ligne_empl.operationnel);

        -- Mise à jour du compteur
        vn_compteur_ajout := vn_compteur_ajout + 1;
        dka_tools_pkg.put_debug_message('Ajout de la ligne EMPLOYEE_NUMBER : ' ||
                                        ligne_empl.employee_number);
        --dka_tools_pkg.put_debug_message('Ajout de la ligne EMPLOYEE_NUMBER : ' ||     -- OBE artf2149317
        --                                ligne_empl.employee_number);                  -- OBE artf2149317
      EXCEPTION
        WHEN OTHERS THEN
          vn_compteur_refus := vn_compteur_refus + 1;
          dka_tools_pkg.put_debug_message('Erreur sur la ligne EMPLOYEE_NUMBER : ' ||
                                          ligne_empl.employee_number);
          --dka_tools_pkg.put_debug_message('Erreur sur la ligne EMPLOYEE_NUMBER : ' || -- OBE artf2149317
          --                                ligne_empl.employee_number);                -- OBE artf2149317
          dka_tools_pkg.put_debug_message('--> Code erreur ' || SQLCODE ||
                                          ' - ' || SQLERRM);
          Pn_Retcode := 1;
      END;

    END LOOP;
    -- Log du nombre d'enregistrements
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre de mises à jour : ' ||
                                       vn_compteur_ajout);
    Dka_Tools_Pkg.Put_Outdebug_Message('Nombre d''echecs        : ' ||
                                       vn_compteur_refus);
    Dka_Tools_Pkg.Put_Outdebug_Message('');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('Fin des logs de traitements DKA : Export du référentiel employé vers NOTILUS');
    Dka_Tools_Pkg.Put_Outdebug_Message('----------------------------------------------------------------------------');
    Dka_Tools_Pkg.Put_Outdebug_Message('');
    COMMIT;
  EXCEPTION
    WHEN OTHERS THEN
      ROLLBACK;
      Pv_Errbuf  := 'Erreur dans la procécure Main : ' || SQLCODE || '-' ||
                    Substr(SQLERRM, 1, 80);
      Pn_Retcode := 2;

      Dka_Tools_Pkg.Put_Outdebug_Message(' ');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message('=> TRAITEMENT TERMINE EN ERREUR');
      Dka_Tools_Pkg.Put_Outdebug_Message('++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++');
      Dka_Tools_Pkg.Put_Outdebug_Message(Pv_Errbuf);
  END Main;

END DKA_IAPEMPLNOT_PKG;


/
show error;
exit;