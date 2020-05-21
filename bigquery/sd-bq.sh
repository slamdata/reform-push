#!/bin/bash

set -e
set -o pipefail

SCRIPT_DIRECTORY=$(dirname "${BASH_SOURCE}")

OTHER_ARGUMENTS=()
TABLE_NAMES=()

while [[ $# -gt 0 ]]
do
key="$1"

case $key in
    -t|--table)
    TABLE_NAMES+=("$2")
    shift
    shift
    ;;
    *)
    OTHER_ARGUMENTS+=("$1")
    shift
    ;;
esac
done

echo "# Table Names: ${TABLE_NAMES[*]}"
echo "# Other arguments: ${OTHER_ARGUMENTS[*]}"

for i in "${TABLE_NAMES[@]}"
do
  echo "table name: $i"
done


DESTINATION_PROJECT_ID=${OTHER_ARGUMENTS[0]}

DESTINATION_DATASET_ID=${OTHER_ARGUMENTS[1]}

PARTITIONING=${OTHER_ARGUMENTS[2]}

VIRTUAL_TABLES_URL="${OTHER_ARGUMENTS[3]}/api/tables"

VIRTUAL_TABLE_URL_PREFIX="${OTHER_ARGUMENTS[3]}/api/table/"

echo "Getting virtual table URLs"
if [ ${#TABLE_NAMES[@]} -eq 0 ]; then
    echo "Pushing all tables"
    VIRTUAL_TABLE_URLS=$(for i in {1..15}; do curl -s --fail "${VIRTUAL_TABLES_URL}" | jq -r 'to_entries | map(select(select(.value."name" | contains("[Archived] ") | not))) | from_entries | keys | .[]' | sed -e "s#^#${VIRTUAL_TABLE_URL_PREFIX}#" && break || sleep 5; done)
else
    echo "Push only specified tables"
    VIRTUAL_TABLE_URLS=$(for i in "${TABLE_NAMES[@]}"; do curl -s "${VIRTUAL_TABLES_URL}" | jq -r --arg table "$i" 'to_entries | map(select(select(.value."name" == $table))) | from_entries | keys | .[]' | sed -e "s#^#${VIRTUAL_TABLE_URL_PREFIX}#" || sleep 5; done)
fi

echo "Virtual Table URLS:"
echo "$VIRTUAL_TABLE_URLS"

echo "Running process for each virtual table"

echo "$VIRTUAL_TABLE_URLS" | xargs -L1 $SCRIPT_DIRECTORY/sd-bq-single.sh $DESTINATION_PROJECT_ID $DESTINATION_DATASET_ID $PARTITIONING
