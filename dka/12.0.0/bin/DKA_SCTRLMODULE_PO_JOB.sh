#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SCTRLMODULE_PO_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SCTRLMODULE_EDT
#-
#- AUTEUR           : Benjamin COUDRIER
#- DATE DE CREATION : 26/06/2013
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
if [ $# -ne 1 ]
then
  echo "\nSyntaxe : $0 <apps_password><DKA><PO>"
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
echo "LANCEMENT DE DKA_SCTRLMODULE"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SCTRLMODULE.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'" \
	"'DKA'" \
	"'PO'"

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
