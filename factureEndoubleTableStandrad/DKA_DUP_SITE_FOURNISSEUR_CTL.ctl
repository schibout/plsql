#!/bin/bash
#----------------------------------------------------------------------------------------------
#--
#-- NOM               : DKA_COMPRESS_FILE_ZIP
#-- DESCRIPTION       : Shell de lancement du traitement [DKA : Compression de fichier zip.]
#--
#-- AUTEUR           : B.COUDRIER
#-- DATE DE CREATION : 09/08/2012
#---
#----------------------------------------------------------------------------------------------
#-- NOM DU PROGRAMME :
#--- PARAMETRES       :
#--    $1 : Nom du fichier en entré       
#--    $2 : Chemin du fichier en entré  
#--    $3 : Chemin du fichier en sortie
#--	   $4 : Nom du fichier en sortie
#--
#-- HISTORIQUE DES MODIFICATIONS
#-- DATE       QUI DESCRIPTION
#---------------------------------------------------------------------------------------------
#---------------------------------------------------------------------------------------------

#set -xv

# decoupage argument "$1" "$2" ...
set $@

# recuperation non du shell
FCP_PROGRAM=$1

# argument OA
shift 1
FCP_ARGS="$1 $2 $3 $4 $5 $6 $7"
export FCP_ARGS

# positionnement des variable d'OA
eval ${FCP_ARGS}
export FCP_USERNAME FCP_PROGRAM FCP_LOGIN \
        FCP_USERID FCP_REQID FCP_PRINTER FCP_NUM_COPIES

#on va recuperer mantenant les arguments du shell        
shift 7

# $1 : Nom du fichier en entré
# $2 : Chemin du fichier en entré
# $3 : Chemin du fichier en sortie
# $4 : Nom du fichier en sortie

# save parameters
FICHIER_ENTRE=`echo $1|tr -d " \" "`
CHEMIN_ENTRE=`echo $2|tr -d " \" "`
CHEMIN_SORTIE=`echo $3|tr -d " \" "`
FICHIER_SORTIE=`echo $4|tr -d " \" "`
cd $CHEMIN_ENTRE

PATH=`echo $PATH:/usr/local/bin:/usr/bin`
export PATH

# Script permettant la compression du fichier.
V_STATUS=`zip $CHEMIN_SORTIE/$FICHIER_SORTIE $FICHIER_ENTRE`

V_ERROR=$?
if [ $V_ERROR -gt 1 ]
then 
	echo "Erreur lors de l'exécution du script: zip ${CHEMIN_SORTIE}/${FICHIER_SORTIE} ${CHEMIN_ENTRE}/${FICHIER_ENTRE}"
	echo "Une erreur s'est produite."
	exit 1
elif [ $V_ERROR -ne 0 ]
then
    echo "Erreur lors de l'exécution du script: zip ${CHEMIN_SORTIE}/${FICHIER_SORTIE} ${CHEMIN_ENTRE}/${FICHIER_ENTRE}"
	echo "L'expression conditionnelle est fausse."
	exit 2
else
	exit 0
fi;
