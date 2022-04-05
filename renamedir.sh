#!/bin/bash

. config.sh
. functions.sh
init

function dateScatti {
	exiftool -v -d %Y%m%d-%H%M%S%%-c.%%le "$1"/ | 
	grep " ModifyDate" | 
	tr -s ' ' | 
	cut -f 6 -d ' ' | 
	tr -d : | 
	sort | 
	uniq -c
}

#archivio="/media/Foto/Archivio"
#backup="/media/Backup/ArchivioFoto_backup/Archivio"
cd $workdir

for dir in "$@"
do
	if checkdirname "$dir"
	then
		echo "$dir: nome directory corretta"
	fi
	if ! [ -d "$dir" ]
	then 
		echocol 2 "$dir  non trovato nell'archivio di lavoro!"
		continue
	fi
	if ! [ -d "$backup/$dir" ]
	then 
		echocol 1 "$dir  non trovato nel backup!"
		continue
	fi
	if ! diff --recursive "$dir" "$backup/$dir"
	then
		echocol 1 "Le directory di lavoro e di backup sono diverse"
		echo "E' possibile rinominarle solo se sono uguali"
		continue
	else
		echo "Le directory di lavoro e di backup sono uguali"
	fi
	echo "Date degli scatti:"
	dateScatti "$dir"
	while true
	do
		echocol 2 "Inserisci il nuovo nome (oppure ctrl-C)"
		echo -n "-> "
		read nuovonome
		checkdirname "$nuovonome" && break
		echo "Nome non conforme!"
	done
	echocol 2 "Rinomino le directory come \"$nuovonome\""
	mv "$dir" "$nuovonome"
	mv "$backup/$dir" "$backup/$nuovonome"

	echocol 2 "Normalizzo i nomi delle foto"
	( cd "$archivio/$nuovonome"; fix_filename )
	( cd "$backup/$nuovonome"; fix_filename )
done

close
