CREATE OR REPLACE PACKAGE BODY DKA_EXTR_DA_PKG  AS
----------------------------------------------------------------------
-- PROGRAM : DKA_EXTR_DA_PKG.sql                                     -
-- AUTEUR  : S. NIKMAOUI / SOCIETE : CAP GEMINI                      -
-- DATE    : 03/12/2018                                              -
----------------------------------------------------------------------
-- VERSION INITIALE : 1.0                                            -
-- PAR        :                                                      -
-- EVENEMENT  :                                                      -
-- OBJET      :                                                      -
--                                                                   -
----------------------------------------------------------------------
--   Version   Date         Author          Remarks
--   -------   -----------  -----------     --------------------------
--   1.0       03-12-2018   S. NIKMAOUI     Base Version              
----------------------------------------------------------------------

 ---------------------------------------------------------------------
/*============================================================================*/
/* FONCTION          : dka_dka_inserer_element                                */
/* Description       : Fonction creation des balises XML                      */
-------------------------------------------------------------------------------
  
   PROCEDURE dka_inserer_element(Doc         dbms_xmldom.domdocument,
                                 Col         VARCHAR2,
                                 Col_val     VARCHAR2,
                                 Target_node dbms_xmldom.domnode
                            )
   IS
   
   
     l_col_Element      dbms_xmldom.domelement; 
     l_colElementNode   dbms_xmldom.domnode; 
     --inner text 
     l_colText          dbms_xmldom.domtext; 
     l_colTextNode      dbms_xmldom.domnode; 
     l_childNode        dbms_xmldom.domnode;
     l_mesg             VARCHAR2(100);

    BEGIN
    l_col_Element    := dbms_xmldom.createelement( doc => Doc, tagName => Col );
    --convert it to a node
    l_colElementNode := dbms_xmldom.makenode( elem => l_col_Element);
    --make the text element
    l_colText        := dbms_xmldom.createtextnode( doc => Doc, DATA => HTF.ESCAPE_SC ( CONVERT(NVL(REPLACE(Col_val,CHR(38),CHR(38)||'amp;'),''),'UTF8') ));
    l_colTextNode    := dbms_xmldom.makenode( t => l_colText ); 
    l_childNode      := dbms_xmldom.appendchild( n => l_colElementNode, newchild => l_colTextNode); 
    l_childNode      := dbms_xmldom.appendchild( n => Target_node, newchild => l_colElementNode ); 
    EXCEPTION
    WHEN OTHERS THEN
        l_mesg := SUBSTR(SQLERRM,1,80);
        dka_Tools_Pkg.put_log_message(l_mesg);
    END;
--------------------------------------------------------------------------
-- ---------------------------- PUBLIC PROCEDURES -----------------------------
/*============================================================================*/
/* Procedure         : MAIN                                                   */
/* Description       : Procedure principale de l'etat                         */
/* Remarques         :                                                        */
/*============================================================================*/
PROCEDURE MAIN ( P_errbuf                 OUT VARCHAR2
               , P_retcode                OUT NUMBER
               , p_region                 IN  VARCHAR2
               , p_uo                     IN  VARCHAR2
               , p_type_DA                IN  VARCHAR2
               , p_redacteur              IN  NUMBER 
               , p_demandeur              IN  NUMBER
               , p_tache_fin              IN  VARCHAR2
               , p_statu_DA               IN  VARCHAR2
               , p_tr_cmd                 IN  VARCHAR2
               , p_creation_dt_du         IN  VARCHAR2
               , p_creation_dt_au         IN  VARCHAR2
               , p_num_da_du              IN  NUMBER
               , p_num_da_au              IN  NUMBER
               , p_nom_fourn              IN  VARCHAR2
               , p_site_frn               IN  VARCHAR2
               )
IS
  --
  -- Variables locales
  --
 l_region              VARCHAR2(30);
 l_type_DA             VARCHAR2(100);
 l_mat_redact          VARCHAR2(200);
 l_redact              VARCHAR2(200);
 l_Clss_achat_frn      VARCHAR2(400);
 l_cat_acht_item       VARCHAR2(400);
 l_descp_achat_frn     VARCHAR2(400);
 l_num_frn             VARCHAR2(400);
 l_cat_id              NUMBER := 0;
 l_date_de             DATE;
 l_date_a              DATE;
 l_docClob             CLOB;
 l_docClob2            CLOB;
 --whole doc 
 l_xmlDoc              dbms_xmldom.domdocument;
 l_xmlDocNode          dbms_xmldom.domnode;
 l_wholeDoc            dbms_xmldom.domnode;

 --root element 
 l_racineElement       dbms_xmldom.domelement;
 l_racineElementNode   dbms_xmldom.domnode;
 l_extr_da_Element     dbms_xmldom.domelement;
 l_extr_da_ElementNode dbms_xmldom.domnode;
 l_childNode           dbms_xmldom.domnode;

 l_instrclob           NUMBER;

 CURSOR extr_da IS 
                    WITH D AS
                            (SELECT
                                      PAPF1.PERSON_ID,
                                      PAPF1.EMPLOYEE_NUMBER,
                                      PAPF1.FULL_NAME,
                                      HAOU1.NAME ATTRIBUTE1,
                                      PAPF1.ATTRIBUTE2,
                                      PAPF1.ATTRIBUTE3,
                                      PAAF1.SUPERVISOR_ID,
                                      PJ1.NAME,
                                      PAPF1.EFFECTIVE_END_DATE SUP_END_DATE
                            FROM HR.PER_ALL_PEOPLE_F PAPF1
                            INNER JOIN HR.PER_ALL_ASSIGNMENTS_F PAAF1
                            ON PAAF1.PERSON_ID            = PAPF1.PERSON_ID
                            INNER JOIN HR.PER_JOBS PJ1
                            ON PJ1.JOB_ID                 = PAAF1.JOB_ID
                            INNER JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU1
                            ON HAOU1.ORGANIZATION_ID      = PAAF1.ORGANIZATION_ID
                            WHERE                        1=1
                            and PAPF1.BUSINESS_GROUP_ID   = 0
                            AND PAPF1.PERSON_TYPE_ID      IN ( 6, 125)
                            AND PAPF1.EFFECTIVE_END_DATE  =
                                (SELECT MAX (PAPF11.EFFECTIVE_END_DATE)
                                FROM HR.PER_ALL_PEOPLE_F PAPF11
                                WHERE PAPF11.PERSON_ID    = PAPF1.PERSON_ID
                                AND PAPF11.PERSON_TYPE_ID IN ( 6, 125))
                            AND PAAF1.EFFECTIVE_END_DATE  =
                                (SELECT MAX (PAAF11.EFFECTIVE_END_DATE)
                                FROM HR.PER_ALL_ASSIGNMENTS_F PAAF11
                                WHERE PAAF11.PERSON_ID    = PAAF1.PERSON_ID)
                            AND PJ1.OBJECT_VERSION_NUMBER =
                                (SELECT MAX (PJ11.OBJECT_VERSION_NUMBER)
                                FROM HR.PER_JOBS PJ11
                                WHERE PJ11.JOB_ID         = PJ1.JOB_ID)
                            ORDER BY 1)
                            SELECT PRHA.created_by red_id , 
                                   HAOU.NAME UO ,
                                   SUBSTR (HAOU.NAME , 1, 3)                        etab ,
                                   SUBSTR (HAOU.NAME , 4, 4)                         Ste ,
                                   TO_NUMBER(PRHA.SEGMENT1)                       num_da ,
                                   PRLA.LINE_NUM                                ligne_da ,
                                   TO_CHAR(PRHA.CREATION_DATE,'DD/MM/YYYY')      date_da ,
                                   PRLA.suggested_vendor_name                        frn ,
                                   PRLA.suggested_vendor_location             site_achat ,
                                   D.EMPLOYEE_NUMBER                          mat_dmdeur ,
                                   D.FULL_NAME                                    dmdeur ,
                                   D.ATTRIBUTE1                        centre_fin_dmdeur ,
                                   D.NAME                                    fonct_dmdeur,
                                   PRLA.ITEM_DESCRIPTION                            item ,
                                   MCB.SEGMENT1
                                   ||'.'
                                   ||MCB.SEGMENT2
                                   ||'.'
                                   ||MCB.SEGMENT3
                                   ||'.'
                                   ||MCB.SEGMENT4                          cat_acht_item ,
                                   MCT.DESCRIPTION                            descp_item ,
                                   PT.TASK_NUMBER                              tache_fin ,
                                   PRLA.QUANTITY                                 qte_cmd ,
                                   PRLA.UNIT_PRICE                                  prix ,
                                   (PRLA.QUANTITY * PRLA.UNIT_PRICE)             val_cmd ,
                                   PRLA.CATALOG_TYPE
                            FROM PO.PO_REQUISITION_HEADERS_ALL PRHA
                            INNER JOIN HR.HR_ALL_ORGANIZATION_UNITS HAOU
                            ON HAOU.ORGANIZATION_ID       = PRHA.ORG_ID
                            INNER JOIN PO.PO_REQUISITION_LINES_ALL PRLA
                            ON PRLA.REQUISITION_HEADER_ID = PRHA.REQUISITION_HEADER_ID
                            INNER JOIN PO.PO_REQ_DISTRIBUTIONS_ALL PRDA
                            ON PRDA.REQUISITION_LINE_ID   = PRLA.REQUISITION_LINE_ID
                            INNER JOIN INV.MTL_CATEGORIES_B MCB
                            ON MCB.CATEGORY_ID            = PRLA.CATEGORY_ID
                            INNER JOIN INV.MTL_CATEGORIES_TL MCT
                            ON (MCT.CATEGORY_ID           = PRLA.CATEGORY_ID
                            AND MCT.LANGUAGE              = 'F')
                            INNER JOIN PA.PA_TASKS PT
                            ON PT.TASK_ID                 = PRDA.TASK_ID
                            INNER JOIN D
                            ON D.PERSON_ID                = PRLA.TO_PERSON_ID
                            WHERE 1=1 
                            AND PRHA.AUTHORIZATION_STATUS               LIKE NVL(p_statu_DA,'%')
                            AND NVL2(PRLA.line_location_id,'Oui','Non') LIKE NVL(p_tr_cmd,'%')
                            AND NVL(prla.cancel_flag,'N')               = 'N'
                            AND HAOU.name                               LIKE NVL(l_region,'%')
                            AND HAOU.name                               LIKE NVL(p_uo,'%')
                            AND PRLA.CATALOG_TYPE                       LIKE NVL(l_type_DA,'%')
                            AND PRLA.CREATED_BY                         = NVL(p_redacteur,PRLA.CREATED_BY)
                            AND D.PERSON_ID                             = NVL(p_demandeur,PRLA.TO_PERSON_ID)
                            AND PT.TASK_NUMBER                          LIKE NVL(p_tache_fin,'%')
                            AND TRUNC(PRHA.CREATION_DATE)               BETWEEN TRUNC(NVL(l_date_de,PRHA.CREATION_DATE)) 
                                                                        AND     TRUNC(NVL(l_date_a,SYSDATE))
                            AND TO_NUMBER(PRHA.SEGMENT1)                BETWEEN TO_NUMBER(NVL(p_num_da_du,'0')) 
                                                                        AND TO_NUMBER(NVL(p_num_da_au,'99999999'))
                            AND NVL(PRLA.suggested_vendor_name,' ')     LIKE NVL(p_nom_fourn,'%')
                            AND NVL(PRLA.suggested_vendor_location,' ') LIKE NVL(p_site_frn,'%')
                            ORDER BY uo, num_da, ligne_da;
BEGIN

    dka_Tools_Pkg.put_log_message('---Début du traitement---');

    l_date_de := TRUNC(fnd_date.canonical_to_date(p_creation_dt_du)); 
    l_date_a  := TRUNC(fnd_date.canonical_to_date(p_creation_dt_au)); 

    dka_Tools_Pkg.put_log_message('---Paramètres de l''état ---');

    dka_Tools_Pkg.put_log_message('Région                    : '||p_region);
    dka_Tools_Pkg.put_log_message('Unité Opérationnelle      : '||p_uo);
    dka_Tools_Pkg.put_log_message('Type de DA                : '||p_type_DA);
    dka_Tools_Pkg.put_log_message('Rédacteur ID              : '||p_redacteur);
    dka_Tools_Pkg.put_log_message('Demandeur ID              : '||p_demandeur);
    dka_Tools_Pkg.put_log_message('Tâche Finance             : '||p_tache_fin);
    dka_Tools_Pkg.put_log_message('Statut de la DA           : '||p_statu_DA);
    dka_Tools_Pkg.put_log_message('Transformé en commande    : '||p_tr_cmd);
    dka_Tools_Pkg.put_log_message('De la date de création DA : '||p_creation_dt_du);
    dka_Tools_Pkg.put_log_message('A la date de création DA  : '||p_creation_dt_au);
    dka_Tools_Pkg.put_log_message('Du numéro de DA           : '||p_num_da_du);
    dka_Tools_Pkg.put_log_message('Au numéro de DA           : '||p_num_da_au);
    dka_Tools_Pkg.put_log_message('Nom du fournisseur        : '||p_nom_fourn);
    dka_Tools_Pkg.put_log_message('Site Fournisseur          : '||p_site_frn);

    --SNI - retour recette
    IF p_region = 'T' OR p_region IS NULL THEN
       l_region := '%';
	ELSE
	   l_region := p_region||'%';
    END IF;

    IF p_type_DA = 'Hors catalogue'
        THEN l_type_DA:= 'NONCATALOG';
    END IF;
    IF p_type_DA = 'Catalogue'
        THEN l_type_DA := 'CATALOG';
    END IF;


    dka_Tools_Pkg.put_log_message('---Début Extraction DA---');
    -- Using dbms_xmldom to make an XML Report
    l_xmlDoc := dbms_xmldom.newDOMDocument();
    dbms_xmldom.setcharset(l_xmlDoc, 'UTF-8');
    dbms_xmldom.setVersion(l_xmlDoc, '1.0');

    --convert it to a node.
    l_xmlDocNode := dbms_xmldom.makenode( doc => l_xmlDoc);
    --make a global element <racine>
    l_racineElement := dbms_xmldom.createelement( doc => l_xmlDoc, tagName => 'racine' );
    --convert it to a node 
    l_racineElementNode := dbms_xmldom.makenode( elem => l_racineElement );

    FOR R0 IN extr_da
    LOOP

    BEGIN
    SELECT DISTINCT aps.attribute8,   M_B.CATEGORY_ID
           INTO     l_Clss_achat_frn, l_cat_id
    FROM ap_suppliers aps, MTL_CATEGORIES_B M_B
    WHERE              1=1
    AND aps.vendor_name = R0.frn
    AND aps.attribute8  =   M_B.SEGMENT1
                          ||'.'
                          ||M_B.SEGMENT2
                          ||'.'
                          ||M_B.SEGMENT3
                          ||'.'
                          ||M_B.SEGMENT4;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
              l_Clss_achat_frn := NULL;
              l_cat_id         := NULL;
          WHEN OTHERS THEN
              p_retcode        := 2;
              p_errbuf         := SQLERRM;
    END;

    BEGIN
    SELECT     M_T.DESCRIPTION 
          INTO l_descp_achat_frn 
    FROM INV.MTL_CATEGORIES_TL M_T
    WHERE M_T.CATEGORY_ID = l_cat_id
    AND M_T.LANGUAGE      = 'F';
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
               l_descp_achat_frn := NULL;
          WHEN OTHERS THEN
               p_retcode         := 2;
               p_errbuf          := SQLERRM;
    END;

    BEGIN
    SELECT     segment1 
          INTO l_num_frn
    FROM ap_suppliers
    WHERE vendor_name = R0.frn;
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
               l_num_frn         := NULL;
         WHEN OTHERS THEN
               p_retcode         := 2;
               p_errbuf          := SQLERRM;
    END;

    IF R0.cat_acht_item = '...' THEN l_cat_acht_item := NULL;
    ELSE l_cat_acht_item := R0.cat_acht_item;
    END IF;

    BEGIN
    SELECT DISTINCT EMPLOYEE_NUMBER, FULL_NAME 
           INTO     l_mat_redact,    l_redact
    FROM PER_ALL_PEOPLE_F
    WHERE person_id = R0.red_id
    AND TRUNC(SYSDATE) BETWEEN TRUNC(effective_start_date) 
                       AND NVL(effective_end_date,SYSDATE);
    EXCEPTION
          WHEN NO_DATA_FOUND THEN
               l_mat_redact      := R0.mat_dmdeur;
               l_redact          := R0.dmdeur;
          WHEN OTHERS THEN
               p_retcode         := 2;
               p_errbuf          := SQLERRM;
    END;

    --make a new root element <extr_da> containing DA informations 
    l_extr_da_Element := dbms_xmldom.createelement( doc => l_xmlDoc, tagName => 'extr_da');
    --convert it to a node 
    l_extr_da_ElementNode := dbms_xmldom.makenode( elem => l_extr_da_Element );
    --Function <<dka_inserer_element>> to print DA informations as XML's out
-----------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'UO',R0.UO,l_extr_da_ElementNode);
-----------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'ETAB',R0.etab,l_extr_da_ElementNode);
-----------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'STE',R0.ste,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'NUM_DA',R0.num_da,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'LINE_DA',R0.ligne_da,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'DATE_DA',R0.date_da,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'NUM_FRN',l_num_frn,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'NOM_FRN',R0.frn,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'SITE_ACHAT',R0.site_achat,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'CLASS_ACHAT',l_Clss_achat_frn,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'DESC_CLASS',l_descp_achat_frn,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'MAT_DEMD',R0.mat_dmdeur,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'NOM_DEMD',R0.dmdeur,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'MAT_RED',l_mat_redact,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'NOM_RED',l_redact,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'CENTRE_FIN',R0.centre_fin_dmdeur,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'TACHE_FIN',R0.tache_fin,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'FONC_DEMD',R0.fonct_dmdeur,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'ARTICLE',R0.item,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'CAT_ARTICLE',l_cat_acht_item,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'DESC_ARTICLE',R0.descp_item,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'QTE_CMD',R0.qte_cmd,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'PRIX_UNIT',R0.prix,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'VAL_CMD',R0.val_cmd,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
    dka_inserer_element(l_xmlDoc,'CATALOG_TYPE',R0.CATALOG_TYPE,l_extr_da_ElementNode);
------------------------------------------------------------------------------------------------------------------
       
    l_wholeDoc := dbms_xmldom.appendchild( n => l_racineElementNode, newchild => l_extr_da_ElementNode );
    END LOOP;
    l_wholeDoc := dbms_xmldom.appendchild( N => L_XMLDOCNODE, newchild => l_racineElementNode);

    dbms_lob.createtemporary(l_docClob, FALSE);
    dbms_xmldom.writetoclob( doc => l_xmlDoc, cl  => l_docClob );
    -------------------------------------------------------------------
     --Cutting Clob to avoid oversizing <<fnd_file.put_line>> function
    -------------------------------------------------------------------
    WHILE( LENGTH(l_docClob)!=0) 
    LOOP
     IF (LENGTH(l_docClob)>32000) THEN
         l_docClob2   :=SUBSTR(l_docClob,1,32000);
         l_instrclob  := INSTR(l_docClob2,'</extr_da>',-1);
         l_docClob2   :=SUBSTR(l_docClob2 ,1,l_instrclob+9 );
         fnd_file.put_line(fnd_file.OUTPUT,l_docClob2);
         l_docClob    :=SUBSTR(l_docClob,l_instrclob+10);
     ELSIF (LENGTH(l_docClob)<32000) THEN
         fnd_file.put_line(fnd_file.OUTPUT,l_docClob);
         l_docClob    :='';
     END IF;
     END LOOP;
    -------------------------

    dka_Tools_Pkg.put_log_message('---Fin du traitement---');
    EXCEPTION
    WHEN OTHERS THEN
          p_retcode   := 2;
          p_errbuf    := SQLERRM;

    END MAIN;

 END DKA_EXTR_DA_PKG;
/
SHOW ERRORS;

EXIT