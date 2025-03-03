#!/bin/bash

function echocol {
# indenta un echo del numero di caratteri nel primo parametro
	tput setaf $1
	echo "$2"
	tput sgr0
}

function checkSubdirectory {
# Verifica se ci sono sottocartelle da gestire
	ls $1/*/ >/dev/null 2>&1
}

# Al momento non viene utilizzato, da testare
function flattendir {
	# Step 1: Controlla nomi duplicati e in caso termina con errore
	if find "$1" -mindepth 2 -type f -printf "%f\n" | sort | uniq -d | grep .; then
		echo "Questi file sono presenti in più directories. Operazione interrotta, directory intatta"
    		exit 1
	fi
	# Step 2: Spostamento dei file nella directory principale
	find "$1" -mindepth 2 -type f -exec mv {} "$1"/ \;
	# Step 3: Rimozioni delle directory vuote
	find "$1" -mindepth 1 -type d -empty -delete
}

function checkdirname {
	function fail  {
		echo -e "\n### $1 non è un nome valido"
		echo "Il formato deve essere <data>-<titolo> (data = yyyymmdd)"
	}
	
	trattino=`echo "$1" | tr -dc '-'`
	data=`basename "$1" | cut -f1 -d-`
	titolo=`basename "$1" | cut -f2 -d-`

	# Errore separatori
	[ ${#trattino} -ne 1 ] && { fail $1; return 1; }
	# Formato data scorretto
	(( ${#data} != 8 )) && { fail $1; return 1; }
	#formato titolo scorretto
	[ -z "$titolo" ] && { fail $1; return 1; }

	return 0;

#	echo
#	echo Data: $data
#	echo Titolo: $titolo
}
#

function fast_md5() {
	(
		cd "$1"
		find . -type f ! -name "md5.lst" -exec sh -c 'echo -n $0 ";"; head --bytes=100K "$0" | md5sum' "{}" \; | sort
	)
}

function fix_filename() {
# Regolarizza i nomi dei file backup (-q -q serve a eliminare warning)
	exiftool -q -q -d %Y%m%d-%H%M%S%%-c.%%le "-filename<DateTimeOriginal" .
	exiftool -q -q '-filename<%f-${model;}.%e' .
}

function full_md5() {
	(
		cd "$1"
		find . -type f ! -name "md5.lst" -exec md5sum {} \; | sort
	)
}

function init() {
	if [ -z "$workdir_mnt" ]
	then
		echo "Non configurata la variabile con il filesystem di lavoro"
		exit 1
	fi
        echo "Il filesystem di lavoro è $workdir_mnt"
	if mountpoint -q "$workdir_mnt"
	then
		echo "Il filesystem di lavoro è già montato"
	else
		echo "Monto il filesystem di lavoro"
		if ! sudo mount "$workdir_mnt"
		then
			echo "Non riesco ad installare il filesystem di lavoro"
			exit 1
		fi
	fi
	
        if [ -z "$backup_mnt" ]
	then
		echo "Non configurata la variabile con il filesystem di backup"
		exit 1
	fi    
        echo "Il filesystem di backup è $backup_mnt"
	if mountpoint -q "$backup_mnt"
	then
		echo "Il filesystem di backup è già montato"
	else
		echo "Monto il filesystem di backup"
		if ! sudo mount "$backup_mnt"
		then
			echo "Non riesco ad installare il filesystem di backup"
			exit 1
		fi
	fi
	trap ctrl_c INT
}	

function ctrl_c() { 
	echo -e "\n** Ricevuto CTRL-C"; 
	close;
	exit 0
} 
	
function close() {
	if mountpoint -q $backup_mnt
	then
		echo -e "\nSmonto la directory di backup"
		sync
		sudo umount $backup_mnt
	fi
}
