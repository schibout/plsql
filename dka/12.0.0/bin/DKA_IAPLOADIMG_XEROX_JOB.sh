#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI
#- PROJET           : Hélios
#- NOM              : DKA_IAPLOADIMG_XEROX_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_IAPLOADIMG_XEROX
#-
#- AUTEUR           : A.Deltour
#- DATE DE CREATION : 31/03/2008
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  -- 02/09/2016 BDE Modification pour Hélios
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -lt 1 ]
then
  echo "\nSyntaxe : $0 <apps_password> "
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
echo "LANCEMENT DE DKA_IAPLOADIMG_XEROX"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IAPLOADIMG_XEROX.sql \
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
