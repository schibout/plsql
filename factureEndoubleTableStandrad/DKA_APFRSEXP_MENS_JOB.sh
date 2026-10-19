# !/bin/ksh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI
#- PROJET           : Hélios
#- NOM              : DKA_SLAUNCHER.sh
#- DESCRIPTION      : Script d'execution de DKA_SLAUNCHER
#-
#- AUTEUR           : Capgemini
#- DATE DE CREATION : 16/09/2016
#- DOC. ASSOCIEE    :
#- NOTES            : A exécuter depuis le répertoire install sous le compte UNIX appdxxx
#- PARAMETRES       : 0 : Script appelant 				(Param OA)
#					: 1 : User Name						(Param OA)
#					: 2 : Login							(Param OA)
#					: 3 : User ID						(Param OA)
#					: 4 : Request ID					(Param OA)
#					: 5 : Nom du shell script			[Obligatoire]
#-                  : 6 : Parametre 1 du script appele	[Facultatif]
#-                  : 7 : Parametre 2 du script appele	[Facultatif]
#-                  : 8 : Parametre 3 du script appele	[Facultatif]
#-                  : 9 : Parametre 4 du script appele	[Facultatif]
#-                  : 10: Parametre 5 du script appele	[Facultatif]
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  20/01/2017 OBE Modification : artf2085298
#------------------------------------------------------------------------------------------
#  10/02/2017 OBE Modification : artf2098714
#------------------------------------------------------------------------------------------



export FCP_LOGIN=$1
#echo "Login " $FCP_LOGIN   

#echo "Fin parametres OA"

export PSWD=${FCP_LOGIN##*/}
#echo "Password " $PSWD 

export FCP_REQID=$4
echo "Request_id " $FCP_REQID  


#--------------------------------------------------------------------------
# function_ExitWarning ()
#--------------------------------------------------------------------------
function_ExitWarning(){

echo " "
echo "========================================================================="
echo "Résultat du traitement : Avertissement                                   "
echo "========================================================================="
echo " " 

# Mise à jour du statut de fin ("WARNING") du traitement
sqlplus -s <<-QUIT 
    $FCP_LOGIN

    SET FEEDBACK OFF
    SET HEADING OFF

    update fnd_concurrent_requests
           set phase_code = 'C',
               status_code = 'G',
               completion_text = 'Fin Anormale',
               actual_completion_date = SYSDATE
         where request_id = $FCP_REQID
         ;
     
    commit;
     
QUIT

exit 1

}

#on va recuperer maintenant les arguments du shell        

SH_SCRIPT=$5
SH_PAR1=$6 
SH_PAR2=$7 
SH_PAR3=$8 
SH_PAR4=$9 
SH_PAR5=${10}

export SH_SCRIPT 
export SH_PAR1 
export SH_PAR2 
export SH_PAR3 
export SH_PAR4 
export SH_PAR5

echo "Liste des arguments soumis :"
echo "Shell script ----> " $SH_SCRIPT
echo "Param1 ----------> " $SH_PAR1
echo "Param2 ----------> " $SH_PAR2
echo "Param3 ----------> " $SH_PAR3
echo "Param4 ----------> " $SH_PAR4
echo "Param5 ----------> " $SH_PAR5

echo "Déclenchement du traitement " $SH_SCRIPT

if [ -n "$SH_PAR5" ]
#Tous les parametres
then
	echo "########## Lancement du Shell avec 5 parametres"
	echo "###############################################"
	ksh $DKA_TOP/bin/$SH_SCRIPT $PSWD "$SH_PAR1" "$SH_PAR2" "$SH_PAR3" "$SH_PAR4" "$SH_PAR5"
	retcode=`echo $?`
elif [ -n "$SH_PAR4" ]
then
#4 parametres
	echo "########## Lancement du Shell avec 4 parametres"
	echo "###############################################"
	ksh $DKA_TOP/bin/$SH_SCRIPT $PSWD "$SH_PAR1" "$SH_PAR2" "$SH_PAR3" "$SH_PAR4"
	retcode=`echo $?`
elif [ -n "$SH_PAR3" ]
then
#3 parametres
	echo "########## Lancement du Shell avec 3 parametres"
	echo "###############################################"
	ksh $DKA_TOP/bin/$SH_SCRIPT $PSWD "$SH_PAR1" "$SH_PAR2" "$SH_PAR3"
	retcode=`echo $?`
elif [ -n "$SH_PAR2" ]
#2 parametres
then
	echo "########## Lancement du Shell avec 2 parametres"
	echo "###############################################"
	ksh $DKA_TOP/bin/$SH_SCRIPT $PSWD "$SH_PAR1" "$SH_PAR2"
	retcode=`echo $?`
elif [ -n "$SH_PAR1" ]
then
#1 parametre
	echo "########## Lancement du Shell avec 1 parametre"
	echo "###############################################"
	ksh $DKA_TOP/bin/$SH_SCRIPT $PSWD "$SH_PAR1"
	retcode=`echo $?`
else
#0 parametre
	echo "########## Lancement du Shell sans parametre"
	echo "###############################################"
	ksh $DKA_TOP/bin/$SH_SCRIPT $PSWD 
	retcode=`echo $?`
fi

echo "###############################################"
echo "Fin du traitement: CODE RETOUR: " $retcode

case $retcode in
    '0') exit 0
           ;;
    '20') exit 2
           ;;
    '4') function_ExitWarning
           ;;
    *)   exit 2
           ;;
esac
exit $retcode

