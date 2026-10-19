#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id: $
#- CAP GEMINI
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SARAUTOPRELEV_JOB_AUTO.sh
#- DESCRIPTION      : Script d'execution de DKA_SARRGLTPRLV_AUTO1
#-
#- AUTEUR           : S.HAHIOUI
#- DATE DE CREATION : 30/01/2020
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 
#------------------------------------------------------------------------------------------

#############################################################################################
# Contrôle des paramètres
#############################################################################################

echo 'param1='$1
echo 'param2=' $2

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
echo "LANCEMENT DE DKA_SARAUTOPRELEV_JOB_AUTO"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SARAUTOPRELEV_JOB_AUTO.sql $2 \
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
 
 
