#!/bin/bash
# Programma per il backup - ottobre 2018 - riveduto gennaio 2021

. config.sh
. functions.sh
init

list=""
for d in $dirs
do
	if ! [ -d "$backup"/"$d" ]
	then list="$list $d"
	fi
done

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
		continue
	fi
	if ! checkdirname "$dir"
	then
		continue
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
	
	fix_filename
	
	if [ -d "$target" ]
	then 
		echo -e "\nATTENZIONE"
		echo "La directory esiste già: controllare che non ci siano foto duplicate!"
		echo -e "\nPremi un tasto per proseguire"
		read
		( 
			cd "$target"
			fix_filename
		)
	fi
	rsync -auv . "$target"
done

close

#rsync -auv $DRYOPT /Foto/ArchivioFoto/ --exclude-from=excludeFile.txt "$backup" |
#  tee /Foto/ArchivioFoto/$RSYNCLOG

#echo -e "Fatto.\nOra cerco le foto solo sul backup (da rimuovere o riportare in archivio)"
#rsync -auv --dry-run "$backup" /Foto/ArchivioFoto/ | grep -v "/$" > backup_only.txt
#echo "Ci sono" `wc -l backup_only.txt` "foto solo sul backup"
#echo "L'elenco è in backup_only.txt"

#sudo umount $MOUNTPOINT
