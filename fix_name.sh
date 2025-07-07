# Le script serve a sistemare i nomi delle directory e dei files in archivio
# Prende come parametro una sequenza di nomi di archivio (i nomi delle directory al primo
# livello nel file di archivio) e per ciascuno:
# - verifica la conformità del nome dell'archivio, e se non conforme ne chiede uno conforme all'utente
# - elimina alcuni file notoriamente residui (lst.md5 e Picasa.ini)
# - verifica ricorsivamente nelle directory i nomi dei file e per ciascuno:
# -   se conforme lo lascia inalterato
# -   altrimenti
# -     se è riconosciuto come file WhatsApp lo ridenomina utilizzando la data contenuta nel nome del file,
#       000000 per l'ora di scatto, e una stringa composta da "WhatsApp" e parte del nome originario del file
# -     altrimenti lo ridenomina utilizzando la data contenuta nel nome dell'archivio, 000000 per l'ora di
#       scatto, la stringa EXTRA seguita dal nome del file originario
# La struttura a sottodirectory dell'archivio resta inalterata 

#!/bin/bash
set -e

function dateScatti {
  if ! [ -d "$1" ]; then 
    echo "Archivio $1 non trovato"
    exit 1
  fi
  exiftool -v -d %Y%m%d-%H%M%S%%-c.%%le "$1"/ | 
  grep " ModifyDate" | 
  tr -s ' ' | 
  cut -f 6 -d ' ' | 
  tr -d : | 
  sort | 
  uniq -c
}

if [ ! -d "$ARCHIVIO" ]; then
  echo "Error: Directory '$ARCHIVIO' not found."
  exit 1
fi

cd $ARCHIVIO

if [ $# -lt 1 ]
  then
    echo "Serve almeno un parametro, il nome della directory (es. '${0##*/} 20210604-PicnicMaranza')"
    exit 1
fi

# Scandisco gli archivi passati come parametro
for dir in "$@"
do
  if ! [ -d "$dir" ]; then 
    echo "Archivio $dir non trovato"
    continue
  fi
  echo "Elaboro l'archivio $dir"
# Se il nome della directory di archivio è non conforme
  if ! [[ "$dir" =~ $DIRREGEX ]]; then
# Fornisco le date degli scatti (utile suggerimento)
    echo "Calcolo le date degli scatti: attendi..."
    dateScatti "$dir"
# Attendo che venga comunicato un nome conforme
    while true
    do
      echo "Inserisci il nuovo nome (oppure ctrl-C)"
      echo -n "-> "
      read nuovonome
#     Esco se il bìnome è conforme
      [[ "$nuovonome" =~ $DIRREGEX ]] && break
      echo "Nome non conforme!"
    done 
    mv -n $ARCHIVIO/$dir $ARCHIVIO/$nuovonome
    dir=$nuovonome # Aggiorno la variabile dir, uasata dopo
    echo "Archivio ridenominato $dir"
  fi
  defaultdate=${BASH_REMATCH[1]}  # Salvo la data per usarla come default
  # Entra nella directory di Archivio
  cd $dir
  # Rimuove i vecchi md5
  if [ -f "md5.lst" ]; then rm -vf "md5.lst"; fi
  # Rimuove configurazione Picasa
  if [ -f "Picasa.ini" ]; then rm -vf "Picasa.ini"; fi
  # rinomina le foto ricorsivamente
  find . -type f -print0 | sort | 
  while IFS= read -r -d '' img
    do
      fn=$(basename "$img")
      dn=$(dirname "$img")
#      echo $img - $dn - $fn
      if ! [[ "$fn" =~ $IMGREGEX ]]; then
# Il nome del file non è conforme, e provo a trattarlo con exiftool     
        if ! exiftool -if 'defined $DateTimeOriginal' -d %Y%m%d-%H%M%S- -filename'<${DateTimeOriginal}${Model;}%-c.%e' "$img" > /dev/null
# se i campi EXIF non sono definiti
        then
#    ma si tratta di un file whatsapp, lo rinomino a partire dal nome del file
          if [[ "$fn" =~ $WAREGEX ]]; then
            newname="$dn/${BASH_REMATCH[2]}-000000-WhatsApp_${BASH_REMATCH[3]}"
            if diff -q "$img" "$newname"; then
                echo "File omonimi uguali: sostituisco"
                mv "$img" "$newname"
            else
                echo "File omonimi diversi: faccio un backup "              
                mv --backup=numbered "$img" "$newname"
            fi
          else
#    altrimenti creo un filename conforme con la data dell'archivio e il nome del file stesso, con un
#    ben riconoscibile nel filename (EXTRA)
            newname="$dn/$defaultdate-000000-EXTRA_$fn"
            if [ -f "$newname" ]; then
              if diff -q "$img" "$newname"; then
                echo "File omonimi uguali: sostituisco"
                mv "$img" "$newname"
              else
                echo "File omonimi diversi: faccio un backup "              
                mv --backup=numbered "$img" "$newname"
              fi
            fi
          fi
#     visualizzo l'operazione
          echo "$img -> $newname"
        fi
      else
# Se il filename è conforme 
        echo "$img conforme"
      fi
    done
# Ritorna all'archivio
  cd $ARCHIVIO
done    

echo -e "===\nEseguo il controllo con le stessa directory sul backup"
echo "Dovrebbero risultare solo file spurii, tipo md5.lst e Picasa.ini"
for dir in "$@"; do
  echo "=== Controllo $dir ==="
  jdupes -ru "$BACKUP/$dir" "$ARCHIVIO/$dir"
done
echo "Verifica che il risultato sia quello atteso: se l'archivio non ha backup ci saranno tutte"
echo "le nuove immagini solo nell'archivio di lavoro"

echo -e "===\nProcedo con il dry-run del backup (a capo per continuare CTRL-C per interrompere)"
echo -n ">"
read

echo $SRCDIR
$SRCDIR/backup.sh -ny

echo -e "\nProcedo con backup? (a capo per continuare CTRL-C per interrompere)"
echo -n ">"
read
$SRCDIR/backup.sh -y
