#!/bin/sh
#------------------------------------------------------------------------------------------
#- 
#- CAPGEMINI
#- PROJET           : Projet Hélios
#- NOM              : DKA_IARRECSICM_JOB.sh
#- DESCRIPTION      : Script d'execution de IARRECSICM
#-
#- AUTEUR           : Benjamin COUDRIER
#- DATE DE CREATION : 29/09/2011
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX apps
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  08/09/2016 BDE Modifications pour le projet Hélios  
#------------------------------------------------------------------------------------------




#############################################################################################
# Contrôle des parametres
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
echo "LANCEMENT DE DKA_IARRECSICM"       

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IARRECSICM.sql \
	"'EXPLOITATION'" \
	"'TOUT_AR_ADMINISTRATEUR'"   
  
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
