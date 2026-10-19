#------------------------------------------------------------------------------------------
#-- $$
#-- CAPGEMINI
#-- PROJET           : DALKIA Oracle Applications
#-- NOM              : DKA_ENG_HERC
#-- DESCRIPTION      : Script de création du .zip
#--
#-- AUTEUR           : CAPGEMINI
#-- DATE DE CREATION : 29/05/2019
#-- DOC. ASSOCIEE    :
#-- COMMENTAIRE      :
#------------------------------------------------------------------------------------------
#-- HISTORIQUE DES MODIFICATIONS
#-- Date       Qui Description
#-- ---------- --- ------------------------------------------------------------------------
#-- 11/12/2020 ARA Ajout du 4ème fichier FINHER_REFAC_${jour}.csv
#------------------------------------------------------------------------------------------

# --------------------------
# Affichage des parametres
# --------------------------
echo "Parametres récupérés"
echo "----------------------------------------------------------------------------+"


LOGIN=${1}

jour=`/bin/date +%Y%m%d`


filename1=FINHER_MO_${jour}.csv
filename2=FINHER_FACTURES_${jour}.csv
filename3=FINHER_ENGAGE_${jour}.csv
filename4=FINHER_REFAC_${jour}.csv

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

for convfile in `find $filename3`
do
echo Fichier trouvé : $convfile
format=`file -bi $convfile`
if [[ $format == *ascii* ]]  
then
echo "Conversion du fichier "${convfile} "en UTF-8"
iconv -f us-ascii -t utf-8 $filename3 > $filename3.retcode
mv  $filename3.retcode $filename3
fi
done

for convfile in `find $filename4`
do
echo Fichier trouvé : $convfile
format=`file -bi $convfile`
if [[ $format == *ascii* ]]  
then
echo "Conversion du fichier "${convfile} "en UTF-8"
iconv -f us-ascii -t utf-8 $filename4 > $filename4.retcode
mv  $filename4.retcode $filename4
fi
done

echo "----------------------Compression des fichiers de sortie ------------------------------------------------------+"

# Script permettant la compression du fichier.
V_STATUS=`zip ${repertoire}/Engages_ORACLE_${jour} FINHER_MO_${jour}.csv FINHER_FACTURES_${jour}.csv FINHER_ENGAGE_${jour}.csv FINHER_REFAC_${jour}.csv`

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
    
echo ' le traitement a généré le dossier ==>    : ' ${repertoire}/Engages_ORACLE_${jour}
  # suppression des fichiers individuels aprés la création du zip.
    rm -f FINHER_MO_${jour}.csv FINHER_FACTURES_${jour}.csv FINHER_ENGAGE_${jour}.csv FINHER_REFAC_${jour}.csv
	exit 0
fi;



