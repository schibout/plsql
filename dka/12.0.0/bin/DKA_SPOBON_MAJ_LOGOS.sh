#!/bin/sh
#------------------------------------------------------------------------------------------
#- $ $
#- PROJET           : DALKIA 
#- NOM              : DKA_SPOBON_MAJ_LOGOS.sh
#- DESCRIPTION      : SEL artf07348911 : INC0391309 - Déplacement des logos vers un nouveau repertoire.
#-
#- AUTEUR           : Samir EL OUAHABI (CAPGEMINI)
#- DATE DE CREATION : 06/02/2020
#- PARAMETRES       : 1 : Mot de passe Oracle du user APPS
#-
#- HISTORIQUE DES MODIFICATIONS
#- Date       Qui Description
#- ---------- --- -------------------------------------------------------------------------




#############################################################################################
# Contrôle des paramètres
#############################################################################################
if [ $# -ne 1 ]
then
  echo "\nSyntaxe : $0 <apps_password>"
  exit 20
fi

#############################################################################################
# DECLARATION DES VARIABLES
#############################################################################################
apps_usr=APPS
apps_pwd=$1

########################################################################
# Création des répertoires 
########################################################################
# on test si le répertoire $REP_DATA/media 
if [ ! -d $REP_DATA/media ]
then
  echo "Le chemin $REP_DATA/media n'existe pas !" | tee -a $logfile
  echo "Création du chemin..." | tee -a $logfile
  
  mkdir $REP_DATA/media
fi


# Deplacement de tous les logos qui sont dans le repertoire $DKA_TOP/media dans le nouveau repertoire $REP_DATA
if [ -e $DKA_TOP/media/* ]
then
  mv $DKA_TOP/media/* $REP_DATA/media
fi

chemin=$REP_DATA/media
echo $chemin

`sqlplus -s $apps_usr/$apps_pwd << _EOF_
set echo off
set feed off
set head off
set termout off
set linesize 200
set pagesize 0
set newpage 0


update hr_organization_units
  set attribute20 = '$chemin/' || substr(attribute20,instr(attribute20,'/',-1)+1,length(attribute20))
where attribute20 is not null;

commit;
_EOF_`


