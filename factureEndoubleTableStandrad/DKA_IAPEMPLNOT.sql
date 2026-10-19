----------------------------------------------------------------------------------------------
-- $$
-- CAP GEMINI 
-- PROJET            : DALKIA Oracle Applications
-- NOM               : DkaExtractBlob_Class.java
-- DESCRIPTION       : DkaExtractBlob_Class.java java class :
--                     Export d'un blob
--- AUTEUR           : Julien Jardez
--- DATE DE CREATION : 06/08/2013
--- DOC. ASSOCIEE    : 
-- COMMENTAIRE       : A exécuter sous SQLPLUS avec le user APPS
----------------------------------------------------------------------------------------------
--- HISTORIQUE DES MODIFICATIONS
--- Date       Qui Description
--- ---------- --- -------------------------------------------------------------------------
--- 06/08/2013 JJA DPE20130064 : Avenant : commande XML
---                Export d'un blob
--------------------------------------------------------------------------------------------

CREATE OR REPLACE JAVA SOURCE NAMED "DkaExtractBlob" AS import java.lang.*; import java.sql.*; import oracle.sql.*; import java.io.*; public class DkaExtractBlob{    public static void ExportBlob(String myFile, BLOB myBlob) throws Exception  {    File binaryFile = new File(myFile);    FileOutputStream outStream = new FileOutputStream(binaryFile);    InputStream inStream = myBlob.getBinaryStream();    int size = myBlob.getBufferSize();    byte[] buffer = new byte[size];    int length = -1;    while ((length = inStream.read(buffer)) != -1)    {      outStream.write(buffer, 0, length);      outStream.flush();    }    inStream.close();    outStream.close();  } };
/

ALTER java source "DkaExtractBlob" compile;

SHOW ERRORS;

EXIT

