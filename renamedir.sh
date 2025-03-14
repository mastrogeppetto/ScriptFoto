#!/bin/bash

set -e

srcdir=$(dirname $0)

. $srcdir/config.sh
. $srcdir/functions.sh
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
		echocol 1 "$dir non trovato nell'archivio di lavoro!"
		echocol 1 "  Non trattato"
		continue
	fi
	if ! [ -d "$backup/$dir" ]
	then 
		echocol 2 "$dir non trovato nel backup!"
#		continue
	else
		if ! diff --recursive "$dir" "$backup/$dir"
		then
			echocol 2 "Le directory di lavoro e di backup sono diverse"
			echocol 2 "E' possibile rinominarle solo se sono uguali"
			continue
		else
			echo "Le directory di lavoro e di backup sono uguali"
		fi
	fi
	echo "Calcolo le date degli scatti: attendi..."
	dateScatti "$dir"
	while true
	do
		echocol 2 "Inserisci il nuovo nome (oppure ctrl-C)"
		echo -n "-> "
		read nuovonome
		checkdirname "$nuovonome" && break
		echo "Nome non conforme!"
	done
	echocol 2 "Rinomino come \"$nuovonome\""
	mv "$dir" "$nuovonome"
# Solo nel caso in cui esista anche il backup
	if [ -d "$backup/$dir" ]; then
  		mv "$backup/$dir" "$backup/$nuovonome"
	fi
done

close
