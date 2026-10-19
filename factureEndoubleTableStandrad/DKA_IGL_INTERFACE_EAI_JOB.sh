#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_OPEN_INTERFACE_AP_EAI_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_OPEN_INTERFACE_AP_EAI
#-
#- AUTEUR           : Benjamin COUDRIER (CGEY)
#- DATE DE CREATION : 10/11/2014
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 29/11/2016 MEG artf2052652 
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
echo "LANCEMENT DE DKA_OPEN_INTERFACE_AP_EAI"

sqlplus -s $apps_usr/$1  @$DKA_TOP/sql/DKA_OPEN_INTERFACE_AP_EAI.sql "'EXPLOITATION'" "'TOUT_AP_ADMINISTRATEUR'"

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
