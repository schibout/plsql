#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id: 
#- CAP GEMINI
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_FLAG_TP.sh
#- DESCRIPTION      : Script d'execution de Flag_tp.sql
#-
#- AUTEUR           : B.COUDRIER
#- DATE DE CREATION : 17/09/2013
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX apps
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS.
#-					  2 : Flag TP.
#- 
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password><Flag TP>"
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
echo "LANCEMENT DE Flag_tp.sql"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/Flag_tp.sql $2 `date +%d-%m-%Y`

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
