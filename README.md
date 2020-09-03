# Container to create couchdb Backups on Kubernetes

Container image for backing up couchdb on Kubernetes or OpenShift clusters

Run as a Cronjob to backup to persistent storage

The driver was to backup couchdb databases that are deployed using the couchDB operator

uses the nodejs tool couchbackup

https://github.com/cloudant/couchbackup

Provides two nodejs binaries

* couchbackup
* couchrestore

# Generated Images

## Alpine base image
docker.io/byroncollins/couchbackup:nodejs-12-alpine

## Red Hat UBI image

docker.io/byroncollins/couchbackup:nodejs-12-ubi


# Install 

## Create persitent storage for backups


```bash
#Example: persistent storage claim
oc apply -f manifests/couchdb-backup-pvc.yaml
```

## Create cronjob for backing up your couchdb

### Environment variables

| Environment Variable | Default  |
| ------------- |-------------|
| IGNORE_TLS | false |
| COUCH_USERNAME | null |
| COUCH_PASSWORD | null |
| COUCH_URL| null |
| COUCH_DATABASE | null |
| BUFFER_SIZE | 500 |
| MODE | full |
| REQUEST_TIMEOUT | 120000 |
| PARALLELISM | 5 |
| DESTINATION_DIRECTORY | /var/couchdbbackups |


### Required Environment Variables

#### COUCH_URL

COUCH_URL is required for the couchbackup script to access the couchDB instance

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

# Running in Docker

```bash
#Map backup volume to your drive
docker run --network host --rm -it --env COUCH_URL=https://my-couchdb-couchdb.apps.example.com --env COUCH_DATABASE=hello-world --env COUCH_USERNAME=admin --env COUCH_PASSWORD=changeme --env IGNORE_TLS=true --env DESTINATION_DIRECTORY=/var/couchdbbackups -v /host/backup:/var/couchdbbackups byroncollins/couchbackup:nodejs-12-alpine
```

# Restore couchdb

## Kubernetes/OpenShift

```bash
#Modify Environment specs for job/pod
kubectl run couchdb-restore \
    --image byroncollins/couchbackup:nodejs-12-alpine \
    --rm -ti \
    --restart=Never \
    --overrides='
{
    "metadata": {
        "labels": {
            "couchdb": "restore"
        }
    },
    "spec": {
        "containers": [
            {
            "env": [
                {
                    "name": "COUCH_URL",
                    "value": "https://my-couchdb.couchdb.svc.cluster.local"
                },
                {
                    "name": "COUCH_DATABASE",
                    "value": "hello-world"
                },
                {
                    "name": "DESTINATION_DIRECTORY",
                    "value": "/var/couchdbbackups"
                },
                {
                    "name": "COUCH_USERNAME",
                    "value": "admin"
                },
                {
                    "name": "COUCH_PASSWORD",
                    "valueFrom": {
                        "secretKeyRef": {
                            "key": "admin_password",
                            "name": "c-my-couchdb-m"
                        }
                    }
                }
            ],
                "stdin": true,
                "tty": true,
                "args": [ "restore" ],
                "name": "couchdb-restore",
                "image": "byroncollins/couchbackup:nodejs-12-alpine",
                "imagePullPolicy": "Always",
                "volumeMounts": [
                    {
                        "mountPath": "/var/couchdbbackups",
                        "name": "couchdb-backup-pvc"
                    }
                ]
            }
        ],
        "volumes": [
            {
                "name":"couchdb-backup-pvc",
                "persistentVolumeClaim" : {
                    "claimName": "couchdb-backup-pvc"
                }
            }
        ]
    }
}
'
```

## Docker


```bash
#Map backup volume to your drive
docker run \
   --network host \
   --rm -it \
   --env COUCH_URL=https://my-couchdb-couchdb.apps.example.com \
   --env COUCH_DATABASE=hello-world \
   --env COUCH_USERNAME=admin \
   --env COUCH_PASSWORD=changeme \
   --env IGNORE_TLS=true \
   --env DESTINATION_DIRECTORY=/var/couchdbbackups -v /host/backup:/var/couchdbbackups byroncollins/couchbackup:nodejs-12-alpine restore

*** Restore Instructions ***
-----------------------------
1. Locate the backup to restore from in /var/couchdbbackups
2. Run the following command to restore the database
   cat /var/couchdbbackups/hello-world.<timestamp>.txt.gz | gunzip | couchrestore -db hello-world --url ${COUCH_URL_FULL}
-----------------------------
bash-4.4$ 
bash-4.4$ cat /var/couchdbbackups/hello-world.20203031-173011.txt.gz | gunzip | couchrestore --url ${COUCH_URL_FULL}

```