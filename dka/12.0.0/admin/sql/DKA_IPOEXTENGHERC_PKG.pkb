create or replace PACKAGE BODY DKA_IPOEXTENGHERC_PKG
AS
------------------------------------------------------------------------------------
-- $Id: DKA_IPOEXTENGHERC_PKG.pkb
-- Capgemini
-- PROJET            : Helios
-- NOM               : DKA_IPOEXTENGHERC_PKG.pkb
-- DESCRIPTION       : KA_IPOEXTENGHERC_PKG package body créé pour l'interface DKA : Extraction des engagés vers Hercule
---
--- AUTEUR           : F.Siham (Capgemini)
--- DATE DE CREATION : 21/05/2019
--- DOC. ASSOCIEE    :
--  COMMENTAIRE      : A exécuter sous SQLPLUS avec le user APPS
------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -----------------------------------------------------------------
--- 21/05/2019 FSI Création
--- 12/08/2019 OCL Modification extraction FINHER_MO + correctif champ DESCRIPTION_DA
--- 12/09/2019 CDE INC0346775 - ajout type de dépense MAIN D'OEUVRE HORS THO VA
--- 20/05/2020 SEL EDB266 - PFAD
--- 10/12/2020 CDE Report Correctif pour pb double quotes - EDB248B
--- 16/02/2021 ARA DALKIA / INT084 - Report de l'évolution EDB248B sur la version du composant pour PFAD EDB266
--- 08/04/2021 ARA Evolution EDB248C
--- 10/04/2021 SHA Evolution EDB248B
--- 10/09/2021 SHA Evolution EDB248E
--- 04/07/2022 IBA Evolution EDB342
------------------------------------------------------------------------------------


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- CONSTANTES ET VARIABLES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

--EXCEPTIONS
  E_FATAL_ERROR EXCEPTION;
  PRAGMA EXCEPTION_INIT(E_FATAL_ERROR, -20012);
  K_FATAL_ERROR_NUM CONSTANT NUMBER := -20012;

  --CONSTANTE
  vg_package_name CONSTANT VARCHAR2(30) := 'DKA_IPOEXTENGHERC_PKG';
  vg_SEPARATOR     CONSTANT VARCHAR2(2) := ';';
  vg_DIRECTORY     CONSTANT ALL_DIRECTORIES.directory_name%TYPE := 'DKA_OUT_DIR';
  vg_nbl_extr_cmd  number:=0;
  vg_nbl_extr_fact  number:=0;
  vg_nbl_extr_maind  number:=0;
  vg_nbl_extr_refac  number:=0;
  vg_directory_path  varchar2(100);
  vg_request_id_cf  number;


--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++
-- FONCTIONS ET PROCEDURES PRIVEES
--++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++++

------------------------------------------------------------------------------------
  --  Nom           : p_put_debug_message
  --  Description   : Ecrit dans le journal du traitement
  --
  --  PARAMETRES    : Message à afficher dans le journal
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_put_debug_message(p_message IN VARCHAR2) IS

  BEGIN

    dka_tools_pkg.put_log_message(p_message);

  END p_put_debug_message;

  ------------------------------------------------------------------------------------
  --  Nom           : p_validate
  --  Description   :
  --
  --  PARAMETRES    : p_condition: Si FALSE => Affiche un message dans le journal et
  --                                           genere une erreur fatale
  --                               Si TRUE  => Fait aucune action
  --                  p_message:   Message a afficher dans le journal
  ------------------------------------------------------------------------------------
  PROCEDURE p_validate(p_condition IN BOOLEAN,
                       p_message   IN VARCHAR2 DEFAULT NULL) IS
  BEGIN

    IF NOT p_condition THEN
      IF p_message IS NOT NULL THEN
        p_put_debug_message(p_message);
      END IF;

      RAISE_APPLICATION_ERROR(K_FATAL_ERROR_NUM,
                              nvl(p_message, 'Erreur fatale : '));

    END IF;

  END p_validate;

  ------------------------------------------------------------------------------------
  --  Nom           : p_check_directory
  --  Description   : Verifie que le directory existe
  --
  --  PARAMETRES    :
  --  p_directory_name          nom du directory
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_check_directory(p_directory_name in ALL_DIRECTORIES.directory_name%type) IS

    CURSOR cur_directory(p_directory_name IN ALL_DIRECTORIES.directory_name%type) IS
      SELECT owner, directory_name, directory_path
        FROM all_directories
       WHERE directory_name = p_directory_name;
    l_dir cur_directory%ROWTYPE;

  BEGIN


    OPEN cur_directory(p_directory_name);
    FETCH cur_directory
      INTO l_dir;

       p_put_debug_message('vérification du répertoire:  ' || p_directory_name ||
                        ' -> ' || l_dir.directory_path);

         vg_directory_path:=l_dir.directory_path;
    IF cur_directory%NOTFOUND THEN
      CLOSE cur_directory;
      p_validate(FALSE,
                 'Le directory ' || p_directory_name || ' n''existe pas.');
    END IF;


    CLOSE cur_directory;



  END p_check_directory;

  ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_cmd
  --  Description   : Extrait des lignes de ventilations de commandes
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  -- 12/08/2019 correctif champ DESCRIPTION_DA
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_cmd(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2,
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    l_file        UTL_FILE.file_type;
	ln_lIEN_CMD   VARCHAR2(4000); --IBA
    ln_file_id    number; -- 28/08/25 CGI

	 /*//-- cursor pour extraction des lignes de ventilations de commandes//*/

    CURSOR cur_data IS

		WITH TASK AS (
		SELECT
			PT.TASK_ID,
			PT.TASK_NUMBER
		FROM
			PA.PA_TASKS PT
		WHERE
			PT.TASK_NUMBER LIKE 'GT%'
			OR PT.TASK_NUMBER LIKE 'GX%'
			OR PT.TASK_NUMBER LIKE 'GY%'
			AND ( PT.COMPLETION_DATE IS NULL
				  OR TRUNC(PT.COMPLETION_DATE + 180) >= TRUNC(SYSDATE))
	                  )
		SELECT
			'"'
			|| PO_DISTRIBUTION_ID
			||'"'||vg_SEPARATOR||'"'
			|| UO
			||'"'||vg_SEPARATOR||'"'
			|| TASK_NUMBER
			||'"'||vg_SEPARATOR||'"'
			|| to_char(to_date(CREATION_DATE,'dd/mm/yy'),'DD/MM/YYYY')  -- selo - EDB266
			||'"'||vg_SEPARATOR||'"'
			|| EXPENDITURE_TYPE
			||'"'||vg_SEPARATOR||'"'
			|| NUM_DA
			||'"'||vg_SEPARATOR||'"'
			|| replace (NVL(DESCRIPTION_DA,''),'"','""')
			||'"'||vg_SEPARATOR||'"'
			|| NUM_CDE
			||'"'||vg_SEPARATOR||'"'
			|| REVISION_NUM
			||'"'||vg_SEPARATOR||'"'
			|| LINE_NUMBER
			||'"'||vg_SEPARATOR||'"'
			|| replace (VENDOR_NAME,'"','""')
			||'"'||vg_SEPARATOR||'"'
			|| ITEM_CATEGORY
			||'"'||vg_SEPARATOR||'"'
			|| NVL(ITEM,'')
			||'"'||vg_SEPARATOR||'"'
			|| replace (ITEM_DESCRIPTION,'"','""')
			||'"'||vg_SEPARATOR||'"'
			|| CURRENCY_CODE
			||'"'||vg_SEPARATOR||'"'
			|| replace (replace (to_number (UNIT_PRICE),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
			|| UOM
			||'"'||vg_SEPARATOR||'"'
            || replace (replace (to_number (QUANTITY_ORDERED),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
            || replace (replace (to_number (QUANTITY_CANCELLED),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
            || replace (replace (to_number (QUANTITY_DELIVERED),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
            || replace (replace (to_number (QUANTITY_BILLED),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
			|| CANCEL_FLAG
			||'"'||vg_SEPARATOR||'"'
			|| LINE_STATUS
			|| '"' AS LIGNE
			--- iBA
			,ATTRIBUTE7
			,PO_HEADER_ID
			--- IBA
		FROM
			  (
		SELECT
			PDA.PO_DISTRIBUTION_ID      PO_DISTRIBUTION_ID,
			HAOU.NAME                   UO,
			TASK.TASK_NUMBER            TASK_NUMBER,
			decode(PHA.ATTRIBUTE7, 'IVALUA', decode(PHA.ATTRIBUTE11, null,null,to_date(PHA.ATTRIBUTE11,'dd/mm/yyyy hh24:mi:ss')) ,to_char(PHA.CREATION_DATE,'dd/mm/YY')) CREATION_DATE, -- selo - EDB266
			PDA.EXPENDITURE_TYPE        EXPENDITURE_TYPE,
			decode(PHA.ATTRIBUTE7, 'IVALUA', substr(PDA.ATTRIBUTE1,1,instr(PDA.ATTRIBUTE1,'-')-1),PRHA.SEGMENT1)               NUM_DA, -- selo - EDB266
			decode(PHA.ATTRIBUTE7,
                   'IVALUA',
                   REPLACE(REPLACE(REPLACE(REPLACE(PDA.ATTRIBUTE2,CHR(9),' '),CHR(10),' '),CHR(13),' '),CHR(34),' '),
                   REPLACE(REPLACE(REPLACE(REPLACE(PRHA.DESCRIPTION,CHR(9),' '),CHR(10),' '),CHR(13),' '),CHR(34),' ')
			)DESCRIPTION_DA, -- selo - EDB266
			PHA.SEGMENT1                NUM_CDE,
			decode(PHA.ATTRIBUTE7, 'IVALUA', PHA.ATTRIBUTE10,PHA.REVISION_NUM )           REVISION_NUM, -- selo - EDB266
			PLA.LINE_NUM
			|| '.'
			   || PLLA.SHIPMENT_NUM
				  || '.'
					 || PDA.DISTRIBUTION_NUM LINE_NUMBER,
			ASU.VENDOR_NAME             VENDOR_NAME,
			decode(PHA.ATTRIBUTE7, 'IVALUA', PLA.ATTRIBUTE5, MCK.CONCATENATED_SEGMENTS )  ITEM_CATEGORY, -- selo - EDB266
			decode(PHA.ATTRIBUTE7, 'IVALUA', PLA.ATTRIBUTE4, NULL) ITEM,  -- selo - EDB266
			REPLACE(REPLACE(REPLACE(REPLACE(PLA.ITEM_DESCRIPTION,CHR(9),' '),CHR(10),' '),CHR(13),' '),CHR(34),' ') ITEM_DESCRIPTION,
			PHA.CURRENCY_CODE           CURRENCY_CODE,
			PLA.UNIT_PRICE  UNIT_PRICE,
			PLA.UNIT_MEAS_LOOKUP_CODE   UOM,
			PDA.QUANTITY_ORDERED        QUANTITY_ORDERED,
			PDA.QUANTITY_CANCELLED      QUANTITY_CANCELLED,
			PDA.QUANTITY_DELIVERED      QUANTITY_DELIVERED,
			PDA.QUANTITY_BILLED         QUANTITY_BILLED,
			PHA.CANCEL_FLAG             CANCEL_FLAG,
			decode(PHA.CANCEL_FLAG,
					'Y',
					'CANCELLED',
						decode(nvl(PHA.CLOSED_CODE,'OPEN'),
						'OPEN',
						decode(PLLA.CANCEL_FLAG,
							   'Y',
							   'CANCELLED',
							   decode(nvl(PLLA.CLOSED_CODE,'OPEN'),
									  'OPEN',
									  'OPEN',
									  'CLOSED FOR RECEIVING',
									  'CLOSED FOR RECEIVING',
									  'CLOSED FOR INVOICE',
									  'CLOSED FOR INVOICE',
									  'CLOSED',
									  'CLOSED',
									  'FINALLY CLOSED',
									  'FINALLY CLOSED'
							         )
						      ),
						'CLOSED',
						'CLOSED',
						'FINALLY CLOSED',
						'FINALLY CLOSED'
						)
					) LINE_STATUS -- EDB248B ARA
					, --<DEBUT IBA EDB342
					  case when PHA.ATTRIBUTE7 like '%IVALUA%' then
					 'IVALUA'
					 else 'NONIVALUA'
					 end ATTRIBUTE7,
					 PDA.PO_HEADER_ID PO_HEADER_ID
--IBA FIN>
		FROM
			PO.PO_DISTRIBUTIONS_ALL PDA
			INNER JOIN TASK ON TASK.TASK_ID = PDA.TASK_ID
			INNER JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU ON HAOU.ORGANIZATION_ID = PDA.ORG_ID
			INNER JOIN PO.PO_LINE_LOCATIONS_ALL PLLA ON PLLA.LINE_LOCATION_ID = PDA.LINE_LOCATION_ID
			INNER JOIN PO.PO_LINES_ALL PLA ON PLA.PO_LINE_ID = PDA.PO_LINE_ID
			INNER JOIN PO.PO_HEADERS_ALL PHA ON PHA.PO_HEADER_ID = PDA.PO_HEADER_ID
			INNER JOIN AP.AP_SUPPLIERS ASU ON ASU.VENDOR_ID = PHA.VENDOR_ID
			 LEFT JOIN PO.PO_REQUISITION_LINES_ALL PRLA ON PRLA.LINE_LOCATION_ID = PLLA.LINE_LOCATION_ID
			 LEFT JOIN PO.PO_REQUISITION_HEADERS_ALL PRHA ON PRHA.REQUISITION_HEADER_ID = PRLA.REQUISITION_HEADER_ID
			INNER JOIN APPS.MTL_CATEGORIES_B_KFV MCK ON (MCK.CATEGORY_ID = PLA.CATEGORY_ID
														  AND MCK.STRUCTURE_ID = (select  ID_FLEX_NUM from FND_ID_FLEX_STRUCTURES_VL where ID_FLEX_STRUCTURE_NAME ='Catégorie Article PO'))
		WHERE
			PHA.AUTHORIZATION_STATUS NOT IN (
				--'CANCELLED', -- EDB248B ARA
				'REJECTED'
			)
			-- and PHA.CANCEL_FLAG not like 'Y' -- EDB248B ARA -- Chargement initial
			AND PLLA.LAST_UPDATE_DATE BETWEEN to_date(P_DATE_DEBUT,'DD/MM/YYYY') AND  to_date(P_DATE_FIN,'DD/MM/YYYY')
			AND PDA.ORG_ID IN (
                 SELECT
                     ORGANIZATION_ID
                 FROM
                     PER_SECURITY_ORGANIZATIONS
                 WHERE
                     SECURITY_PROFILE_ID = (
                         SELECT
                             SECURITY_PROFILE_ID
                         FROM
                             PER_SECURITY_PROFILES
                         WHERE
                             SECURITY_PROFILE_NAME = 'DKA_TOUT'
                                           )
                                  )
		ORDER BY
			2,
			3,
			7);
    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;

    --ln_step PLS_INTEGER := 10000;

  BEGIN

    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);

    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;



  --création de l'entête
     utl_file.put_line(l_file,'"DISTRIBUTION_ID";"UO";"TASK_NUMBER";"CREATION_DATE";"EXPENDITURE_TYPE";"NUM_DA";"DESCRIPTION_DA";"NUM_CDE";"REVISION_NUM";"LINE_NUMBER";"VENDOR_NAME";"ITEM_CATEGORY";"ITEM";"ITEM_DESCRIPTION";"CURRENCY_CODE";"UNIT_PRICE";"UOM";"QUANTITY_ORDERED";"QUANTITY_CANCELLED";"QUANTITY_DELIVERED";"QUANTITY_BILLED";"CANCEL_FLAG";"LINE_STATUS";"LIEN_CMD"'); --EDB342_LIEN_CMD -- EDB248B_LINE_STATUS
  -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT INTO lt_cur_data;

     ln_lIEN_CMD :=NULL;  --IBA

      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP

-------------------------IBA . CGI 28/08/2025 : refait avec fnd_gfm
	  begin
	  if lt_cur_data(i).ATTRIBUTE7 = 'IVALUA' then
/*	  select fd.url
     into ln_lIEN_CMD
      from fnd_attached_documents fad,fnd_documents          fd,fnd_documents_tl       fdt
            where fad.pk1_value = to_char(lt_cur_data(i).PO_HEADER_ID)
            and fad.document_id = fd.document_id
            and fd.document_id = fdt.document_id
            and fdt.language = 'F'
            and fdt.description = 'BON DE COMMANDE'
             and rownum = 1
            order by fad.CREATION_DATE asc;
	  else
	select (SELECT replace(home_url,'AppsLogin','') ||'fndgfm.jsp?mode=download_blob'  FROM icx_parameters)||
       chr(38) || 'fid=' || fl.file_id || chr(38) || 'accessid=' ||
       fla.access_id
	   into ln_lIEN_CMD
  from
       fnd_attached_documents fad,
       fnd_documents          fd,
       fnd_documents_tl       fdt,
       fnd_lobs               fl,
       fnd_lob_access         fla
where fad.pk1_value = to_char(lt_cur_data(i).PO_HEADER_ID)
   and fad.document_id = fd.document_id
   and fd.document_id = fdt.document_id
   and fd.media_id = fL.file_id
   and fla.file_id = fl.file_id
   and fdt.language = 'F'
   and fdt.description = 'BON DE COMMANDE'
   and fla.timestamp = (select max(timestamp)
                          from fnd_lob_access
                         where file_id = fl.file_id)
    and rownum = 1
    order by fad.CREATION_DATE asc;*/

	select  fl.file_id 
	   into ln_file_id
  from
       fnd_attached_documents fad,
       fnd_documents          fd,
       fnd_documents_tl       fdt,
       fnd_lobs               fl,
       fnd_lob_access         fla
where fad.pk1_value = to_char(lt_cur_data(i).PO_HEADER_ID)
   and fad.document_id = fd.document_id
   and fd.document_id = fdt.document_id
   and fd.media_id = fL.file_id
   and fla.file_id = fl.file_id
   and fdt.language = 'F'
   and fdt.description = 'BON DE COMMANDE'
   and fla.timestamp = (select max(timestamp)
                          from fnd_lob_access
                         where file_id = fl.file_id)
    and rownum = 1
    order by fad.CREATION_DATE asc;

    ln_lIEN_CMD := fnd_gfm.construct_download_url(gfm_agent     => fnd_web_config.gfm_agent,
                                file_id       => ln_file_id,
                                --purge_on_view boolean default FALSE,
                                --modplsql      boolean default FALSE,
                                authenticate  =>false --,
                                --user_name     => 'DKAEXPLOIT'
                                --lifespan      number  default NULL
                                );

	  end if;
	   EXCEPTION
        when no_data_found then
	ln_lIEN_CMD := null;
    WHEN OTHERS THEN
         p_validate(FALSE, 'ERREUR po_header_id'||lt_cur_data(i).PO_HEADER_ID||'ATTRIBUTE7 '||lt_cur_data(i).ATTRIBUTE7||'('|| SQLERRM||')');
	  end;
	  -------------------------IBA . CGI 28/08/2025 : refait avec fnd_gfm
            BEGIN
              vv_ligne :=lt_cur_data(i).LIGNE||vg_SEPARATOR||'"'||ln_lIEN_CMD||'"';

              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne); --IBA

              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;

            EXCEPTION
              WHEN OTHERS THEN
                p_put_debug_message('ERREUR ' ||lt_cur_data(i).LIGNE||vg_SEPARATOR||'"'||ln_lIEN_CMD||'"'||' - '  || SQLERRM); --IBA
            END;

        END LOOP;


      END IF;

      EXIT WHEN cur_data%NOTFOUND;

    END LOOP;
    CLOSE cur_data;


    --  COMMIT;
    -- Fermeture du fichier
      UTL_FILE.FCLOSE(l_file);

      -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_cmd      := vn_nb_lignes;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_cmd);
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE, 'Probleme dans la procedure p_extract_data_cmd (' || SQLERRM || ')');

  END p_extract_data_cmd;

   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_inv
  --  Description   : Extrait des lignes de ventilations des factures
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  PROCEDURE p_extract_data_inv(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2,
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    l_file        UTL_FILE.file_type;
    ln_LIEN_FACTURE  VARCHAR2(4000); --IBA
    ln_file_id  number; -- 28/08/2025 CGI
	 /*//-- cursor pour extraction des lignes de ventilations des factures//*/

    CURSOR cur_data IS

		WITH TASK AS (
    SELECT
        PT.TASK_ID,
        PT.TASK_NUMBER
    FROM
        PA.PA_TASKS PT
    WHERE
        PT.TASK_NUMBER LIKE 'GT%'
        OR PT.TASK_NUMBER LIKE 'GX%'
		OR PT.TASK_NUMBER LIKE 'GY%'
        AND ( PT.COMPLETION_DATE IS NULL
              OR TRUNC(PT.COMPLETION_DATE + 180) >= TRUNC(SYSDATE))
)
SELECT
    '"'
    || PO_DISTRIBUTION_ID
    ||'"'||vg_SEPARATOR||'"'
    || UO
    ||'"'||vg_SEPARATOR||'"'
    || TASK_NUMBER
    ||'"'||vg_SEPARATOR||'"'
    || to_char (INVOICE_DATE,'DD/MM/YYYY')
    ||'"'||vg_SEPARATOR||'"'
    || EXPENDITURE_TYPE
    ||'"'||vg_SEPARATOR||'"'
    || INVOICE_NUM
    ||'"'||vg_SEPARATOR||'"'
    || INVOICE_LINE
    ||'"'||vg_SEPARATOR||'"'
    || replace (VENDOR_NAME,'"','""')
    ||'"'||vg_SEPARATOR||'"'
    || replace (DESCRIPTION,'"','""')
    ||'"'||vg_SEPARATOR||'"'
    || CURRENCY_CODE
    ||'"'||vg_SEPARATOR||'"'
    || replace (replace (to_number (QUANTITY_INVOICED),'.',','),'-,','-0,')
    ||'"'||vg_SEPARATOR||'"'
    || replace (replace (to_number (ACCOUNTED_AMOUNT),'.',','),'-,','-0,')
    ||'"'||vg_SEPARATOR||'"'
    || replace (replace (to_number (UNACCOUNTED_AMOUNT),'.',','),'-,','-0,')
    ||'"'||vg_SEPARATOR||'"'
    || REVERSAL_FLAG
    || '"' AS LIGNE,
	invoice_id
FROM
    (
        SELECT
            AIDA.PO_DISTRIBUTION_ID     PO_DISTRIBUTION_ID,
            HAOU.NAME                   UO,
            TASK.TASK_NUMBER            TASK_NUMBER,
            AIA.INVOICE_DATE            INVOICE_DATE,
            AIDA.EXPENDITURE_TYPE       EXPENDITURE_TYPE,
            AIA.INVOICE_NUM             INVOICE_NUM,
            AIDA.INVOICE_LINE_NUMBER
            || '.'
            || AIDA.DISTRIBUTION_LINE_NUMBER INVOICE_LINE,
            ASU.VENDOR_NAME             VENDOR_NAME,
            REPLACE(REPLACE(REPLACE(REPLACE(AIDA.DESCRIPTION,CHR(9),' '),CHR(10),' '),CHR(13),' '),CHR(34),' ') DESCRIPTION
           ,
            AIA.INVOICE_CURRENCY_CODE   CURRENCY_CODE,
            AIDA.QUANTITY_INVOICED      QUANTITY_INVOICED,
            DECODE(AIDA.POSTED_FLAG,'Y',1,0) * AIDA.AMOUNT  ACCOUNTED_AMOUNT,
            DECODE(AIDA.POSTED_FLAG,'Y',0,1) * AIDA.AMOUNT  UNACCOUNTED_AMOUNT,
            AIDA.REVERSAL_FLAG          REVERSAL_FLAG,
			--<Debut IBA EDB342
			aida.invoice_id invoice_id
			--IBA EDB342 FIN >
        FROM
            AP.AP_INVOICE_DISTRIBUTIONS_ALL AIDA
            INNER JOIN TASK ON TASK.TASK_ID = AIDA.TASK_ID
            INNER JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU ON HAOU.ORGANIZATION_ID = AIDA.ORG_ID
            INNER JOIN AP.AP_INVOICES_ALL AIA ON AIA.INVOICE_ID = AIDA.INVOICE_ID
            INNER JOIN AP.AP_SUPPLIERS ASU ON ASU.VENDOR_ID = AIA.VENDOR_ID
			INNER JOIN GL.GL_CODE_COMBINATIONS GCC ON AIDA.DIST_CODE_COMBINATION_ID = GCC.CODE_COMBINATION_ID
        WHERE
            AIDA.LINE_TYPE_LOOKUP_CODE NOT IN (
                'PREPAY',
                'TAX',
                'REC_TAX',
                'NONREC_TAX'
            )
            AND AIDA.AMOUNT <> 0
            AND AIA.INVOICE_TYPE_LOOKUP_CODE NOT IN (
                'EXPENSE REPORT',
                'PREPAYMENT'
            )
            AND ASU.VENDOR_TYPE_LOOKUP_CODE <> 'EMPLOYEE'
            --  and nvl(AIDA.REVERSAL_FLAG,'N') <> 'Y'  -- pour initialisation
            AND ( AIDA.LAST_UPDATE_DATE BETWEEN to_date(P_DATE_DEBUT,'DD/MM/YYYY') AND  to_date(P_DATE_FIN,'DD/MM/YYYY')
                  OR AIA.LAST_UPDATE_DATE BETWEEN to_date(P_DATE_DEBUT,'DD/MM/YYYY') AND  to_date(P_DATE_FIN,'DD/MM/YYYY'))
			AND AIDA.ORG_ID IN (
                 SELECT
                     ORGANIZATION_ID
                 FROM
                     PER_SECURITY_ORGANIZATIONS
                 WHERE
                     SECURITY_PROFILE_ID = (
                         SELECT
                             SECURITY_PROFILE_ID
                         FROM
                             PER_SECURITY_PROFILES
                         WHERE
                             SECURITY_PROFILE_NAME = 'DKA_TOUT'
                                           )
                                  )
			-- SHA EDB248E
			AND EXISTS (SELECT  ffvv.flex_value
                     FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                    WHERE ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE'
                      AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                      AND ffvv.enabled_flag = 'Y'
                      AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND
                          NVL(ffvv.end_date_active, SYSDATE)
                     and ffvv.flex_value = GCC.segment4

                     and NVL(attribute11,'NN') != 'NON' )
        ORDER BY
            1,
            2,
            6
    );

    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;

    --ln_step PLS_INTEGER := 10000;

  BEGIN

    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);

    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;

     --création de l'entête
     utl_file.put_line(l_file,'"DISTRIBUTION_ID";"UO";"TASK_NUMBER";"INVOICE_DATE";"EXPENDITURE_TYPE";"INVOICE_NUM";"INVOICE_LINE";"VENDOR_NAME";"DESCRIPTION";"CURRENCY_CODE";"QUANTITY_INVOICED";"ACCOUNTED_AMOUNT";"UNACCOUNTED_AMOUNT";"REVERSAL_FLAG";"LIEN_FACTURE"'); --EDB342_LIEN_FACTURE
    -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT INTO lt_cur_data;

      ln_LIEN_FACTURE :=NULL; --IBA

      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP
 -------------------------<DEBUT IBA EDB342
 --- CGI 28/08/2023 refait avec fnd_gfm
BEGIN
/*		select
       (SELECT replace(home_url,'AppsLogin','') ||'fndgfm.jsp?mode=download_blob'  FROM icx_parameters) ||
       chr(38) || 'fid=' || fl.file_id || chr(38) || 'accessid=' ||
       fla.access_id
	   into ln_LIEN_FACTURE
  from
       fnd_attached_documents fad,
       fnd_documents          fd,
       fnd_documents_tl       fdt,
       fnd_lobs               fl,
       fnd_lob_access         fla
where fad.entity_name = 'AP_INVOICES'
   and fad.pk1_value = to_char(lt_cur_data(i).invoice_id)
   and fad.document_id = fd.document_id
   and fd.document_id = fdt.document_id
   and fd.media_id = fL.file_id
   and fla.file_id = fl.file_id
   and fdt.language = 'F'
   and fdt.description = 'IMAGE FACTURE'
   and fla.timestamp = (select max(timestamp)
                          from fnd_lob_access
                         where file_id = fla.file_id)
and rownum = 1
*/
		select
         fl.file_id 
	   into ln_file_id
  from
       fnd_attached_documents fad,
       fnd_documents          fd,
       fnd_documents_tl       fdt,
       fnd_lobs               fl,
       fnd_lob_access         fla
where fad.entity_name = 'AP_INVOICES'
   and fad.pk1_value = to_char(lt_cur_data(i).invoice_id)
   and fad.document_id = fd.document_id
   and fd.document_id = fdt.document_id
   and fd.media_id = fL.file_id
   and fla.file_id = fl.file_id
   and fdt.language = 'F'
   and fdt.description = 'IMAGE FACTURE'
   and fla.timestamp = (select max(timestamp)
                          from fnd_lob_access
                         where file_id = fla.file_id)
and rownum = 1

    order by fad.CREATION_DATE asc;
        ln_LIEN_FACTURE := fnd_gfm.construct_download_url(gfm_agent     => fnd_web_config.gfm_agent,
                                file_id       => ln_file_id,
                                --purge_on_view boolean default FALSE,
                                --modplsql      boolean default FALSE,
                                authenticate  =>false --,
                                --user_name     => 'DKAEXPLOIT'
                                --lifespan      number  default NULL
                                );

EXCEPTION
    when no_data_found then
	ln_LIEN_FACTURE := null;
	WHEN OTHERS THEN
      p_validate(FALSE, 'ERREUR invoice_id :'||lt_cur_data(i).invoice_id||'('|| SQLERRM||')');
end;
		 -------------------------IBA EDB342 FIN>
            BEGIN
              vv_ligne :=lt_cur_data(i).LIGNE||vg_SEPARATOR||'"'||ln_LIEN_FACTURE||'"';  --IBA

              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne);

              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;

            EXCEPTION
              WHEN OTHERS THEN
               p_put_debug_message('ERREUR ' || lt_cur_data(i).LIGNE ||vg_SEPARATOR||'"'||ln_LIEN_FACTURE||'"'||' - ' || SQLERRM); --IBA
            END;

        END LOOP;

      END IF;

      EXIT WHEN cur_data%NOTFOUND;

    END LOOP;
    CLOSE cur_data;

    --  COMMIT;
    -- Fermeture du fichier
    UTL_FILE.FCLOSE(l_file);

	   -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_fact:=vn_nb_lignes;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_fact);
  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE, 'Probleme dans la procedure p_extract_data_inv (' || SQLERRM || ')');

  END p_extract_data_inv;

   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_maind
  --  Description   : Extrait des lignes d'heure de main d'?uvre valorisées.
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------
  --  12/08/2019 OCL : Ajout du champ EXPENDITURE_ITEM_ID
  PROCEDURE p_extract_data_maind(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2,
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    l_file        UTL_FILE.file_type;

	 /*//-- cursor pour extraction des lignes  d'heure de main d'?uvre valorisées--//*/

    CURSOR cur_data IS

			WITH TASK AS (
			SELECT
				PT.TASK_ID,
				PT.TASK_NUMBER
			FROM
				PA.PA_TASKS PT
			WHERE
				PT.TASK_NUMBER LIKE 'GT%'
				OR PT.TASK_NUMBER LIKE 'GX%'
				OR PT.TASK_NUMBER LIKE 'GY%'
				AND ( PT.COMPLETION_DATE IS NULL
					  OR TRUNC(PT.COMPLETION_DATE + 180) >= TRUNC(SYSDATE))
		                  )
		SELECT
			'"'
			|| EXPENDITURE_ITEM_ID
			||'"'||vg_SEPARATOR||'"'
			|| TASK_NUMBER
			||'"'||vg_SEPARATOR||'"'
			|| UO
			||'"'||vg_SEPARATOR||'"'
			|| to_char (EXPENDITURE_ITEM_DATE,'DD/MM/YYYY')
			||'"'||vg_SEPARATOR||'"'
			|| EXPENDITURE_TYPE
			||'"'||vg_SEPARATOR||'"'
            || replace (replace (to_number (QUANTITY),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
            || replace (replace (to_number (MONTANT),'.',','),'-,','-0,')
			|| '"' AS LIGNE
		FROM
			(
				SELECT
				    PEIA.EXPENDITURE_ITEM_ID     EXPENDITURE_ITEM_ID,
					TASK.TASK_NUMBER             TASK_NUMBER,
					HAOU.NAME                    UO,
					PEIA.EXPENDITURE_ITEM_DATE   EXPENDITURE_ITEM_DATE,
					replace(PEIA.EXPENDITURE_TYPE,CHR(188),'OE')        EXPENDITURE_TYPE,
					PEIA.QUANTITY                QUANTITY,
					PEIA.RAW_COST                MONTANT
				FROM
					PA.PA_EXPENDITURE_ITEMS_ALL PEIA
					INNER JOIN TASK ON TASK.TASK_ID = PEIA.TASK_ID
					INNER JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU ON HAOU.ORGANIZATION_ID = PEIA.ORG_ID
				WHERE
					(PEIA.EXPENDITURE_TYPE IN (
						'MAIN  D''OEUVRE AU THO',
						--'MAIN D''?UVRE HORS THO',
            'MAIN D''OEUVRE HORS THO VA'
					)  OR   PEIA.EXPENDITURE_TYPE LIKE 'MAIN D%UVRE HORS THO')
					AND PEIA.LAST_UPDATE_DATE BETWEEN to_date(P_DATE_DEBUT,'DD/MM/YYYY') AND  to_date(P_DATE_FIN,'DD/MM/YYYY')
					AND PEIA.ORG_ID IN (
										 SELECT
											 ORGANIZATION_ID
										 FROM
											 PER_SECURITY_ORGANIZATIONS
										 WHERE
											 SECURITY_PROFILE_ID = (
												 SELECT
													 SECURITY_PROFILE_ID
												 FROM
													 PER_SECURITY_PROFILES
												 WHERE
													 SECURITY_PROFILE_NAME = 'DKA_TOUT'
																   )
										)
				ORDER BY
					2,
					1
			);

    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;


  BEGIN
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);

    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;

    --création de l'entête
     utl_file.put_line(l_file,'"EXPENDITURE_ITEM_ID";"TASK_NUMBER";"UO";"EXPENDITURE_ITEM_DATE";"EXPENDITURE_TYPE";"QUANTITY";"MONTANT"');
    -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT INTO lt_cur_data;

      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP

            BEGIN
              vv_ligne :=lt_cur_data(i).LIGNE;

              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne);

              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;

            EXCEPTION

              WHEN OTHERS THEN
                p_put_debug_message('ERREUR ' || lt_cur_data(i).LIGNE || ' - ' || SQLERRM);
            END;

        END LOOP;
      END IF;

      EXIT WHEN cur_data%NOTFOUND;

    END LOOP;
    CLOSE cur_data;

       --  COMMIT;
       -- Fermeture du fichier
       UTL_FILE.FCLOSE(l_file);

	  -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_maind      := vn_nb_lignes;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_maind);

  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE, 'Probleme dans la procedure p_extract_data_maind (' || SQLERRM || ')');
  END p_extract_data_maind;

-- EDB248B_Nouveau_fichier_REFAC
   ------------------------------------------------------------------------------------
  --  Nom           : p_extract_data_refac
  --  Description   : Extrait des lignes de « refacturation interne ».
  --
  --  PARAMETRES    :
  --  p_directory_name        Nom du directory
  --  p_file_name             Nom du fichier
  --  p_nb_lignes             Nombre de lignes inserees
  --
  ------------------------------------------------------------------------------------

  PROCEDURE p_extract_data_refac(p_directory_name IN ALL_DIRECTORIES.directory_name%type,
                           p_file_name      IN VARCHAR2,
                           P_DATE_DEBUT IN VARCHAR2,
						   P_DATE_FIN IN VARCHAR2,
                           p_nb_lignes      IN OUT VARCHAR2) IS

    vv_ligne      VARCHAR2(4000);
    vn_nb_lignes  NUMBER := 0;
    vv_attribute10 VARCHAR2(10); --ARA
    l_file        UTL_FILE.file_type;

	 /*//-- cursor pour extraction des lignes  d'heure de main d'?uvre valorisées--//*/

    CURSOR cur_data IS

			WITH TASK AS (
			SELECT
				PT.TASK_ID,
				PT.TASK_NUMBER
			FROM
				PA.PA_TASKS PT
			WHERE
				PT.TASK_NUMBER LIKE 'GT%'
				OR PT.TASK_NUMBER LIKE 'GX%'
				OR PT.TASK_NUMBER LIKE 'GY%'
				AND ( PT.COMPLETION_DATE IS NULL
					  OR TRUNC(PT.COMPLETION_DATE + 180) >= TRUNC(SYSDATE))
		                  )
		SELECT
			'"'
			|| to_char (EFFECTIVE_DATE,'DD/MM/YYYY')
			||'"'||vg_SEPARATOR||'"'
			|| TASK_NUMBER
			||'"'||vg_SEPARATOR||'"'
			|| CURRENCY_CODE
			||'"'||vg_SEPARATOR||'"'
			|| replace (replace (to_number (ENTERED_DR),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
			|| replace (replace (to_number (ENTERED_CR),'.',','),'-,','-0,')
			||'"'||vg_SEPARATOR||'"'
            || replace (DESCRIPTION,'"','""')
			||'"'||vg_SEPARATOR||'"'
            || replace (SEGMENT4,'"','""')
			||'"'||vg_SEPARATOR||'"'
            || replace (CONTREPASSATION_AUTO,'"','""')
			||'"'||vg_SEPARATOR||'"'
            || replace (ID_PIECE_COMPTABLE,'"','""')
			||'"'||vg_SEPARATOR||'"'
            || replace (ID_PIECE_CONTREPASSEE,'"','""')
			|| '"' AS LIGNE,
			SEGMENT4 --ARA
		FROM
			(
				SELECT gjl.EFFECTIVE_DATE EFFECTIVE_DATE,
                PT.TASK_NUMBER     TASK_NUMBER,
                gjh.CURRENCY_CODE  CURRENCY_CODE,
                gjl.ENTERED_DR     ENTERED_DR,
                gjl.ENTERED_CR     ENTERED_CR,
                gjl.DESCRIPTION    DESCRIPTION,
				glcc.segment4	   SEGMENT4, --ARA,
				decode (gjh.reversed_je_header_id , null ,'NON',gjh.reversed_je_header_id , 'OUI') CONTREPASSATION_AUTO,--SHA
				gjh.je_header_id          ID_PIECE_COMPTABLE   ,--SHA
				gjh.reversed_je_header_id ID_PIECE_CONTREPASSEE--SHA
				  from gl_je_headers gjh,
					   gl_je_lines   gjl,
					   gl_ledgers    gl,
					   fnd_user      fu,
					   GL_CODE_COMBINATIONS glcc,
					   -- hr_operating_units hou,
					   PA.PA_TASKS PT
				 where gjl.attribute17 = PT.Task_id
				   AND gjh.je_header_id = gjl.je_header_id
				   AND fu.user_id = gjh.created_by
				   AND gjh.ledger_id = gl.ledger_id
					  --AND hou.set_of_books_id = gl.ledger_id
				   and (PT.TASK_NUMBER LIKE 'GT%' OR PT.TASK_NUMBER LIKE 'GX%' OR
					   PT.TASK_NUMBER LIKE 'GY%')
				   AND nvl(PT.COMPLETION_DATE + 180, sysdate) >= TRUNC(SYSDATE)
				   AND gjh.POSTED_DATE BETWEEN to_date(P_DATE_DEBUT,'DD/MM/YYYY') AND  to_date(P_DATE_FIN,'DD/MM/YYYY')
				   AND gjl.CONTEXT3 in ('Y.E.X', 'Y.R.X')
				   AND gjh.JE_SOURCE IN ('Manual', 'Spreadsheet')
				   AND glcc.CODE_COMBINATION_ID = gjl.CODE_COMBINATION_ID
				   and exists (select 'x'
							from   hr_operating_units hou,
								   per_security_profiles psp,
								   per_security_organizations pso
							where  hou.organization_id = pso.organization_id
							   and psp.security_profile_id = pso.security_profile_id
							   and psp.security_profile_name = 'DKA_TOUT'
							   and  hou.set_of_books_id = gjh.ledger_id)
			);

    TYPE t_cur_data IS TABLE OF cur_data%ROWTYPE index by binary_integer;
    lt_cur_data t_cur_data;


  BEGIN
    -- Verification de l'existence du directory
    p_check_directory(p_directory_name);

    -- Ouverture du fichier
    l_file := UTL_FILE.fopen(p_directory_name, p_file_name, 'W',32767);

    -- Controle que le fichier est bien ouvert pour ecriture
    IF utl_file.is_open(l_file) THEN
      p_put_debug_message('Le fichier ' || p_directory_name || '/' ||p_file_name || ' est ouvert en écriture');
    ELSE
      p_validate(FALSE, 'Le fichier ne peut pas être ouvert en écriture');
    END IF;

    --création de l'entête
     utl_file.put_line(l_file,'"EFFECTIVE_DATE";"TASK_NUMBER";"CURRENCY_CODE";"ENTERED_DR";"ENTERED_CR";"DESCRIPTION";"COMPTE_GROUPE";"CONTREPASSATION_AUTO";"ID_PIECE_COMPTABLE";"ID_PIECE_CONTREPASSEE"');
    -- Extraction des donnees
    OPEN cur_data;
    LOOP
      FETCH cur_data BULK COLLECT INTO lt_cur_data;

      IF lt_cur_data.COUNT > 0 THEN
        FOR i in lt_cur_data.FIRST .. lt_cur_data.LAST LOOP
            BEGIN
			--ARA Evolution EDB248C
                SELECT  NVL(ffvv.attribute10,'NO')
                    INTO vv_attribute10
                     FROM fnd_flex_value_sets ffvs, fnd_flex_values_vl ffvv
                    WHERE ffvs.flex_value_set_name = 'DAOPCCF_ANALYTIQUE' --DKA_SCTRLMOD_MOA_MAIL
                      AND ffvs.flex_value_set_id = ffvv.flex_value_set_id
                      AND ffvv.enabled_flag = 'Y'
                      AND SYSDATE BETWEEN NVL(ffvv.start_date_active, SYSDATE) AND
                          NVL(ffvv.end_date_active, SYSDATE)
                          AND ffvv.flex_value = TO_CHAR(lt_cur_data(i).SEGMENT4);
            END;
            BEGIN
			/*Fnd_File.put_line(Fnd_File.log,
                        'lt_cur_data(i).SEGMENT4 =  '|| lt_cur_data(i).SEGMENT4);
            Fnd_File.put_line(Fnd_File.log,
                        'vv_attribute10 =  '|| vv_attribute10);*/

			IF (vv_attribute10 = 'NO' OR vv_attribute10 = 'OUI') THEN
              vv_ligne :=lt_cur_data(i).LIGNE;

              -- Ecrit dans le fichier
              utl_file.put_line(l_file, vv_ligne);

              -- Maj des compteurs
              vn_nb_lignes := vn_nb_lignes + 1;
			END IF;
            EXCEPTION

              WHEN OTHERS THEN
                p_put_debug_message('ERREUR ' || lt_cur_data(i).LIGNE || ' - ' || SQLERRM);
            END;

        END LOOP;
      END IF;

      EXIT WHEN cur_data%NOTFOUND;

    END LOOP;
    CLOSE cur_data;

       --  COMMIT;
       -- Fermeture du fichier
       UTL_FILE.FCLOSE(l_file);

	  -- Remet les valeurs des compteurs dans les parametres de la procedure
	   vg_nbl_extr_refac      := vn_nb_lignes;
	   p_put_debug_message('L''écriture dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est terminée');
	   p_put_debug_message('Le nombre de lignes dans le fichier ' || p_directory_name || '/' ||p_file_name || ' est :'|| vg_nbl_extr_refac);

  EXCEPTION
    WHEN OTHERS THEN
      p_validate(FALSE, 'Probleme dans la procedure p_extract_data_refac (' || SQLERRM || ')');
  END p_extract_data_refac;

  ------------------------------------------------------------------------------------
  --  Nom           : Output_Header
  --  Description   : Procédure pour insérer une en-tête dans le fichier de sortie
  --
  --  PARAMETRES    :
  --
  --
  ------------------------------------------------------------------------------------

  PROCEDURE output_header IS
    cv_line                  VARCHAR2(100);
    v_conc_program_name      fnd_concurrent_programs.concurrent_program_name%TYPE;
    v_user_conc_program_name fnd_concurrent_programs_tl.user_concurrent_program_name%TYPE;
  BEGIN

    cv_line := '+-------------------------------------------------------------------------+';

    ----- Récupération des noms abrégé et long du traitement en fonction de la langue -----
    BEGIN
      SELECT fcp.concurrent_program_name, fcpt.user_concurrent_program_name
        INTO v_conc_program_name, v_user_conc_program_name
        FROM fnd_concurrent_programs fcp, fnd_concurrent_programs_tl fcpt
       WHERE fcp.application_id = Fnd_Global.prog_appl_id
         AND fcp.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.application_id = Fnd_Global.prog_appl_id
         AND fcpt.concurrent_program_id = Fnd_Global.conc_program_id
         AND fcpt.LANGUAGE = Fnd_Global.current_language;
    EXCEPTION
      WHEN OTHERS THEN
        v_user_conc_program_name := '???????????????????????';
        v_conc_program_name      := '???????';
    END;

    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10));
    Fnd_File.put_line(Fnd_File.output,
                      'Nom du traitement  : ' || v_user_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Code du traitement : ' || v_conc_program_name);
    Fnd_File.put_line(Fnd_File.output,
                      'Programme lancé le : ' ||
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || CHR(10));
    Fnd_File.put_line(Fnd_File.output, cv_line || CHR(10) || CHR(10));
  END output_header;

  ------------------------------------------------------------------------------------
  --  Nom           : main
  --  Description   : point d'entrée du traitement
  --
  --  PARAMETRES    :
  --  pv_errbuf             message d'erreur si pn_retcode != 0
  --  pn_retcode            code de sortie (0 : normal, 1 : warning,2 : erreur)

  ------------------------------------------------------------------------------------
  PROCEDURE main(
  pv_errbuf OUT NOCOPY VARCHAR2, pn_retcode OUT NOCOPY NUMBER, P_DATE_DEBUT IN VARCHAR2, P_DATE_FIN IN VARCHAR2,P_EXTRACT_MAN IN VARCHAR2) IS

    lv_current_program_unit VARCHAR2(30) := 'main';
    lv_nom_fichier1          VARCHAR2(200);
	lv_nom_fichier2          VARCHAR2(200);
	lv_nom_fichier3          VARCHAR2(200);
	lv_nom_fichier4			VARCHAR2(200);
    ln_nb_lignes            NUMBER:=0;


	lv_EXTRACT_MAN VARCHAR2(3);
     cn_tempo                CONSTANT NUMBER       := 20;
     vn_user_id                       NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);

  BEGIN

	lv_EXTRACT_MAN:=P_EXTRACT_MAN;

    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||'DEBUT DE L''INTERFACE');
    Output_Header;


    -- Construction du premier nom du fichier
    lv_nom_fichier1 := 'FINHER_ENGAGE_' || TO_CHAR(SYSDATE, 'YYYYMMDD')  ||'.csv';
	-- Construction du deuxième nom du fichier
    lv_nom_fichier2 := 'FINHER_FACTURES_' || TO_CHAR(SYSDATE, 'YYYYMMDD')  ||'.csv';
    -- Construction du troisième nom du fichier
    lv_nom_fichier3 := 'FINHER_MO_' || TO_CHAR(SYSDATE, 'YYYYMMDD')  ||'.csv';
	-- Construction du 4ème nom du fichier -- EDB248B ARA
    lv_nom_fichier4 := 'FINHER_REFAC_' || TO_CHAR(SYSDATE, 'YYYYMMDD')  ||'.csv';


    Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'PHASE D''EXTRACTION DES DONNEES');

    -- Extrait les lignes d'écritures dans le premier fichier
     p_extract_data_cmd(vg_DIRECTORY, lv_nom_fichier1, P_DATE_DEBUT,P_DATE_FIN,ln_nb_lignes);
	 -- Extrait les lignes d'écritures dans le deuxième fichier
	 p_extract_data_inv(vg_DIRECTORY, lv_nom_fichier2, P_DATE_DEBUT,P_DATE_FIN, ln_nb_lignes);
     -- Extrait les lignes d'écritures dans le troisième fichier
     p_extract_data_maind(vg_DIRECTORY, lv_nom_fichier3, P_DATE_DEBUT,P_DATE_FIN, ln_nb_lignes);
	 -- Extrait les lignes d'écritures dans le 4ème fichier
	 p_extract_data_refac(vg_DIRECTORY, lv_nom_fichier4, P_DATE_DEBUT,P_DATE_FIN, ln_nb_lignes);
     Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'AFFICHAGE DU BILAN');
 ---- compression des fichiers de sortie en zip
   Fnd_File.put_line(Fnd_File.LOG,
                      TO_CHAR(SYSDATE, 'DD/MM/YYYY HH24:MI:SS') || ' - ' ||
                      'LAncement de traitement de compression des fichiers ');
       compression_fichier_sortie;

    -- Edite un rapport de traitment
            bilan(p_date_debut ,
                    p_date_fin ,
                    P_EXTRACT_MAN ,
                    lv_nom_fichier1 ,
                    lv_nom_fichier2 ,
                    lv_nom_fichier3,
					lv_nom_fichier4);



  EXCEPTION
    WHEN OTHERS THEN
      pv_errbuf  := 'Erreur procedure ' || vg_package_name || '.' || lv_current_program_unit || chr(10) || SQLERRM;
      pn_retcode := 2;
  END main;

    ------------------------------------------------------------------------------------
  --  Nom           : bilan
  --  Description   : Affichage des stats

  ------------------------------------------------------------------------------------
  PROCEDURE bilan( p_date_debut varchar2,
                    p_date_fin varchar2,
                    p_extr_man varchar2,
                    p_file_name1 varchar2,
                    p_file_name2 varchar2,
                    p_file_name3 varchar2,
					p_file_name4 varchar2) IS

  BEGIN



    Fnd_File.put_line(Fnd_File.log,
                      '---------------------Bilan du traitement------------------------------------');
    Fnd_File.put_line(Fnd_File.log,
                      'TRAITEMENT, lancé le ' ||
                      to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));
    Fnd_File.put_line(Fnd_File.log,
                      'Paramètre du traitement :---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.log, '1) Date de début : ' || p_date_debut);

    Fnd_File.put_line(Fnd_File.log, '2) Date de fin : ' || p_date_fin);

       Fnd_File.put_line(Fnd_File.log,'3) extraction manuelle: ' || p_extr_man);

    Fnd_File.put_line(Fnd_File.log, chr(10));

    Fnd_File.put_line(Fnd_File.log,
                      '---------------------------------------------------------');
    Fnd_File.put_line(Fnd_File.log,
                      '-- BILAN                                                 ');
    Fnd_File.put_line(Fnd_File.log,
                      '---------------------------------------------------------');


    IF vg_nbl_extr_cmd > 0 THEN
      Fnd_File.put_line(Fnd_File.log,
                        'le nombre de lignes générées dans le fichier '||p_file_name1||' est : ' || vg_nbl_extr_cmd ||
                        ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.log, 'Aucune ligne trouvée pour le fichier '||p_file_name1);
    END IF;

     IF vg_nbl_extr_fact > 0 THEN
      Fnd_File.put_line(Fnd_File.log,
                        'le nombre de lignes générées dans le fichier '||p_file_name2||' est : ' || vg_nbl_extr_fact||
                        ' lignes.');
    ELSE
     Fnd_File.put_line(Fnd_File.log, 'Aucune ligne trouvée pour le fichier '||p_file_name2);
    END IF;

       IF vg_nbl_extr_maind > 0 THEN
      Fnd_File.put_line(Fnd_File.log,
                        'le nombre de lignes générées dans le fichier '||p_file_name3||' est : ' || vg_nbl_extr_maind||
                        ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.log, 'Aucune ligne trouvée pour le fichier '||p_file_name3);
    END IF;

	-- EDB248B ARA
	IF vg_nbl_extr_refac > 0 THEN
      Fnd_File.put_line(Fnd_File.log,
                        'le nombre de lignes générées dans le fichier '||p_file_name4||' est : ' || vg_nbl_extr_refac||
                        ' lignes.');
    ELSE
      Fnd_File.put_line(Fnd_File.log, 'Aucune ligne trouvée pour le fichier '||p_file_name4);
    END IF;

  END bilan;

  procedure compression_fichier_sortie
  as


    cn_tempo                        CONSTANT NUMBER       := 20;
    vn_user_id                      NUMBER (15);
    vn_request_id                    NUMBER (15);
    vv_rphase                        VARCHAR2 (80);
    vv_rstatus                       VARCHAR2 (80);
    vv_dphase                        VARCHAR2 (30);
    vv_dstatus                       VARCHAR2 (30);
    vv_message                       VARCHAR2 (240);
  begin


                vn_request_id := FND_REQUEST.SUBMIT_REQUEST(
                  'DKA',
                  'DKA_COMPRESS_FICHIER',
                  '',
                  '',
                  FALSE,
                  'DKA',
                  vg_directory_path,
                  '',
                  '',
                  '',
                  '',
                  '',
                  '',
                  '',
                  '',
                   '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '', '',
                  '', '', '', '', '', '', '', '', '');
                    COMMIT;
                  vg_request_id_cf:=vn_request_id;

      Fnd_File.put_line(Fnd_File.output,
                      'TRAITEMENT, lancé le ' ||
                      to_char(sysdate, 'DD/MM/YYYY HH24:MI:SS'));

     Fnd_File.put_line(Fnd_File.log, 'Validation pour que les GTS puissent prendre la demande');

    IF vn_request_id = 0
    THEN
         Fnd_File.put_line(Fnd_File.log, 'Impossible de lancer le Traitement de compression dse fichiers de sorties ');
        RETURN;
    END IF;
 Fnd_File.put_line(Fnd_File.log, 'Traitement de Compression de fichier numéro : ' || TO_CHAR (vn_request_id));

    IF NOT fnd_concurrent.wait_for_request (vn_request_id, cn_tempo, 0, vv_rphase, vv_rstatus, vv_dphase, vv_dstatus, vv_message)
    THEN

        RETURN;
    ELSE
        IF vv_dstatus = 'WARNING'
        THEN
           Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Traitement termine en Warning ');

            RETURN;
        ELSIF vv_dstatus != 'NORMAL'
        THEN
              Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Traitement termine en Erreur ');
            RETURN;
        END IF;
    END IF;
    IF vv_dstatus != 'NORMAL'then
       Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Traitement termine en Erreur ');
    END IF;
   Fnd_File.put_line(Fnd_File.log,'>>> Fin normale');

     IF vv_dstatus = 'NORMAL'then
       Fnd_File.put_line(Fnd_File.log,CHR (10) || '>>> Le traitement à généré le dossier: Engages_ORACLE_'||to_char (sysdate,'yyyymmdd')||' dans le chemin  '||vg_directory_path);
    END IF;

EXCEPTION
    WHEN OTHERS
    THEN
          Fnd_File.put_line(Fnd_File.log,(' ==> ERREUR : ' || SQLERRM));
  end compression_fichier_sortie;

END DKA_IPOEXTENGHERC_PKG;
/
SHOW ERRORS;

EXIT
