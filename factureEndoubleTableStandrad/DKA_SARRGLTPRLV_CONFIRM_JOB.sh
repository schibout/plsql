#!/bin/sh
# **************************************************************************
# $HEADER				: 	$
# FICHIER     	:  	DKA_SPOREPCOMCONT V 1.0
#
# DESCRIPTION   :  	Specifique de reprise des commandes de contrat
#
# PARAMETRES    : 	1 : FILE_NAME	
#
# AUTEUR      	:  	A.DELTOUR
#
# DATE CREATION : 	06/09/2007
# NOTES            : A EXÉCUTER DEPUIS LE RÉPERTOIRE BIN DU SERVEUR DE DONNEES
#                 
#
# ************************* M O D I F I C A T I O N S **********************
# VER        DATE        AUTEUR           NATURE
# --------------------------------------------------------------------
# V1.1    03/02/2009   C. DELCASSO  Modif répertoire de dépot des fichiers DKA_TOP/in => REP_DATA/in
#***************************************************************************
#   Get the concurrent program arguments

# decoupage argument "$1" "$2" ...
set $@

# recuperation nom du shell
FCP_PROGRAM=$1

# argument OA
shift 1
FCP_ARGS="$1 $2 $3 $4 $5 $6 $7"
export FCP_ARGS

# positionnement des variable d'OA
eval ${FCP_ARGS}
export FCP_USERNAME FCP_PROGRAM FCP_LOGIN \
        FCP_USERID FCP_REQID FCP_PRINTER FCP_NUM_COPIES

echo $FCP_LOGIN        

#on va recuperer maintenant les arguments du shell        
shift 7

# $1 : file name

# save parmeters
REPERTOIRE=$REP_DATA/in
FILE_NAME=`echo $1|tr -d " \" "`

#Debug
#echo "Debug ... ${REPERTOIRE}" >> ${APPLCSF}/log/${FCP_PROGRAM}.log
#echo "Debug ... ${FILE_NAME}" >> ${APPLCSF}/log/${FCP_PROGRAM}.log

abs_file=`echo ${REPERTOIRE}/${FILE_NAME}`

#Debug
#echo "Debug ... ${abs_file}" >> ${APPLCSF}/log/${FCP_PROGRAM}.log

rep=`dirname $abs_file`
nom_fichier=`basename $abs_file`

echo " "
echo "******************************************************************"
echo "=> Etape 1 : Chargement des données dans la table temporaire"
echo "******************************************************************"

#partie a adapter selon l'interface
exe_name='DKA_SPOREPCOMCONT'
tmp_table='DKA_PO_COM_CONT_TMP'

#positionnement code d'erreur en sortie du shell
ERROR=0

#on vide la table temporaire
`sqlplus -s $FCP_LOGIN << _EOF_
set echo off
set feed off
set head off
set termout off
set linesize 200
set pagesize 0
set newpage 0
delete FROM $tmp_table;
_EOF_`

echo "TRAITEMENT ${exe_name}" > ${APPLCSF}/log/${exe_name}.log
	
rm ${APPLCSF}/log/${exe_name}_sqlloader.bad 1>/dev/null 2>&1

#load data into temporay table 
sqlldr userid=$FCP_LOGIN \
control=$DKA_TOP/bin/${exe_name}.ctl \
data=${abs_file} \
log=${APPLCSF}/log/${exe_name}_sqlloader.log \
bad=${APPLCSF}/log/${exe_name}_sqlloader.bad \
discard=${APPLCSF}/log/${exe_name}_sqlloader.dsc \
errors=1000000 1>/dev/null 2>&1

NB_LINE_FILE=`wc -l $abs_file|awk '{print $1}'`

#BUG unix si dernier ligne n'a pas de retour chariot, elle n'est pas contabilisee
if [ `grep -c -v '#@##@###@####@#@#@#@' $abs_file` -ne $NB_LINE_FILE ] 
then
	let  NB_LINE_FILE=${NB_LINE_FILE}+1
fi

echo" "
echo "********** FICHIER $nom_fichier DEBUT TRAITEMENT **********" >> ${APPLCSF}/log/${exe_name}.log
if [ -f ${APPLCSF}/log/${exe_name}_sqlloader.bad ]
then
  echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
  echo "SQLloader ${exe_name}.ctl error loading" >>${APPLCSF}/log/${exe_name}.log
  echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
  #awk -v PARAM='ERRORloader' -f $DKA_TOP/bin/filtre_${exe_name}.awk ${APPLCSF}/log/${exe_name}_sqlloader.log  >>${APPLCSF}/log/${exe_name}.log
  #echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
	echo "Lignes en erreur:" >>${APPLCSF}/log/${exe_name}.log
  #echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
	cat ${APPLCSF}/log/${exe_name}_sqlloader.bad >>${APPLCSF}/log/${exe_name}.log
  echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
  ERROR=2  
  
else
	
  echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
  echo "SQLloader ${exe_name}.ctl loading Status OK" >>${APPLCSF}/log/${exe_name}.log
  echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
  #awk -v PARAM='OKloader' -f $DKA_TOP/bin/filtre_${exe_name}.awk ${APPLCSF}/log/${exe_name}_sqlloader.log  >>${APPLCSF}/log/${exe_name}.log
  #echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
fi
  
NB_LINE=`sqlplus -s $FCP_LOGIN << _EOF_
  set echo off
  set feed off
  set head off
  set termout off
  set linesize 500
  set pagesize 0
  set newpage 0
  SELECT count(1) from $tmp_table ;
_EOF_`
  
  echo $NB_LINE " lignes sont inserees dans la table $tmp_table" >> ${APPLCSF}/log/${exe_name}.log
  echo "pour le fichier $nom_fichier qui comporte $NB_LINE_FILE lignes" >> ${APPLCSF}/log/${exe_name}.log
 	echo "********** FICHIER $nom_fichier FIN TRAITEMENT **********" >> ${APPLCSF}/log/${exe_name}.log
	echo " ">> ${APPLCSF}/log/${exe_name}.log
	echo " ">> ${APPLCSF}/log/${exe_name}.log
	
echo "--------------------------------------------------------------------------------" >>${APPLCSF}/log/${exe_name}.log
cat ${APPLCSF}/log/${exe_name}_sqlloader.log >> ${APPLCSF}/log/${exe_name}.log

## -----------------------------------------------------------
## Recherche des informations user, responsabilite, application 
## de la responsabilite pour le passage des parametres du CONCSUB
## -----------------------------------------------------------
#echo $FCP_REQID >> ${APPLCSF}/log/${exe_name}.log
#sqlplus  $FCP_LOGIN <<FIN >>/dev/null
#col v_user new_value v_user
#col v_appl_sname new_value v_appl_sname
#col v_resp_name new_value v_resp_name
#
#select fu.user_name v_user,fa.application_short_name v_appl_sname,fr.responsibility_name v_resp_name,fcr.outfile_name v_sortie
#from fnd_user fu
#, fnd_responsibility_vl fr
#, fnd_application fa
#, fnd_concurrent_requests fcr
#where fcr.requested_by = fu.user_id
#and fa.application_id = fcr.responsibility_application_id
#and fr.application_id = fcr.responsibility_application_id
#and fr.responsibility_id = fcr.responsibility_id
#and fcr.request_id = $FCP_REQID;
#
#host echo &v_user>v_user
#host echo &v_appl_sname>v_appl_sname
#host echo &v_resp_name>v_resp_name
#exit;
#FIN
#
## recuperation des informations liees au concurrent_request courant
#V_USER=`cat v_user`
#V_APPL_SNAME=`cat v_appl_sname`
#V_RESP_NAME=`cat v_resp_name`
#
#echo $V_USER >> ${APPLCSF}/log/${exe_name}.log
#echo $V_APPL_SNAME >> ${APPLCSF}/log/${exe_name}.log
#echo $V_RESP_NAME >> ${APPLCSF}/log/${exe_name}.log
#
#if [$ERROR = 0]
#then
#echo " "
#echo "******************************************************************"
#echo "=> Etape 2 : Import et approbation des contrats cadres "
#echo "******************************************************************"
#CONCSUB $FCP_LOGIN $V_APPL_SNAME \"$V_RESP_NAME\" $V_USER WAIT=5 CONCURRENT DKA  DKA_SPOREPCONTDEPSSTR_PKG $FCP_REQID >> ${APPLCSF}/log/${exe_name}.log
#
## -----------------------------------------------------------
## Recherche des informations user, responsabilite, application
## de la responsabilite pour le passage des parametres du CONCSUB
## -----------------------------------------------------------
#echo $FCP_REQID >> ${APPLCSF}/log/${exe_name}.log
#sqlplus $FCP_LOGIN <<FIN >>/dev/null
#col v_status new_value v_status
#col v_request_id new_value v_request_id
#
#SELECT
#  Fcr.Status_Code v_status
#, Fcr.Request_Id v_request_id
#FROM
#  Fnd_Concurrent_Requests Fcr
#WHERE
#  Fcr.Parent_Request_Id = $FCP_REQID;
#
#host echo &v_status>v_status
#exit;
#FIN
#
## recuperation des informations liees au concurrent_request courant
#V_STATUS=`cat v_status`
#V_REQUEST_ID=`cat v_request_id`
#
#echo $V_STATUS >> ${APPLCSF}/log/${exe_name}.log
#echo $V_REQUEST_ID >> ${APPLCSF}/log/${exe_name}.log
#
#case $V_STATUS in
#	'C') echo "PL/SQL : traitement des fichiers SUCCESSFULLY" >> ${APPLCSF}/log/${exe_name}.log
#       ;;
#	'G') echo "PL/SQL : traitement des fichiers  WARNING"  >> ${APPLCSF}/log/${exe_name}.log
#      ;;
#	*)	echo "PL/SQL : traitement des fichiers  ERROR"  >> ${APPLCSF}/log/${exe_name}.log
#  	 	ERROR=2
#exit $ERROR
#      ;;
#esac
#
#cat ${APPLCSF}/log/${exe_name}.log
#exit $ERROR
#else
#cat ${APPLCSF}/log/${exe_name}.log
#exit $ERROR
#fi
cat ${APPLCSF}/log/${exe_name}.log
exit $ERROR
