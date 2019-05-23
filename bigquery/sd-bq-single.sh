#!/bin/bash

set -e
set -o pipefail

ACCESS_TOKEN=$(gcloud auth application-default print-access-token)

DESTINATION_PROJECT_ID=$1
DESTINATION_DATASET_ID=$2
FLOAT64_COLUMN_NAMES=$3
PARTITIONING=$4
TABLE_URL=$5

echo "Getting virtual table name..."
TABLE_INFO=$(curl --fail "$TABLE_URL")

echo "Getting virtual table single use token..."
TOKEN=$(curl --silent ${TABLE_URI}/access-token | jq -r '.secret')

echo "Table info:"
echo "${TABLE_INFO}"

TABLE_NAME_ORIGINAL=$(echo "${TABLE_INFO}" | jq -r .name)
TABLE_NAME=$(echo "${TABLE_NAME_ORIGINAL}" | perl -pe 'chomp if eof' | perl -pe 's/[^A-Za-z0-9]/_/g')
echo "Virtual table name: ${TABLE_NAME}"

TABLE_COLUMNS=$(echo "${TABLE_INFO}" | jq "[.columns | .[] | .type = if (.column as \$column | ${FLOAT64_COLUMN_NAMES} | .\"${TABLE_NAME_ORIGINAL}\" | index(\$column)) then \"FLOAT64\" elif .type == \"offsetdatetime\" then \"TIMESTAMP\" elif .type == \"number\" then \"NUMERIC\" elif .type == \"string\" then \"STRING\" elif .type == \"boolean\" then \"BOOLEAN\" else null end | .[\"name\"] = (.column | gsub(\"[ ]\"; \"_\")) | del(.column)]")

echo "Virtual table columns: ${TABLE_COLUMNS}"

PARTITIONING_INFO=$(if [ "$PARTITIONING" = "day_partitioning" ]; then printf '"timePartitioning": { "type": "DAY" },'; else printf ''; fi)
WRITE_DISPOSITION=$(if [ "$PARTITIONING" = "day_partitioning" ]; then printf 'WRITE_APPEND'; else printf 'WRITE_TRUNCATE'; fi)

JOB_CONFIGURATION=\
"{\
   \"configuration\": {\
     \"load\": {\
       \"sourceFormat\": \"CSV\",\
       \"skipLeadingRows\": 1,\
       \"allowQuotedNewlines\": true,\
       \"schemaUpdateOptions\": [ \"ALLOW_FIELD_ADDITION\" ],\
       \"schema\": {\
         \"fields\": $TABLE_COLUMNS\
       },$PARTITIONING_INFO\
       \"writeDisposition\": \"$WRITE_DISPOSITION\",\
       \"destinationTable\": {\
         \"projectId\": \"$DESTINATION_PROJECT_ID\",\
         \"datasetId\": \"$DESTINATION_DATASET_ID\",\
         \"tableId\": \"$TABLE_NAME\"\
       }\
     }\
   }\
 }"

echo "Job configuration: ${JOB_CONFIGURATION}"

echo "Creating job..."
JOB_URL_PRIME=$(echo $JOB_CONFIGURATION | curl --fail -i -H "Authorization: Bearer $ACCESS_TOKEN" -H "Content-type: application/json" --data @- -X POST "https://www.googleapis.com/upload/bigquery/v2/projects/${DESTINATION_PROJECT_ID}/jobs?uploadType=resumable")

echo "Job url prime: ${JOB_URL_PRIME}"
JOB_URL=$(printf "${JOB_URL_PRIME}" | perl -n -e '/^Location: (.*)/i && print $1')

echo "Job URL: ${JOB_URL}"

echo "Streaming virtual table into Google BigQuery..."
curl --fail "$TABLE_URL/result/${TOKEN}.csv" | curl --fail -X PUT --data-binary @- ${JOB_URL%$'\r'}
