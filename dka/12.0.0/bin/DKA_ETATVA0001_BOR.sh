#!/bin/ksh
#------------------------------------------------------------------------------------------
#- $ $
#- Capgemini
#- PROJET           : DALKIA Oracle Applications
#- NOM              : DKA_ETATVA0001_BOR.sh
#- DESCRIPTION      : Script de création du bordereau
#-
#- AUTEUR           : Capgemini
#- DATE DE CREATION : 16/05/2004
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire bin sous le compte UNIX appdxxx
#- PARAMETRES       : 
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 10/11/2016 YWA Migration R12
#------------------------------------------------------------------------------------------
typeset nb_pages=0
typeset nb_total_pages=0
typeset nb_lignes=0
typeset nb_total_lignes=0
typeset nom_fichier
typeset mon_repertoire=$REP_DATA/editions_legales/DKA_ETATVA0001
typeset la_date
typeset code_bande=$1
typeset chaine

#############################################################################################
# fonction de comptage du nombre de pages du fichier courant
#############################################################################################
function compte_pages
{ 
    echo $chaine $nom_fichier
    nb_pages=`grep "$chaine" $nom_fichier | wc -l`
    let nb_total_pages=nb_total_pages+nb_pages
}

#############################################################################################
# fonction de comptage du nombre de lignes du fichier courant
#############################################################################################
function compte_lignes
{
    #nb_lignes=`wc -l $nom_fichier`
	nb_lignes=`wc -l < $nom_fichier`
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
		  let nb_total_lignes+=nb_lignes
          #let nb_total_lignes=nb_total_lignes+nb_lignes
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
if test -f $mon_repertoire/DKA_*.out 
then
    for i in `ls $mon_repertoire/DKA_GL_DECLAR_TVA_0001*.out`
    do
        nom_fichier=$i
        chaine='Page :'
        compte_pages
        let nb_total_pages=nb_total_pages+1
        compte_lignes
    done

    for i in `ls $mon_repertoire/DKA_AR_JUST_TVA_ENC_0001*.out`
    do
        nom_fichier=$i
        chaine="PAGE :  "
        compte_pages
        compte_lignes
    done

    for i in `ls $mon_repertoire/DKA_RAPJUSTTVADEC_0001*.out`
    do
        nom_fichier=$i
        chaine="          Page "
        compte_pages
        compte_lignes
    done

    for i in `ls $mon_repertoire/DKA_RJETVADEDUC_0001*.out`
    do
        nom_fichier=$i
        chaine="capitulatif de la TVA D"
        compte_pages
        compte_lignes
    done

    for i in `ls $mon_repertoire/DKA_JEFRTXDC_*0001*.out`
    do
        nom_fichier=$i
        chaine="          Page : "
        compte_pages
        compte_lignes
    done

    for i in `ls $mon_repertoire/DKA_ARXCOA2_0001*.out`
    do
        nom_fichier=$i
        chaine="          Page : "
        compte_pages
        let nb_total_pages=nb_total_pages+1
        compte_lignes
    done

    for i in `ls $mon_repertoire/DKA_TVACOLLECTEE_0001*.out`
    do
        nom_fichier=$i
        chaine="          Page: "
        compte_pages
        let nb_total_pages=nb_total_pages+1
        compte_lignes
    done

fi

#############################################################################################
# Generation du fichier bordereau.txt
#############################################################################################
la_date=`date +"20%y%m%d%H%M"`
echo "C" $la_date $nb_total_pages $nb_total_lignes $code_bande > $mon_repertoire/bordereau.tmp
awk '{ printf("%s%12s%08d%017d%-6s",$1 ,$2, $3, $4, substr($5, 1, 6)) }' $mon_repertoire/bordereau.tmp > $mon_repertoire/DKA_ETATVA0001.bor
rm $mon_repertoire/bordereau.tmp
more $mon_repertoire/DKA_ETATVA0001.bor
