# Precog Push

This project contains various scripts for pushing to various destinations. Ideally these scripts will eventually become connectors.
The instructions below describe how to run these scripts.

## Google BigQuery

The Google Bigquery script has the ability to either push all of your Precog tables or just specific tables to Bigquery.

### Install gcloud
You will need a working installation of `gcloud` to run the Bigquery script.

If you do not have it installed follow these instructions: 

https://cloud.google.com/sdk/docs/downloads-interactive

In short, the link above says to run the following commands to install `gcloud`:

The command below will prompt you with questions you must answer.

```
curl https://sdk.cloud.google.com | bash
```

Once you install `gcloud` refresh your shell:

```
exec -l $SHELL
```

Now you can initialize `gcloud` using:

```
gcloud init
```

In order to start executing `gcloud` commands you will need to
setup a GCP service account with the following roles:

```
BigQuery Admin
BigQuery Data Editor
Service Account Token Creator
```

Generate and download a private login key for the service account you just created:

https://cloud.google.com/iam/docs/creating-managing-service-account-keys#creating_service_account_keys

Activate the service account key using:

```
gcloud auth activate-service-account <service-account-email> --key-file=<path-service-account-json-file> --project=<project-name>
```

`gcloud` will also need for you to set the following environment variable:

```
export GOOGLE_APPLICATION_CREDENTIALS=<path-to-service-account-json-file>
```

### Create a Bigquery dataset

In order to push data to Bigquery you must have an existing dataset to push data into.
You can create a dataset within the Bigquery project you specified above using:

https://cloud.google.com/bigquery/docs/datasets#create-dataset

### Push Procog table(s) to Bigquery

At this stage you have two options either push all your tables or only push certain ones to Bigquery.

If you wish to push all of your tables run the `sd-bq.sh` script like this:

```
./bigquery/sd-bq.sh <project-name> <data-set-name> <time-partitioning> <precog-base-url>
```

If you only want to push certain tables run `sd-bq.sh` like this:

```
./bigquery/sd-bq.sh -t <a-table-name> -t <another-table-name> -t <"table with spaces in the name">  <project-name> <data-set-name> <time-partitioning> <precog-base-url>
```

### Examples

```
./sd-bq.sh my-project myDataset none http://192.168.99.101:8080
```

or 

```
./sd-bq.sh -t mytable1 -t "my other table" my-project myDataset day_partitioning http://192.168.99.101:8080
```
