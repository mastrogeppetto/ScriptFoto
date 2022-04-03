#!/bin/bash

function checkdirname {
	function fail  {
		echo -e "\n### $d non è valido"
		echo "Il formato deve essere <data>-<titolo> (data = yyyymmdd)"
	}
	
	trattino=`echo "$1" | tr -dc '-'`
	data=`basename "$1" | cut -f1 -d-`
	titolo=`basename "$1" | cut -f2 -d-`

	# Errore separatori
	[ ${#trattino} -ne 1 ] && { fail; return 1; }
	# Formato data scorretto
	(( ${#data} != 8 )) && { fail; return 1; }
	#formato titolo scorretto
	[ -z "$titolo" ] && { fail; return 1; }

	return 0;

#	echo
#	echo Data: $data
#	echo Titolo: $titolo
}
#


function fast_md5() {
	(
		cd "$1"
		find . -type f ! -name "md5.lst" -exec sh -c 'echo -n $0 ";"; head --bytes=100K "$0" | md5sum' "{}" \; | sort
	)
}

function full_md5() {
	(
		cd "$1"
		find . -type f ! -name "md5.lst" -exec md5sum {} \; | sort
	)
}
