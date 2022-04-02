#!/bin/bash
# Programma per il backup - ottobre 2018 - riveduto gennaio 2021



HDUUID="e8a972e4-422a-4a1a-8f40-dcfaeaf4c4db"   # uuid dell'HD (Trekstor)
# BACKUPUUID="" # uuid del filesystem di backup
# FILENAME="BACKUP"
MOUNTPOINT="/media/Backup"
EXCLUDEFILE="exclude_from_backup"
RSYNCLOG=backup-`date +"%Y%m%d:%H%M%S"`.log
DRYOPT=""

trap ctrl_c INT
function ctrl_c() {
        echo -e "\n** Ricevuto CTRL-C"
#        sudo umount $MOUNTPOINT
        exit 0
}

echo -n "Controllo che l'hard disk sia montato... "
if ! lsblk -o UUID | grep --silent $HDUUID
then
	echo -e "Fail\nHard disk non montato: per favore controlla e riparti"
	exit
fi
echo "Ok"

# Calcolo il mountpoint dell'HD
mountpoint=`lsblk -o UUID,MOUNTPOINT | grep $HDUUID | cut -f2- -d' '`

#echo "Controllo l'integrità del filesystem di backup... "
#if ! sudo e2fsck -f "$mountpoint"
#then
#	echo -e "\n*** Problemi al filesytem di backup: controlla e ripara!"
#	exit
#fi
#echo "Ok"


workdir=/media/Foto/Archivio

if [ $# -lt 1 ]
  then
    echo "Serve almeno un parametro, il nome della directory (es. '${0##*/} 20210604-PicnicMaranza')"
    exit 1
fi


for dir in "$@"
do
	
	if [ ! -d $workdir/$dir  ]
	then
		echo "Non esiste la directory $workdir/$dir"
		exit 1
	fi
	
	data=`echo $dir | cut -f1 -d-`
	titolo=`echo $dir | cut -f2 -d-`
	
	if (( ${#data} != 8 )) #formato data scorretto
	then 
		echo -e "\n### Fail\nIl nome della directory non è valido"
		echo "Il formato deve essere <data>-<titolo> (data = yyyymmdd)"
		exit
	fi
	if [ -z $titolo ] #formato titolo scorretto
	then 
		echo -e "\n### Fail\nIl nome della directory non è valido"
		echo "Il formato deve essere <data>_<titolo> (data = yyyymmdd)"
		exit
	fi
	
	echo
	echo Data: $data
	echo Titolo: $titolo
	
	cd $workdir/$dir
	
	echo -e "\nProcedo? (a capo per continuare CTRL-C per interrompere)"
	echo -n ">"
	read
	
	backup="$mountpoint/ArchivioFoto_backup"
	target="$backup"/Archivio/$dir
	
	# Regolarizzo i nomi sul master
	exiftool -q -q -d %Y%m%d-%H%M%S%%-c.%%le "-filename<DateTimeOriginal" .
	exiftool -q -q '-filename<%f-${model;}.%e' .
	
	if [ -d "$target" ]
	then 
		echo -e "\nATTENZIONE"
		echo "La directory esiste già: controllare che non ci siano foto duplicate!"
		echo -e "\nPremi un tasto per proseguire"
		read
		( 
			cd "$target"
			# Regolarizzo i nomi sul backup (-q -q serve a eliminare warning)
			exiftool -q -q -d %Y%m%d-%H%M%S%%-c.%%le "-filename<DateTimeOriginal" .
			exiftool -q -q '-filename<%f-${model;}.%e' .
		)
	fi
	
	rsync -auv . "$target"

done

#rsync -auv $DRYOPT /Foto/ArchivioFoto/ --exclude-from=excludeFile.txt "$backup" |
#  tee /Foto/ArchivioFoto/$RSYNCLOG

#echo -e "Fatto.\nOra cerco le foto solo sul backup (da rimuovere o riportare in archivio)"
#rsync -auv --dry-run "$backup" /Foto/ArchivioFoto/ | grep -v "/$" > backup_only.txt
#echo "Ci sono" `wc -l backup_only.txt` "foto solo sul backup"
#echo "L'elenco è in backup_only.txt"

#sudo umount $MOUNTPOINT
