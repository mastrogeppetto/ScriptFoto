#!/bin/bash
set -e

#archivio=Archivio
backup=/media/Backup/ArchivioFoto_backup/Archivio/
workdir=/media/Foto/Archivio

. functions.sh

cd $workdir
dirs=`find . -maxdepth 1 -mindepth 1 -type d ! -name Orfani | sort`

IFS=$'\n'
# Verifico che le directory nell'archivio siano anche presenti
# nel backup: Vengono visualizzate le directory che non sono presenti.
# Probabilmente è necessario eseguire il backup.
echo -e "\n# Passo 1: verifica sui filename."
echo "Queste directory master non sono hanno backup:"
n=0
for d in $dirs
do
	if ! [ -d "$backup"/"$d" ]
	then echo "[no-backup] $d"; let n=n+1;
	fi
done
echo "Fine verifica directory (passo 1): $n problemi"

# Verifico che le directory nel backup siano presenti anche
# nell'archivio di lavoro: vengono visualizzate le directory che 
# non sono presenti.
# Probabilmente la directory originaria è stata modificata e le
# stesse foto sono altrove
echo -e "\n# Passo 2: verifica sui filename."
echo "Queste directory sul backup non hanno master:"
n=0
for d in $dirs
do
	dir=`basename "$d"`
	if ! [ -d "$dir" ]
	then echo "[no-master] $dir"; let n=n+1;
	fi
done
echo "Fine verifica directory (Passo 2): $n problemi" 

# Verifico che il nome della directory segua lo schema richiesto
# E' sufficiente allineare il nome della directory dell'archivio e
# del backup allo standard (attenzione a dare lo stesso nome, pena
# duplicazione)
echo -e "\n# Passo 3: verifica del nome della directory."
echo "Queste directory hanno nome irregolare:"
n=0
for d in $dirs
do
	if ! checkdirname "$d" > /dev/null
	then echo "[bad-name]" \"$d\"; let n=n+1;
	fi
done
echo -e "Fine verifica nome directory: $n problemi"

echo
read -r -p "# Ricalcolo gli md5 dei file? " input
case $input in
    [sS][Iiì]|[sS])
	echo "Sì"
	for d in $dirs
	do
		echo "$d: ricalcolo l'md5, richiede tempo"
		fast_md5 "$d" > "$d"/md5.lst
		fast_md5 "$backup"/"$d" > "$backup"/"$d"/md5.lst
	done
	;;
    [nN][oO]|[nN])
	echo "No"
       ;;
    *)
	echo "Risposta non valida!"
	exit 1
	;;
esac


echo -e "\n# Passo 4a: presenza file duplicati (master)"
echo "Queste directory contengono file duplicati:"
n=0
for d in $dirs
do
	dup=`	cat "$d"/md5.lst | 
			cut -f 2 -d ";" |
			sort | 
			uniq -c | 
			tr -s ' ' | 
			grep  -v '^ 1 ' | 
			wc -l`
	if [[ $dup -gt 1 ]]
	then
		echo "[dup-master] $d ($dup)"
	fi
done

echo -e "\n# Passo 4b: presenza file duplicati (backup)"
echo "Queste directory contengono file duplicati:"
n=0
for d in $dirs
do
	dup=`	cat $backup/"$d"/md5.lst | 
			cut -f 2 -d ";" |
			sort | 
			uniq -c | 
			tr -s ' ' | 
			grep  -v '^ 1 ' | 
			wc -l`
	if [[ $dup -gt 1 ]]
	then
		echo "[dup-backup] $d ($dup)"
	fi
done

echo -e "\n# Passo 5a: Verifica sincronizzazione backup -> master"
echo "Queste directory di backup contengono file che non sono sul master"
n=0
for d in $dirs
do
	m=0
	for md5 in `cut -f2 -d";" "$backup"/"$d"/md5.lst | cut -c -32 `
	do
		if ! grep $md5 "$d"/md5.lst > /dev/null
		then
			let m=m+1
		fi
	done
	if [ $m -gt 0 ]
	then 
		echo "[backup-only] $d ($m)"
		let n=n+1
	fi
done
echo "Fine verifica sincronizzazione (passo 5a): $n problemi"


echo -e "\n###\nIMPORTANTE: eventuali problemi rilevati dopo il test precedente"
echo "possono essere recuperati rimuovendo il backup e eseguendo..."

echo -e "\n# Passo 5b: Verifica sincronizzazione master -> backup"
echo "Queste directory master contengono file che non sono backup"
n=0
for d in $dirs
do
	m=0
	for md5 in `cut -f2 -d";" "$d"/md5.lst | cut -c -32 `
	do
		if ! grep $md5 "$backup"/"$d"/md5.lst > /dev/null
		then
			let m=m+1
		fi
	done
	if [ $m -gt 0 ]
	then 
		echo "[master-only] $d ($m)"
		let n=n+1
	fi
done
echo "Fine verifica sincronizzazione (passo 5b): $n problemi"

# Calcola l'md5 per tutti gli archivi e verifica che quello del master
# e quello del backup contengano gli stessi digest. Per queste directory
# va controllato il contenuto.
echo -e "\n# Passo 6: verifica veloce del contenuto dei file."
echo "In queste directory il contenuto dei file è differente:"
n=0
for d in $dirs
do
	md5_m=`cut -f2 -d";" "$d"/md5.lst | cut -c -32 | sort | md5sum`
	md5_b=`cut -f2 -d";" "$backup"/"$d"/md5.lst | cut -c -32 | sort | md5sum`
	if [ $md5_m != $md5_b ]
	then 
#		cat "$master_md5"
#		echo
#		cat "$backup_md5"
#		echo "$md5_m  $md5_b"
		echo "[content-diff] $d"; let n=n+1;
	fi
done
echo "Fine verifica sincronizzazione (passo 6): $n problemi"

# Calcola l'md5 per tutti gli archivi e verifica che quello del master
# e quello del backup siano identici. Per queste directory andrebbe
# eseguito l'md5check per capire esattamente qualisiano le differenze
echo -e "\n# Passo 6: verifica veloce del contenuto dei file."
echo "In queste directory la denominazione dei file è diversa:"
n=0
for d in $dirs
do
	master_md5="$d"/md5.lst
	backup_md5="$backup"/"$d"/md5.lst
	md5_m=`cut -f2 -d";" "$master_md5" | cut -c -32 | sort | uniq | md5sum`
	md5_b=`cut -f2 -d";" "$backup_md5" | cut -c -32 | sort | uniq | md5sum`
#	fast_md5 "$d" > "$master_md5"
#	fast_md5 "$backup"/"$d" > "$backup_md5"
	if ! diff "$master_md5" "$backup_md5" > /dev/null
	then
#	if ! diff --recursive "$backup"/"$d" "$d" > /dev/null
		if [ $md5_m == $md5_b ]
		then 
			echo "[name-diff] $d"; let n=n+1;
		fi
	fi
done
echo "Fine verifica sincronizzazione (passo 6): $n problemi"


