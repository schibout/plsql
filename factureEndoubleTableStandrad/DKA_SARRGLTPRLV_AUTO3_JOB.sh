#------------------------------------------------------------------------------------------
#-- $$
#-- CAPGEMINI
#-- PROJET           : DALKIA Oracle Applications
#-- NOM              : DKA_EXT_SOLD_HERC
#-- DESCRIPTION      : Script de création du .zip
#--
#-- AUTEUR           : F.Siham (CAPGEMINI)
#-- DATE DE CREATION : 05/07/2019
#-- DOC. ASSOCIEE    :
#-- COMMENTAIRE      :
#------------------------------------------------------------------------------------------
#-- HISTORIQUE DES MODIFICATIONS
#-- Date       Qui Description
#-- ---------- --- ------------------------------------------------------------------------
#------------------------------------------------------------------------------------------

# --------------------------
# Affichage des parametres
# --------------------------
echo "Parametres récupérés"
echo "----------------------------------------------------------------------------+"


LOGIN=${1}

jour=`/bin/date +%Y%m%d`


filename1=ComptesgroupesP3_ORACLE_${jour}.csv
filename2=ComptesgroupesP6_ORACLE_${jour}.csv

vars=( $LOGIN )
echo ' repertoire     : ' ${vars[9]} | sed 's/"//g'

repertoire=`echo ${vars[9]} | sed 's/"//g'`

cd ${repertoire}

echo "---------------------conversion des fichiers de sortie en UTF-8----------------------------+"

for convfile in `find $filename1`
do
echo Fichier trouvé : $convfile
format=`file -bi $convfile`
if [[ $format == *ascii* ]]  
then
echo "Conversion du fichier "${convfile} "en UTF-8"
iconv -f us-ascii -t utf-8 $filename1 > $filename1.retcode
mv  $filename1.retcode $filename1
fi
done

for convfile in `find $filename2`
do
echo Fichier trouvé : $convfile
format=`file -bi $convfile`
if [[ $format == *ascii* ]]  
then
echo "Conversion du fichier "${convfile} "en UTF-8"
iconv -f us-ascii -t utf-8 $filename2 > $filename2.retcode
mv  $filename2.retcode $filename2
fi
done

echo "----------------------Compression des fichiers de sortie ------------------------------------------------------+"

# Script permettant la compression du fichier.
V_STATUS=`zip ${repertoire}/ComptesgroupesP3_ORACLE_${jour} ComptesgroupesP3_ORACLE_${jour}.csv`
V_STATUS=`zip ${repertoire}/ComptesgroupesP6_ORACLE_${jour} ComptesgroupesP6_ORACLE_${jour}.csv`

V_ERROR=$?
if [ $V_ERROR -gt 1 ]
then 
	echo "Erreur lors de l'exécution du script: zip"
	echo "Une erreur s'est produite."
	exit 1
elif [ $V_ERROR -ne 0 ]
then
    echo "Erreur lors de l'exécution du script: zip"
	echo "L'expression conditionnelle est fausse."
	exit 2
else
    
echo ' le traitement a généré le dossier  ==>    : ' ${repertoire}/ComptesgroupesP3_ORACLE_${jour}
echo ' le traitement a généré le dossier  ==>    : ' ${repertoire}/ComptesgroupesP6_ORACLE_${jour}
  # suppression des fichiers individuels aprés la création du zip.
    rm -f ComptesgroupesP3_ORACLE_${jour}.csv ComptesgroupesP6_ORACLE_${jour}.csv 
	exit 0
fi;



