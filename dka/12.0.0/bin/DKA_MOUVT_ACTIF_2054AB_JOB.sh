#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_MOUVT_ACTIF_2054AB_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_MOUVT_ACTIF_2054AB
#-
#- AUTEUR           : Capgemini
#- DATE DE CREATION : 07/01/2003
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 15/05/2004 EMA Ajout de l'appel au fichier DKA_AMOR_FISC_BOR.sh
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
#if [ $# -ne 1 ]
#then
#  echo "\nSyntaxe : $0 <apps_password>"
#  exit 20
#fi
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <code_bande>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1
code_bande=$2
logfile=`echo $0 | cut -f 1 -d .`.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE DKA_MOUVT_ACTIF_2054AB"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_MOUVT_ACTIF_2054AB.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'"
code_retour=$?

ksh $DKA_TOP/bin/DKA_MOUVT_ACTIF_2054AB_BOR.sh $code_bande

#############################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
#############################################################################################
# 0 : SUCCESS
# 1 : FAILURE
# 2 : WARNING

case $code_retour in
    '0') exit 0
           ;;
    '1') exit 20
           ;;
    '2') exit 4
           ;;
    *)   exit 20
           ;;
esac
