#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SAPXCRRCR_JOB.sh
#- DESCRIPTION      : Script d'execution de SAPXCRRCR
#-
#- AUTEUR           : X. Descamps (CGEY)
#- DATE DE CREATION : 20/05/2003
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  10/04/2007  TB  Ajout d'un nouveau paramètre : type de fournisseurs
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -lt 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <Date campagne (10 ou FDM)> <Type fournisseur (TIERS, GROUPE, EMPLOYE)>"
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
echo "LANCEMENT DE SAPXCRRCR"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SAPXCRRCR.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'" \
	"'$2'" \
  "'$3'"

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
