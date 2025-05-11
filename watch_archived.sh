#!/bin/bash
# Questo script controlla i file che vengono spostati nella directory
# WATCH_DIR e modifica il loro gruppo come TARGET_GROUP
# Funzionamento:
# Il comando inotifywait è inserito in un loop: ogni volta che viene
# catturato un evento interessante, la directory dove è accaduto viene
# inserito in un array associativo, che associa un dato fittizio (1)
# alla directory. Quando il flusso di eventi si arresta per più di
# INACTIVITY_TIMEOUT secondi, il comando inotifywait termina con un output
# diverso da zero, e questo innesca l'esecuzione della funzione
# "process_queue". Questa scandisce tutte le directory per cui è presente
# una voce nell'array associativo, ad esclusione della radice WATCH_DIR, e
# modifica il gruppo della directory e di tutti i file in essa contenuti in
# TARGET_GROUP, con privilegi di lettura e scrittura per i membri del gruppo.
# L'evento "CLOSE_WRITE" è associato alla modifica di un file. Di questo file
# viene messo in output la directory dove risiede il file modificato.
# Lo script è abbastanza efficiente: in linea di massima dovrebbero essere
# modificate solo una volta le sottodirectory dell'Archivio in cui ci sono foto
# caricate. E' stato scritto in collaborazione con ChatGPT. 

WATCH_DIR="/media/Foto/Archivio"
TARGET_GROUP="foto"

INACTIVITY_TIMEOUT=2
declare -A PATH_QUEUE

process_queue() {
    for path in "${!PATH_QUEUE[@]}"; do
	# Skip the top-level watched directory itself
    	if [ "$path" = "$WATCH_DIR" ]; then
            unset "PATH_QUEUE[$path]"
            continue
        fi
        # Forse più cauto dell'opportuno, ma se ci sono dei race è meglio
        if [ -e "$path" ]; then
            if [ -d "$path" ]; then
                chgrp -R "$TARGET_GROUP" "$path"
                chmod -R g+rw "$path"
            fi
        fi
        unset "PATH_QUEUE[$path]"
    done
}

# Debounced loop: waits for N seconds of inactivity
while true; do
    output=$(inotifywait --recursive --timeout "$INACTIVITY_TIMEOUT" -e CLOSE_WRITE --format "%w" "$WATCH_DIR" 2>/dev/null)
    status=$?

    if [ "$status" -eq 0 ]; then
        # Got an event
        PATH_QUEUE["$output"]=1
    else
        # Timeout occurred (inactivity)
        if (( ${#PATH_QUEUE[@]} > 0 )); then
            process_queue
        fi
    fi
done



