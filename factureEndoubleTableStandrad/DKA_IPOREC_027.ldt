#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id: DKA_APXRECLC_JOB.sh $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_APXRECLC_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SAPAUTORGT / DKA_APXRECLC.sql
#-
#- AUTEUR           : R. BELAYACHI (CAP)
#- DATE DE CREATION : 12/10/2016
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date               Qui                     Description
#- ---------- --- -------------------------------------------------------------------------
#- ------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <VARIABLE>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1

case "$2" in
EMPLOYE) EMPLOYE=$2;;
TIERS)  TIERS=$2;;
GROUPE) GROUPE=$2;;
esac

logfile=`basename $0 | cut -d. -f1 `.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE SAPAUTORGT"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_APXRECLC.sql "'$2'" \
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
