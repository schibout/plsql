#
# script export donnees ORACLE R12
#

####################################################################
# 					Suivi des modifications
####################################################################
#
#    16/06/2021 Abdou : Rattrapage de Finance : Pour P2P
# 	 
# 	Extractions spéciale de la seule Table PO.RCV_TRANSACTIONS
#	
####################################################################


# repertoire contenant les fichiers dmp, log et tar.gz
#DATA_PUMP_DIR=/data/flf/files/DATAPUMP


# nom du fichier dum
DUMP_FILE_NAME=FIN01_$(date +%Y%m%d%H%M%S)_FINACHATSGLOBAL_001_$6_$1
# code retour
SHELL_RES=0

# extraction via l outil expdp
# parametre 1: date au format YYYYMMDD
# parametre 2: identifiant
# parametre 3: mot de passe
# parametre 4: nom de l instance
# parametre 5: nom de l objet repertoire
# parametre 6: date debut extraction YYYYMMDD

$ORACLE_HOME/bin/expdp USERID=$2/$3@$4 DIRECTORY=$5 LOGFILE=$DUMP_FILE_NAME.log DUMPFILE=$DUMP_FILE_NAME.dmp "TABLES= PO.RCV_TRANSACTIONS"
 QUERY=PO.RCV_TRANSACTIONS:\"WHERE LAST_UPDATE_DATE\>=TO_DATE\(\'$6\',\'YYYYMMDD\'\)\" EXCLUDE=GRANT,INDEX,TABLE_STATISTICS,INDEX_STATISTICS,COMMENT,CONSTRAINT,REF_CONSTRAINT,MARKER,TRIGGER,TABLE_EXPORT/TABLE/POST_TABLE_ACTION
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
	tar -czvf $DUMP_FILE_NAME.tar.gz $DUMP_FILE_NAME.dmp $DUMP_FILE_NAME.log 
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