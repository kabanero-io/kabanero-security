#!/bin/bash
TOKEN=$1
if [ -z "$TOKEN" ]
then
    echo "Usage: logout.sh <token>"
    echo "    <token> : The string 'missing' will omit the Authorization header from the request. The string 'empty' will set the Authorization header to have a Bearer token that is an empty string."
    exit 1
fi

if [[ "$TOKEN" == "missing" ]]
then
    HEADER=""
elif [[ "$TOKEN" == "empty" ]]
then
    HEADER="Authorization: Bearer "
else
    HEADER="Authorization: Bearer $TOKEN"
fi
echo "Set header: [$HEADER]"

curl -k -v -X POST -H "Accept: application/json" -H "$HEADER" http://localhost:9080/kabasec/logout
