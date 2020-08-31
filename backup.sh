#!/bin/bash

function timestamp() {
  date +"%Y%M%d-%H%M%S"
}

function urlencode() {
    # urlencode <string>
    local length="${#1}"
    for (( i = 0; i < length; i++ )); do
        local c="${1:i:1}"
        case $c in
            [a-zA-Z0-9.~_-]) printf "$c" ;;
            *) printf '%%%02X' "'$c"
        esac
    done
}

function urldecode() {
    # urldecode <string>

    local url_encoded="${1//+/ }"
    printf '%b' "${url_encoded//%/\\x}"
}

DESTFILE=${DESTINATION_DIRECTORY}/${COUCH_DATABASE}.$(timestamp).txt.gz

### user name recognition at runtime w/ an arbitrary uid - for OpenShift deployments
if ! whoami &> /dev/null; then
  if [ -w /etc/passwd ]; then
    echo "${USER_NAME:-default}:x:$(id -u):0:${USER_NAME:-default} user:${MULE_HOME}:/sbin/nologin" >> /etc/passwd
  fi
fi

if [ "${IGNORE_TLS}" = true ]; then
    export NODE_TLS_REJECT_UNAUTHORIZED=0
fi

if [ -r "/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt" ]; then
    #Trust OpenShift self-signed certificates
    export NODE_EXTRA_CA_CERTS=/var/run/secrets/kubernetes.io/serviceaccount/service-ca.crt
fi

if [ -z "${COUCH_URL}" ]; then
    echo "Missing COUCH_URL Parameter";exit 1
fi

if [ -z "${COUCH_DATABASE}" ]; then
    echo "Missing COUCH_DATABASE Parameter";exit 1
fi

if [ -n "${COUCH_USERNAME}" ] || [ -n "${COUCH_PASSWORD}"]; then
    ENCODED_PASSWORD=$(urlencode ${COUCH_PASSWORD})
    ENCODED_USERNAME=$(urlencode ${COUCH_USERNAME})

    HOSTNAME="${COUCH_URL#http://}"
    HOSTNAME="${COUCH_URL#https://}"
    PROTOCOL="${COUCH_URL%%://*}"
    COUCH_URL_FULL="${PROTOCOL}://${ENCODED_USERNAME}:${ENCODED_PASSWORD}@${HOSTNAME}"
else
    COUCH_URL_FULL=${COUCH_URL}
fi

couchbackup \
    --buffer-size ${BUFFER_SIZE} \
    --mode ${MODE} \
    --request-timeout ${REQUEST_TIMEOUT} \
    --parallelism ${PARALLELISM} \
    --url ${COUCH_URL_FULL} \
    --db ${COUCH_DATABASE} | gzip > ${DESTFILE}
