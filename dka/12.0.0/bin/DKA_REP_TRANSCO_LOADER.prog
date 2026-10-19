# !/bin/ksh
#------------------------------------------------------------------------------------------
#- $ $
#- CAP GEMINI
#- PROJET           : Hélios
#- NOM              : DKA_REP_TRANSCO_LOADER.prog
#- DESCRIPTION      : Script d'execution de DKA_REP_TRANSCO_LOADER
#-
#- AUTEUR           : Capgemini
#- DATE DE CREATION : 10/03/2017
#- DOC. ASSOCIEE    :
#- NOTES            : 
#- PARAMETRES       : 0 : Script appelant 				 (Param OA)
#					          : 1 : User Name						     (Param OA)
#					          : 2 : Login							       (Param OA)
#					          : 3 : User ID						       (Param OA)
#					          : 4 : Request ID					     (Param OA)
#					          : 5 : Nom du fichier a charger [Obligatoire]
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------
#  10/03/2017 MEG Création
#------------------------------------------------------------------------------------------

export FCP_LOGIN=$1
export PSWD=${FCP_LOGIN##*/}
export FCP_REQID=$4

#Recuperation des arguments du shell        
SH_FILE=${REP_DATA_IN}/$5
export SH_FILE

#Fichier de compte rendu du traitement
LV_OUTPUT_FILE=`sqlplus -s $FCP_LOGIN <<EOF
                set termout off
                set feedback off
                set pagesize 0
                SELECT r.outfile_name
                FROM fnd_concurrent_programs_vl pt,
                     fnd_concurrent_programs pb,
                     fnd_concurrent_requests r
                WHERE pb.application_id = r.program_application_id
                  AND pb.concurrent_program_id = r.concurrent_program_id
                  AND pb.application_id = pt.application_id
                  AND pb.concurrent_program_id = pt.concurrent_program_id
                  AND r.request_id = $FCP_REQID;
                exit
                EOF`
export LV_OUTPUT_FILE

#Debut du traitement
echo "============================================================================"
echo "DKA : Chargement des tables de transcodifications pour la reprise de données"
echo "Lancement du traitement :" `date +%T` 
echo "Request_id :" $FCP_REQID  
echo "============================================================================"
echo "Liste des arguments soumis :"
echo "Nom du fichier a charger ----> " $SH_FILE
echo "============================================================================"
echo " "
echo "Declenchement du script DKA_REP_TRANSCO_SQLLOADER"

echo "============================================================================" >> $LV_OUTPUT_FILE
echo "DKA : Chargement des tables de transcodifications pour la reprise de données" >> $LV_OUTPUT_FILE
echo "Lancement du traitement :" `date +%T`                                         >> $LV_OUTPUT_FILE
echo "Request_id :" $FCP_REQID                                                      >> $LV_OUTPUT_FILE
echo "============================================================================" >> $LV_OUTPUT_FILE
echo "Liste des arguments soumis :"                                                 >> $LV_OUTPUT_FILE
echo "Nom du fichier a charger ----> " $SH_FILE                                     >> $LV_OUTPUT_FILE
echo "============================================================================" >> $LV_OUTPUT_FILE

#Suppression des fichiers de log et fichiers bad
if [ -f $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.bad ]; then
     rm $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.bad
fi

if [ -f $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.log ]; then
     rm $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.log
fi

#Lancement du script permettant le sqlloader
ksh $DKA_TOP/bin/DKA_REP_TRANSCO_SQLLOADER.sh $PSWD "$SH_FILE"
retcode=`echo $?`

cat $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.log

if [ $retcode -ne 0 ] && [ $retcode -ne 2 ] || [ -f $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.bad ]; then

  #Fichier est rejete => un fichier bad peut etre genere
  echo " "
  echo "Le fichier $SH_FILE n est pas valide !!!"
  echo " "                                                      >> $LV_OUTPUT_FILE
  echo "Le fichier $SH_FILE n est pas valide !!!"               >> $LV_OUTPUT_FILE
  echo " "                                                      >> $LV_OUTPUT_FILE
  if [ -f $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.bad ]; then
      echo "Les lignes non valides sont les suivantes :"    >> $LV_OUTPUT_FILE
      cat $DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.bad        >> $LV_OUTPUT_FILE
  fi
  
  retcode=4

else
  #Fichier est OK
  echo " "                                      >> $LV_OUTPUT_FILE
  echo "Le fichier $SH_FILE est valide"         >> $LV_OUTPUT_FILE
  echo " "                                      
  echo "Le fichier $SH_FILE est valide"
  echo " "                                      >> $LV_OUTPUT_FILE
  echo " "                                      

fi 

echo "###############################################"
echo "Fin du traitement: CODE RETOUR: " $retcode

case $retcode in
    '0') exit 0
           ;;
    '20') exit 2
           ;;
    '4') exit 2
           ;;
    *)   exit 2
           ;;
esac
exit $retcode

