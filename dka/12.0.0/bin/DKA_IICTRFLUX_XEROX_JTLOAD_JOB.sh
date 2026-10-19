#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id $
#- Capgemini 
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_IICTRFLUX_XEROX_JTLOAD.sh
#- DESCRIPTION      : Script d'execution de DKA_IICTRFLUX_XEROX_JTLOAD.sql
#-
#- AUTEUR           : Franck MICHEL
#- DATE DE CREATION : 13/11/2009
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  16/09/2016 JJA Portage Helios R12
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
echo "LANCEMENT DE DKA_IICTRFLUX_XEROX_JTLOAD.sql"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IICTRFLUX_XEROX_JTLOAD.sql \
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
