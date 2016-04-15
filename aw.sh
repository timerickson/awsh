#!/bin/bash

#http://docs.aws.amazon.com/general/latest/gr/sigv4_signing.html

function rawurlencode {
  #http://stackoverflow.com/questions/296536/how-to-urlencode-data-for-curl-command
  local string="${1}"
  local strlen=${#string}
  local encoded=""
  local pos c o

  for (( pos=0 ; pos<strlen ; pos++ )); do
     c=${string:$pos:1}
     case "$c" in
        [-_.~a-zA-Z0-9] ) o="${c}" ;;
        * )               printf -v o '%%%02x' "'$c"
     esac
     encoded+="${o}"
  done
  echo "${encoded}"    # You can either set a return variable (FASTER) 
  REPLY="${encoded}"   #+or echo the result (EASIER)... or both... :p
}

function canonicalize_uri {
  local encoded=""
  IFS='/'
  read -ra CHUNKS <<< "$1"z
  IFS=
  local i=0
  for chunk in "${CHUNKS[@]}"; do
    if [ "$chunk" == "" ]
    then
      if [ "$i" -ne 0 ]
      then
        encoded="${encoded}/$( rawurlencode $chunk )"
      fi
    else
      encoded="${encoded}/$( rawurlencode $chunk )"
    fi
    ((i++))
  done
  encoded=${encoded:0:${#encoded}-1}
  if [ "$encoded" == "" ]
  then
    encoded="/"
  fi
  echo $encoded
}

http_request_method=$1
uri=$2
query_string=$3
headers=$4
signed_headers=$5
hexed_hashed_request_payload=$6

signed_headers="" #this should be populated by canonicalize_headers call below

canonical_uri=$(canonicalize_uri "$uri")
canonical_query_string=$(canonicalize_query_string "$query_string")
canonical_headers=$(canonicalize_headers "$headers")

canonical_request="$http_request_method"$'\n'"$canonical_uri"$'\n'"$canonical_query_string"$'\n'"$canonical_headers"$'\n'"$signed_headers"$'\n'"$hexed_hashed_request_payload"

echo $canonical_request
