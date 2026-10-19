#!/bin/ksh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_SARREFAC_ETAT_BOR.sh
#- DESCRIPTION      : Script de création du bordereau
#-
#- AUTEUR           : Capgemini
#- DATE DE CREATION : 30/05/2006
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire bin sous le compte UNIX appdxxx
#- PARAMETRES       : 
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 27/09/2016 JJA Portage HELIOS R12 
#------------------------------------------------------------------------------------------
typeset nb_pages=0
typeset nb_total_pages=0
typeset nb_lignes=0
typeset nb_total_lignes=0
typeset nom_fichier
typeset mon_repertoire=$REP_DATA/editions_legales/DKA_SARREFAC
typeset la_date
typeset code_bande=$1

#############################################################################################
# fonction de comptage du nombre de pages du fichier courant
#############################################################################################
function compte_pages
{
    nb_pages=`grep '          Page' $nom_fichier | wc -l`
    # let nb_pages=nb_pages+1
    let nb_total_pages=nb_total_pages+nb_pages
}

#############################################################################################
# fonction de comptage du nombre de lignes du fichier courant
#############################################################################################
function compte_lignes
{
    nb_lignes=`wc -l $nom_fichier`
    echo $nb_lignes|awk -F' "'\
         '{for (k=1;k<=NF;k++)\
         printf("%s\n",substr($k,1,length($k)))}'>\
         "$mon_repertoire/param."$$

    j=1
    while read lig
    do 
        case $j in
        1)
          nb_lignes=$lig
          let nb_total_lignes=nb_total_lignes+nb_lignes
        ;;
        *)
        ;;
        esac
        let j=j+1
    done < $mon_repertoire/param.$$
  
    rm $mon_repertoire/param.$$
}

#############################################################################################
# Boucle de lecture du repertoire
#############################################################################################
if test -f $mon_repertoire/REFAC_*.out 
then
    for i in `ls $mon_repertoire/REFAC_*.out`
    do
        nom_fichier=$i
        compte_pages
        compte_lignes
    done
fi

#############################################################################################
# Generation du fichier bordereau.txt
#############################################################################################
la_date=`date +"20%y%m%d%H%M"`
echo "C" $la_date $nb_total_pages $nb_total_lignes $code_bande > $mon_repertoire/bordereau.tmp
awk '{ printf("%s%12s%08d%017d%-6s",$1 ,$2, $3, $4, substr($5, 1, 6)) }' $mon_repertoire/bordereau.tmp > $mon_repertoire/REFAC.bor
rm $mon_repertoire/bordereau.tmp
more $mon_repertoire/REFAC.bor
