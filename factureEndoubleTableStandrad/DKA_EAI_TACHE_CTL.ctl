#!/bin/ksh
##------------------------------------------------------------------------------------------
## $$
## Capgemini
## PROJET            : NEXT
## NOM               : DKA_IIWSSORB01_FITLRE.sh
## DESCRIPTION       : Script shell qui permet de filter le fichier AFB120
##- AUTEUR           : G. Vanackère
##- DATE CREATION    : 17/12/2008
##- DOC ASSOCIATED   :
## COMMENTAIRE       :
##------------------------------------------------------------------------------------------
##- HISTORIQUE DES MODIFICATIONS
##- Date       Qui Description
##- ---------- --- -------------------------------------------------------------------------
##- 18/09/2017 YWA artf2223169 : SPE081 - Filtre table CE_BANK_ACCOUNTS - Defect Beb #1071 
##- 12/03/2018 OBE artf2393439 : SPE081 - Filtre RB
##------------------------------------------------------------------------------------------  

#############
# VARIABLES #
#############
APPS_USR=APPS
APPS_PWD=$1
FICH_LOG_SHELL=$REP_DATA/log/AFB120.log
REP_TRV=$REP_DATA/in
fich_src=$REP_TRV/AFB120.txt

echo "SCRIPT DE FILTRE DU FICHIER AFB120 \n"
echo "SCRIPT DE FILTRE DU FICHIER AFB120 \n" > $FICH_LOG_SHELL

##################################
# CONTROLE PRESENCE DES FICHIERS #
##################################

# On vérifie que le fichier AFB120.txt existe dans le répertoire
if [ ! -s $fich_src ]
then
    echo "Aucun fichier AFB120 trouvé dans $REP_TRV !"
    echo "Aucun fichier AFB120 trouvé dans $REP_TRV !" >> $FICH_LOG_SHELL
    exit 20
fi
############################
# CONTROLE DU MOT DE PASSE #
############################
# Test de présence des paramètres de login pour la connexion BD
if [ $# -ne 1 ]
then
  echo '\nUsage : ' $0 ' <Motde passe APPS>'
  exit 20
fi

ret=`sqlplus -s $APPS_USR/$APPS_PWD <<END1
END1`

# Message d'erreur si connexion échouée
if [ -n "$ret" ]
then
  echo "Le mot de passe du user $APPS_USR est incorrect"
	echo "Le mot de passe du user $APPS_USR est incorrect" >> $FICH_LOG_SHELL
	exit 20
fi

############################
# FILTRE DU FICHIER AFB120 #
############################

# On se connecte à Oracle pour rechercher les comptes RB en rapprochement
echo "Connexion à Oracle pour constitution de la liste des comptes bancaires à traiter"
echo "Connexion à Oracle pour constitution de la liste des comptes bancaires à traiter" >> $FICH_LOG_SHELL
{
sqlplus -s $APPS_USR/$APPS_PWD <<ENDOFSQL
SET HEADING OFF;
SET FEEDBACK OFF;
SET LINESIZE 300;
SELECT banque, guichet, compte
FROM (select abb.bank_number banque,
             abb.branch_number guichet,
             abaa.bank_account_num compte,
             rbi.import_date date_dernier_import,
             row_number() over (partition by rbi.bank_account_id order by rbi.import_date desc) rn      
      from ce_bank_accounts abaa, -- ywa artf2223169
           ce_bank_branches_v abb,
           rb_bank_accounts_all rbaa,
           rb_batch_import rbi
      where rbaa.bank_account_id = abaa.bank_account_id -- ywa artf2223169
        and abb.branch_party_id = abaa.bank_branch_id -- ywa artf2223169
        and rbi.bank_account_id = rbaa.bank_account_id 
        and rbaa.status = 'Y'
     )
WHERE rn = 1
  AND date_dernier_import > add_months(sysdate, -2)
UNION
SELECT abb.bank_number banque,
       abb.branch_number guichet,
       abaa.bank_account_num compte
FROM ce_bank_accounts abaa,-- ywa artf2223169
     ce_bank_branches_v abb,
     rb_bank_accounts_all rbaa
WHERE rbaa.bank_account_id = abaa.bank_account_id -- ywa artf2223169
AND abb.branch_party_id = abaa.bank_branch_id -- ywa artf2223169
AND rbaa.status = 'Y'  
AND NOT EXISTS (select null from rb_batch_import rbi
                where rbi.bank_account_id = rbaa.bank_account_id
               );   
ENDOFSQL
} | while read ligne
do
  if [ "$ligne" ] # Ligne non NULL
  then 
      set $ligne
      banque="$1"
      guichet="$2"
      compte="$3"
      
      # Comptage du nombre de lignes du RIB en cours de traitement
      x=`grep -c ".*${banque}.*${guichet}EUR.*${compte}.*" $fich_src`
      if [ $x -ne 0 ]
      then           
          echo "Traitement du RIB $banque.$guichet.$compte : $x lignes trouvées" >> $FICH_LOG_SHELL    
      else
          echo "Traitement du RIB $banque.$guichet.$compte : aucune ligne trouvée" >> $FICH_LOG_SHELL
      fi
      # On créé un fichier tmp ne contenant que les lignes concernant le compte bancaire en cours
      #sed '/'"$banque"'.*'"$guichet"'EUR.*'"$compte"'/ !d' < $fich_src > $REP_TRV/${banque}.${guichet}.${compte}.tmp
      sed '/'"$banque"'.*'"$guichet"'EUR.*'"$compte"'/ !d' < $fich_src > $REP_TRV/fichier.tmp
      sed -n '/^01/,/^07/p' < $REP_TRV/fichier.tmp > $REP_TRV/${banque}.${guichet}.${compte}.tmp
      rm $REP_TRV/fichier.tmp
  fi    
done

# On concatène tous les fichiers filtrés pour remplacer le fichier AFB120.txt
cat $REP_TRV/*.tmp > $fich_src

# Suppression du fichier temporaire
rm $REP_TRV/*.tmp

##########
# SORTIE #
##########
echo "Consulter le fichier $FICH_LOG_SHELL pour plus d'informations"
echo "Filtre terminé" >> $FICH_LOG_SHELL
exit 0


