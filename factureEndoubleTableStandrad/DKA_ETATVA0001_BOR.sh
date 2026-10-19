#!bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET            DALKIA Oracle Applications
#- NOM               DKA_SFABUDGET_JOB.sh
#- DESCRIPTION       Script d'execution de DKA_SFABUDGET
#-
#- AUTEUR            Capgemini
#- DATE DE CREATION  11/06/2004
#- DOC. ASSOCIEE    
#- NOTES             A executer depuis le repertoire install sous le compte UNIX appdxxx
#- PARAMETRES        1  Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#------------------------------------------------------------------------------------------

#############################################################################################
# Controle des parametres
#############################################################################################
if [ $# -ne 1 ]
then
  echo syntaxe  $0 apps_password
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1
logfile=`echo $0  cut -f 1 -d .`.log


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo LANCEMENT DE SFABUDGET


	sqlplus -s $apps_usr/$1 \
        @$DKA_TOP/sql/DKA_SFABUDGET.sql \
        "'EXPLOITATION'" \
        "'DKA_EXPLOITATION'"

#############################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
#############################################################################################
# 0  SUCCESS
# 1  FAILURE
# 2  WARNING

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