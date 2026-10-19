#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_ENCOURS_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_ENCOURS
#-
#- AUTEUR           : E.Matuszewski
#- DATE DE CREATION : 26/03/2008
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
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


case $(basename $0) in
  *ENCOURS*) prog='DKA_ENCOURS_RECOUVREMENT' ;;
  *AVOIRS*)  prog='DKA_AVOIRS_RECOUVREMENT' ;;
  *RATIO*)   prog='DKA_RATIOS_RECOUVREMENT' ;;
esac


case $(basename $0) in
  *FRANCE*) mode='FRANCE' ; prog=$(echo $prog | sed 's/RECOUVREMENT/FRANCE/g') ;;
  *)        mode='ORG' ;;
esac 

#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE $prog"

sqlplus -s $apps_usr/$1 @$DKA_TOP/sql/DKA_AUTO_SARRECOUVREMENT.sql "DKA" "$prog" "$mode" | tee $logfile
code_retour=$?

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
