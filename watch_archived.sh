#!/bin/bash
# Questo script controlla i file che vengono spostati nella directory
# WATCH_DIR e modifica il loro gruppo come TARGET_GROUP
# Funzionamento:
# Ogni volta che viene chiuso in scrittura un file nella directory controllata,
# il comando inotifywait produce in stdout la sua directory: questa viene
# inserita in un array associativo, che associa un dato fittizio (1)
# alla directory, e viene avviata l'elaborazione dell'array. L'elaborazione è
# ritardata di INACTIVITY_TIMEOUT secondi, e se viene nel frattempo inserito
# un nuovo dato nell'array, l'elaborazione precedente viene interrotta e ne 
# viene avviata un'altra. C'è una piccola finestra temporale che causa
# l'interruzione di una chgrp/own, ma è abbastanza ridotta.
# L'elaborazione dell'array scandisce tutte le directory nell'array e, ad
# esclusione della radice WATCH_DIR, e modifica il gruppo della directory e
# di tutti i file in essa contenuti in TARGET_GROUP, con privilegi di lettura
# e scrittura per i membri del gruppo.
# L'evento "CLOSE_WRITE" è associato alla modifica di un file. Di questo file
# viene messo in output la directory dove risiede il file modificato.
# Lo script è abbastanza efficiente: in linea di massima dovrebbero essere
# modificate solo una volta le sottodirectory dell'Archivio in cui ci sono foto
# caricate. Esiste una finestra che può cancellare un chgrp. Si apre quando un
# nuovo evento viene generato esattamente quando viene eseguito il chgrp.
# Lo script e' stato scritto in collaborazione con ChatGPT. 

WATCH_DIR="/media/Foto/Archivio"
TARGET_GROUP="foto"
INACTIVITY_TIMEOUT=2
declare -A PATH_QUEUE
# PID of current sleep+process task
SCHEDULED_PID=""

log() {
    logger -t "watch-archived" "$1"
}

process_queue() {
    count=${#PATH_QUEUE[@]}
    log "Processing $count path(s) after inactivity."
    for path in "${!PATH_QUEUE[@]}"; do
	# Skip the top-level watched directory itself
    	if [ "$path" = "$WATCH_DIR" ]; then
            unset "PATH_QUEUE[$path]"
            continue
        fi
        # Forse più cauto dell'opportuno, ma se ci sono dei race è meglio
        if [ -e "$path" ]; then
            if [ -d "$path" ]; then
		log "Updating permissions on directory: $path"
                chgrp -R "$TARGET_GROUP" "$path"
                chmod -R g+rw "$path"
            fi
        else
            log "Skipped missing path: $path"
        fi
        unset "PATH_QUEUE[$path]"
    done
}

# Debounced schedule: cancel previous and start new one
schedule_processing() {
    if [ -n "$SCHEDULED_PID" ] && kill -0 "$SCHEDULED_PID" 2>/dev/null; then
        kill "$SCHEDULED_PID" 2>/dev/null
    fi
#    log "reschedule"
    (
        sleep "$INACTIVITY_TIMEOUT"
        process_queue
    ) &
    SCHEDULED_PID=$!
}

# Cleanup handler
cleanup() {
    if [ -n "$SCHEDULED_PID" ]; then
        kill "$SCHEDULED_PID" 2>/dev/null
    fi
    exit
}
trap cleanup EXIT

# Main watcher
inotifywait -m --recursive -e CLOSE_WRITE --format "%w" "$WATCH_DIR" | while read path; do
    PATH_QUEUE["$path"]=1
    schedule_processing
done



