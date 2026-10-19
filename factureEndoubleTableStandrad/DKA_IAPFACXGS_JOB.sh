#!/bin/sh
#------------------------------------------------------------------------------------------
#- 
#- CAP GEMINI
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_IFA_FLUXCM__JOB.sh
#- DESCRIPTION      : Script d'execution de IFA_FLUXCM
#-
#- AUTEUR           : Clément DEFAUX
#- DATE DE CREATION : 03/11/2011
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX apps
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  20/02/2017 YWA artf2101653   
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 1 ]
then
  echo "\nSyntaxe : $0 <apps_password>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1
logfile=`echo $0 | cut -f 1 -d .`.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE DKA_IFA_FLUXCM"       

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IFA_FLUXCM.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'"      
  
#echo "COPIE DU FICHIER GENERE DANS LE REPERTOIRE DATA/EAI" #artf2101653 
#cp $REP_DATA/out/FOACMFA* /data/eai/.          

#echo "DEPLACEMENT DU FICHIER DANS EAI/out"  #artf2101653 
#mv /data/eai/FOACMFA* /data/eai/out/.   

#############################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
#############################################################################################
# 0 : SUCCESS
# 1 : FAILURE
# 2 : WARNING

case $? in
    '0') exit 0
           ;;
    '1') exit 20
           ;;
    '2') exit 4
           ;;
    *)   exit 20
           ;;
esac