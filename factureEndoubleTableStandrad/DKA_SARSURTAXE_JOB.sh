#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications Helios
#- NOM              : DKA_IAR_EVENEMENTS_DTR_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_IAR_EVENEMENTS_DTR
#-
#- AUTEUR           : Oussama BENHAYOUN (CAPGEMINI)
#- DATE DE CREATION : 21/09/2017
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 25/09/2017 OBE artf2226947 : INT082 - Automatisation en erreur
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 3 ]
then
  echo "\nSyntaxe : $0 <apps_password> <Date de dernière exécution> <Date du plan de production>"
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
echo "LANCEMENT DE DKA_IAR_EVENEMENTS_DTR"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IAR_EVENEMENTS_DTR.sql \
	"'EXPLOITATION'" \
	"'DKA_EXPLOITATION'" \
	$2 \
  $3

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
