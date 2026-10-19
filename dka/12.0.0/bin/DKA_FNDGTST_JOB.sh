#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_FNDGTST_JOB.sh
#- DESCRIPTION      : Script d'execution de FNDGTST
#-
#- AUTEUR           : S.HAHIOUI
#- DATE DE CREATION : 30/05/2022
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 3 ]
then
  echo "\nSyntaxe : $0 <apps_password> <owner> <table>"
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
echo "LANCEMENT DE FNDGTST"


sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SFNDGTST.sql \
	"'SYSADMIN'" \
	"'SYSTEM_ADMINISTRATOR'" \
	"'DKA_CSP'" \
	$2 \
	$3


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
 