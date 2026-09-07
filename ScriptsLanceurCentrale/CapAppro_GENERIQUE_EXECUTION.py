# -*- coding: utf-8 -*-
"""
Created on Tue Dec  5 12:08:13 2023
@author: jguedes
V1.7
"""
# =============================================================================
#                   O R D O N N A N C E U R    C E N T R A L
# =============================================================================
import cx_Oracle
import sqlalchemy
import re
import math
import subprocess
import logging
import csv
import time
from datetime import datetime
import os.path
import tempfile
import sys
import os
import pandas as pd
import fire
from configparser import ConfigParser, ExtendedInterpolation
from dateutil.parser import parse
from openpyxl.utils import get_column_letter
from pathlib import Path
import magic
from shutil import copy
    
try:
    from gdrive import gdrive
    from pylibrary import libraries
    from gmail import Mail
except Exception:
    pass

libraryPath = "C:\\RPA\\python-libraries\\"
if(libraryPath not in sys.path):
    sys.path.append(libraryPath)
    from pylibrary import libraries
    from gmail import Mail
    from gdrive import gdrive
    
# =============================================================================
# Récupération des variables passées en paramètres
# =============================================================================
args = {}

def saveToExcel(df, filePath, sheetName, setIndex=False):
    nbRows = df.shape[0]
    nbCols = df.shape[1]
    print("Dimensions Enregistrement du fichier '{filePath}'")
    print("nbRows={nbRows}  | nbCols= {nbCols} ")
    try:
        writer = pd.ExcelWriter(filePath, engine="xlsxwriter",
                                date_format="DD/MM/YYYY", datetime_format="DD/MM/YYYY")
        df.to_excel(writer, sheet_name=sheetName, index=setIndex)
        writer.close()
    except Exception as Err:
        print("[ERROR-SAVETOEXCEL]-Enregistrement du fichier {filePath}\n" + str(Err))
        pass

def saveToCsv(df, filePath):
    df.to_csv(filePath, index=None, sep=';', quoting=csv.QUOTE_NONNUMERIC,
              encoding='utf-8-sig', date_format='%d/%m/%Y %H:%M:%S', float_format='%.5f')

def copyFolder(source_folder, destination_folder):
    import os
    import shutil
    # fetch all files
    for file_name in os.listdir(source_folder):
        # construct full file path
        source = source_folder + file_name
        destination = destination_folder + file_name
        # copy only files
        if os.path.isfile(source):
            shutil.copy(source, destination)
            print('copied', file_name)

def _getSize(filename):
    if os.path.isfile(filename): 
        st = os.stat(filename)
        return st.st_size
    else:
        return -1

def get_size(file_path, unit='mb'):
    file_size = os.path.getsize(file_path)
    exponents_map = {'bytes': 0, 'kb': 1, 'mb': 2, 'gb': 3}
    if unit not in exponents_map:
        raise ValueError("Must select from \
        ['bytes', 'kb', 'mb', 'gb']")
    else:
        size = file_size / 1024 ** exponents_map[unit]
        return str(round(size, 3)) + ' ' + unit.upper()
    
def funcParams(idExec,
               ProjectName,
               DownloadDossier_drive_id,
               filenameLanceur,
               UploadDossier_drive_id,
               copiedataviz,
               requestExpirationDate,
               configBDD,
               ListeDeDiffusion
               # ListeDeDiffusion="joel-externe.guedes@dalkia.fr"
               ):
    global args

    MSG_TO_PROJET = ListeDeDiffusion
    MSG_TO_CC_PROJET = MSG_TO_PROJET

    print("="*15)
    print("Affichage des valeurs passées en paramètres")
    print("="*15, "\n")

    args["idExec"] = idExec
    args["ProjectName"] = ProjectName
    args["DownloadDossier_drive_id"] = DownloadDossier_drive_id
    args["filenameLanceur"] = filenameLanceur
    args["UploadDossier_drive_id"] = UploadDossier_drive_id
    args["copiedataviz"] = copiedataviz
    args["ListeDeDiffusion"] = ListeDeDiffusion
    args["requestExpirationDate"] = requestExpirationDate
    args["configBDD"] = configBDD
    args["MSG_TO_PROJET"] = MSG_TO_PROJET
    args["MSG_TO_CC_PROJET"] = MSG_TO_CC_PROJET

    print("PASSAGE DANS LA FONCTION DE RECUPERATION DES PARAMETRES")
    print("ProjectName", args["ProjectName"])
    print("DownloadDossier_drive_id", args["DownloadDossier_drive_id"])
    print("filenameLanceur", args["filenameLanceur"])
    print("UploadDossier_drive_id", args["UploadDossier_drive_id"])
    print("copiedataviz", args["copiedataviz"])
    print("ListeDeDiffusion", args["ListeDeDiffusion"])
    print("requestExpirationDate", args["requestExpirationDate"])
    print("configBDD", args["configBDD"])

if __name__ == '__main__':
    # converting our fucntion in a Command Line Interface (CLI).
    print("Rentrée dans la fonction main")
    # fire.Fire(funcParmas)
    fire.Fire(funcParams)

# =============================================================================
#           Nettoyage des éléments passés en paramètres.
# =============================================================================
print(args)
for key, value in args.items():
    if value == 'nan':
        args[key] = None
print(args)

# Vérification que tous les éléments sont correctements renseignés.
# any_empty_vals = bool(len(['' for x in args.values() if not x]))
idExec = args["idExec"]
ProjectName = args["ProjectName"]
DownloadDossier_drive_id = args["DownloadDossier_drive_id"]
filenameLanceur = args["filenameLanceur"]
UploadDossier_drive_id = args["UploadDossier_drive_id"]
copiedataviz = args["copiedataviz"]
ListeDeDiffusion = args["ListeDeDiffusion"]
requestExpirationDate = args["requestExpirationDate"]
configBDD = args["configBDD"]

# Attribution des mails pour la réception des résultats ou des incidents.
if ListeDeDiffusion is None:
    MSG_TO_PROJET = "dsin-rpa-run@dalkia.fr"
    MSG_TO_CC_PROJET = None
else:
    MSG_TO_PROJET = ListeDeDiffusion
    MSG_TO_CC_PROJET = "dsin-rpa-run@dalkia.fr"

print("-"*70+'\n', f"EXECUTION GENERIQUE REQUETES POUR {ProjectName}\n", "-"*70+'\n')
print("en dehors du main")

print("+"*70,"\n",f"DATA POUR LE PROJET {ProjectName}\n", "+"*70,"\n"
      f"""
idExec = '{idExec}'
ProjectName = '{ProjectName}'
DownloadDossier_drive_id = '{DownloadDossier_drive_id}'
filenameLanceur = '{filenameLanceur}'
UploadDossier_drive_id = '{UploadDossier_drive_id}'
copiedataviz = '{copiedataviz}'
ListeDeDiffusion = '{ListeDeDiffusion}'
requestExpirationDate = '{requestExpirationDate}'
configBDD = '{configBDD}'
MSG_TO_CC_PROJET = '{MSG_TO_CC_PROJET}'
""","+"*70+"\n")

# =============================================================================
#   UNE FOIS QUE L'ON A RÉCUPÉRÉ L'ENSEMBLE DES ÉLÉMENTS ON PEUT EFFECTUER
#               LE SCRIPT D'EXTRACTION CAPAPPRO DYNAMIQUE
# =============================================================================

# =============================================================================
# aujourdhui = datetime.now().strftime("%d/%m/%Y")
aujourdhui = datetime.now().strftime("%d/%m/%Y %H:%M:%S")

# ***************************************************************************
#                               FUNCTIONS
# ***************************************************************************

def getElapsedTime(startTime, EndTime):
    elapsed_time = EndTime - startTime
    return time.strftime("%H:%M:%S", time.gmtime(elapsed_time))

def createFile(filePath, content, encoding=None):
    try:
        if encoding:
            with open(filePath, 'w', encoding='utf-8') as f:
                f.write(content)
        else:
            with open(filePath, 'w') as f:
                f.write(content)
    except FileNotFoundError:
        print("The 'docs' directory does not exist")

def secTohms(nb_sec):
    q, s = divmod(nb_sec, 60)
    h, m = divmod(q, 60)
    return "%d:%d:%d" % (h, m, s)

def getFileContent(filepath):
    encoding = getFileEncoding(filepath)
    with open(filepath, "r", encoding=encoding) as fichier:
            contentFile = fichier.read()
    return contentFile

def getFileExtension(filename):
    extensionFile = filename.split(".")[-1]
    return extensionFile

def convert(dataf, colonne):
    dataf[colonne] = dataf[colonne].fillna(0)
    dataf[colonne] = dataf.loc[dataf[colonne].notnull(), colonne].apply(
        lambda x:  math.trunc(x))
    dataf[colonne] = dataf[colonne].replace([0], '')

def replacetext(filePath, text, subs, flags=0):
    print(f"replacetext pour le fichier {filePath}")
    encoding = getFileEncoding(filePath)
    print(f"Encoding trouvé {encoding}")
    with open(filePath, "r+",encoding=encoding) as file:
        # read the file contents
        file_contents = file.read()
        text_pattern = re.compile(re.escape(text), flags)
        file_contents = text_pattern.sub(subs, file_contents)
        file.seek(0)
        file.truncate()
        file.write(file_contents)
        file.close()

# =============================================================================
def lancementScriptProcedure(filepath, DB_USER, DB_PASSWORD):
    global errorMessage
    try:
        file_name = os.path.basename(filepath)
        file_extension = os.path.splitext(filepath)
        batFile = file_name.replace(file_extension[1], ".bat")
        filePathbatFile = rf"{folderBat}{batFile}"
        batFileTxt = file_name.replace(file_extension[1], ".txt")
        filePathbatFileTxt = rf"{folderBat}{batFileTxt}"
        procedure = f'sqlplus.exe {DB_USER}/{DB_PASSWORD}@{BASE_URL}:{BASE_PORT}/{BASE_SERVICE_NAME} @"{filepath}"  >"{filePathbatFileTxt}"'
        batchStr = sqlplusPath + "\n" + procedure
        # batchStr = procedure
        createFile(filePathbatFile, batchStr,encoding='utf-8')
        # createFile(r'C:\Temp\batchStr.bat', batchStr,encoding='utf-8')
        # =============================================================================
        #   LANCEMENT DU FICHIER BAT POUR LES PROCÉDURES STOCKÉES.
        # =============================================================================
        start_time = time.time()
        logging.info('Exécution de la procédure :: ' + file_name)
        logging.info('lancement du fichier pour exécution :: ' + filePathbatFile)

        subprocess.run([filePathbatFile])
        time.sleep(3)
        # =============================================================================
       #   Vérification de la présence d'erreur suite à l'éxécution de la procédure.
       # =============================================================================
        msgFR = "Procédure PL/SQL terminée avec succès"
        msgEN = "PL/SQL procedure successfully completed"
        scriptOK = False
        encoding= getFileEncoding(filePathbatFileTxt)
        with open(filePathbatFileTxt, 'r',encoding=encoding) as fp:
            fileContent = fp.readlines()
            for line in fileContent:
                print(line)
                if (line.find(msgFR) != -1) or (line.find(msgEN) != -1):
                    print('string exists in file')
                    print('Line Number:', fileContent.index(line))
                    print('Line:', line)
                    scriptOK = True
                    break
        if not scriptOK:
            print("Procédure KO")            
        # if open(filePathbatFileTxt, 'r').read().find('Procédure PL/SQL terminée avec succès.') < 0:
            # fileContent = open(filePathbatFileTxt, 'r').read()
            fileContent = getFileContent(filePathbatFileTxt)
            print("################         Erreur dans la Procédure  " + file_name + "      ################\n",fileContent)
            errorMessage += "<br><b>Error</b> : Exécution Procédure <b>" + file_name + "</b> : <br>" + fileContent + "<br>"
            logging.ERROR("Error exécution Procédure " + file_name + "\n" + fileContent)
        
        logging.info("temps ecoule exécution Batch '" + file_name + "' " + getElapsedTime(start_time, time.time()))
        print("temps ecoule exécution Batch '",file_name,"' ",
              getElapsedTime(start_time, time.time()))
    except Exception as Err:
        errorMessage += "<br><b>Error</b> : Exécution Procédure <b>" + file_name + "</b><br>"
        logging.ERROR("Error exécution Procédure " + file_name + "\n" + str(Err))
        pass

def append_horodatage(filename,formatHorodatage):
    newFormat = formatHorodatage.replace(
                "DD", "%d").replace(
                "MM","%m").replace(
                "YYYY", "%Y").replace(
                "YY", "%y"
                )
    horodatage = datetime.now().strftime(newFormat)
    print("horodatage : ",horodatage)
    path = Path(filename)
    print("path.stem :: ", path.stem)
    print("path.suffix :: ", path.suffix)
    newFileName = str(path.with_name(f"{path.stem}_{horodatage}{path.suffix}"))
    return newFileName

def detect(
    file_path,
):
    return magic.Magic(
        mime_encoding=True,
    ).from_file(rf"{file_path}")

def getFileEncoding(filePath):
    src_path = filePath
    destination_path = r'C:\Temp\temp.txt'
    copy(src_path, destination_path)
    print('File copied and renamed successfully!')
    encodedFile = detect(destination_path)
    print(f"encodedFile : {encodedFile}")
    os.remove(destination_path)
    print('File removed successfully!')
    return encodedFile

    # =============================================================================
    #                               D   A   T   A
    # =============================================================================
global errorMessage
errorMessage = ""
nomRobot = f"[Lanceur Central][{ProjectName}]"

sqlplusPath = "cd ""C:\\app\\product\\12.2.0\\client_1"""
sqlplusFolderPath = "C:\\app\\product\\12.2.0\\client_1\\"

dateEN = datetime.now().strftime("%Y-%m-%d")
dateENTime = datetime.now().strftime("%Y-%m-%d_%H-%M-%S")
baseFolder = "C:\\RPA\\CapAppro\\04-TestCentral\\downloadFolder\\" + dateEN + "\\"

ONGLET_HISTO = "HistoExec"

mail = Mail()
mail.demarrageRobot(nomRobot)

utils = libraries()
utils.createFolder(baseFolder)

temp_dir = tempfile.TemporaryDirectory(dir=baseFolder)
download_folder = temp_dir.name + "\\"
folderBat = download_folder + "batProcedure\\"
folderOut = download_folder + "extractFiles\\"
folderRequest = download_folder + 'requetes\\'

utils.createFolder(folderBat)
utils.createFolder(folderOut)
utils.createFolder(folderRequest)
_DownloadFolder = folderRequest

logFile = baseFolder + \
    ProjectName + '_' + dateENTime + '.log'
    
logging.basicConfig(filename=logFile, filemode='w', format='%(asctime)s - [ %(levelname)s ] - %(message)s',
                    datefmt='%d/%m/%Y %H:%M:%S', level=logging.INFO)
# datefmt='%d/%m/%Y %H:%M:%S', level=logging.DEBUG)

# =============================================================================
#    I D E N T I F I A N T S    B A S E    D E   D O N N E E S
# =============================================================================
try:
    tempsTotalStart = time.time()
# ==========================================================================================================================================================

    # =============================================================================
    #                       D E B U G      S C R I P T
    # =============================================================================
        # ProjectName = 'Extractions Clôtures_Test'
        # DownloadDossier_drive_id = '1-VX4UPGXLh_H77n6jrK0NJFH4ihqGJur'
        # filenameLanceur = 'EXTRACTIONS.xlsx'
        # UploadDossier_drive_id = '1odH5pbjcbZVYJ4K-mFkQdOsMKOgB0Zy_'
        # copiedataviz = ''
        # ListeDeDiffusion = 'joel-externe.guedes@dalkia.fr'
        # requestExpirationDate = ''
        # configBDD = 'config_oracle_test'
        # MSG_TO_CC_PROJET = 'joel-externe.guedes@dalkia.fr'
# ==========================================================================================================================================================

    # =============================================================================
    #     Lecture du fichier de configuration
    # =============================================================================
    try:
        iniFile = r"C:\RPA\CapAppro\04-TestCentral\Scripts\config_lanceur_central.ini"
        cfg = ConfigParser(interpolation=ExtendedInterpolation())
        cfg.read(iniFile, encoding="utf-8")
        
        cfg_PROJET = cfg[configBDD]
        DB_USER = cfg_PROJET["DB_USER"]
        DB_PASSWORD = cfg_PROJET["DB_PASSWORD"]

        BASE_URL = cfg_PROJET["BASE_URL"]
        BASE_PORT = cfg_PROJET["BASE_PORT"]
        BASE_SERVICE_NAME = cfg_PROJET["BASE_SERVICE_NAME"]
        TYPE_BDD = cfg_PROJET["TYPE"]
    except Exception as Err:
        logging.error("ERROR lecture du fichier de configuration.\nRécupération des infos du fichier de configuration\n" + str(Err))
        errorMessage += "ERROR lecture du fichier de configuration.\nRécupération des infos du fichier de configuration\n" + str(Err)
        raise Exception("Récupération des infos du fichier de configuration")

    # =============================================================================
    #                   Connexion à la BDD ORACLE
    # =============================================================================
    if TYPE_BDD == "ORACLE":
        try:
            print("connexion à la base de données\nDB_USER=" +
                  DB_USER+" \nDB_PASSWORD = " + DB_PASSWORD)
            cx_Oracle.init_oracle_client(lib_dir=sqlplusFolderPath + "\\bin")
            chaineConnexion = "oracle+cx_oracle://" + DB_USER + ":" + \
                DB_PASSWORD + "@" + BASE_URL + "/?service_name=" + BASE_SERVICE_NAME
            engine = sqlalchemy.create_engine(chaineConnexion, arraysize=1000)
        except Exception as Err:
            errorMessage += "<br>Error Configuration </b> : <br>Erreur dans la préparation de la configuration du script de lancement.<br>" + \
                str(Err) + "<br>"
            print("errorMessage", errorMessage)
            logging.error(errorMessage)
            # Sortie du pgm car on ne peut pas continuer
            raise Exception()
    # =============================================================================
    #                   Connexion à la MSSQLSERVER
    # =============================================================================
   # TODO mettre en place le cas ou on devra effectuer des requêtes dans le cas de base de données MSSL SERVER
    if TYPE_BDD == "SQLSERVER":
        try:
            print("connexion à la base de données\nDB_USER=" +
                  DB_USER+" \nDB_PASSWORD = " + DB_PASSWORD)
            chaineConnexion = "mssql+pyodbc://" + DB_USER + ":" + \
                DB_PASSWORD + "@" + BASE_URL + "/" + BASE_SERVICE_NAME + "?driver=SQL+Server"
            engine = sqlalchemy.create_engine(chaineConnexion)
        except Exception as Err:
            errorMessage += "<br>Error Configuration </b> : <br>Erreur dans la préparation de la configuration du script de lancement.<br>" + \
                str(Err) + "<br>"
            print("errorMessage", errorMessage)
            logging.error(errorMessage)
            # Sortie du pgm car on ne peut pas continuer
            raise Exception()
    # =============================================================================
    #                         INSTANCIATION DE GDRIVE.
    # =============================================================================
    try:
        listExecution = []

        if UploadDossier_drive_id:
            gdriveUpload = gdrive(
                UploadDossier_drive_id, token="générique")
            idFolderUpload = gdriveUpload.getRootFolderId()

        gdriveDownload = gdrive(DownloadDossier_drive_id, token="générique") 

        # =============================================================================
        # 1 - TELECHARGEMENT DU FICHIER EXCEL DE LANCEMENT DES REQUETES  LOCAL
        # =============================================================================
        try:
            fileIdLancementCapAppro = gdriveDownload.get_Element_id(filenameLanceur)
            print(f"L id du fichier lanceur est {filenameLanceur} ")
            gdriveDownload.download_fileById(fileIdLancementCapAppro, folder_path=_DownloadFolder)
        except Exception as Err:
            errorMessage += "<br><b>Error</b> : Le Fichier <b>" + filenameLanceur + \
                "</b> n'a pas pu être téléchargé depuis le drive.<br>" + \
                str(Err) + "<br>"
            logging.error("Le Fichier " + filenameLanceur +
                          " n'a pas pu être téléchargé depuis le drive.\n" + str(Err))
            print("récupération du fichier de lancement des requêtes : \n", "Le Fichier " +
                  filenameLanceur + " n'a pas pu être téléchargé depuis le drive.")
            raise Exception()

        # =============================================================================
        # 2 - LISTER LES FICHIERS QUI SONT A LANCER
        # =============================================================================
        try:
            # ==========================================================================================================================================================
            listMyElements = gdriveDownload.get_childrenFolder(
                DownloadDossier_drive_id, filesOnly=True)

            dflistMyElements = pd.DataFrame(listMyElements)
            df_driveFiles = dflistMyElements[["id", "name"]]

            Listcolumns = ['Nom rêquete', 'Type rêquete',
                           'Exécution', 'Nom fichier sortie','formatHorodatage']
            dfRequestLists = pd.read_excel(folderRequest + filenameLanceur, usecols=Listcolumns)
            dfRequestLists = dfRequestLists.loc[dfRequestLists["Exécution"].str.lower() == "oui"]
            # On regarde si tous les fichiers sont présents dans le drive pour être téléchargé.
            dfjoinLeft = pd.merge(dfRequestLists,
                                  df_driveFiles,
                                  left_on='Nom rêquete',
                                  right_on='name',
                                  how="left",
                                  indicator=True
                                  )

            missingFiles = dfjoinLeft.query('_merge=="left_only"').drop(columns=["_merge"])
            listMissingFiles = missingFiles["Nom rêquete"].to_list()

            # =============================================================================
            # RECHERCHE DE FICHIERS NON PRESENTS SUR LE DRIVE QUI SONT A TELECHARGER
            # =============================================================================
            if listMissingFiles:
                print("ok")
                missingFilesStr = "- " + \
                    '\n- '.join(missingFiles["Nom rêquete"].to_list())
                print(
                    f"Les fichiers suivants sont manquants sur le drive\n{missingFilesStr}")
                logging.error(
                    f"Les fichiers suivants sont manquants sur le drive\n{missingFilesStr}")
                # TODO envoie d'un mail pour prévenir que des fichiers sont maquants sur le drive
                subject = f'{nomRobot} Export {TYPE_BDD} - Fichiers manquants'
                mail.sendMail(MSG_TO_PROJET, subject,
                              f"Les fichiers suivants sont manquants sur le drive\n{missingFilesStr}", msgToCC=MSG_TO_CC_PROJET)
                missingFilesStr = missingFilesStr.replace("\n", "<br>")
                errorMessage += f"Les fichiers suivants sont manquants sur le drive<br><b>{missingFilesStr}</b><br>"

            dfRequestsList = dfjoinLeft.query('_merge=="both"').drop(columns=["_merge"])
            # saveToExcel(dfRequestsList, r"C:\Temp\dfRequestsListToLaunch.xlsx", "sheetName")
            # =============================================================================
            #             LISTE LES REQUÊTES QUI SONT À LANCER
            # =============================================================================
            dfRequests = dfRequestsList.loc[(dfRequestsList["Type rêquete"].str.lower() == "export")]
            # saveToExcel(dfRequestsList, r"C:\Temp\dfRequests.xlsx", "sheetName")
            # =============================================================================
            #             LISTE LES SCRIPTS DE PROCÉDURE QUI SONT À LANCER
            # =============================================================================
            dfScripts = dfRequestsList.loc[dfRequestsList["Type rêquete"].str.lower(
            ) == "script"]
            # saveToExcel(dfRequestsList, r"C:\Temp\dfScripts.xlsx", "sheetName")
            dfTelechargementFiles = pd.concat([dfScripts, dfRequests])
            # saveToExcel(dfRequestsList, r"C:\Temp\dfTelechargementFiles.xlsx", "sheetName")
# ==========================================================================================================================================================
            listfile_ids = dfTelechargementFiles["id"].to_list()
            listfile_names = dfTelechargementFiles["name"].to_list()
            try:
                gdriveDownload.downloadDocuments(listfile_ids, listfile_names, _DownloadFolder)
                print("--")
                listFolder = utils.getFileList(_DownloadFolder)
                dfFichiersManquant = dfTelechargementFiles[~dfTelechargementFiles['name'].isin(listFolder)]
                print(dfFichiersManquant.shape[0])
                if dfFichiersManquant.shape[0] > 0:
                    missingFilesStr = "- " + \
                        '\n- '.join(dfFichiersManquant["name"].to_list())
                    print(
                        "des fichiers sont manquants après le téléchargement du drive vers le local", missingFilesStr)
                    errorMessage += "<br><b>Error</b> : Erreur lors du téléchargement des fichiers de requêtes<br>" + \
                        missingFilesStr + "<br>"
                    logging.error(
                        f"des fichiers de requêtes sont manquants après le téléchargement du drive vers le local {missingFilesStr}")
            except Exception as Err:
                errorMessage += "<br><b>Error</b> : Erreur lors du téléchargement des fichiers de requêtes<br>" + \
                    str(Err) + "<br>"
                logging.error(
                    "Erreur lors du téléchargement de certains fichiers de requêtes")
                print("errorMessage", errorMessage)
                raise Exception()
            
            # =============================================================================
            # 4 - MODIFIER LES FICHIERS DE REQUETES POUR ENLEVER LE ';'
            # =============================================================================
            print("On commence la phase de remplacement des ';'")
            for filename in dfRequests["Nom rêquete"].to_list():
                print(f"Remplacement pour le fichier {filename}")
                replacetext(_DownloadFolder + filename, ";", "")
            print("Fin de la phase de remplacement des ';'")

        except Exception as Err:
            errorMessage += "<br><u> - Error Google DRIVE - </u><br> Une Erreur est survenue pendant la phase de récupération des fichiers sur le DRIVE<br>" + \
                str(Err) + "<br>"
            logging.error(
                "Error Google DRIVE - Une Erreur est survenue pendant la phase de récupération des fichiers sur le DRIVE\n" + str(Err))
            print("errorMessage", errorMessage)
            raise Exception()
    except Exception as Err:
        errorMessage += "<br><u> - Error Google DRIVE - </u><br> Une Erreur est survenue pendant la phase de récupération des fichiers sur le DRIVE<br>" + \
            str(Err) + "<br>"
        logging.error(
            "Error Google DRIVE - Une Erreur est survenue pendant la phase de récupération des fichiers sur le DRIVE\n" + str(Err))
        print("errorMessage", errorMessage)
        raise Exception()
# ==========================================================================================================================================================
    # =============================================================================
    #   LANCEMENT DE L EXECUTION DE L ENSEMBLE DES REQUETES
    # =============================================================================
    
    try:
        logging.info(f"{ProjectName} - LANCEMENT DE L EXECUTION DE L ENSEMBLE DES REQUETES")
        # logging.info('lancement de l extraction')
        now = datetime.now()
        nbRequests = dfRequests.shape[0]
        numRequest = 0
        dfRequestListsExec = dfTelechargementFiles.copy()
        dfRequestListsExec.fillna("", inplace=True)
        dfRequestListsExec = dfRequestListsExec.sort_index(ascending=True)
        print("Lancement de l'exécution")
        for i in dfRequestListsExec.index:
            nom_Element = ""
            statut_ExcRequest = ""
            statut_EnregistrementLocal = "-"
            statut_EnregistrementDistant = "-"

            # EXÉCUTION DES SCRIPTS DE PROCÉDURE.
            if (str(dfRequestListsExec["Type rêquete"][i]).lower() == "script"):
                try:
                    print("\n====================================\nLancement du script :: ",
                          dfRequestListsExec["Nom rêquete"][i], "\n====================================")
                    logging.info("\n====================================\nLancement du script :: " +
                                 dfRequestListsExec["Nom rêquete"][i] + "\n====================================")
                    # =============================================================================
                    # 5 - LANCEMENT DES SCRIPTS DE PREPARATION
                    # =============================================================================
                    tempsExecutionScriptsStart = time.time()
                    nom_Element = dfRequestListsExec["Nom rêquete"][i]
                    lancementScriptProcedure(
                        _DownloadFolder + dfRequestListsExec["Nom rêquete"][i], DB_USER, DB_PASSWORD)
                    tempsExecutionScriptsEnd = time.time()
                    statut_ExcRequest = "OK"
                    listExecution.append(
                        (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                    print("\n====================================\nFIN Lancement du script :: ",
                          dfRequestListsExec["Nom rêquete"][i], "\n====================================")
                    print("\n\n ----- Temps d'exécution des scripts de préparation ----- [", getElapsedTime(
                        tempsExecutionScriptsStart, tempsExecutionScriptsEnd), "]")
                    logging.info("Temps Temps d'exécution des scripts de préparation  : [" + getElapsedTime(
                        tempsExecutionScriptsStart, tempsExecutionScriptsEnd) + "]")
                except Exception as Err:
                    statut_ExcRequest = "KO"
                    logging.error("[ERROR] lancement du script : " +
                                 dfRequestListsExec["Nom rêquete"][i] + "\n" + str(Err))
                    print("[ERROR] lancement du script : ",
                          dfRequestListsExec["Nom rêquete"][i] + "\n" + str(Err))
                    errorMessage += \
                        "<br>[ERROR] lancement du script : <b>" + \
                        dfRequestListsExec["Nom rêquete"][i] + "</b><br>" + str(Err)
                    listExecution.append(
                        (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                    copyFolder(download_folder, r"C:\Temp\debugOracle\\")
                    continue
            # EXÉCUTION DE LA REQUÊTE
            elif (str(dfRequestListsExec["Type rêquete"][i]).lower() == "export"):
                numRequest += 1
                tempsTraitementStart = time.time()
                nom_Element = dfRequestListsExec["Nom rêquete"][i]
                try:
# =============================================================================
#       effectuer le remplacement du nom de fichier si l'horodatage est renseigné.
# =============================================================================
                    formatHorodatage = dfRequestListsExec["formatHorodatage"][i]
                    print(f"formatHorodatage : {formatHorodatage} ", type(formatHorodatage))
                    if len(formatHorodatage) == 0:
                        print("le format d'horodatage n'est pas renseigné")
                        nomFichierSortie = dfRequestListsExec["Nom fichier sortie"][i]
                    else:
                        print("le format d'horodatage est renseigné")
                        nomFichierSortie = append_horodatage(dfRequestListsExec["Nom fichier sortie"][i]
                                                             ,formatHorodatage)
                    extensionFichierSortie = utils.getFileExtension(
                        nomFichierSortie).lower()
                        
                    pathFileOut = folderOut + nomFichierSortie
                    requestName = dfRequestListsExec["Nom rêquete"][i]
                    print("--> Exécution de la requête ", requestName)
                    
                    fileReq = folderRequest + requestName
                # =============================================================================
                #      EXECUTION REQUETE
                # =============================================================================
                    startRequest = time.time()
                    query = getFileContent(fileReq)
                    print("Lancement requête :: [", numRequest.__str__(), "/", nbRequests.__str__(
                    ), "] - Requête  ", requestName, " A enregister dans le fichier -> ", nomFichierSortie)
                   
                    logging.info("\n" + "="*70 + "\nLancement requête :: " + \
                                 "[" + str(numRequest) + "/" + str(nbRequests) + "] - Requête  " + requestName + " A enregister dans le fichier -> " + str(nomFichierSortie) + \
                                  "\n" + "="*70
                                     )
                    # logging.info("Lancement requête :: [" + str(numRequest) + "/" + str(nbRequests) + "] - Requête  " + requestName + " A enregister dans le fichier -> " + str(nomFichierSortie))
                    df = pd.read_sql(query, engine)
                    statut_ExcRequest = "OK"
                    endRequest = time.time()
                    print(
                        "      * Temps Exécution requete : [", getElapsedTime(startRequest, endRequest), "]")
                    logging.info(
                        "Temps exécution requête : [" + getElapsedTime(startRequest, endRequest) + "]")
                except Exception as Err:
                    statut_ExcRequest = "KO"
                    errorMessage += "<br>Error  Requête  - <b>" + \
                        requestName + "</b><br>" + str(Err) + "<br>"
                    logging.error("Error  Requête  - " + \
                        requestName + "\n" + str(Err))
                    print(
                        "[ERROR] détectée lors de l'exécution de la requête \n", Err)
                    listExecution.append(
                        (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                    continue

                # ENREGISTREMENT DANS L'EXTENSION CIBLE CSV OU XLSX
                try:
                    my_type = 'float64'
                    dtypes = df.dtypes.to_dict()

                    for col_name, typ in dtypes.items():
                        if (typ == my_type and col_name.startswith('id')):
                            convert(df, col_name)

                    startToExec = time.time()
                    # =============================================================================
                    #         ENREGISTREMENT RESULTATS DANS UN CSV
                    # =============================================================================
                    if extensionFichierSortie == 'csv':
                        logging.info(
                            "Enregistrement des données vers le fichier CSV")
                        df.to_csv(pathFileOut, index=None, sep=';', quoting=csv.QUOTE_NONNUMERIC,
                                  encoding='utf-8-sig', date_format='%d/%m/%Y %H:%M:%S', float_format='%.5f')
                        statut_EnregistrementLocal = "OK"
                    # =============================================================================
                    #         ENREGISTREMENT RESULTATS DANS UN FICHIER EXCEL
                    # =============================================================================
                    elif extensionFichierSortie == 'xlsx':
                        logging.info(
                            "Enregistrement des données vers le fichier EXCEL")
                        saveToExcel(df, pathFileOut, "Sheet1")
                        statut_EnregistrementLocal = "OK"
                    else:
                        errorMessage += "<br>Error  Requête  - <b>" + requestName + \
                            "</b><br>Le fichier de sortie ne correspond à aucun des formats attendus, 'csv|xlsx'.<br>"
                        print(
                            "L'extension du fichier de sortie n'est pas reconnu, 'csv' ou 'xlsx'")
                        logging.info(
                            "L'extension du fichier de sortie n'est pas reconnu, 'csv' ou 'xlsx'")
                        statut_EnregistrementLocal = "KO"

                    endToExec = time.time()

                    print("Fin de copie de fichier en local [", getElapsedTime(
                        startToExec, endToExec), "]")
                    logging.info("Temps enregistrement des résultats en Local : [" + str(
                        getElapsedTime(startToExec, endToExec)) + "]")
                except Exception as Err:
                    statut_EnregistrementLocal = "KO"
                    errorMessage += "<br>[ERROR] Enregistrement du fichier  - <b>" + \
                        requestName + "</b><br>" + str(Err) + "<br>"
                    logging.error(
                        "Erreur lors de l'enregistrement du fichier  - " + \
                            nomFichierSortie + "\n" + str(Err))
                    print(
                        "[ERROR] détectée lors de l'enregistrement du fichier de résultats\n", Err)
                    listExecution.append(
                        (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                    continue

                # Upload du fichier sur le drive
                if UploadDossier_drive_id:
                    try:
                        print("--> Upload du fichier sur le drive")
                    # =============================================================================
                    #           UPLOAD DU FICHIER SUR LE REPERTOIRE DRIVE DU PROJET
                    # =============================================================================
                        startToDrive = time.time()
                        print("=> Upload du fichier vers le Drive : {nomFichierSortie} ( "+ get_size(pathFileOut) + ")")
                        logging.info(f"=> Upload du fichier vers le Drive : {nomFichierSortie} ( "+ get_size(pathFileOut) + " )")
                        # print("Nom du fichier sur le drive " , nomFichierSortie, " - " , pathFileOut," - " ,idFolderUpload)
                        upLoaded = False
                        msgError = ""
                        for i in range(0, 3):
                            try:
                                print("Tentative d'upload N°", i+1)
                                gdriveUpload.uploadFileToDrive(
                                    pathFileOut, nomFichierSortie, idFolderUpload, True)
                                print("Le fichier a correctement était uploadé.")
                                upLoaded = True
                                break
                            except Exception as Err:
                                msgError = Err
                                continue               
                        
                        if upLoaded:    
                            endToDrive = time.time()
                            print("Fin de copie de local vers le drive : ", nomFichierSortie,
                                  "[", getElapsedTime(startToDrive, endToDrive), "]")
                            logging.info("Temps Upload vers le Drive : " + nomFichierSortie +
                                         "[" + str(getElapsedTime(startToDrive, endToDrive)) + ']')
                            statut_EnregistrementDistant = "OK"
                            # listExecution.append((nom_Element,statut_ExcRequest,statut_EnregistrementLocal,statut_EnregistrementDistant))
                        else:
                            raise Exception(msgError)
                            
                    except Exception as Err:
                        statut_EnregistrementDistant = "K0"
                        listExecution.append(
                            (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                        errorMessage += "<br>[ERROR] Upload du fichier sur le drive - <b>" + \
                            nomFichierSortie + "</b><br>" + str(Err) + "<br>"
                        logging.error(
                            "[ERROR] Upload du fichier sur le drive - " + nomFichierSortie + "\n" + str(Err))
                        print("[ERROR] Upload du fichier sur le drive \n", Err)
                        continue

                # Upload du fichier sur le dataViz
                if copiedataviz:
                    try:
                        print("--> Upload du fichier sur le dataViz")
                    # =============================================================================
                    #           UPLOAD DU FICHIER SUR LE REPERTOIRE DRIVE DU PROJET
                    # =============================================================================
                        startToDrive = time.time()
                        print(":::  Copie de Local vers le DataViz :::")
                        logging.info("=> Upload du fichier vers le DataViz")
                        print("liste des fichiers présents dans le dossier source :: \n", utils.getFileList(
                            folderOut))
                        # On rajoute la fin du / pour effectuer la copie vers le dataViz si manquant
                        copy(pathFileOut,copiedataviz)
                        # utils.copyAllFiles(folderOut, copiedataviz)
                        statut_EnregistrementDistant = "OK"
                        endToDrive = time.time()
                        print("Fin de copie de local vers le DataViz : ", nomFichierSortie,
                              "[", getElapsedTime(startToDrive, endToDrive), "]")
                        logging.info("Temps Upload vers le DataViz : " + nomFichierSortie +
                                     "[" + str(getElapsedTime(startToDrive, endToDrive)) + ']')
                    except Exception as Err:
                        statut_EnregistrementDistant = "KO"
                        listExecution.append(
                            (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                        errorMessage += "4<br>[ERROR] Upload du fichier sur le DataViz - <b>" + \
                            nomFichierSortie + "</b><br>" + str(Err) + "<br>"
                        logging.error(
                            "[ERROR] Upload du fichier sur le DataViz - " + nomFichierSortie + "\n" + str(Err))
                        print("[ERROR] Upload du fichier sur le DataViz \n", Err)
                        continue

                listExecution.append(
                    (nom_Element, statut_ExcRequest, statut_EnregistrementLocal, statut_EnregistrementDistant))
                tempsTraitementEnd = time.time()
                
                print("\nTemps de traitement de l'EXPORT =>  [", getElapsedTime(
                    tempsTraitementStart, tempsTraitementEnd), "]\n")
                logging.info("=> Temps traitement de la requête =>  [" + getElapsedTime(
                    tempsTraitementStart, tempsTraitementEnd) + "]")
                print("\n====================================\nFIN Lancement de la requête :: ",
                      requestName, "\n====================================")

    except Exception as Err:
        # errorMessage += "<br>[ERROR] phase d'exécution des requêtes<br>" + str(Err) + "<br>"
        print("2-Erreur détectée dans le process de Scripts/Requêtes\n", Err)
        logging.error(
            "2-Erreur détectée dans le process de Scripts/Requêtes\n" + str(Err))

except Exception as Err:
    # errorMessage += "<br>[ERROR] phase d'exécution des requêtes<br>" + str(Err) + "<br>"
    print("3-Erreur détectée dans le process de requêtes\n", Err)
    logging.error("3-Erreur détectée dans le process de requêtes\n" + str(Err))

tempsTotalEnd = time.time()
tempsTraitementTotal = getElapsedTime(tempsTotalStart, tempsTotalEnd)
print("\n ----- Temps de traitement des différents EXPORTS ----- [", getElapsedTime(
    tempsTotalStart, tempsTotalEnd), "]\n\n")
logging.info("Temps Total de traitement des différents EXPORTS  : [" + getElapsedTime(
    tempsTotalStart, tempsTotalEnd) + "]")

# =============================================================================
#                       préparation des stats
# =============================================================================
bodyStart = '''
<html>
<head>
<style>               
table.dataframe {
  font-family: "Trebuchet MS", Helvetica, sans-serif;
  border: 1px solid #1C6EA4;
  background-color: #EEEEEE;
  width: 50%;
  border-collapse: collapse;
}

table.dataframe td{
    text-align: center;
}

table.dataframe td:first-child {
    text-align: left;
}

table.dataframe td, table.dataframe th {
  border: 1px solid #AAAAAA;
  padding: 3px 2px;
}
table.dataframe tbody td {
  font-size: 13px;
}
table.dataframe tr:nth-child(even) {
  background: #B1B8CB;
}
table.dataframe thead {
  background: #46537C;
  background: -moz-linear-gradient(top, #747e9d 0%, #586489 66%, #46537C 100%);
  background: -webkit-linear-gradient(top, #747e9d 0%, #586489 66%, #46537C 100%);
  background: linear-gradient(to bottom, #747e9d 0%, #586489 66%, #46537C 100%);
  border-bottom: 2px solid #444444;
}
table.dataframe thead th {
  font-size: 14px;
  font-weight: bold;
  color: #FFFFFF;
  text-align: center;
  border-left: 2px solid #D0E4F5;
}
table.dataframe thead th:first-child {
  border-left: none;
}

table.dataframe tfoot td {
  font-size: 14px;
}
table.dataframe tfoot .links {
  text-align: right;
}
</style>
</head>
<body>
<p>Bonjour,</p>
<p>le script d'exécution des reqêtes est terminé.</p>
'''
if listExecution:
    df = pd.DataFrame(listExecution, columns=[
                      "nom_Element", "statut_ExcRequest", "statut_EnregistrementLocal", "statut_EnregistrementDistant"])
    html_table = df.to_html(escape=False, index=False)
    bodyEnd = bodyStart + html_table
else:
    bodyEnd = bodyStart

subjectEnd = f'{nomRobot} Export {TYPE_BDD} - Fin Exécution du robot'

if errorMessage != "":
    subjectEnd = f'{nomRobot} Export {TYPE_BDD} - Incident rencontré le {aujourdhui}'
    bodyEnd = bodyEnd + \
        "\nUne ou plusieurs erreur(s) a/ont été rencontrée(s) lors de l'exécution du scipt<br><br>" + \
        errorMessage + "<br>"

bodyEnd += """
<p><span style="text-decoration: underline;"><span style="color: #0000ff; text-decoration: underline;">Team Rpa</span></span></p>
</body>
</html>
"""
if errorMessage != "":
    mail.sendMail(MSG_TO_PROJET, subjectEnd, bodyEnd, msgToCC=MSG_TO_CC_PROJET)
    print("errorMessage", errorMessage)
    pass
else:
    mail.sendMail(MSG_TO_PROJET, subjectEnd, bodyEnd, msgToCC=MSG_TO_CC_PROJET)

# ------------------------------------------------------------------------------------------------
#             Envoi d'un mail en cas de date expirée dans le fichier Excel
# ------------------------------------------------------------------------------------------------
try:
    if requestExpirationDate:
        dateExpirationRequete = parse(requestExpirationDate)
        print(dateExpirationRequete)

        if (dateExpirationRequete < now):
            expireDate = dateExpirationRequete.strftime("%d/%m/%Y")
            bodyRequeteExpiree = f"""
                <html>
                <body>
                <p>Bonjour,</p>
                <p>les requêtes du projet <b>{ProjectName}</b> ont été exécutées </p>
                mais ont une date d'expiration dépassant la date fixée dans le fichier de lancement <b>{expireDate}</b>.<br><p>Team RPA</p>
            """
            print(
                f"Comparaison des dates pour voir la date d'expiration {requestExpirationDate} < {now}")
            print(f"requestExpirationDate : {requestExpirationDate}")
    
            print(f"comparaison de {dateExpirationRequete} < {now}", type(
                dateExpirationRequete), type(now))
            
            print(f"Projet [{ProjectName}] date dépassée " + now.strftime("%d/%m/%Y") +
                  " vs " + requestExpirationDate)
            logging.info(f"Projet [{ProjectName}] date dépassée " + now.strftime("%d/%m/%Y") +
                  " vs " + requestExpirationDate)
            bodyRequeteExpiree += "</body></html>"
            mail = Mail()
            subject = f'{nomRobot} Export {TYPE_BDD} - Expiration requête(s)'
            mail.sendMail(MSG_TO_PROJET, subject, bodyRequeteExpiree, msgToCC=MSG_TO_CC_PROJET)
except Exception as Err:
    print("Erreur recontrée dans l'envoie du mail de requêtes expirées.", str(Err))
    errorMessage += "Erreur recontrée dans l'envoie du mail de requêtes expirées."
    logging.error(
        "Erreur recontrée dans l'envoie du mail de requêtes expirées.\n" + str(Err))
    pass

# =============================================================================
# Mise à jour vers le googleSheet du statut général d'exécution
# =============================================================================
# emplacement de l'ordonnanceur central
dossier_drive_id_root = "1bkXK77bOQb8TXG69y_n_Qw9zM-Wru1BO"
gdriveExec = gdrive(dossier_drive_id_root,token='générique')

# =============================================================================
#                   MISE A JOUR DE L EXECUTION 
# =============================================================================
# Informations sur le fichier d'ordonnancement central 
spreadsheet_id = "1QNJUUM8lJcHkVOQTNguInGvmI5xZX69EwUqxYL0al1Q"

if errorMessage != "":  
    statut_Traitement = "KO"
else:
    statut_Traitement = "OK"

logFileName = os.path.basename(logFile)

rowUpdate = [idExec
            ,ProjectName
            ,aujourdhui
            ,tempsTraitementTotal
            ,statut_Traitement
            ,logFileName
            ]
print(rowUpdate)
colsCount = gdriveExec.get_SheetColumnCount(spreadsheet_id, ONGLET_HISTO)
endLetter = get_column_letter(colsCount)
range_notation = f"'{ONGLET_HISTO}'!A:{endLetter}"
service = gdriveExec.getGheetService()
sheet = service.spreadsheets()
body = {
     'values': [
         rowUpdate
         ]
 }
result = sheet.values().append(spreadsheetId=spreadsheet_id,
                               range=range_notation,
                               body=body,
                                valueInputOption="RAW",
                                # permet de noter les formules directement 
                                # valueInputOption="USER_ENTERED",
                               insertDataOption="INSERT_ROWS").execute()

updatedRange = result['updates']['updatedRange']       
regexp = "\w(\d+):\w\d+"      
text = re.search(rf'{regexp}', updatedRange, re.IGNORECASE)
row_Index = str(int(text.group(1)) - 1)
print("row_Index : {row_Index}")    

# =============================================================================
# Récupération des données des onglets de l'ordonnanceur
dfHistoExec = gdriveExec.SetValuesGsheetToDataFrame(spreadsheet_id, ONGLET_HISTO)
# saveToExcel(dfHistoExec, r"C:\Temp\dfHistoExec.xlsx", "sheetName")
dfData = gdriveExec.SetValuesGsheetToDataFrame(spreadsheet_id, "data")
# saveToExcel(dfData, r"C:\Temp\dfData.xlsx", "sheetName")
dfLanceur = gdriveExec.SetValuesGsheetToDataFrame(spreadsheet_id, "Feuil1")
# saveToExcel(dfLanceur, r"C:\Temp\dfLanceur.xlsx", "sheetName")
# Upload du fichier de log dans le drive adéquat
# Récupération dans feuil1 de la config utilisée
# configBDD = "config_oracle_finance"
# Récupération dans data du dossier drive de la config utilisée pour les logs.
try:
    print("Recherche dans le fichier de data le dossier drive id correspondant à la configuration en cours.")
    driveLogs = dfData.loc[dfData["configBDD"]==configBDD]["driveLogs"].values[0]
    print(f"le drive récupéré pour l'upload est driveLogs={driveLogs} avec la configuration {configBDD}")
    print(f"le fichier de log a uploadé est logFile={logFile}")
    gdriveExec.uploadFileToDrive(logFile,folder_id=driveLogs, override=True)
    
    # =============================================================================
    #  ajout d'un lien hyperlink vers le dossier contenant les logs d'exécution du projet   
    # =============================================================================
    
    # def addHyperlink(self, hyperlink, text, sheetId, rowIndex, colIndex):
    # hyperlink = "https://drive.google.com/drive/u/0/folders/1Lh69FQwcB42J6TDzYwAEGnF4IcLkmnqP"
    hyperlink = f"https://drive.google.com/drive/u/0/folders/{driveLogs}"
    text = logFileName
    sheetId = gdriveExec.get_SheetId(spreadsheet_id, ONGLET_HISTO)
    rowIndex = row_Index
    colIndex = "5"
    requests = []
    requests.append({
        "updateCells": {
            "rows": [
                {
                    "values": [{
                        "userEnteredValue": {
                            "formulaValue":"=LIEN_HYPERTEXTE(\"{}\";\"{}\")".format(hyperlink, text) 
                        }
                    }]
                }
            ],
            "fields": "userEnteredValue",
            "start": {
                "sheetId": sheetId,
                "rowIndex": rowIndex,
                "columnIndex": colIndex
            }
        }})
    body = {
        "requests": requests
    }
    request = service.spreadsheets().batchUpdate(spreadsheetId=spreadsheet_id, body=body)
    request.execute()
except Exception as Err:
    print(f"ERROR Upload Log.\nImpossible de récupérer le drive de la configuration utilisée : {configBDD}", str(Err))
    logging.error(
        f"ERROR Upload Log.\nImpossible de récupérer le drive de la configuration utilisée : {configBDD}" + "\n" + str(Err))

# ==========================================================================================================================================================
#                   METS EN ÉCHEC EN CAS D'ERREURS RECONTRÉES.
# ==========================================================================================================================================================
mail.finRobot(nomRobot)
if errorMessage != "":
    print("des erreurs ont eu lieu pendant l'exécution du script \n", errorMessage)
    raise Exception(errorMessage)
# temp_dir.cleanup()