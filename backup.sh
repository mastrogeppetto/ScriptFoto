#!/bin/bash
# Programma per il backup - ottobre 2018 - riveduto gennaio 2021
set -e

if ! command -v tree 2>&1 >/dev/null
then
    echo "E' necessario installare il comando tree con \"sudo apt install tree\""
    exit 1
fi

srcdir=$(dirname $0)

. $srcdir/config.sh
. $srcdir/functions.sh

init

dryrun=""
while getopts "nb:" opt; do
  case $opt in
    n)
      echo "Opzione -n: dry-run, verifico senza eseguire"
      dryrun="--dry-run"
      ;;
    b)
# Non usato, ma utile se servisse
      echo "Opzione -b specificata con valore: $OPTARG"
      ;;
    *)
      echo "Opzione non valida"
      ;;
  esac
done
shift $((OPTIND-1))

# Si arresta se non ci sono parametri
if [ $# -lt 1 ]
  then
    echo "Serve almeno un parametro, il nome della directory (es. '${0##*/} 20210604-PicnicMaranza')"
    exit 1
fi

echo $@

# Loop su tutte le directory passate come parametro
for dir in "$@"
do
	# Controllo esistenza directory
	if [ ! -d "$workdir/$dir"  ]
	then
		echo "Non esiste la directory $workdir/$dir"
		continue
	fi
	# Verifica che il nome della directory sia lecito (yyyymmdd-titolo)
        # altrimenti passa al successivo
	if ! checkdirname "$dir"
	then
		continue
	fi
	# Visualizza i dati generati da checkdirname
	echo
	echo Data: "$data"
	echo Titolo: "$titolo"
	# Entra nella directory di cui fare backup e chiede conferma
	cd $workdir/$dir
	echo -e "\nProcedo? (a capo per continuare CTRL-C per interrompere)"
	echo -n ">"
	read
	# Costruzione del nome della directory di backup
	backup="$backup_mnt/ArchivioFoto_backup"
	diffdir="$backup_mnt/ArchivioFoto_diff/Archivio/$dir_$(date +%Y%m%d-%H%M%S)"
	target="$backup"/Archivio/$dir
	# Normalizzazione dei nomi di file
        echo "Normalizzo i nomi dei file (anche nelle sottodirectory)"
	export -f fix_filename
	find . -type d -exec bash -c 'fix_filename "{}"' \;
	# Verifica che la directory sia piatta
	if checkSubdirectory "$workdir/$dir"
	then
		echo "Ci sono sotto-cartelle con questa struttura:"
		tree -d "$workdir/$dir"
		read -r -p "Vuoi che appiattisca le cartelle? [y/N] " response
		if [[ "$response" =~ ^([yY][eE][sS]|[yY])$ ]]
		then
        		flattendir "$workdir/$dir"
        	fi
	fi
	# Controlla se la directory di backup esiste, ma offre la possibilità
        # di continuare
        # (prima verranno normalizzati i nomi nella directory di backup)
	if [ -d "$target" ]
	then 
		echo -e "\nATTENZIONE"
		echo "La directory esiste già: controllare che non ci siano foto duplicate!"
		echo -e "\nPremi un tasto per proseguire"
		read
                # Normalizza i nomi nella directory di backup
#		( 
#			cd "$target"
#			fix_filename
#		)
	fi
        # Comando di backup
	rsync -av $dryrun --update --delete --info=stats2 --backup-dir=$diffdir . "$target"
done

close

#rsync -auv $DRYOPT /Foto/ArchivioFoto/ --exclude-from=excludeFile.txt "$backup" |
#  tee /Foto/ArchivioFoto/$RSYNCLOG

#echo -e "Fatto.\nOra cerco le foto solo sul backup (da rimuovere o riportare in archivio)"
#rsync -auv --dry-run "$backup" /Foto/ArchivioFoto/ | grep -v "/$" > backup_only.txt
#echo "Ci sono" `wc -l backup_only.txt` "foto solo sul backup"
#echo "L'elenco è in backup_only.txt"

#sudo umount $MOUNTPOINT
