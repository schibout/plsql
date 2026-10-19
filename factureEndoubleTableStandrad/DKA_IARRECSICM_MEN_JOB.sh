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
PARAM=${2}
CHEMIN=${3}
echo "PARAM=" $PARAM

echo "CHEMIN=" $CHEMIN


filename1=DSP01_INV_*_${PARAM}*.csv

cd ${CHEMIN}

#touch UTF8_EMPTY1.csv

#cp $APPLCSF/$APPLOUT/UTF8_EMPTY.csv UTF8_EMPTY1.csv

echo "---------------------conversion des fichiers de sortie en UTF-8----------------------------+"

for convfile in `find $filename1`
do
echo Fichier trouvé : $convfile
#cat $convfile >> UTF8_EMPTY1.csv
iconv -f "windows-1252" -t "UTF-8" ${convfile} > ${convfile}.utf8

rm -f ${convfile}
touch ${convfile}
cp ${convfile}.utf8 ${convfile}
rm -f ${convfile}.utf8
done

#rm -f ${filename1}*

#touch ${filename1}.csv
#cp UTF8_EMPTY1.csv ${filename1}.csv
#rm -f UTF8_EMPTY1.csv
