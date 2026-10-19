#! /bin/sh
# **************************************************************************
# FILE NAME :  DKA_XX_PARAM.sh
# PURPOSE   :  Utility for dka_parameters download 
#
# ARGUMENTS :  1 : Program code
#              2 : Apps password
# NOTES     : 
#
# HISTORY : 
# ver        date        author           description
# ---------  ----------  ---------------  ------------------------------------
# 1.0        28/01/2002  K.Helali         Created 
#******************************************************************************/
#set -x
if [ $# -ne 2 ]
then
  echo '\nSyntax : '$0' <set_name> <apps_password>'
  exit 1
fi
apps_pwd=$2
filename=$1.dtt
prefixe=`echo $filename | cut -c 1-4`
if [ "$prefixe" != "DKA_" ]
then
  filename="DKA_$filename"
fi

FNDLOAD apps/$apps_pwd 0 Y DOWNLOAD $DKA_TOP/admin/import/DKA_XX_TRANSCO.lct $filename DKA_STRANSCO_HEADERS SET_NAME=$1

echo '\n\n Check .log files'
echo  The name for the generated file is : $filename

