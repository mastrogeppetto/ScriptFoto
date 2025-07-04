#!/bin/bash
# Programma per il backup - nuova versione 2025
set -e

# Mountpoint del filesystem dei backup
BACKUP_MNT=/media/Backup
# Directory di backup
BACKUP_DIR=$BACKUP_MNT/ArchivioFoto
# Muontpoint del filesystem delle foto
ARCHIVIO_MNT=/media/Foto
# Directory con l'archivio delle foto
ARCHIVIO_DIR=$ARCHIVIO_MNT

# Gestione delle opzioni
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

# Controllo esistenza directory
if [ ! -d "$BACKUP_DIR"  ]
then
  echo "Non esiste la directory delle foto $BACKUP_DIR"
  exit 1
else
  echo "Il backup è in $BACKUP_DIR"
fi

if [ ! -d "$ARCHIVIO_DIR"  ]
then
  echo "Non esiste la directory delle foto $ARCHIVIO_DIR"
  exit 1
else
  echo "Le foto sono nella directory $ARCHIVIO_DIR"
fi

if [[ $dryrun ]]
then
  echo "Ti ricordo che hai richiesto un dry run, nessun file verrà alterato"
fi

echo -e "\nProcedo? (a capo per continuare CTRL-C per interrompere)"
echo -n ">"
read

#echo -n "Conteggio delle difformità (attendi pazientemente): "
#./checkname.sh | wc -l

diffdir="$BACKUP_MNT"/ArchivioFoto_diff/"$(date +%Y%m%d-%H%M%S)"
rsync -av $dryrun \
  --update \
  --delete \
  --info=stats2 \
  --backup-dir="$diffdir" \
  --include='Archivio/***' \
  --exclude='*' \
  "$ARCHIVIO_DIR"/ "$BACKUP_DIR"/

exit 1
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
	cd "$workdir"/"$dir"
	echo -e "\nProcedo? (a capo per continuare CTRL-C per interrompere)"
	echo -n ">"
	read
	# Costruzione del nome della directory di backup
	backup="$backup_mnt"/ArchivioFoto_backup
	diffdir="$backup_mnt"/ArchivioFoto_diff/Archivio/"$dir"_"$(date +%Y%m%d-%H%M%S)"
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
