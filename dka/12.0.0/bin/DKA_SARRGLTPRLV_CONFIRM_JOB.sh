#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications Helios
#- NOM              : DKA_SARRGLTPRLV_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SARRGLTPRLV_CONFIRM_JOB
#-
#- AUTEUR           : A.AMENKOUR (CAPGEMINI)
#- DATE DE CREATION : 01/10/2019
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#
#------------------------------------------------------------------------------------------

#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <planif>"
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
echo "LANCEMENT DE DKA_SARRGLTPRLV_CONFIRM"
echo "A :" $1
echo "B :" $2
sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SARRGLTPRLV_CONFIRM.sql $2 \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'" 

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
