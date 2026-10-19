#!/usr/bin/ksh
#
#**************************************************************************
#  $HEADER : DKA_IPOCTR_SSTR_IVALUA_LOADER V1.0  
# 
#  FILENAME
#   DKA_IPOCTR_SSTR_IVALUA_LOADER
# 
#  DESCRIPTION
#     Phase de chargement via Sql*Loader.
# 
#  USAGE
#   DKA_IPOCTR_SSTR_IVALUA_LOADER FCP_LOGIN FCP_USERID FCP_USERNAME FCP_REQID P_PATH_NAME P_FILE_NAME
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
#  P_PATH_NAME       Nom du répertoire du fichier a charger  
#  P_FILE_NAME       Nom du fichier a charger  
# 
#  HISTORY
#  =======
# 
#  VERSION DATE        QUI        DESCRIPTION
#  ------- ----------- ---------  ------------------------------------
#  1.0     11/10/2024  KHH        Creation --- Prg DKA : Import des contrats SSTR depuis iValua
# 
# *************************************************************************
# 
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
G_RET_CODE1=                     # code retour
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


#G_SYSDATE=`date +"%Y%m%d%H%M%S"`
G_SYSDATE=`date '+%d/%m/%Y %H:%M:%S'`
echo Current Date and Time is: ${G_SYSDATE}

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
log_error_message()
{
G_CURRENT_FUNCTION="log_error_message"
if [ ${1} -eq 6 ] || [ ${1} -eq 11 ]
then
Load_message=`sqlplus -s $FCP_LOGIN <<EOF
                set termout off
                set feedback off
                set pagesize 0
                 select message_text
				  from fnd_new_messages
				 where message_name like 'DKA_IPOCTR_SSTR_001' 
				   and language_code= 'F';
                exit
                EOF`
log "$2 ${Load_message}"
output "\n===> ERREUR : ${Load_message}"
fi
if [ ${1} -eq 7 ]
then
Load_message=`sqlplus -s $FCP_LOGIN <<EOF
                set termout off
                set feedback off
                set pagesize 0
                 select message_text
				  from fnd_new_messages
				 where message_name in 'DKA_IPOCTR_SSTR_002' 
				   and language_code= 'F';
                exit
                EOF`
log "$2 ${Load_message}"
output "\n===> ERREUR : ${Load_message}"
fi

if [ ${1} -ne 6 ] && [ ${1} -ne 7 ] && [ ${1} -ne 11 ]
then
   log "\n"
   log "------"
   log "ERREUR ${1} : ${2}"
   log "[Fonction : ${G_CURRENT_FUNCTION}]"
   log "------"
   log "\n"
fi

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
   #TO_DO=${P_PATH_NAME}
   #BAD=${TMP}
   #DIS=${TMP}
   #LOG=${TMP}

   TO_DO=${REP_DATA_IN}
   BAD=${REP_DATA_LOG}
   DIS=${REP_DATA_LOG}
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
   FILE_EXTENSION='csv'
   PREFIX_FILE_NAME_HEAD='DSP01_PO_CONTRAT_SSTR_'
   echo ${PREFIX_FILE_NAME_HEAD}
   FILE_NAME_HEAD=${PREFIX_FILE_NAME_HEAD}*.${FILE_EXTENSION}
   echo ${FILE_NAME_HEAD}
   
   if test -f $REP_DATA_IN/${FILE_NAME_HEAD}
   then
   FILE_NAME_HEADER_REP=`ls $REP_DATA_IN/${FILE_NAME_HEAD}` 
   
   var1=`ls $REP_DATA_IN/${FILE_NAME_HEAD} | wc -l`
   if [ $var1 -eq 1 ]
   then
       echo ""
	else
       process_error 6 ${CTL_FILE_HEAD}
   fi
   FILE_NAME_HEADER=`basename $FILE_NAME_HEADER_REP`
   echo $FILE_NAME_HEADER 
   fi
   
   #FILE_NAME_HEAD="DSP01_PO_ENTETE_"${G_SYSDATE}".csv"
   #FILE_NAME_LINES="DSP01_PO_LIGNE_"${G_SYSDATE}".csv"
   #CTL_FILE="${DKA_TOP}/${APPLBIN}/"`basename ${PROGRAM_NAME}`".ctl"
   CTL_FILE_HEAD="${DKA_TOP}/${APPLBIN}/"DKA_IPOCTR_SSTR_IVALUA_LOADER".ctl"
   #TMP_CTL_FILE="${TMP}/${G_LOAD_REQUEST_ID}"_HEAD".ctl"
   TMP_CTL_FILE_HEAD="${TMP}/${G_LOAD_REQUEST_ID}"_HEAD".ctl"
  
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
   
   if test ! -f ${CTL_FILE_HEAD}
   then process_error 6 ${FILE_NAME_HEADER}
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
   G_OUT_DIR=$APPLCSF/$APPLOUT/o${FCP_REQID}.out  

   output "-------------------------------------------------------------------------------------------------" >> $G_OUT_DIR
   output "COMPTE-RENDU DU TRAITEMENT « DKA : Import des contrats SSTR depuis iValua - Chargement des fichiers »" >> $G_OUT_DIR
   output "Traitement n° "${FCP_REQID} >> $G_OUT_DIR
   output "Programme lancé le : "${G_SYSDATE} >> $G_OUT_DIR

   output "-------------------------------------------------------------------------------------------------" >> $G_OUT_DIR 
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
         6 )     log_error_message ${1} "DKA_IPOCTR_SSTR_001"
                 ;;
         7 )     log_error_message ${1} "DKA_IPOCTR_SSTR_002"
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

   DELETE FROM DKA_IPOCTR_SSTR_IVALUA
   WHERE LOADER_REQUEST_ID = $FCP_REQID
   ;
   DELETE FROM DKA_IPOCTR_SSTR_IVALUA_HIST
   WHERE LOADER_REQUEST_ID = $FCP_REQID
   ;
   DELETE FROM DKA_IPOCTR_SSTR_IVALUA_REPORT
   WHERE LOADER_REQUEST_ID = $FCP_REQID
   ;
   
  COMMIT;
   EXIT;
eof
   G_RET_CODE="${?}"
   if [ ${G_RET_CODE} -ne 0 ]
   then
      process_error 10
   fi
   
   echo code retour de la purge: $G_RET_CODE
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
   cat "${CTL_FILE_HEAD}" \
       | sed "s/!LOAD_REQUEST_ID!/${G_LOAD_REQUEST_ID}/g" \
       | sed "s/!USER_ID!/${FCP_USERID}/g" \
	   | sed "s/!FILE_NAME!/${FILE_NAME_HEADER}/g" \
       | sed "s/!INTERFACE_CODE!/${P_INTERFACE_CODE}/g" \
         > ${TMP_CTL_FILE_HEAD}
 
   # Appel Sql*Loader
   log ""
   sqlldr \
           userid=${FCP_LOGIN} \
           control=${TMP_CTL_FILE_HEAD} \
           log=${LOG}/${G_LOAD_REQUEST_ID}.log \
           data=${TO_DO}/${FILE_NAME_HEADER} \
           bad=${BAD}/${G_LOAD_REQUEST_ID}.bad \
           discard=${DIS}/${G_LOAD_REQUEST_ID}.dis \
           errors=1000
   G_RET_CODE=$?
   retcode=G_RET_CODE 

   log ""
      
#   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
#       >> ${G_OUT_DIR}
   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
       >> ${G_LOG_DIR}
   rm -f ${LOG}/${G_LOAD_REQUEST_ID}.log
   rm -f ${TMP_CTL_FILE_HEAD}

   # Controle si rejets
   G_BAD_OR_DIS=0
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.bad ] ;
   then
      # echo entree fichier bad
       log "\nFICHIER REJETE : Toutes les lignes du fichier n ont pas pu etre traitees correctement"
       log "\n\nEnregistrements rejetés :"
       #cat ${BAD}/${G_LOAD_REQUEST_ID}.bad \
       #   >> ${G_OUT_DIR}
      # rm -f ${TMP}/${G_LOAD_REQUEST_ID}.bad
       G_BAD_OR_DIS=1 
   fi
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.dis ] ;
   then
      #echo entree fichier dis
      log "\n\n\nEnregistrements de type inconnu : "
      #cat ${BAD}/${G_LOAD_REQUEST_ID}.dis \
      #   >> ${G_OUT_DIR}
      #rm -f ${TMP}/${G_LOAD_REQUEST_ID}.dis
      G_BAD_OR_DIS=1
   fi
    # gestion des rejets SQL*Loader
   echo rejet header est :$G_BAD_OR_DIS  
   # gestion des codes retour de SQL*Loader
   echo codes retour de SQL*Loader header est :$G_RET_CODE
   
   case $G_RET_CODE in
   0)
      G_CURRENT_FUNCTION="BODY"
      if [ $G_BAD_OR_DIS != 0 ]
      then
         log "\n\nVoir dans le fichier de log la cause des rejets"
         process_error 7
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
   # gestion des codes retour de SQL*Loader
 echo G_RET_CODE : $G_RET_CODE 
 echo G_RET_CODE1: $G_RET_CODE1

 
  if [ $G_RET_CODE != 0 ] && [ $G_RET_CODE1 != 0 ] 
  then
    process_error 7
  else
    G_CURRENT_FUNCTION="BODY"
      if [ $G_BAD_OR_DIS != 0 ]
      then
         log "\n\nVoir dans le fichier de log la cause des rejets"
         process_error 7
      else
         log "\nChargement réussi"
         output "\n===> Le chargement des fichiers s'est déroulé avec succès."
      fi
  fi   
   



# Fin normale

exit $CONST_RET_OK

# Fin

