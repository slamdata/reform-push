#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIRECTORY=$(dirname "${BASH_SOURCE}")

DESTINATION_PROJECT_ID=$1

DESTINATION_DATASET_ID=$2

#FLOAT64_COLUMN_NAMES=$3

PARTITIONING=$3

VIRTUAL_TABLES_URL="${4}/api/tables"

VIRTUAL_TABLE_URL_PREFIX="${4}/api/table/"

echo "Getting virtual table URLs"

VIRTUAL_TABLE_URLS=$(for i in {1..15}; do curl -s --fail "${VIRTUAL_TABLES_URL}" | jq -r 'to_entries | map(select(select(.value."name" | contains("[Archived] ") | not))) | from_entries | keys | .[]' | sed -e "s#^#${VIRTUAL_TABLE_URL_PREFIX}#" && break || sleep 5; done)

echo "$VIRTUAL_TABLE_URLS"

echo "Running process for each virtual table"

#echo "$VIRTUAL_TABLE_URLS" | xargs -L1 $SCRIPT_DIRECTORY/sd-bq-single.sh $DESTINATION_PROJECT_ID $DESTINATION_DATASET_ID "$FLOAT64_COLUMN_NAMES" $PARTITIONING
echo "$VIRTUAL_TABLE_URLS" | xargs -L1 $SCRIPT_DIRECTORY/sd-bq-single.sh $DESTINATION_PROJECT_ID $DESTINATION_DATASET_ID $PARTITIONING
