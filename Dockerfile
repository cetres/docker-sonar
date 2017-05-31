FROM sonarqube

ADD plugins/* /opt/sonarqube/extensions/plugins/

RUN chown -R 1001 /opt/sonarqube && \
    chmod -R g+w /opt/sonarqube

USER 1001
