#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SPAPLOADIMG_JOB.sh
#- DESCRIPTION      : Script d'execution de SPAPLOADIMG
#-
#- AUTEUR           : Eric BLONDEEL
#- DATE DE CREATION : 16/01/2006
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
## MODIFICATION                                                               *
##                                                                            *
## Auteur         :  SEL                                                      *
## Date           :  13/01/2020                                               *
## Description    :  artf07147631 - Rapprochement des images facture          *
##                                                                            *
## ****************************************************************************
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


# SEL : artf07147631 : Debut

res=$(echo "@$DKA_TOP/admin/sql/ALADIN_IN_REP.sql exit" | sqlplus "apps/$1" |grep "Resultat= " |cut -f2 -d' ')
echo "Modification des noms des fichiers en majusculs"

cd $res

for fichier in *[a-z]*
do
echo $fichier
  basename=$(tr '[:lower:]' '[:upper:]' <<< "${fichier}")
  newname="$basename"
  mv "$fichier" "$newname"
done
;

# SEL : artf07147631 : Fin




#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE IIFFOOAP01"

sqlplus -s $apps_usr/$1 @$DKA_TOP/sql/DKA_SPAPLOADIMG.sql "'EXPLOITATION'" "'DKA_EXPLOITATION'"

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
