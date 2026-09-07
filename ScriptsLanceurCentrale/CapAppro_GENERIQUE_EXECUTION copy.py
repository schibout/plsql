# -*- coding: utf-8 -*-
"""
Created on Tue Dec  5 12:08:13 2023
@author: jguedes
V1.1
"""
# =============================================================================
#                   O R D O N N A N C E U R    C E N T R A L
# =============================================================================
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

# =============================================================================
#                               D   A   T   A
# =============================================================================
global errorMessage
errorMessage = ""

UploadDossier_drive_id = "1BknpE2qPdJCGWgELnpGSIyXd5d5LFbuA"
pathFileOut = r"C:\Temp\CapAppro\Suivi des notes de frais.xlsx"
nomFichierSortie = r"Suivi des notes de frais.xlsx"

# pathFileOut = r"C:\Temp\CapAppro\Suivi des notes de frais - Copie.xlsx"
# nomFichierSortie = r"Suivi des notes de frais - Copie.xlsx"


# =============================================================================
#    I D E N T I F I A N T S    B A S E    D E   D O N N E E S
# =============================================================================
try:
    # =============================================================================
    #                         INSTANCIATION DE GDRIVE.
    # =============================================================================
    try:
        if UploadDossier_drive_id:
            gdriveUpload = gdrive(
                UploadDossier_drive_id, token="générique")
            idFolderUpload = gdriveUpload.getRootFolderId()

            gdriveUpload.uploadFileToDrive(
                                    pathFileOut, nomFichierSortie, idFolderUpload, True)    

    except Exception as Err:
        # errorMessage += "<br>[ERROR] phase d'exécution des requêtes<br>" + str(Err) + "<br>"
        print("3-Erreur détectée dans le process de requêtes\n", Err)


except Exception as Err:
    # errorMessage += "<br>[ERROR] phase d'exécution des requêtes<br>" + str(Err) + "<br>"
    print("3-Erreur détectée dans le process de requêtes\n", Err)
