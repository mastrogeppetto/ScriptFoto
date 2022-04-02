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

echo -en "\nDry run? (y/N)"
read
if [ ! -z $REPLY ] && [ $REPLY == "y" ]
then
	echo -e "\nProvo solo il backup, senza eseguirlo"
	DRYOPT="--dry-run"
else
	echo -e "\nOK, le operazioni verranno effettivamente eseguite"
fi

backup="$mountpoint/ArchivioFoto_backup"

# Controlla che la posizione sia corretta
p=`dirname "$PWD"`
if [ "$p" != "/media/Foto/Archivio" ]
then 
	echo -e "\n### Fail\nDevi essere in una directory dell'archivio delle foto"
	exit
fi

data=`basename $PWD | cut -f1 -d-`
titolo=`basename $PWD | cut -f2 -d-`

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

target="$backup"/Archivio/`basename $PWD`

# Regolarizzo i nomi sul master
exiftool -d %Y%m%d-%H%M%S%%-c.%%le "-filename<DateTimeOriginal" .
exiftool '-filename<%f-${model;}.%e' .

if [ -d "$target" ]
then 
	echo -e "\nATTENZIONE"
	echo "La directory esiste già: controllare che non ci siano foto duplicate!"
	echo -e "\nPremi un tasto per proseguire"
	read
	( 
		cd "$target"
		# Regolarizz i nomi sul backup
		exiftool -d %Y%m%d-%H%M%S%%-c.%%le "-filename<DateTimeOriginal" .
		exiftool '-filename<%f-${model;}.%e' .
	)
fi

rsync -auv $DRYOPT . "$target"

#rsync -auv $DRYOPT /Foto/ArchivioFoto/ --exclude-from=excludeFile.txt "$backup" |
#  tee /Foto/ArchivioFoto/$RSYNCLOG

#echo -e "Fatto.\nOra cerco le foto solo sul backup (da rimuovere o riportare in archivio)"
#rsync -auv --dry-run "$backup" /Foto/ArchivioFoto/ | grep -v "/$" > backup_only.txt
#echo "Ci sono" `wc -l backup_only.txt` "foto solo sul backup"
#echo "L'elenco è in backup_only.txt"

#sudo umount $MOUNTPOINT
