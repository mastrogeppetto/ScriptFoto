#!/bin/bash

function checkdirname {
	data=`basename "$1" | cut -f1 -d-`
	titolo=`basename "$1" | cut -f2 -d-`

	if (( ${#data} != 8 )) #formato data scorretto
	then 
        echo -e "\n### $d non è valido"
        echo "Il formato deve essere <data>-<titolo> (data = yyyymmdd)"
        return 1
	fi
	if [ -z "$titolo" ] #formato titolo scorretto
	then 
        echo -e "\n### Fail\nIl nome della directory non è valido"
        echo "Il formato deve essere <data>_<titolo> (data = yyyymmdd)"
        return 1
	fi
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
