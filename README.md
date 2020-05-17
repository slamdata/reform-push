# Precog Push

This projject contains various scripts for pushing to various datasources. Ideally these scripts will eventually become connectors.
Below you'll find some instructions on how to run these scripts.

## Google BigQuery

This script makes use of the `gcloud` command:

```
gcloud auth application-default print-access-token
``` 

which in order to execute successfully and get a useful token you'll need gcloud account.

To sart, issue the command

```
gcloud auth login
```

Now configure a service account and set your poject name:

```
gcloud auth activate-service-account --key-file <service-account-auth-file>.json --project=<project-name>
```

To perofrm a push

```
./sd-bq.sh <project-name> <data-set-name> <quoted-space-separated-list-of-column-names> <precog-base-url>
```

For example:

```
./sd-bq.sh my-project test "subject cc body" none http://192.168.99.101:8080
```
