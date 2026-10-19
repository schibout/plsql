create or replace package body DKA_ETA081_PKG is
---------------------------------------------------------------------------------------------------------------
-- Capgemini
-- NOM         : DKA_ETA081_PKG.pkb
-- DESCRIPTION : Insertion des donnees dans la table de travail de l'etat ETA081
---              Pour chaque traitement, la table de travail contenant les donnees se nomme differemment
---              Cela necessite du sql dynamique. cela est impossible dans un Report 
---              => Fait dans le package appele dans le befort report 
--- AUTEUR     : EFL
--- DATE DE CREATION : 21/02/2017
--- DOC. ASSOCIEE    : N/A
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
---------------------------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- 05/10/2018 NBO artf3036953 : INC0253407 - Etat de TVA qui n'aboutie pas  
---
---------------------------------------------------------------------------------------------------------------
PROCEDURE INSERT_TABLE_P (P_Table_Name      VARCHAR2 
                         ,P_SOCIETE         DKA_RAPJUSTTVADEC.SOCIETE%TYPE
                         ,P_COMPANY_NUM     DKA_RAPJUSTTVADEC.COMPANY_NUM%TYPE
                         ,P_COMPANY_NAME    DKA_RAPJUSTTVADEC.COMPANY_NAME%TYPE
                         ,P_FACTURE_DATE    DKA_RAPJUSTTVADEC.FACTURE_DATE%TYPE 
                         ,P_FACTURE_ID      DKA_RAPJUSTTVADEC.FACTURE_ID%TYPE
                         ,P_FACTURE_NUM     DKA_RAPJUSTTVADEC.FACTURE_NUM%TYPE
                         ,P_COMPTE          DKA_RAPJUSTTVADEC.COMPTE%TYPE
                         ,P_G_COMPTE        DKA_RAPJUSTTVADEC.G_COMPTE%TYPE 
                         ,P_TAUX_TVA        DKA_RAPJUSTTVADEC.TAUX_TVA%TYPE
                         ,P_FACTURE_AMOUNT  DKA_RAPJUSTTVADEC.FACTURE_AMOUNT%TYPE
                         ,P_BASE_HT         DKA_RAPJUSTTVADEC.BASE_HT%TYPE
                         ,P_BASE_TVA        DKA_RAPJUSTTVADEC.BASE_TVA%TYPE
                         ,P_DUE_HT          DKA_RAPJUSTTVADEC.DUE_HT%TYPE
                         ,P_DUE_TVA         DKA_RAPJUSTTVADEC.DUE_TVA%TYPE
                         ,P_FOURNISSEUR     DKA_RAPJUSTTVADEC.FOURNISSEUR%TYPE
--- 05/10/2018 NBO artf3036953 : INC0253407 - Etat de TVA qui n'aboutie pas  
                         ,P_CONC_REQUEST_ID DKA_RAPJUSTTVADEC.CONC_REQUEST_ID%TYPE )
IS
  l_mesg VARCHAR2(80);
BEGIN
--- 05/10/2018 NBO artf3036953 : INC0253407 - Etat de TVA qui n'aboutie pas 
    EXECUTE IMMEDIATE      
    'insert into dka.'||P_Table_Name||' 
    (SOCIETE,COMPANY_NUM,COMPANY_NAME,FACTURE_DATE,FACTURE_ID,
     FACTURE_NUM,COMPTE,G_COMPTE,TAUX_TVA,FACTURE_AMOUNT,
     BASE_HT,BASE_TVA,DUE_HT,DUE_TVA,FOURNISSEUR, CONC_REQUEST_ID)
     values
     (:1,:2,:3,:4,:5,
      :6,:7,:8,:9,:10,
      :11,:12,:13,:14,:15,:16)'
     USING
     P_SOCIETE,P_COMPANY_NUM,P_COMPANY_NAME,P_FACTURE_DATE,P_FACTURE_ID,
     P_FACTURE_NUM,P_COMPTE,P_G_COMPTE,P_TAUX_TVA,P_FACTURE_AMOUNT,
--- 05/10/2018 NBO artf3036953 : INC0253407 - Etat de TVA qui n'aboutie pas  
     P_BASE_HT,P_BASE_TVA,P_DUE_HT,P_DUE_TVA,P_FOURNISSEUR, P_CONC_REQUEST_ID;
EXCEPTION
WHEN OTHERS THEN     
     l_mesg := SUBSTR(SQLERRM,1,80);
     Fnd_File.put_line (Fnd_File.log,'Error in DKA_ETA081_PKG.INSERT_TABLE_P (');
     Fnd_File.put_line (Fnd_File.log,P_Table_Name||','||P_SOCIETE||','||P_COMPANY_NUM||','||P_COMPANY_NAME||','||P_FACTURE_DATE||','||P_FACTURE_ID||',');
     Fnd_File.put_line (Fnd_File.log,P_FACTURE_NUM||','||P_COMPTE||','||P_G_COMPTE||','||P_TAUX_TVA||','||P_FACTURE_AMOUNT||',');
     Fnd_File.put_line (Fnd_File.log,P_BASE_HT||','||P_BASE_TVA||','||P_DUE_HT||','||P_DUE_TVA||','||P_FOURNISSEUR||')');
     Fnd_File.put_line (Fnd_File.log,l_mesg);
     RAISE;
END INSERT_TABLE_P;                         
end DKA_ETA081_PKG;
/
SHOW ERRORS
EXIT;
