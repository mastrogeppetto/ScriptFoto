#!/bin/bash
# Programma per il backup - nuova versione 2025
set -e

# Gestione delle opzioni
dryrun=""
while getopts "nyb:" opt; do
  case $opt in
    n)
      echo "Opzione -n: dry-run, verifico senza eseguire"
      dryrun="--dry-run"
      ;;
    y)
      echo "Opzione -y: non chiede conferme"
      noack="yes"
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
fi

if [ ! -d "$ARCHIVIO_DIR"  ]
then
  echo "Non esiste la directory delle foto $ARCHIVIO_DIR"
  exit 1
fi


if ! [[ $noack ]]; then
  if [[ $dryrun ]]
  then
    echo "Ti ricordo che hai richiesto un dry run, nessun file verrà alterato"
  fi
  echo -e "\nProcedo? (a capo per continuare CTRL-C per interrompere)"
  echo -n ">"
  read
fi

#echo -n "Conteggio delle difformità (attendi pazientemente): "
#./checkname.sh | wc -l
diffdir="$BACKUP_MNT"/ArchivioFoto_diff/"$(date +%Y%m%d-%H%M%S)"

echo -e "\e[2m"
rsync -av $dryrun \
  --update \
  --delete \
  --info=stats2 \
  --backup-dir="$diffdir" \
  --include='Archivio/***' \
  --exclude='*' \
  "$ARCHIVIO_DIR"/ "$BACKUP_DIR"/
echo -e "\e[0m"

exit 0
