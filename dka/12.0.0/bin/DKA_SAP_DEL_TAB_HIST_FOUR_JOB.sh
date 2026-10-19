#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAPGEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications Helios
#- NOM              : DKA_SAP_DEL_TAB_HISTORY_FOUR.sh
#- DESCRIPTION      : Script d'execution de DKA_SAP_DEL_TAB_HISTORY_FOUR.sh
#-
#- AUTEUR           : SELO (CAPGEMINI)
#- DATE DE CREATION : 21/12/2021
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#- 					: 2 : Nombre de jours
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#
#------------------------------------------------------------------------------------------





#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1
p_nbre_jrs=$2
logfile=`echo $0 | cut -f 1 -d .`.log

#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 1 ]
then
  echo "\nSyntaxe : $0 <apps_password>"
  exit 20
fi


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE DKA_SAP_DEL_TAB_HISTORY_FOUR"
echo "A :" $1

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SAP_DEL_TAB_HISTORY_FOUR.sql \
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
