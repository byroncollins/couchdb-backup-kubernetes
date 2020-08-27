# Container to create couchdb Backups on Kubernetes

container image for backing up couchdb on Kubernetes or OpenShift clusters

Run as a Cronjob to backup to persistent storage

The driver was to backup couchdb databases that are deployed using the couchDB operator

# Install 

## Create persitent storage for backups


```bash
#Example: persistent storage claim
oc apply -f manifests/couchdb-backup-pvc.yaml
```

## Create cronjob for backing up your couchdb

Environment variables

### COUCH_URL

COUCH_URL is required for the couchbackuo script to access the couchDB instance

It can point to an external route or internal service (recommended) if running the cronjob in the same project as your couchdb instance

COUCH_URL=https://<servicename>.<project>.svc.cluster.local

example: COUCH_URL=https://my-couchdb.couchdb-dev.svc.cluster.local

### COUCH_DATABASE

COUCH_DATABASE is the database that you want to backup to the persistent volume

### DESTINATION_DIRECTORY

DESTINATION_DIRECTORY is the directory location where you want the backups to be placed

backups are compressed by default with gzip and file names of the backups are:

```bash
${DESTINATION_DIRECTORY}/${COUCH_DATABASE}.$(date +"%Y%M%d-%H%M%S").txt.gz
```

### COUCH_USERNAME

COUCH_USERNAME is the username to access the couchdb database

### COUCH_PASSWORD

COUCH_PASSWORD should ideally point to a secret key that contains the password required to access the couchdb


```bash
oc project <project name>
oc apply -f mainfests/backup-couchdb-cronjob.yaml
```

