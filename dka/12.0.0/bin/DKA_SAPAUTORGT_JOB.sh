#!/bin/sh
#------------------------------------------------------------------------------------------
#- $Id: DKA_SAPAUTORGT_JOB.sh 34 2008-08-05 12:53:03Z tbonduae $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SAPAUTORGT_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_SAPAUTORGT / SAPAUTORGT
#-
#- AUTEUR           : X. Descamps (CGEY)
#- DATE DE CREATION : 21/05/2002
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date               Qui                     Description
#- ---------- --- -------------------------------------------------------------------------
#- 24/02/2003  S. Bellout (CGEY)               Declaration du traitement
#- 07/07/2008  V. KNAB                         Modifications pour Projet NEXT
#- ------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <VARIABLE>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1

case "$2" in
EMPLOYE) EMPLOYE=$2;;
TIERS)  TIERS=$2;;
GROUPE) GROUPE=$2;;
esac

logfile=`basename $0 | cut -d. -f1 `.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE SAPAUTORGT"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_SAPAUTORGT.sql "'$2'" \
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
