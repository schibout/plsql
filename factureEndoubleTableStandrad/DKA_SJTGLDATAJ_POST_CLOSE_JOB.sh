#!/usr/bin/ksh
#
#**************************************************************************
#  $HEADER : DKA_LOADER_DKA_EMPJOBSIMP V1.0  
# 
#  FILENAME
#   DKA_LOADER_DKA_EMPJOBSIMP
# 
#  DESCRIPTION
#     Phase de chargement via Sql*Loader.
# 
#  USAGE
#   DKA_LOADER_DKA_EMPJOBSIMP FCP_LOGIN FCP_USERID FCP_USERNAME FCP_REQID
#
#  NOTES
#   Executable seulement sous une connexion OeBs
# 
#  PARAMETERS
#  ==========
#  NAME              DESCRIPTION
#  ----------------- ------------------------------------------------------
#  FCP_REQID         Paramètre standard Request ID
#  FCP_LOGIN         Paramètre standard Login
#  FCP_USERID        Paramètre standard User Id
#  FCP_PRINTER       Paramètre standard Printer
#  FCP_SAVE_OUT      Paramètre standard Save Out
#  FCP_NUM_COPIES    Paramètre standard Number Of Copies
#  FCP_USERNAME      Paramètre standard User Name
# 
#  HISTORY
#  =======
# 
#  VERSION DATE        QUI        DESCRIPTION
#  ------- ----------- ---------  ------------------------------------
#  1.0     03/10/2016  PBR        Creation
# 
# *************************************************************************
# 

trap "process_error 0" ERR


# ----- DEFINITION DES CP PARAMETERS SPECIFIQUES -----------------------

#P_PATH_NAME=                      # Nom du répertoire du fichier a charger  
#P_FILE_NAME=                      # Nom du fichier à charger

# ----- REDEFINITION DES COMMANDES A RISQUE ----------------------------

ECHO=echo

# ----- DEFINITION DES CONSTANTES --------------------------------------

# codes retour
CONST_RET_OK=0
CONST_RET_KO=1

# ----- DEFINITION DES VARIABLES DE TRAVAIL ----------------------------

G_CURRENT_FUNCTION=             # nom de la fonction en cours d'exec.
G_SYSDATE=                      # date systeme
G_RET_CODE=                     # code retour
G_BAD_OR_DIS=                   # indicateur si rejets SQL*Loader
G_OUT_DIR=                      # nom du fichier de sortie et chemin associé
G_LOG_DIR=                      # nom du fichier de log et chemin associé
G_SQLL_RET=                     # code de retour de SQL*Loader

# ----- DEFINITION DES FONCTIONS UTILITAIRES GENERAUX ------------------

# 
# Ecriture dans le journal standard
#       Parametres :
#               1  : Texte a ecrire
#       NB :
#       Un texte de plusieurs lignes doit etre envoye en une seule fois,
#       avec, le cas echeant, des caracteres de saut de ligne (\n)
# 
log()
{
   $ECHO ${1}
}


# 
# Ecriture de la date/heure système formatee
# 
log_time()
{
   G_SYSDATE=`date '+%d/%m/%Y %H:%M:%S`
   log "- $G_SYSDATE -"
}


# 
# Ecriture d'un message d'erreur
#       Parametres :
#               1  : Message a ecrire
#       NB :
#       Un message de plusieurs lignes doit etre envoye en une seule fois,
#       avec, le cas echeant, des caracteres de saut de ligne (\n)
# 
log_error_message()
{
   log "\n"
   log "------"
   log "ERREUR ${1} : ${2}"
   log "[Fonction : ${G_CURRENT_FUNCTION}]"
   log "------"
   log "\n"
}


# 
# Ecriture d'un message d'avertissement
#       Parametres :
#               1  : Message a ecrire
#       NB :
#       Un message de plusieurs lignes doit etre envoye en une seule fois,
#       avec, le cas echeant, des caracteres de saut de ligne (\n)
# 
log_warning()
{
   log "\n"
   log "------"
   log "WARNING : ${1}"
   log "------"
   log "\n"
}


# 
# Ecriture dans l'etat standard
#       Parametres :
#               1  : Texte a ecrire
#       NB :
#       Un texte de plusieurs lignes doit etre envoye en une seule fois,
#       avec, le cas echeant, des caracteres de saut de ligne (\n)
# 
output()
{
   $ECHO ${1} >> $G_OUT_DIR
}


# ----- DEFINITION DES FONCTIONS SPECIFIQUES --------------------------


# 
# Initialisation des variables globales specifiques
# et controles generaux
# 
init()
{
   G_CURRENT_FUNCTION="init"

   # --- Variables
   G_LOAD_REQUEST_ID=${FCP_REQID}   # Numero du Traitement en cours

   # --- Noms de Repertoire
   TMP=${APPLTMP}
   TO_DO=${REP_DATA_IN}
   BAD=${TMP}
   DIS=${TMP}
   LOG=${REP_DATA_LOG}

   #  initialisation du nom de fichier en fonction d'une variable environnement
   if test `set | grep "APPCPNAM=REQID" | wc -l` -ne 0
      then
      G_OUT_DIR=$APPLCSF/$APPLOUT/o${FCP_REQID}.out
      G_LOG_DIR=$APPLCSF/$APPLLOG/l${FCP_REQID}.req
      else
      G_OUT_DIR=$APPLCSF/$APPLOUT/$FCP_USERNAME.$FCP_REQID
   fi      

   # --- Noms de Fichier
   FILE_NAME_HEADER="DKA_EMPLOYEE_JOBS.csv"
   CTL_FILE_HEADER="${DKA_TOP}/${APPLBIN}/"DKA_EMPJOBSIMP".ctl"
   TMP_CTL_FILE_HEADER="${TMP}/${G_LOAD_REQUEST_ID}"_JOBS".ctl"    

   # Verification de la configuration du specifique

   # Repertoires
   if test ! -d ${TO_DO}
   then process_error 5 ${TO_DO}
   fi
   if test ! -d ${BAD}
   then process_error 5 ${BAD}
   fi
   if test ! -d ${DIS}
   then process_error 5 ${DIS}
   fi
   if test ! -d ${LOG}
   then process_error 5 ${LOG}
   fi
   if test ! -d ${TMP}
   then process_error 5 ${TMP}
   fi

   # Fichiers
   #if test ! -f ${CTL_FILE}
   #then process_error 6 ${CTL_FILE}
   #fi
   #if test ! -f "${TO_DO}/${FILE_NAME}"
   #then process_error 6 "${TO_DO}/${FILE_NAME}"
   #fi 
   
   if test ! -f ${CTL_FILE_HEADER}
   then process_error 6 ${CTL_FILE_HEADER}
   fi
   if test ! -f "${TO_DO}/${FILE_NAME_HEADER}"
   then process_error 6 "${TO_DO}/${FILE_NAME_HEADER}"
   fi
}


# 
# Ecriture de l'en-tete du journal
# 
log_header()
{
   log ""
   log "Arguments :"
   log "------------------"
   #log "P_PATH_NAME               : ${P_PATH_NAME}"
   #log "P_FILE_NAME               : ${P_FILE_NAME}"
}


# 
# Rappel (en cas d'erreur) dans le fichier journal 
# de la liste des parametres specifiques attendus
# 
usage()
{
   log "\nArguments attendus :"
   log "------------------"
   #log "P_PATH_NAME            : Nom du répertoire du fichier à charger"
   #log "P_FILE_NAME            : Nom du fichier à charger"
   log "------------------"
}


# 
# Traitement des erreurs
#    Parametres :
#       1  : Numero d'erreur
#       *  : Tout autre parametre necessaire a la constitution du
#            message d'erreur
#    NB :
#    Numeros d'erreur particuliers :
#       0 : Erreur Unix
#
#       1 : cas d'erreur de programmation ou de coherence entre les
#           differents modules du concurrent program :)
# 
process_error()
{
   if [ $# -eq 0 ]
   then
      log_error_message "Erreur indefinie ..."
   else
      case $1 in
         0 )     log_error_message ${1} "Erreur Unix !"
                 ;;
         1 )     log_error_message ${1} "Erreur interne ! ${2}"
                 ;;
         2 )     log_error_message ${1} "Nombre de paramètres standards incorrect"
                 ;;
         3 )     log_error_message ${1} "Erreur durant l'exécution de SQL*Loader"
                 ;;
         4 )     log_error_message ${1} "Nombre de paramètres spécifiques incorrect"
                 usage
                 ;;
         5 )     log_error_message ${1} "Répertoire inexistant : ${2}"
                 ;;
         6 )     log_error_message ${1} "Fichier inexistant : ${2}"
                 ;;
         7 )     log_error_message ${1} "SQL*Loader a détecté des anomalies."
                 purge
                 ;;
         9 )     log_error_message ${1} "Erreur SQL*Plus !"
                 purge
                 ;;
         10 )    log_error_message ${1} "Echec lors de la suppression des données chargées."
                 ;;
         * )     log_error_message ${1} "Erreur indéfinie ..."
                 ;;
      esac
   fi

# fin du traitement en cas d'erreur

   log "\nTRAITEMENT INTERROMPU"
   log " "
   exit $CONST_RET_KO
}

# 
# Suppression des donnees chargees en cas d'erreur bloquante
# survenue apres l'appel a SQL*Loader
# 
purge()
{
   G_CURRENT_FUNCTION="purge"
   log "Suppression des données chargées ..."
   log "Connexion SQL*Plus ..." 
   sqlplus -s /nolog <<eof  
   WHENEVER SQLERROR EXIT FAILURE ROLLBACK
   connect ${FCP_LOGIN}

   DELETE FROM DKA_EMPLOYEE_JOBS_TMP;
   
   COMMIT;
   EXIT;
eof
   G_RET_CODE="${?}"
   if [ ${G_RET_CODE} -ne 0 ]
   then
      process_error 10
   fi
}


# ----- CORPS DU SCRIPT ------------------------------------------------

G_CURRENT_FUNCTION="BODY"

# Recuperation du nom du Concurrent Program
PROGRAM_NAME=`echo ${0} | sed 's/.prog//g'`
echo $PROGRAM_NAME

# Recuperation des parametres standard
FCP_LOGIN=`echo $* | awk '{print $3}' | cut -f2 -d'='`
FCP_LOGIN=`echo $FCP_LOGIN | sed 's/\"//g'`
FCP_USERID=`echo $* | awk '{print $4}' | cut -f2 -d'='`
FCP_USERNAME=`echo $* | awk '{print $5}' | cut -f2 -d'='`
FCP_USERNAME=`echo $FCP_USERNAME | sed 's/\"//g'`
FCP_REQID=`echo $* | awk '{print $2}' | cut -f2 -d'='`

if [ "$FCP_LOGIN" = "" ]
then
   process_error 2
fi
if [ "$FCP_USERID" = "" ]
then
   process_error 2
fi
if [ "$FCP_USERNAME" = "" ]
then
   process_error 2
fi
if [ "$FCP_REQID" = "" ]
then
   process_error 2
fi

# Recuperation des parametres specifiques
#P_PATH_NAME=`echo $* | awk '{print $9}' | cut -f2 -d'='`
#P_PATH_NAME=`echo $P_PATH_NAME | sed 's/\"//g'`
#P_PATH_NAME=
#P_PATH_NAME=
#P_FILE_NAME=`echo $* | awk '{print $10}' | cut -f2 -d'='`
#P_FILE_NAME=`echo $P_FILE_NAME | sed 's/\"//g'`

#if [ "$P_PATH_NAME" = "" ]
#then
#   process_error 4
#fi
#if [ "$P_FILE_NAME" = "" ]
#then
#   process_error 4
#fi

# Ecriture en-tete du journal
log_header
G_CURRENT_FUNCTION="BODY"

# Initialisations et controles generaux
init
G_CURRENT_FUNCTION="BODY"

# FICHIER DES ENTETES

if [ -f  ${TO_DO}/${FILE_NAME_HEADER} ] ;
  then

	
   # Chargement en base
   log "\nChargement des données ..."
   log "\t. Traitement du fichier $FILE_NAME_HEADER ..."

   # Generation du fichier de controle
   cat "${CTL_FILE_HEADER}" \
       | sed "s/!LOAD_REQUEST_ID!/${G_LOAD_REQUEST_ID}/g" \
       | sed "s/!USER_ID!/${FCP_USERID}/g" \
         > ${TMP_CTL_FILE_HEADER}
 
   # Appel Sql*Loader
   log ""
   G_SQLL_RET=`sqlldr \
           userid=${FCP_LOGIN} \
           control=${TMP_CTL_FILE_HEADER} \
           log=${LOG}/${G_LOAD_REQUEST_ID}.log \
           data=${TO_DO}/${FILE_NAME_HEADER} \
           bad=${BAD}/${G_LOAD_REQUEST_ID}.bad \
           discard=${DIS}/${G_LOAD_REQUEST_ID}.dis \
           errors=100 2>&1;  echo $?`
   G_RET_CODE="${?}"

   log ""
      
#   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
#       >> ${G_OUT_DIR}
   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
       >> ${G_LOG_DIR}
   rm -f ${LOG}/${G_LOAD_REQUEST_ID}.log
   rm -f ${TMP_CTL_FILE_HEADER}

   # Controle si rejets
   G_BAD_OR_DIS=0
   if [ -f  ${TMP}/${G_LOAD_REQUEST_ID}.bad ] ;
   then
       output "\nFICHIER REJETE : Toutes les lignes du fichier n ont pas pu etre traitees correctement"
       output "\n\nEnregistrements rejetés :"
       cat ${TMP}/${G_LOAD_REQUEST_ID}.bad \
          >> ${G_OUT_DIR}
       rm -f ${TMP}/${G_LOAD_REQUEST_ID}.bad
       G_BAD_OR_DIS=1 
   fi
   if [ -f  ${TMP}/${G_LOAD_REQUEST_ID}.dis ] ;
   then
      output "\n\n\nEnregistrements de type inconnu : "
      cat ${TMP}/${G_LOAD_REQUEST_ID}.dis \
         >> ${G_OUT_DIR}
      rm -f ${TMP}/${G_LOAD_REQUEST_ID}.dis
      G_BAD_OR_DIS=1
   fi

   # gestion des codes retour de SQL*Loader
   case $G_RET_CODE in
   0)
      G_CURRENT_FUNCTION="BODY"
      if [ $G_BAD_OR_DIS != 0 ]
      then
         output "\n\nVoir dans le fichier de log la cause des rejets"
         process_error 7
      else
         log "\nChargement réussi"
         output "\nToutes les lignes du fichier ont pu etre traitees correctement"
      fi
      ;;
      
   *) 
      process_error 7
      ;;
      
   esac
   
else

   #Aucun fichier candidat
   process_error 6

fi

# Fin normale

exit $CONST_RET_OK

# Fin

