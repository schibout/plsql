#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CapGemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SGLABONNEMENT_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SGLABONNEMENT
#-
#- AUTEUR           : CapGemini
#- DATE DE CREATION : 07/01/2003
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
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
echo "LANCEMENT DE DKA_SGLABONNEMENT"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SGLABONNEMENT.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'"
code_retour=$?

#############################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
#############################################################################################
# 0 : SUCCESS
# 1 : FAILURE
# 2 : WARNING

case $code_retour in
    '0') exit 0
           ;;
    '1') exit 20
           ;;
    '2') exit 4
           ;;
    *)   exit 20
           ;;
esac
