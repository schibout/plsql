#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_IIWSSORB01_JOB.sh
#- DESCRIPTION      : Script d'execution de DKA_IIWSSORB01
#-
#- AUTEUR           : Grégory VANACKERE
#- DATE DE CREATION : 03/02/2009
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-                    2 : Nom du fichier
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 07/09/2017 OBE artf2220093 : SPE081 - Automatisation en erreur - Defect Beb #1067
#- ---------- --- -------------------------------------------------------------------------

fin_erreur () {
    echo "\n"
    echo "========================================================================="
    echo "!!!!!!!!!! Fin du traitement : le chargement a échoué          !!!!!!!!!!"
    echo "========================================================================="
    exit 20
}

#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <apps_password> <rb_file>"
  exit 20
fi


#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1


# nom du programme cut à la 1ère colonne avant "le point"
logfile=`echo $0 | cut -f 1 -d .`.log


RB_FILE=$2
echo "RB_FILE : $RB_FILE"


# Transformation de la date courante en chaine de caractères YYYYMMDDHHMNSS
#############################################################################################
RB_DATE_FILE=`date '+%Y%m%d%H%M%S'`
echo "RB_DATE_FILE : $RB_DATE_FILE"


# On vérifie que la variable d'environnement $REP_DATA est bien renseignée
#############################################################################################
if [ "$REP_DATA" = "" ]; then
    echo "La variable d'environnement REP_DATA n'est pas renseignée !!!"
    fin_erreur
fi
echo "REP_DATA : $REP_DATA"


# Les fichiers à traiter sont amenés via INTERPEL dans le répertoire $REP_DATA/in
#############################################################################################
RB_INPUT_DIR=$REP_DATA/in
# Vérification de l'existence de ce répertoire
if [ ! -d $RB_INPUT_DIR ]; then
    echo "Le répertoire des données RB_INPUT_DIR : $RB_INPUT_DIR n'existe pas !!!"
    fin_erreur
fi
echo "RB_INPUT_DIR : $RB_INPUT_DIR"


# Les fichiers traités sont archivés dans le répertoire $REP_DATA/traite
#############################################################################################
RB_TRAITE_DIR=$REP_DATA/traite
# Vérification de l'existence de ce répertoire
if [ ! -d $RB_TRAITE_DIR ]; then
    echo "Le répertoire des données RB_TRAITE_DIR : $RB_TRAITE_DIR n'existe pas !!!"
    fin_erreur
fi
echo "RB_TRAITE_DIR : $RB_TRAITE_DIR"


# Les relevés erronés sont archivés dans le répertoire $REP_DATA/log
#############################################################################################
RB_ERROR_DIR=$REP_DATA/log
# Vérification de l'existence de ce répertoire
if [ ! -d $RB_ERROR_DIR ]; then
    echo "Le répertoire des données RB_ERROR_DIR : $RB_ERROR_DIR n'existe pas !!!"
    fin_erreur
fi
echo "RB_ERROR_DIR : $RB_ERROR_DIR"


# Les fichiers traités portent le nom du fichier d'entrée et sont dans RB_TRAITE_DIR
# et les fichiers d'erreurs le nom du fichier d'entrée suivi de .err dans RB_ERROR_DIR
#############################################################################################
RB_TRAITE_FILE=$RB_TRAITE_DIR/$RB_FILE
RB_ERROR_FILE=$RB_ERROR_DIR/$RB_FILE.err

echo "RB_TRAITE_FILE : $RB_TRAITE_FILE"
echo "RB_ERROR_FILE : $RB_ERROR_FILE"


# Détermination du chemin complet du fichier d'entrée
#############################################################################################
RB_INPUT_FILE=$RB_INPUT_DIR/$RB_FILE
# On vérifie que le fichier de données existe dans le répertoire $G_IN_ROOT
if [ ! -s $RB_INPUT_FILE ]; then
    echo "le fichier de données $RB_INPUT_FILE n'existe pas dans le répertoire $RB_INPUT_DIR !!!"
    fin_erreur
fi
echo "RB_INPUT_FILE : $RB_INPUT_FILE"


#############################################################################################
# LANCEMENT DU SCRIPT
#############################################################################################
echo "LANCEMENT DE IIWSSORB01"

sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IIWSSORB01.sql \
	"'EXPLOITATION'" \
	"'DKA*RB*RESPONSABLE*RAPPRO'" \
	"$RB_INPUT_FILE" \
	"$RB_TRAITE_DIR" \
	"$RB_ERROR_DIR"

echo "RETOUR DE IIWSSORB01"

if [ ! -s $RB_TRAITE_FILE ]; then
    echo "le fichier de données RB_TRAITE_FILE : $RB_TRAITE_FILE n'existe pas dans le répertoire $RB_TRAITE_DIR !!!"
else
   mv $RB_TRAITE_FILE `echo $RB_TRAITE_FILE`_$RB_DATE_FILE 
fi

if [ ! -s $RB_ERROR_FILE ]; then
    echo "le fichier de données RB_ERROR_FILE : $RB_ERROR_FILE n'existe pas dans le répertoire $RB_ERROR_DIR !!!"
else
    mv $RB_ERROR_FILE `echo $RB_ERROR_FILE | cut -f 1 -d .`_$RB_DATE_FILE.err 
fi


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
