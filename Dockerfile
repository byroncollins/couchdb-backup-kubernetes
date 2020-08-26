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
&& mkdir -p /var/couchdbbackups \
&& chmod -R g+wrx /var/couchdbbackups \
&& chgrp -R 0 /var/couchdbbackups \
&& chmod +x /opt/app-root/src/backup.sh \
&& chmod -R g=u ${MULE_HOME} /etc/passwd

USER 1001

VOLUME /var/couchdbbackups
CMD /opt/app-root/src/backup.sh