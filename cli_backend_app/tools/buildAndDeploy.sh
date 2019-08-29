#!/bin/bash
OL_INSTALL=$1
SERVER_NAME=$2
DEFAULT_SERVER_NAME="kabasec-server"

if [ -z $OL_INSTALL ]
then
    echo "Usage: buildAndDeploy.sh <ol-installation-path> [desired-server-name]"
    echo "    ol-installation-path : Full or relative path to the root directory of a built Open Liberty installation (e.g. /Users/adam/libertyGit/open-liberty)"
    echo "    desired-server-name  : Optional. Name of the server to create in your Open Liberty installation to test this application. If not specified, the default server name is $DEFAULT_SERVER_NAME."
    exit 1
fi
if [ -z $SERVER_NAME ]
then
    SERVER_NAME="$DEFAULT_SERVER_NAME"
fi

echo "Using Open Liberty installation at: $OL_INSTALL"
echo "Will create new server named $SERVER_NAME"

cd app

echo "Running Maven build..."
mvn clean install

cd ..

echo "Removing existing directory in OL installation for server $SERVER_NAME..."
rm -rf "$OL_INSTALL""/dev/build.image/wlp/usr/servers/$SERVER_NAME"

echo "Creating new directory in OL installation for server $SERVER_NAME..."
mkdir "$OL_INSTALL""/dev/build.image/wlp/usr/servers/$SERVER_NAME"

echo "Copying repository server files into server directory..."
cp -r server/* "$OL_INSTALL""/dev/build.image/wlp/usr/servers/$SERVER_NAME"

echo "Copying application WAR into server's dropins directory..."
cp app/target/kabasec.war "$OL_INSTALL""/dev/build.image/wlp/usr/servers/$SERVER_NAME/dropins/"

