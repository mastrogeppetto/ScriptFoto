#!/bin/bash
set -e

# Controlla il formato della directory e dei file contenuti
# Il formato richiesto per le directory è YYYYMMDD-<titolo>, dove titolo è una stringa senza
# spazi e lineette (-)
# Il formato richiesto per i file è YYYYMMDD-HHMMSS-<apparecchio>, dove apparecchio indica 
# la macchina fotografica o dispositivo con cui è stata scattata la foto.
# Il formato di uscita indica prima il tipo di irregolarità: "[bad-dirname]" oppure "[bad-filename]"
# Nel primo caso dopo una tabulazione segue il nome della directory
# Nel secondo segue il nome della directory che contiene il file e poi il nome del file, separati
# da tabulazione

fast=''

TEMP_FILE=$(mktemp)
# Controllo creazione del file
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create a temporary file." >&2
    exit 1
fi
#echo $TEMP_FILE
if [ ! -d "$ARCHIVIO" ]; then
  echo "Error: Directory '$ARCHIVIO' not found."
  exit 1
fi

find $ARCHIVIO -mindepth 1 > $TEMP_FILE

while IFS= read -r line || [[ -n "$line" ]]; do
    relative="${line#$ARCHIVIO/}"
#    echo "Processing line: '$relative'"
# Controlla se è una directory/archivio
    if [[ "$relative" =~ ^[^/]*$ ]]; then
# Stampa statistiche archivio precedente
      if [[ $n -gt 0 ]]; then
        echo -e "[bad-filenames]\tin\t$archive:\t$n"
      fi
      archive=$relative
      n=0
      if ! [[ "$relative" =~ $DIRREGEX ]] && [[ -d $line ]]; then
        echo -e "[bad-dirname]:\t$relative"
      fi
# Altrimenti è una immagine
    else
      imgname=`basename "$relative"`
      if ! [[ "$imgname" =~ $IMGREGEX ]] && ! [[ -d $line ]];then
        if ! [[ "$imgname" =~ $NOCHECK ]]; then
          n=$(($n + 1))
#          echo -e "[bad-filename]-$archive: \t$imgname ($n)"
        fi
      fi
    fi
done < "$TEMP_FILE"

rm "$TEMP_FILE"



