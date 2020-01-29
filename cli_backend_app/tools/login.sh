#!/bin/bash
USER=$1
PAT=$2

if [ -z "$USER" ] || [ -z "$PAT" ]
then
    echo "Usage: login.sh <gituser> <gitpat>"
    echo "    <gituser> : The string 'missing' will omit the gituser parameter from the request body. The string 'empty' will set the parameter to an empty string."
    echo "    <gitpat>  : The string 'missing' will omit the gitpat parameter from the request body. The string 'empty' will set the parameter to an empty string."
    exit 1
fi

if [[ "$USER" == "missing" ]]
then
    USER=""
elif [[ "$USER" == "empty" ]]
then
    USER='"gituser":""'
else
    USER='"gituser":"'"$1"'"'
fi
echo "Set user: [$USER]"

if [[ "$PAT" == "missing" ]]
then
    PAT=""
elif [[ "$PAT" == "empty" ]]
then
    PAT='"gitpat":""'
else
    PAT='"gitpat":"'"$2"'"'
fi
echo "Set PAT: [$PAT]"


if [ -z "$PAT" ]
then
    BODY="{$USER}"
elif [ -z "$USER" ]
then
    BODY="{$PAT}"
else
    BODY="{$USER,$PAT}"
fi

echo "Set body: [$BODY]"

curl -k -v -H "Content-Type: application/json" -H "Accept: application/json" -d $BODY http://localhost:9080/kabasec/login
