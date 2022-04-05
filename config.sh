# In caso di errore esce
set -e
# Mountpoint di backup
backup_mnt=/media/Backup
# Directory di backup
backup=$backup_mnt/ArchivioFoto_backup/Archivio/
workdir_mnt=/media/Foto
# Directory con l'archivio di lavoro
workdir=$workdir_mnt/Archivio

#HDUUID="e8a972e4-422a-4a1a-8f40-dcfaeaf4c4db"   # uuid dell'HD (Trekstor)
# BACKUPUUID="" # uuid del filesystem di backup
# FILENAME="BACKUP"
#MOUNTPOINT="/media/Backup"
#EXCLUDEFILE="exclude_from_backup"
#RSYNCLOG=backup-`date +"%Y%m%d:%H%M%S"`.log
#DRYOPT=""
