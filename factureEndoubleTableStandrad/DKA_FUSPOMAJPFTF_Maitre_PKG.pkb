CREATE OR REPLACE PACKAGE BODY DKA_CGA_AUTO_PKG AS
------------------------------------------------------------------------------------------
-- $$
-- CAPGEMINI
-- PROJET            : DALKIA Oracle Applications
-- NOM               : dka_CGA_AUTO_pkg.pkb
-- DESCRIPTION       : dka_CGA_AUTO_pkg package body :
--
-- AUTEUR           : CAPGEMINI
-- DATE DE CREATION : 16/10/2019
-- COMMENTAIRE      : 
------------------------------------------------------------------------------------------
-- HISTORIQUE DES MODIFICATIONS
-- Date       Qui Description
-- ---------- --- ------------------------------------------------------------------------
-- 16/10/2019 SCH CREATION Automatisation 
------------------------------------------------------------------------------------------

PROCEDURE AUTO_CGA(pv_errbuf             IN OUT VARCHAR2,
                   pn_retcode            IN OUT NUMBER,
				   P_ORG_ID 			 IN 	NUMBER) IS

  Vn_User_Id       Fnd_User.User_Id%TYPE;
  Vn_Doc_Id_1      Fnd_Documents_vl.Document_Id%TYPE;
  Vn_Doc_Id_2      Fnd_Documents_vl.Document_Id%TYPE;
  Vn_med_Id_1      Fnd_Documents_vl.Media_Id%TYPE;
  Vn_med_Id_2      Fnd_Documents_vl.Media_Id%TYPE;
  Vn_Category_Id   Fnd_Document_Categories_Tl.Category_Id%TYPE;
  Vn_Datatype_Id   Fnd_Document_Datatypes.Datatype_Id%TYPE;
  V_Is_attached    varchar2(1);
  P_Org_name       varchar2(25);

  CURSOR cur_operating_unit IS
    	select hou.name,hou.organization_id,l.language_code 
		from hr_operating_units hou, fnd_languages l 
		where (language_code IN ('F', 'US')) 
		  and (not exists 	( select org_id from DKA_SPOBON_ANNEXE where 	org_id=hou.organization_id)) 
		  and hou.organization_id = P_ORG_ID;
	
  
BEGIN

  V_Is_attached:='N';
  select name into P_Org_name
    from hr_operating_units
   where Organization_id=P_ORG_ID;
--------------------------
  -- Recherche du user_id --
  --------------------------
  SELECT Fu.User_Id
  INTO   Vn_User_Id
  FROM   Fnd_User Fu
  WHERE  Fu.User_Name = 'EXPLOITATION';

	Fnd_File.put_line (Fnd_File.LOG, 'Vn_User_Id : ' || Vn_User_Id);

  -----------------------------------------------------------------------
  -- Recherche de la categorie de document 'BON DE COMMANDE : ANNEXES' --
  -----------------------------------------------------------------------
  SELECT DISTINCT Fdct.Category_Id
  INTO   Vn_Category_Id
  FROM   Fnd_Document_Categories_Tl Fdct
  WHERE  Fdct.User_Name = 'BON DE COMMANDE : ANNEXES';
  
	Fnd_File.put_line (Fnd_File.LOG, 'Vn_Category_Id : ' || Vn_Category_Id);
  
  ------------------------------
  -- Recherche du Datatype_Id --
  ------------------------------    
  SELECT DISTINCT Datatype_Id
  INTO   Vn_Datatype_Id
  FROM   Fnd_Document_Datatypes
  WHERE  Name = 'LONG_TEXT';

	Fnd_File.put_line (Fnd_File.LOG, 'Datatype_Id : ' || Vn_Datatype_Id);

  ---------------------------------------------
  -- Recherche du Document_Id et du Media_id --
  ---------------------------------------------
  SELECT document_id, media_id 
  INTO   Vn_Doc_Id_1, Vn_med_Id_1
  FROM   Fnd_Documents_vl
  WHERE  description = 'DKA : CONDITIONS GENERALES ACHATS - Partie 01';
  
	Fnd_File.put_line (Fnd_File.LOG, 'Vn_Doc_Id_1 : ' || Vn_Doc_Id_1);
	Fnd_File.put_line (Fnd_File.LOG, 'Vn_med_Id_1 : ' || Vn_med_Id_1);

  SELECT document_id, media_id 
  INTO   Vn_Doc_Id_2, Vn_med_Id_2
  FROM   Fnd_Documents_vl
  WHERE  description = 'DKA : CONDITIONS GENERALES ACHATS - Partie 02';
  
	Fnd_File.put_line (Fnd_File.LOG, 'Vn_Doc_Id_2 : ' || Vn_Doc_Id_2);
	Fnd_File.put_line (Fnd_File.LOG, 'Vn_med_Id_2 : ' || Vn_med_Id_2);
  
  FOR rec_operating_unit IN cur_operating_unit LOOP
  
    ---------------------------------------------------------------------------
    -- Insertion du document 'DKA : CONDITIONS GENERALES ACHATS - Partie 01' --
    ---------------------------------------------------------------------------
    INSERT INTO DKA_SPOBON_ANNEXE
      VALUES (
        rec_operating_unit.organization_id,
        rec_operating_unit.language_code,
        Vn_Doc_Id_1,
        'DKA : CONDITIONS GENERALES ACHATS - Partie 01',
        Vn_Datatype_Id,
        Vn_med_Id_1,
        SYSDATE,
        -1,
        SYSDATE,
        -1
        );

    ---------------------------------------------------------------------------
    -- Insertion du document 'DKA : CONDITIONS GENERALES ACHATS - Partie 02' --
    ---------------------------------------------------------------------------
    INSERT INTO DKA_SPOBON_ANNEXE
      VALUES ( 
        rec_operating_unit.organization_id,
        rec_operating_unit.language_code,
        Vn_Doc_Id_2,
        'DKA : CONDITIONS GENERALES ACHATS - Partie 02',
        Vn_Datatype_Id,
        Vn_med_Id_2,
        SYSDATE,
        -1,
        SYSDATE,
        -1
        );
		V_Is_attached:='Y';
  END LOOP;
  
  IF V_Is_attached = 'N' then
	Fnd_File.put_line (Fnd_File.OUTPUT, 'Les conditions générales d''achat sont déjà attachées sur l''unité opérationnelle: ' || P_Org_name);
	Pn_Retcode := 1;
  else
	Fnd_File.put_line (Fnd_File.OUTPUT, 'Les conditions générales d''achat ont bien été attachées sur l''unité opérationnelle: ' || P_Org_name);
  END if;
	COMMIT;
	
 EXCEPTION
 WHEN OTHERS THEN
            Pv_Errbuf  := ' AUTO_CGA - ERREUR : ' || SQLERRM;
			Pn_Retcode := 1;
END AUTO_CGA;

END DKA_CGA_AUTO_PKG;
/
SHOW ERRORS
EXIT