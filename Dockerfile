FROM registry.redhat.io/ubi8/nodejs-12


ENV IGNORE_TLS=false \
    COUCH_USERNAME= \
    COUCH_PASSWORD= \
    COUCH_URL= \
    COUCH_DATABASE= \
    DESTINATION_DIRECTORY=/var/couchdbbackups

USER root

WORKDIR /opt/app-root/src
COPY backup.sh /opt/app-root/src/backup.sh
RUN npm install -g @cloudant/couchbackup \
&& mkdir -p ${DESTINATION_DIRECTORY} \
&& chmod -R g+wrx ${DESTINATION_DIRECTORY} \
&& chgrp -R 0 ${DESTINATION_DIRECTORY} \
&& chmod +x /opt/app-root/src/backup.sh \
&& chmod -R g=u /opt/app-root/src /etc/passwd

USER 1001

VOLUME ${DESTINATION_DIRECTORY}
CMD /opt/app-root/src/backup.sh