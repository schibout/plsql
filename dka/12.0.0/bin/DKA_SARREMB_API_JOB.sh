#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CapGemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SARREMB_API_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SARREMB_API_JOB
#-
#- AUTEUR           : Anas RAOUF
#- DATE DE CREATION : 28/05/2024
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#------------------------------------------------------------------------------------------


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1
logfile=`echo $0 | cut -f 1 -d .`.log
location=`echo $DKA_TOP/sql`

#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE SCRIPT"

sqlplus $apps_usr/$apps_pwd @$DKA_TOP/sql/DKA_SARCONTEXT.tab $apps_pwd $2 $3 $location

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