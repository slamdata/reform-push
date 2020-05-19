# Precog Push

This project contains various scripts for pushing to various datasources. Ideally these scripts will eventually become connectors.
Below you'll find some instructions on how to run these scripts.

## Google BigQuery

You will need `gcloud`. To install it follow these instructions: 

https://cloud.google.com/sdk/docs/downloads-interactive

This script makes use of the `gcloud` command:

```
gcloud auth application-default print-access-token
```

which in order to execute successfully and get a useful token you'll need gcloud account.

To start, issue the command

```
gcloud auth login
```

Now configure a service account and set your project name:

```
gcloud auth activate-service-account --key-file <service-account-auth-file>.json --project=<project-name>
```

To perform a push

```
./sd-bq.sh <project-name> <data-set-name> <partitioning><precog-base-url>
```

For example:

```
./sd-bq.sh my-project test none http://192.168.99.101:8080
```
