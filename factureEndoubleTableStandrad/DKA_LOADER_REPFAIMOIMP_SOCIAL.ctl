#************************************************************************
# PROGRAM : DKA_IPOFRS_IVALUA.prog                                      *
# Version : 1.0                                                         *
# AUTEUR  : Saloua HAHIOUI / SOCIETE : CAPGEMINI                        *
# DATE    : 06/05/2020                                                  *
#************************************************************************
# APPELE PAR :                                                          *
# FONCTION   :                                                          *
#                                                                       *
#                                                                       *
#************************************************************************
# HISTORIQUE                                                            *
# Version   Date      Auteur        NumAno - Commentaires               *
# 1.0                 SHA                                               *
# 2.0                 SHA EDB302                                        *
#########################################################################


#
####################################################################
#                                                                  #
#                           M A I N                                #
#                                                                  #
####################################################################
#
# ----- DEFINITION DES VARIABLES DE TRAVAIL ----------------------------

G_CURRENT_FUNCTION=             # nom de la fonction en cours d'exec.
G_SYSDATE=                      # date systeme
G_RET_CODE=                     # code retour
G_RET_CODE1=                     # code retour
G_RET_CODE2=                     # code retour
G_BAD_OR_DIS=                   # indicateur si rejets SQL*Loader
G_OUT_DIR=                      # nom du fichier de sortie et chemin associé
G_LOG_DIR=                      # nom du fichier de log et chemin associé
G_SQLL_RET=                     # code de retour de SQL*Loader

trap "process_error 0" ERR
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
# Ecriture d'un message d'erreur
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
				 where message_name like 'DKA_IPOFRS_001' 
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
				 where message_name like 'DKA_IPOFRS_002' 
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
# Ecriture de la date/heure système formatee
# 


#G_SYSDATE=`date +"%Y%m%d%H%M%S"`
 G_SYSDATE='20200504000000'
#echo Current Date and Time is: ${G_SYSDATE}



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
   PREFIX_FILE_NAME_ENTETE='DSP01_SUP_ENTETE_'
   P_DAT_FILE_ENT=${PREFIX_FILE_NAME_ENTETE}*.${FILE_EXTENSION}
   
   if test -f $REP_DATA_IN/${P_DAT_FILE_ENT}
   then
   FILE_NAME_ENTETE=`ls $REP_DATA_IN/${P_DAT_FILE_ENT}` 
   var1=`ls $REP_DATA_IN/${P_DAT_FILE_ENT} | wc -l`
   if [ $var1 -le 1 ]
   then
       echo ""
	 else
       process_error 6 ${LV_CTL_FILE_FOURNISSEURS}
   fi
   P_DAT_FILE_ENTETE=`basename $FILE_NAME_ENTETE`
   fi 
   
   PREFIX_FILE_NAME_LIGNE='DSP01_SUP_SITE_'
   P_DAT_FILE_LIG=${PREFIX_FILE_NAME_LIGNE}*.${FILE_EXTENSION}
   
   if test -f $REP_DATA_IN/${P_DAT_FILE_LIG}
   then
   
   FILE_NAME_LIGNE=`ls $REP_DATA_IN/${P_DAT_FILE_LIG}` 
   var1=`ls $REP_DATA_IN/${P_DAT_FILE_LIG} | wc -l`
   if [ $var1 -le 1 ]
   then
       echo ""
	 else
       process_error 6 ${LV_CTL_FILE_SITE_FOURNISSEUR}
   fi
   P_DAT_FILE_LIGNE=`basename $FILE_NAME_LIGNE`
   fi
   
   PREFIX_FILE_NAME_HOMO='DSP01_SUP_HOMOLOGATION_'
   P_DAT_FILE_HOMO=${PREFIX_FILE_NAME_HOMO}*.${FILE_EXTENSION}
   if test -f $REP_DATA_IN/${P_DAT_FILE_HOMO}
   then
   
   FILE_NAME_HOMOLOGATION=`ls $REP_DATA_IN/${P_DAT_FILE_HOMO}`
   var1=`ls $REP_DATA_IN/${P_DAT_FILE_HOMO} | wc -l`
   if [ $var1 -le 1 ]
   then
       echo ""
	 else
       process_error 6 ${LV_CTL_FILE_HOMOLOGATIONS}
   fi   
   P_DAT_FILE_HOMOLOGATION=`basename $FILE_NAME_HOMOLOGATION`
   fi
   
   LV_CTL_FILE_FOURNISSEURS="${DKA_TOP}/${APPLBIN}/"DKA_IPOFRS_ENETETES".ctl"
   LV_CTL_FILE_SITE_FOURNISSEUR="${DKA_TOP}/${APPLBIN}/"DKA_IPOFRS_LIGNES".ctl"
   LV_CTL_FILE_HOMOLOGATIONS="${DKA_TOP}/${APPLBIN}/"DKA_IPOFRS_HOMOLOGATIONS".ctl"
   
   LV_TMP_FILE_FOURNISSEURS="${TMP}/${G_LOAD_REQUEST_ID}"_HEAD".ctl"
   LV_TMP_FILE_SITE_FOURNISSEUR="${TMP}/${G_LOAD_REQUEST_ID}"_LINES".ctl"
   LV_TMP_FILE_HOMOLOGATIONS="${TMP}/${G_LOAD_REQUEST_ID}"_HOMO".ctl"
     

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

   
   log "header ctl "
   if test ! -f ${LV_CTL_FILE_FOURNISSEURS}
   then process_error 6 ${LV_CTL_FILE_FOURNISSEURS}
   fi
    log "header file "
  
   log "ligne ctl "
   if test ! -f ${LV_CTL_FILE_SITE_FOURNISSEUR}
   then process_error 6 ${LV_CTL_FILE_SITE_FOURNISSEUR}
   fi
   
   
   log "homo ctl "
   if test ! -f ${LV_CTL_FILE_HOMOLOGATIONS}
   then process_error 6 ${LV_CTL_FILE_HOMOLOGATIONS}
   fi
   
    log "homo file ,ligne file et header file "
   if test ! -f "${REP_DATA_IN}/${P_DAT_FILE_ENTETE}" && test ! -f "${REP_DATA_IN}/${P_DAT_FILE_LIGNE}" && test ! -f "${REP_DATA_IN}/${P_DAT_FILE_HOMOLOGATION}"
   then
        
            process_error 6
		
    fi   
   
    
}

# 
# Ecriture de l'en-tete du journal
# 
out_header()
{
   
   OUT_SYSDATE=`date '+%d/%m/%Y %H:%M:%S'`   
   G_OUT_DIR=$APPLCSF/$APPLOUT/o${FCP_REQID}.out 
   
   output "---------------------------------------------------------------------------------------" >> $G_OUT_DIR
   
   output "COMPTE-RENDU DU TRAITEMENT « DKA : Import des données Fournisseurs depuis iValua - Chargement des fichiers »" >> $G_OUT_DIR
   output "Traitement n° "${FCP_REQID} >> $G_OUT_DIR
   output "Le :  ${OUT_SYSDATE}" >> $G_OUT_DIR
   
   output "---------------------------------------------------------------------------------------"  >> $G_OUT_DIR  
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
         6 )     log_error_message ${1} "DKA_IPOFRS_001"
                 ;;
         7 )     log_error_message ${1} "DKA_IPOFRS_002"
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

   DELETE FROM DKA_IPOFRS_ENTETES
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;
   
   DELETE FROM DKA_IPOFRS_LIGNES
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;

   DELETE FROM DKA_IPOFRS_HOMOLOGATIONS 
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ; 
   DELETE FROM DKA_IPOFRS_HIST_ENTETES
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   
   DELETE FROM DKA_IPOFRS_HIST_LIGNES
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;

   DELETE FROM DKA_IPOFRS_HIST_HOMOLOGATIONS 
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;   
   DELETE FROM DKA_IPOFRS_REPORTING_ENTETES
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;
   
   DELETE FROM DKA_IPOFRS_REPORTING_LIGNES
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;

   DELETE FROM DKA_IPOFRS_REPORTING_HOMOLOG
   WHERE LOADER_REQUEST_ID =$FCP_REQID
   ;      


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


# Ecriture en-tete du journal
out_header
G_CURRENT_FUNCTION="BODY"

# Initialisations et controles generaux
init
G_CURRENT_FUNCTION="BODY"

# FICHIER DES ENTETES

if [ -f  ${REP_DATA_IN}/${P_DAT_FILE_ENTETE} ] ;
  then

	
   # Chargement en base
   log "\nChargement des données ..."
   log "\t. Traitement du fichier $P_DAT_FILE_ENTETE ..."

   # Generation du fichier de controle
   cat "${LV_CTL_FILE_FOURNISSEURS}" \
       | sed "s/!LOAD_REQUEST_ID!/${G_LOAD_REQUEST_ID}/g" \
       | sed "s/!USER_ID!/${FCP_USERID}/g" \
	   | sed "s/!FILE_NAME!/${P_DAT_FILE_ENTETE}/g" \
         > ${LV_TMP_FILE_FOURNISSEURS}
 
   # Appel Sql*Loader
   log ""
   G_SQLL_RET=`sqlldr \
           userid=${FCP_LOGIN} \
           control=${LV_TMP_FILE_FOURNISSEURS} \
           log=${LOG}/${G_LOAD_REQUEST_ID}.log \
           data=${REP_DATA_IN}/${P_DAT_FILE_ENTETE} \
           bad=${BAD}/${G_LOAD_REQUEST_ID}.bad \
           discard=${DIS}/${G_LOAD_REQUEST_ID}.dis \
           errors=100 2>&1;  echo $?`
   G_RET_CODE=${?}
   retcode=`echo $?` 

   log ""
      
#   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
#       >> ${G_OUT_DIR}
   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
       >> ${G_LOG_DIR}
   rm -f ${LOG}/${G_LOAD_REQUEST_ID}.log
   rm -f ${LV_TMP_FILE_FOURNISSEURS}

   # Controle si rejets
   G_BAD_OR_DIS=0
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.bad ] ;
   then
       log "\nFICHIER REJETE : Toutes les lignes du fichier n ont pas pu etre traitees correctement"
       log "\n\nEnregistrements rejetés :"
      #cat ${BAD}/${G_LOAD_REQUEST_ID}.bad \
       # >> ${G_OUT_DIR}
       #rm -f ${BAD}/${G_LOAD_REQUEST_ID}.bad
       G_BAD_OR_DIS=1 
   fi
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.dis ] ;
   then
      log "\n\n\nEnregistrements de type inconnu : "
      #cat ${BAD}/${G_LOAD_REQUEST_ID}.dis \
       #  >> ${G_OUT_DIR}
      #rm -f ${BAD}/${G_LOAD_REQUEST_ID}.dis
      G_BAD_OR_DIS=1
   fi
   
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
   #process_error 6 -- SHA EDB302
   echo ""
fi


# FICHIER DES LIGNES

if [ -f  ${REP_DATA_IN}/${P_DAT_FILE_LIGNE} ] ;
  then

	
   # Chargement en base
   log "\nChargement des données ..."
   log "\t. Traitement du fichier $P_DAT_FILE_LIGNE ..."

   # Generation du fichier de controle
   cat "${LV_CTL_FILE_SITE_FOURNISSEUR}" \
       | sed "s/!LOAD_REQUEST_ID!/${G_LOAD_REQUEST_ID}/g" \
       | sed "s/!USER_ID!/${FCP_USERID}/g" \
	   | sed "s/!FILE_NAME!/${P_DAT_FILE_LIGNE}/g" \
         > ${LV_TMP_FILE_SITE_FOURNISSEUR}
 
   # Appel Sql*Loader
   log ""
   G_SQLL_RET=`sqlldr \
           userid=${FCP_LOGIN} \
           control=${LV_TMP_FILE_SITE_FOURNISSEUR} \
           log=${LOG}/${G_LOAD_REQUEST_ID}.log \
           data=${REP_DATA_IN}/${P_DAT_FILE_LIGNE} \
           bad=${BAD}/${G_LOAD_REQUEST_ID}.bad \
           discard=${DIS}/${G_LOAD_REQUEST_ID}.dis \
           errors=100 2>&1;  echo $?`
   G_RET_CODE1="${?}"

   log ""
      
#   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
#       >> ${G_OUT_DIR}
   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
       >> ${G_LOG_DIR}
   rm -f ${LOG}/${G_LOAD_REQUEST_ID}.log
   rm -f ${LV_TMP_FILE_SITE_FOURNISSEUR}

   # Controle si rejets
   G_BAD_OR_DIS=0
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.bad ] ;
   then
       log "\nFICHIER REJETE : Toutes les lignes du fichier n ont pas pu etre traitees correctement"
       log "\n\nEnregistrements rejetés :"
       #cat ${BAD}/${G_LOAD_REQUEST_ID}.bad \
       #   >> ${G_OUT_DIR}
       #rm -f ${BAD}/${G_LOAD_REQUEST_ID}.bad
       G_BAD_OR_DIS=1 
   fi
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.dis ] ;
   then
      log "\n\n\nEnregistrements de type inconnu : "
      #cat ${BAD}/${G_LOAD_REQUEST_ID}.dis \
      #  >> ${G_OUT_DIR}
      #rm -f ${BAD}/${G_LOAD_REQUEST_ID}.dis
      G_BAD_OR_DIS=1
   fi
   case $G_RET_CODE1 in
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
   #process_error 6 -- SHA EDB302
   echo ""
fi

# FICHIER DES HOMOLOGATIONS

if [ -f  ${REP_DATA_IN}/${P_DAT_FILE_HOMOLOGATION} ] ;
  then

	
   # Chargement en base
   log "\nChargement des données ..."
   log "\t. Traitement du fichier $P_DAT_FILE_HOMOLOGATION ..."

   # Generation du fichier de controle
   cat "${LV_CTL_FILE_HOMOLOGATIONS}" \
       | sed "s/!LOAD_REQUEST_ID!/${G_LOAD_REQUEST_ID}/g" \
       | sed "s/!USER_ID!/${FCP_USERID}/g" \
	   | sed "s/!FILE_NAME!/${P_DAT_FILE_HOMOLOGATION}/g" \
         > ${LV_TMP_FILE_HOMOLOGATIONS}
 
   # Appel Sql*Loader
   log ""
   G_SQLL_RET=`sqlldr \
           userid=${FCP_LOGIN} \
           control=${LV_TMP_FILE_HOMOLOGATIONS} \
           log=${LOG}/${G_LOAD_REQUEST_ID}.log \
           data=${REP_DATA_IN}/${P_DAT_FILE_HOMOLOGATION} \
           bad=${BAD}/${G_LOAD_REQUEST_ID}.bad \
           discard=${DIS}/${G_LOAD_REQUEST_ID}.dis \
           errors=100 2>&1;  echo $?`
   G_RET_CODE2="${?}"

   log ""
      
#   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
#       >> ${G_OUT_DIR}
   cat ${LOG}/${G_LOAD_REQUEST_ID}.log \
       >> ${G_LOG_DIR}
   rm -f ${LOG}/${G_LOAD_REQUEST_ID}.log
   rm -f ${LV_TMP_FILE_HOMOLOGATIONS}

   # Controle si rejets
   G_BAD_OR_DIS=0
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.bad ] ;
   then
       log "\nFICHIER REJETE : Toutes les lignes du fichier n ont pas pu etre traitees correctement"
       log "\n\nEnregistrements rejetés :"
       #cat ${BAD}/${G_LOAD_REQUEST_ID}.bad \
       #   >> ${G_OUT_DIR}
       #rm -f ${BAD}/${G_LOAD_REQUEST_ID}.bad
       G_BAD_OR_DIS=1 
   fi
   if [ -f  ${BAD}/${G_LOAD_REQUEST_ID}.dis ] ;
   then
       log "\n\n\nEnregistrements de type inconnu : "
      #cat ${BAD}/${G_LOAD_REQUEST_ID}.dis \
       #  >> ${G_OUT_DIR}
      #rm -f ${BAD}/${G_LOAD_REQUEST_ID}.dis
      G_BAD_OR_DIS=1
   fi
   case $G_RET_CODE2 in
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
   #process_error 6 -- SHA EDB302
   echo ""
fi

# gestion des codes retour de SQL*Loader
 
  if [ $G_RET_CODE != 0 ] && [ $G_RET_CODE1 != 0 ] && [ $G_RET_CODE2 != 0 ] 
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
         log "\n===> Le chargement des fichiers s'est déroulé avec succès."
		 # Archivage
         log " recuperation du repertoire archive "
         archiv_dir=`find $REP_DATA/traite/in/ -type d | sort | tail -1`
         
		if [ -f  ${REP_DATA_IN}/${P_DAT_FILE_ENTETE} ] ;
     
        then
		    log " move $P_DAT_FILE_ENTETE  in $archiv_dir "
		    mv ${REP_DATA_IN}/${P_DAT_FILE_ENTETE}  $archiv_dir 
		fi
            if [ -f  ${REP_DATA_IN}/${P_DAT_FILE_LIGNE} ] ;
            then 
			   log " move $P_DAT_FILE_LIGNE "
                mv ${REP_DATA_IN}/${P_DAT_FILE_LIGNE}   $archiv_dir 
			fi 	
	            if [ -f  ${REP_DATA_IN}/${P_DAT_FILE_HOMOLOGATION} ] ;
		        then 
				   log " move $P_DAT_FILE_HOMOLOGATION "
                   mv ${REP_DATA_IN}/${P_DAT_FILE_HOMOLOGATION}  $archiv_dir
            
		        fi
            
           
        
         
      fi
  fi   
   



# Fin normale

exit $CONST_RET_OK

# Fin

