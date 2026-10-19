#!/bin/sh
########################################################################
# $Id$
# Capgemini
# Projet           : Dalkia
# Nom              : Execution_lettrage.sh
# Description      : Script Execution_lettrage
# Auteur           : Julien Jardez
# Date de création : 09/03/2012
# Doc. associée    :
# Notes            : 
# Paramètres       : 1 : Mot de passe Oracle du user APPS
#
# Historique
# Date       Qui Description
# ---------- --- -------------------------------------------------------
# 
########################################################################

########################################################################
# Déclaration des variables
########################################################################
APPS_USR=APPS
logfile=lettrage_$2.log
if [ $# -ne 2 ]
then
   echo "\nSyntaxe : $0 <APPS_PASSWORD> <ANNEE (YY)>" | tee -a $logfile
   exit 1
fi
# Contrôles des passwords
ret=`sqlplus -s $APPS_USR/$1 <<__END1__
__END1__`
if [ -n "$ret" ]
then
   echo Mot de passe incorrect pour le user $APPS_USR | tee -a $logfile
   exit 1
fi

########################################################################
# Exécution du script
########################################################################
echo "\nExécution du script" | tee -a $logfile
echo "PERIODE JAN-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql JAN-$2 | tee -a $logfile
echo "PERIODE FEV-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql FEV-$2 | tee -a $logfile
echo "PERIODE MAR-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql MAR-$2 | tee -a $logfile
echo "PERIODE AVR-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql AVR-$2 | tee -a $logfile
echo "PERIODE MAI-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql MAI-$2 | tee -a $logfile
echo "PERIODE JUN-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql JUN-$2 | tee -a $logfile
echo "PERIODE JUL-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql JUL-$2 | tee -a $logfile
echo "PERIODE AOU-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql AOU-$2 | tee -a $logfile
echo "PERIODE SEP-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql SEP-$2 | tee -a $logfile
echo "PERIODE OCT-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql OCT-$2 | tee -a $logfile
echo "PERIODE NOV-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql NOV-$2 | tee -a $logfile
echo "PERIODE DEC-$2" | tee -a $logfile
sqlplus $APPS_USR/$1 @$DKA_TOP/admin/sql/DKA_APUREMENT_PASSE_POST_CUTOFF.sql DEC-$2 | tee -a $logfile

# SORTIE
echo "\nConsulter le fichier $logfile pour plus d'informations" | tee -a $logfile
exit 0
