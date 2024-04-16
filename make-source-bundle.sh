#!/bin/bash

SOURCE_BUNDLE_PATH=source-bundle.zip

rm "$SOURCE_BUNDLE_PATH"
zip -r "$SOURCE_BUNDLE_PATH" backend frontend nginx docker-compose.yml > /dev/null
echo "{\"path\":\"$SOURCE_BUNDLE_PATH\",\"md5\":\"$(md5sum "$SOURCE_BUNDLE_PATH" | awk '{ print $1 }')\"}"
