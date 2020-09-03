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