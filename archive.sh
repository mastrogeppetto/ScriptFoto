#!/bin/bash
set -e

cleanup() {
    local final_exit_code=$? # Capture the exit status of the last command before cleanup
    if [[ "$SCRIPT_EXIT_CODE" -ne 0 ]]; then
        final_exit_code="$SCRIPT_EXIT_CODE"
    fi
    if [[ -f "$TEMP_FILE" ]]; then
        rm -rf "$TEMP_FILE"
    fi
    exit $final_exit_code
}

trap cleanup EXIT INT TERM

dn=$(basename $(pwd))

if ! [[ "$dn" =~ $DIRREGEX ]]; then
  echo -e "\e[91mERRORE\e[0m: Il nome di questa directory non è conforme"
  echo -e "  Dovrebbe essere YYYYMMDD-titolo"
  echo -e "  Questo comando funziona solo in una directory di archivio"
  echo -e "  correttamente denominata"
  echo -e "\e[93mCorreggi e riprova\e[0m"
  exit 1
fi

TEMP_FILE=$(mktemp)
# Controllo creazione del file
if [[ $? -ne 0 ]]; then
    echo "Error: Failed to create a temporary file." >&2
    exit 1
fi

num=0
ok=0
exif=0
wa=0
extra=0
find . -type f -print0 | while IFS= read -r -d '' fn; do
  img=$(basename $fn)
  if [[ "$img" =~ $IMGREGEX ]];then
    echo -e "$num\t$fn\tnome conforme"
    ((++ok))
  else
    if exiftool -if 'defined $DateTimeOriginal' "$fn" &>/dev/null; then
      echo -e "$num\t$fn\tEXIF presente"
      ((++exif))
    else 
      if [[ "$img" =~ $WAREGEX ]]; then
        echo -e "$num\t$fn\tWhatsApp senza EXIF"
        ((++wa))
      else
        echo -e "$num\t$fn\tFile non riconosciuto"
        ((++extra))
      fi   
    fi
  fi
  ((++num))
  echo "# $num $ok $exif $wa $extra"
done > $TEMP_FILE

#cat $TEMP_FILE
tabs -3
echo -e "\e[1;47;94m"
echo -e "Nella directory ci sono $(tail -1 $TEMP_FILE | cut -f2 -d" " ) file"
echo -e "$(tail -1 $TEMP_FILE | cut -f3 -d" " )\t immagini con nome conforme:"
echo -e "\t non verranno trattate"
echo -e "$(tail -1 $TEMP_FILE | cut -f4 -d" " )\t immagine con nome non conforme ma informazioni EXIF:"
echo -e "\t verranno ridenominate"
echo -e "$(tail -1 $TEMP_FILE | cut -f5 -d" " )\t immagine con nome non conforme da WhatsApp senza EXIF:"
echo -e "\t verranno ridenominate"
echo -e "\e[38;5;208m$(tail -1 $TEMP_FILE | cut -f6 -d" " )\t che non sembrano immagini:"
grep "File non riconosciuto" $TEMP_FILE | 
  tr "\n" "\0" | 
  cut -f2 -z |
  xargs -0 -I {} basename {} |
  xargs -I {} echo -e "\t - {}"
  
#perl -pe 's/\x00/\n/g'
echo -e "\t sarebbe meglio rimuoverli, altrimenti verranno ridenominati come EXTRA"
echo -e "\t con la data nel nome della directory\e[0m"

echo -e "Ora sto per aggiornare l'archivio delle foto con la nuova directory"
echo -e "Procedo o preferisci ritoccarla? (CTRL-C per interrompere)"
echo -n ">"
read

if [ -d "$ARCHIVIO/$dn" ]; then
  echo -e "\e[31mATTENZIONE\e[0m: esiste già in archivio una directory con lo stesso nome"
  echo -e "  Se prosegui quella directory verrà aggiornata con i contenuti"
  echo -e "   di questa, aggiungendo e sostituendo file: è questo quello che vuoi?"
  echo -e "Se sì dai a capo, altrimenti CTRL-C per interrompere"
  echo -n ">"
  read
fi

echo rsync

rsync -av . "$ARCHIVIO/$dn"

$SRCDIR/fix_name.sh $dn

Echo 

