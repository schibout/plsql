#************************************************************************
# PROGRAM : DKA_REPAPFRSIMP.prog                                           *
# Version : 1.0                                                         *
# AUTEUR  : warid younes / SOCIETE : CAPGEMINI                          *
# DATE    : 15/03/2016                                                  *
#************************************************************************
# APPELE PAR :                                                          *
# FONCTION   :                                                          *
#                                                                       *
#                                                                       *
#************************************************************************
# HISTORIQUE                                                            *
# Version   Date      Auteur        NumAno - Commentaires               *
# 1.0                 YWA                                                *
#                                                                       *
#########################################################################


#
####################################################################
#                                                                  #
#                           M A I N                                #
#                                                                  #
####################################################################
#

#--------------------------------------------------------------------------
# function_ExitIfErr ()
#--------------------------------------------------------------------------
# Fonction d'arret du traitement si une erreur est survenue
#
function_ExitIfErr(){

echo " "
echo "========================================================================="
echo "DKA : Reprise AP fournisseurs import                     "
echo "Fin du traitement : `date +%T`                                           "
echo "Resultat du traitement : ERREUR                                          "
echo "========================================================================="
echo " " 
#date +%d'/'%m'/'%Y' '%H':'%M':'%S

exit 2

}


#--------------------------------------------------------------------------
# function_ExitIfAttention ()
#--------------------------------------------------------------------------
# Fonction d'arret du traitement si une erreur non grave est survenue
#
function_ExitIfAttention(){

echo " "
echo "========================================================================="
echo "DKA : Reprise AP fournisseurs import                     "
echo "Fin du traitement : `date +%T`                                           "
echo "Resultat du traitement : AVERTISSEMENT                                   "
echo "========================================================================="
echo " " 
#date +%d'/'%m'/'%Y' '%H':'%M':'%S

# Mise a jour du statut de fin ("WARNING") du traitement
sqlplus -s <<-QUIT 
    $FCP_LOGIN

    SET FEEDBACK OFF
    SET HEADING OFF

    update fnd_concurrent_requests
           set phase_code = 'C',
               status_code = 'G',
               completion_text = 'Fin Anormale'
         where request_id = $FCP_REQID;
     
    commit;
     
QUIT

exit

}

#--------------------------------------------------------------------------
# function_Exit ()
#--------------------------------------------------------------------------
# Fonction d'arret du traitement
#
function_Exit(){

echo " "
echo "========================================================================="
echo "DKA : Reprise AP fournisseurs import                     "
echo "Fin du traitement : `date +%T`                                           "
echo "Resultat du traitement : OK                                              "
echo "========================================================================="
echo " " 
#date +%d'/'%m'/'%Y' '%H':'%M':'%S

exit

}

#--------------------------------------------------------------------------
# function_file_existe ()
#--------------------------------------------------------------------------
# Fonction verifi si fichier existe
#                     code retour : 0 : fichier existe
#                                 : 2 : fichier introuvable
#
function_file_existe(){
    bol_erreur=0
    if [ "$LV_DATAFILE" != "" ] ; then
    
        if [ -f $LV_DATAFILE ]; then
            bol_erreur=2
        fi
  
    else
    
        bol_erreur=2
    fi
}


#--------------------------------------------------------------------------
# function_load_file ()
#--------------------------------------------------------------------------
# Fonction de chargement de fichier
#                 code retour : 0 : fichier valide
#                               2 : fichier invalide
#
function_load_file(){

    bol_erreur=0
    echo $bol_erreur

    echo " "                                                    >> $LV_OUTPUT_FILE
    echo "FICHIER A LIRE   :"${LV_DATAFILE}                     >> $LV_OUTPUT_FILE
    echo " "

    echo "\n "
    echo "FICHIER A LIRE   :"$LV_DATAFILE
    echo " "

    LV_LOGFILE=${LV_DATALOG}/${LV_DATAFILE}.log
    LV_BADFILE=${LV_DATALOG}/${LV_DATAFILE}.bad
    LV_DSCFILE=${LV_DATALOG}/${LV_DATAFILE}.discard

    rm $LV_LOGFILE
    rm $LV_BADFILE
    rm $LV_DSCFILE
	
	mv "$DKA_TOP/bin/${LV_CTL_FILE}.ctl" "$DKA_TOP/bin/${LV_CTL_FILE}_bak.ctl"
	# Generation du fichier de controle
     cat "$DKA_TOP/bin/${LV_CTL_FILE}_bak.ctl" \
        | sed "s/!LOAD_REQUEST_ID!/${FCP_REQID}/g" \
        | sed "s/!USER_ID!/${FCP_USERID}/g" \
          > "$DKA_TOP/bin/${LV_CTL_FILE}.ctl"
		 
	
    
	sqlldr  SILENT=FEEDBACK,HEADER \
            USERID=$FCP_LOGIN \
            CONTROL=$DKA_TOP/bin/${LV_CTL_FILE} \
            DATA=${LV_DATAFILE}.txt \
            LOG=${LV_LOGFILE} \
            BAD=${LV_BADFILE} \
            DISCARD=${LV_DSCFILE} 
        
    LN_RETCODE=$? 
    
	rm "$DKA_TOP/bin/${LV_CTL_FILE}.ctl"
	mv "$DKA_TOP/bin/${LV_CTL_FILE}_bak.ctl" "$DKA_TOP/bin/${LV_CTL_FILE}.ctl"
		
    cat $LV_LOGFILE

    if [ $LN_RETCODE -ne 0 ] && [ $LN_RETCODE -ne 2 ] || [ -f $LV_BADFILE ]; then

        #Fichier est rejete => un fichier bad peut etre genere
        echo " "                                              >> $LV_OUTPUT_FILE
        echo "LE FICHIER $LV_DATAFILE N EST PAS VALIDE"       >> $LV_OUTPUT_FILE
        echo " "
        echo "LE FICHIER $LV_DATAFILE N EST PAS VALIDE"

        if [ -f $LV_BADFILE ]; then
            echo "Les lignes non valides sont les suivantes :"    >> $LV_OUTPUT_FILE
            cat $LV_BADFILE                                       >> $LV_OUTPUT_FILE
        fi

        echo "Pour plus d'informations, consultez le journal (log) du traitement"     >> $LV_OUTPUT_FILE

        
        #function_ExitIfErr
        bol_erreur=2

    else
        #Fichier est OK
        echo " "                                      >> $LV_OUTPUT_FILE
        echo "LE FICHIER $LV_DATAFILE EST VALIDE"     >> $LV_OUTPUT_FILE
        echo "LE FICHIER $LV_DATAFILE EST VALIDE"
        echo " "                                      >> $LV_OUTPUT_FILE
		
    fi 
	
  
}


#--------------------------------------------------------------------------
# function_deplacer_file ()
#--------------------------------------------------------------------------
# Fonction pour deplacer les fichier
#
function_deplacer_file(){

    if [ $bol_erreur -eq 2 ]; then
        # Copie du fichier dans le repertoire de rejet
        mv $LV_DATAFILE  ${LV_DATALOG}/$LV_DATAFILE"."$LD_SYSDATE
    else
        mv $LV_DATAFILE  ${LV_DATALOG}/$LV_DATAFILE"."$LD_SYSDATE
    fi
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
   exit 1
}

# RETSQLPLUS="0"
#recuperation non du shell
# FCP_PROGRAM=$0

#Recuperation Parametres Systemes passes par OA
# FCP_LOGIN="$1"
# FCP_USERID="$2"
# FCP_USERNAME=`echo $3|cut -c 1-8`
# FCP_REQID="$4"


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




# Fichier de compte rendu du traitement
LV_OUTPUT_FILE=`sqlplus -s $FCP_LOGIN <<EOF
                set termout off
                set feedback off
                set pagesize 0
                SELECT r.outfile_name
                FROM fnd_concurrent_programs_vl pt,
                     fnd_concurrent_programs pb,
                     fnd_concurrent_requests r
                WHERE pb.application_id = r.program_application_id
                  AND pb.concurrent_program_id = r.concurrent_program_id
                  AND pb.application_id = pt.application_id
                  AND pb.concurrent_program_id = pt.concurrent_program_id
                  AND r.request_id = $FCP_REQID;
                exit
                EOF`
                
# Affichage Bandeau demarrage Interface 
echo "----------------------------------------------"  
echo "-   Parametres Systemes passes par OA        -"        
echo "----------------------------------------------"    
echo " NÂ° du traitement : <$FCP_REQID>"                                                    
echo "   ID du Login OA : <$FCP_USERID>"                                        
echo "         Login OA : <$FCP_USERNAME>"
echo Fichier de sortie du traitement : $LV_OUTPUT_FILE


echo "========================================================================="        >> $LV_OUTPUT_FILE
echo "DKA : Reprise AP fournisseurs import                     					"       >> $LV_OUTPUT_FILE
echo "Debut du traitement `date +%T`                                           "        >> $LV_OUTPUT_FILE
echo "========================================================================="        >> $LV_OUTPUT_FILE
echo "Parametres utilisateur :                                                 "        >> $LV_OUTPUT_FILE
echo "\n                                                                       "        >> $LV_OUTPUT_FILE
echo "========================================================================="        >> $LV_OUTPUT_FILE
echo "Controle de presence des fichiers attendus                               "        >> $LV_OUTPUT_FILE
echo "Chargement des fichiers dans les tables de travail intermediaires        "        >> $LV_OUTPUT_FILE
echo "========================================================================="        >> $LV_OUTPUT_FILE

LD_SYSDATE=`date '+%Y%m%d%H%M%S' `

## Repertoire des fichiers de donnees
LV_DATADIR=$REP_DATA_IN
LV_DATALOG=$REP_DATA_LOG

echo Repertoire de donnees : $LV_DATADIR  

if [ ! -d $LV_DATADIR ]
then
  echo Repertoire $LV_DATADIR inexistant.
  function_ExitIfErr                                                            >> $LV_OUTPUT_FILE
fi      

P_DAT_FILE_FOUNISSEURS=DKA_REP_FOURNISSEUR
P_DAT_FILE_SITES_FOUNISSEUR=DKA_REP_SITE_FOURNISSEUR
P_DAT_FILE_CONTACT_SF=DKA_REP_SITE_FOURNISSEUR_CONTACT
P_DAT_FILE_BANK_FOUNISSEUR=DKA_REP_FOURNISSEUR_BANQUE
P_DAT_FILE_DUP_SITE_FOURNISSEUR=DKA_REP_DUP_SITE_FOURNISSEUR

echo Fichier de donnees fournisseurs        : $P_DAT_FILE_FOUNISSEURS
echo Fichier de donnees sites fournisseur : $P_DAT_FILE_SITES_FOUNISSEUR
echo Fichier de donnees contacts        : $P_DAT_FILE_CONTACT_SF
echo Fichier de donnees banques fournisseurs      : $P_DAT_FILE_BANK_FOUNISSEUR
echo Fichier de donnees des societées de duplication      : $P_DAT_FILE_DUP_SITE_FOURNISSEUR


## Tables Intermediaires 
LV_TABLE_FOURNISSEURS=DKA_AP_REP_SUPP_TMP
LV_TABLE_SITE_FOURNISSEUR=DKA_AP_REP_SUPP_SITES_TMP
LV_TABLE_CONTACT_SF=DKA_AP_REP_SUPP_SITES_CTCT_TMP
LV_TABLE_BANK_FOURNISSEUR=DKA_AP_REP_SUPP_BANK_TMP
LV_TABLE_DUP_SITE_FOURNISSEUR=DKA_DUP_SITE_FOURNISSEUR


echo Table intermediaire fournisseurs       : $LV_TABLE_FOURNISSEURS
echo Table intermediaire sites fournisseur  : $LV_TABLE_SITE_FOURNISSEUR
echo Table intermediaire contacts       : $LV_TABLE_CONTACT_SF
echo Table intermediaire banques fournisseurs      : $LV_TABLE_BANK_FOURNISSEUR
echo Table intermediaire DUP_SITE_FOURNISSEUR      : $LV_TABLE_DUP_SITE_FOURNISSEUR

## Fichier de control  pour chargement
LV_CTL_FILE_FOURNISSEURS=DKA_AP_REP_SUPP_CTL
LV_CTL_FILE_SITE_FOURNISSEUR=DKA_AP_REP_SUPP_SITES_CTL
LV_CTL_FILE_CONTACT_SF=DKA_AP_REP_SUPP_SITES_CTCT_CTL
LV_CTL_FILE_BANK_FOURNISSEUR=DKA_AP_REP_SUPP_BANK_CTL
LV_CTL_FILE_DUP_SITE_FOURNISSEUR=DKA_DUP_SITE_FOURNISSEUR_CTL

echo Fichier de controle fournisseurs      : $LV_CTL_FILE_FOURNISSEURS
echo Fichier de controle sites fournisseur: $LV_CTL_FILE_SITE_FOURNISSEUR
echo Fichier de controle contacts       : $LV_CTL_FILE_CONTACT_SF
echo Fichier de controle banques fournisseurs       : $LV_CTL_FILE_BANK_FOURNISSEUR
echo Fichier de controle societées de duplication    : $LV_CTL_FILE_DUP_SITE_FOURNISSEUR


#echo "Purge des tables intermediaires ..."
#sqlplus -s $FCP_LOGIN << _EOF_
#set echo off
#set feed off
#set head off
#set termout off
#set linesize 200
#set pagesize 0
#set newpage 0
#delete FROM $LV_TABLE_FOURNISSEURS;
#delete FROM $LV_TABLE_SITE_FOURNISSEUR;
#delete FROM $LV_TABLE_CONTACT_SF;
#delete FROM $LV_TABLE_BANK_FOURNISSEUR;
#delete FROM $LV_TABLE_DUP_SITE_FOURNISSEUR;
#commit;
#_EOF_

#echo "... Tables intermediaires purgees"

#on se positionne dans le repertoire de donnees
cd $LV_DATADIR

# chargement du fichier fournisseurs
LV_DATAFILE=$P_DAT_FILE_FOUNISSEURS
LV_CTL_FILE=$LV_CTL_FILE_FOURNISSEURS
bol_erreur=0
function_load_file
bol_erreur_file_1=$bol_erreur

# chargement du fichier sites fournisseurs
LV_DATAFILE=$P_DAT_FILE_SITES_FOUNISSEUR
LV_CTL_FILE=$LV_CTL_FILE_SITE_FOURNISSEUR
bol_erreur=0
function_load_file
bol_erreur_file_2=$bol_erreur

# chargement du fichier contact site fournisseurs
LV_DATAFILE=$P_DAT_FILE_CONTACT_SF
LV_CTL_FILE=$LV_CTL_FILE_CONTACT_SF
bol_erreur=0
function_load_file
bol_erreur_file_3=$bol_erreur

# chargement du fichier banques fournisseurs
LV_DATAFILE=$P_DAT_FILE_BANK_FOUNISSEUR
LV_CTL_FILE=$LV_CTL_FILE_BANK_FOURNISSEUR
bol_erreur=0
function_load_file
bol_erreur_file_4=$bol_erreur

# chargement du fichier 
LV_DATAFILE=$P_DAT_FILE_DUP_SITE_FOURNISSEUR
LV_CTL_FILE=$LV_CTL_FILE_DUP_SITE_FOURNISSEUR
bol_erreur=0
function_load_file
bol_erreur_file_5=$bol_erreur

# si erreur de structure sur 1 des fichiers alors on arrete le traitement
if [ $bol_erreur_file_1 -eq 2 ] || [ $bol_erreur_file_2 -eq 2 ] || [ $bol_erreur_file_3 -eq 2 ]|| [ $bol_erreur_file_4 -eq 2 ] ; then
    echo "\n FIN DU TRAITEMENT : "`date`       
    function_ExitIfErr                                           >> $LV_OUTPUT_FILE
fi;

if [ $bol_erreur_file_1 -eq 1 ] && [ $bol_erreur_file_2 -eq 1 ] && [ $bol_erreur_file_3 -eq 1 ]&& [ $bol_erreur_file_4 -eq 1 ]; then
    echo "\n FIN DU TRAITEMENT : "`date`       
    echo "\nFichiers introuvables"                                 >> $LV_OUTPUT_FILE 
    function_ExitIfAttention                                       >> $LV_OUTPUT_FILE
fi;



echo "\n FIN DU TRAITEMENT : "`date`       
function_Exit                                                                         >> $LV_OUTPUT_FILE
