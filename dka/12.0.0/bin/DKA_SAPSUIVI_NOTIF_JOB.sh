#! /bin/sh
################################################################################
# $Id: DKA_SAPSUIVI_NOTIF_JOB.sh 880 2008-08-07 10:11:00Z CORP\tbonduae $
# Capgemini
# Projet           : DALKIA Oracle Applications
# Nom              : DKA_SAPSUIVI_NOTIF_JOB.sh
# Description      : Script d'execution de DKA_SAPSUIVI_NOTIF.sql
#
# Auteur           : Thomas Bonduaeux
# Date de creation : 07/08/2008
# Doc. associee    :
# Notes            :
# Parametres       : 1 - Mot de passe Oracle du user APPS
################################################################################
# Historique
# Date       Qui Description
#
################################################################################


################################################################################
# Contrôle des parametres
################################################################################
if [ $# -ne 1 ]
then
  echo "\nSyntaxe : $0 <apps_password>"
  exit 20
fi


################################################################################
# DECLARATION DES VARIABLES
################################################################################
apps_usr=APPS
apps_pwd=$1
logfile=`echo $0 | cut -f 1 -d .`.log


################################################################################
# LANCEMENT DU SCRIPT
################################################################################
echo "LANCEMENT DE SAPSUIVI_NOTIF"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SAPSUIVI_NOTIF.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'"

################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
################################################################################
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
