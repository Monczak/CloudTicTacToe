#!/bin/bash

SOURCE_BUNDLE_PATH=source-bundle.zip

zip -r "$SOURCE_BUNDLE_PATH" backend frontend nginx docker-compose.yml > /dev/null
echo "{\"md5\":\"$(md5sum "$SOURCE_BUNDLE_PATH" | awk '{ print $1 }')\"}"
