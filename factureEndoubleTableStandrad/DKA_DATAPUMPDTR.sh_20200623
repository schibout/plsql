#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SSATIPOIDS_JOB.sh
#- DESCRIPTION      : Script d'execution de SSATIPOIDS
#-
#- AUTEUR           : Evelyne SIMON (CGEY)
#- DATE DE CREATION : 26/07/2002
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 09/02/2017 YWA artf2098389
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 1 ] #YWA artf2098389
then
  echo "\nSyntaxe : $0 <apps_password>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1

#case "$2" in
#EMPLOYE) EMPLOYE=$2;;
#TIERS)  TIERS=$2;;
#GROUPE) GROUPE=$2;;
#esac #YWA artf2098389 

logfile=`echo $0 | cut -f 1 -d .`.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE SSATIPOIDS"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SSATIPOIDS.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'"
#"'81'"

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
