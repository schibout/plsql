#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_ETATVA0001_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_ETATVA0001
#-
#- AUTEUR           : Capgemini
#- DATE DE CREATION : 24/09/2004
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 10/11/2016 YWA Migration R12
#------------------------------------------------------------------------------------------
# 16/01/2017 NBO artf2083890 - SPE077 : TVA : Edition états TVA societe 001 : Automatisation

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
#code_bande=$2
logfile=`echo $0 | cut -f 1 -d .`.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE DKA_ETATVA0001"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_ETATVA0001.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'"
code_retour=$?

#############################################################################################
# LANCEMENT DU SCRIPT DE CONSTITUTION DU BORDEREAU D'EXPEDITION
#############################################################################################
# ksh $DKA_TOP/bin/DKA_ETATVA0001_BOR.sh $code_bande


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
