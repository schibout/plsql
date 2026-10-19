#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI ERNST AND YOUNG
#- PROJET           : DALKIA Oracle Applications Helios
#- NOM              : DKA_IGLHYPERIONDR_JOB.sh
#- DESCRIPTION      : Script d'execution de IGLHYPERIONDR
#-
#- AUTEUR           : Maxime EGOT (CAPGEMINI)
#- DATE DE CREATION : 24/07/2002
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#- 27/01/2020 SELO DGE20190021 Gestion des comptes en quantité
#------------------------------------------------------------------------------------------



#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 1 ] && [ $# -ne 2 ] 
then
  echo "\nSyntaxe : $0 <apps_password> <Periode>"
  echo "\nSyntaxe : avec <apps_password> obligatoire"
  echo "\nSyntaxe : et <Periode> optionnel"
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
echo "LANCEMENT DE IHYPERION"


if [ x$1 != x ] && [ x$2 != x ]
 then
sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IGLHYPERIONDR.sql \
	"'EXPLOITATION'" \
	"'TOUT_GL_OPE_ADMINISTRATEUR'" \
  "'OPERATIONNEL'" \
  $2
else
sqlplus -s $apps_usr/$1 \
	@$DKA_TOP/sql/DKA_IGLHYPERIONDR.sql \
	"'EXPLOITATION'" \
	"'TOUT_GL_OPE_ADMINISTRATEUR'" \
  "'OPERATIONNEL'" \
  "'A'"
fi



  


#############################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
#############################################################################################
# 0 : SUCCESS
# 1 : FAILURE
# 2 : WARNING



case $? in
    '0') code=0
           ;;
    '1') code=1
           ;;
    '2') code=2
           ;;
    *)   code=20
           ;;
esac




res=$(echo "@$DKA_TOP/admin/sql/DKA_IGLHYPERIONDR_REP.sql exit" | sqlplus "apps/$1" |grep "Resultat= " |cut -f2 -d' ')
echo "Recuperation du chemin des fichiers de donnees"
echo $res
cd $res

Fichier_total=`ls -rt $res/FIN01_SRC_DR*  | tail -1`
echo $Fichier_total
Fichier_qte=`ls -rt $res/FIN01_SRC_QTE*  | tail -1`
echo $Fichier_qte
filename1=`basename $Fichier_total`
filename2=`basename $Fichier_qte`

sqlplus -s $apps_usr/$1 @$DKA_TOP/sql/DKA_CONCATENAT_FILE.sql $filename1 $filename2

#cat $Fichier_qte>>$Fichier_total


#############################################################################################
# CONTROLE ET TRANSMISSION AU SCHEDULER DU CODE RETOUR DE LA COMMANDE SQL
#############################################################################################
# 0 : SUCCESS
# 1 : FAILURE
# 2 : WARNING


case $code in
    '0') exit 0
           ;;
    '1') exit 20
           ;;
    '2') exit 4
           ;;
    20)   exit 20
           ;;
esac
