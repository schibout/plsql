#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id: DKA_SPORETRT_DA_INCOMPLT_JOB.sh
#- CAP GEMINI
#- PROJET           : HELIOS
#- NOM              : DKA_SPORETRT_DA_INCOMPLT_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SPORETRT_DA_INCOMPLT_JOB
#-
#- AUTEUR           : Coudrier Benjamin
#- DATE DE CREATION : 18/06/2012
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
echo "LANCEMENT DE DKA_SPORETRT_DA_INCOMPLT.sql"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SPORETRT_DA_INCOMPLT.sql \
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
  