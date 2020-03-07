#!/usr/bin/env bash

if [ -z "$1" ];
then
	query='global';
	echo '(-h for help)';
elif [ "$1" = '-h' ];
then
	printf '\nUsage: ./covid.sh [query]\n\n';
	printf 'Examples:\n';
	echo './covid.sh USA    # retrieve latest USA covid stats';
	echo './covid.sh all    # retrieve all current covid stats';
	echo './covid.sh global # retrieve covid stats as a global sum';
	echo './covid.sh        # retrieve covid stats as a global sum';
	printf './covid.sh -h     # show this help message\n\n';
	exit;
else
	query="$1";
fi;

# get the data
data="$(
	curl 'https://www.worldometers.info/coronavirus/' \
		-H 'Accept: text/html,application/xhtml+xml,application/xml;q=0.9,image/webp,*/*;q=0.8' \
		-H 'Accept-Language: en-US,en;q=0.5' \
		-H 'Referer: https://www.google.com/' \
		-H 'Connection: keep-alive' \
		-H 'Upgrade-Insecure-Requests: 1' \
		-H 'Cache-Control: max-age=0' \
		-H 'TE: Trailers' \
		--compressed 2>/dev/null
)";

# parse the data
table="$(
	echo "$data" |
	grep -o '<table.*table>'
)";
thead="$(
	echo "$table" |
	grep -o '<thead.*thead>' |
	sed 's/th>\s*<th/th>\t<th/g; s/<br\s\/>//g; s/<[^>]*>//g; s/^\s*//; s/\t/ /g' |
	xargs printf '| %-20s'
)";
tbody="$(
	echo "$table" |
	grep -o '<tbody.*tbody>' |
	sed 's/<tr/\n<tr/g; s/td>\s*<td/td>\t<td/g; s/<[^>]*>//g; s/ //g; s/\t\t*/ /g'
)";

# format and display the data
if [ "$query" = 'global' ];
then
	echo "$data" |
	sed 's/<head.*head//g; s/<[^>]*>//g; s/^\s*//g; s/ \- Worldometer.*//g' |
	head -n 1
	exit;
elif [ "$query" = 'all' ];
then
	echo "$thead";
	while read line;
	do
		printf '| %-20s' $line;
		echo;
	done <<< "$tbody";
else
	result="$( grep "$query" <<< "$tbody" )";
	if [ ! -z "$result" ];
	then
		echo "$thead";
		printf '| %-20s' $result;
	fi;
fi;
