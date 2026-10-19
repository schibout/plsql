#! /bin/sh
#************************************************************************
# PROGRAM : DKA_REP_TRANSCO_SQLLOADER.sh                                *
# Version : 1.0                                                         *
# AUTEUR  : Julien Jardez / SOCIETE : CAPGEMINI                         *
# DATE    : 15/04/2016                                                  *
#************************************************************************
# APPELE PAR :                                                          *
# FONCTION   :                                                          *
#                                                                       *
#                                                                       *
#************************************************************************
# HISTORIQUE                                                            *
# Version   Date      Auteur        NumAno - Commentaires               *
# 1.0                 JJA                                               *
# 1.1     10/03/17    MEG                                               *
#########################################################################

apps_usr=APPS
apps_pwd=$1
data_file=$2

###############################
# Contrôle des parametres
###############################
if [ $# -ne 2 ]
then
  echo "\nSyntaxe : $0 <APPS_PASSWORD> <DATA_FILE>"
  exit 1
fi

# Contrôle des passwords

ret=`sqlplus -s $apps_usr/$apps_pwd <<__END1__
__END1__`

if [ -n "$ret" ]
then
  echo Mot de passe incorrect pour le user $apps_usr
  exit 1
fi

###############################
# Lancement du SQLLOADER
###############################
echo "\nLancement du SQLLOADER"
sqlldr  SILENT=FEEDBACK,HEADER \
        USERID=$apps_usr/$apps_pwd \
        CONTROL=$DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.ctl \
        DATA=$data_file \
        LOG=$DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.log \
        BAD=$DKA_TOP/bin/DKA_REP_TRANSCO_LINES_CTL.bad 

##################################
# Exit
##################################

echo "\nPlease read logfile for more informations"
exit 0
