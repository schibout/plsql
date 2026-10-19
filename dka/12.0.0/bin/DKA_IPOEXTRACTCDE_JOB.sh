#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id $
#- CAP GEMINI
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_IPOEXTRACTCDE_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_IPOEXTRACTCDE
#-
#- AUTEUR           : J. JARDEZ
#- DATE DE CREATION : 27/03/2008
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  09/05/2016 BDE Modification de $XXVE en $DKA_TOP
#                 Modification de la responsabilité (VT_EXPLOITATION) en DKA_EXPLOITATION
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
echo "LANCEMENT DE IPOEXTRACTCDE"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IPOEXTRACTCDE.sql \
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
