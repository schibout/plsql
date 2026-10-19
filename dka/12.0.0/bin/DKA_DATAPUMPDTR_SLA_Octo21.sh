#
# script export donnees ORACLE R12
#

####################################################################
# 					Suivi des modifications
####################################################################
#
# 20/10/2020 : Récupération des données de SLA #XLA.XLA_DISTRIBUTION_LINKS,
#XLA.XLA_AE_LINES,
#XLA.XLA_AE_HEADERS 	
#
####################################################################


# repertoire contenant les fichiers dmp, log et tar.gz
#DATA_PUMP_DIR=/data/flf/files/DATAPUMP


# nom du fichier dum
DUMP_FILE_NAME=FIN01_$(date +%Y%m%d%H%M%S)_FINACHATSLA_001_$6_$1
# code retour
SHELL_RES=0

# extraction via l outil expdp
# parametre 1: date au format YYYYMMDD
# parametre 2: identifiant
# parametre 3: mot de passe
# parametre 4: nom de l instance
# parametre 5: nom de l objet repertoire
# parametre 6: date debut extraction YYYYMMDD

$ORACLE_HOME/bin/expdp USERID=$2/$3@$4 DIRECTORY=$5 LOGFILE=$DUMP_FILE_NAME.log DUMPFILE=$DUMP_FILE_NAME.dmp "TABLES=XLA.XLA_DISTRIBUTION_LINKS,XLA.XLA_AE_LINES,XLA.XLA_AE_HEADERS EXCLUDE=GRANT,INDEX,TABLE_STATISTICS,INDEX_STATISTICS,COMMENT,CONSTRAINT,REF_CONSTRAINT,MARKER,TRIGGER,TABLE_EXPORT/TABLE/POST_TABLE_ACTION"
if [ $? -ne 0 ]
then
   SHELL_RES=20
fi
# archivage et compression des fichiers generes
if [ -e $DATA_PUMP_DIR/$DUMP_FILE_NAME.dmp -o -e $DATA_PUMP_DIR/$DUMP_FILE_NAME.log ]
then
	echo "GOTO dump directory"
	cd $DATA_PUMP_DIR
	if [ $? -ne 0 ]
	then
	   SHELL_RES=20
	fi
	
	echo "Archiving and compressiong the dump and log files : " $DUMP_FILE_NAME.dmp " and " $DUMP_FILE_NAME.log
	tar -cEzvf $DUMP_FILE_NAME.tar.gz $DUMP_FILE_NAME.dmp $DUMP_FILE_NAME.log 
	if [ $? -ne 0 ]
	then
	   SHELL_RES=20
	fi
	
	echo "Removing files (only keep tar.gz)" 
	rm -f $DUMP_FILE_NAME.dmp $DUMP_FILE_NAME.log 
	if [ $? -ne 0 ]
	then
	   SHELL_RES=20
	fi	
fi

if [ $SHELL_RES -eq 0 ] 
then
	echo "Operation successful - file created : " $DUMP_FILE_NAME.tar.gz
else
	echo "Operation failed"
fi

exit $SHELL_RES
