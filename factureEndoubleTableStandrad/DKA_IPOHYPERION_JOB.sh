#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id: $
#- CAP GEMINI
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_IAPARGLCTRLFISCAL_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_IAPARGLCTRLFISCAL
#-
#- AUTEUR           : Julien Jardez
#- DATE DE CREATION : 16/12/2013
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-                    2 : Société légale ou opérationelle
#-
#- HISTORIQUE DES MODIFICATIONS
#- AUTEUR           : WARID YOUNES YWA
#- DATE DE modification : 06/06/2016
#- DESCRIPTION     : MIGRATION R12
#- ---------- --- -------------------------------------------------------------------------
#------------------------------------------------------------------------------------------


#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <LEG OU OPE>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1
p_type=$2

logfile=`echo $0 | cut -f 1 -d .`.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE DKA_IAPARGLCTRLFISCAL_JOB"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IAPARGLCTRLFISCAL.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'" \
  "'$2'"
	
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
 
 
 