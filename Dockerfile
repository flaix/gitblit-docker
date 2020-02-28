FROM openjdk:8-jre-slim

ENV GITBLIT_VERSION 1.9.0
ENV GITBLIT_DOWNLOAD_SHA 349302ded75edfed98f498576861210c0fe205a8721a254be65cdc3d8cdd76f1

LABEL maintainer="James Moger <james.moger@gitblit.com>, Florian Zschocke <f.zschocke+gitblit@gmail.com>" \
      org.label-schema.schema-version="1.0" \
      org.label-schema.version="${GITBLIT_VERSION}"


ENV GITBLIT_DOWNLOAD_URL https://github.com/gitblit/gitblit/releases/download/v${GITBLIT_VERSION}/gitblit-${GITBLIT_VERSION}.tar.gz

# Download and  Install Gitblit & Move the data files to a separate directory
RUN set -eux ; \
    apt-get update && apt-get install -y --no-install-recommends \
        wget \
        ; \
    rm -rf /var/lib/apt/lists/* ; \
    wget --progress=bar:force:noscroll -O gitblit.tar.gz ${GITBLIT_DOWNLOAD_URL} ; \
    echo "${GITBLIT_DOWNLOAD_SHA} *gitblit.tar.gz" | sha256sum -c - ; \
    mkdir -p /opt/gitblit ; \
    tar xzf gitblit.tar.gz -C /opt/gitblit --strip-components 1 ; \
    rm -f gitblit.tar.gz ;


# Move the data files to a separate directory and set some defaults
RUN set -eux ; \
    mv /opt/gitblit/data /opt/gitblit-data ; \
    ln -s /opt/gitblit-data /opt/gitblit/data ; \
# Create a system.properties file that sets the defaults for this docker setup.
    echo "server.httpPort=8080" >> /opt/gitblit/system.properties ; \
    echo "server.httpsPort=8443" >> /opt/gitblit/system.properties ; \
    echo "server.redirectToHttpsPort=true" >> /opt/gitblit/system.properties ; \
# Create a properties file for settings that can be set via environment variables from docker
    printf '\
''#\n\
''# GITBLIT-DOCKER.PROPERTIES\n\
''#\n\
''# This file is used by the docker image to store settings that are defined\n\
''# via environment variables. The settings in this file are automatically changed,\n\
''# added or deleted.\n\
''#\n\
''# Do not define your custom settings in this file. Your overrides or\n\
''# custom settings should be defined in the "gitblit.properties" file.\n\
''#\n\
\n' > /opt/gitblit-data/gitblit-docker.properties ; \
# Currently RPC is enabled by default
    echo "web.enableRpcManagement=true" >> /opt/gitblit-data/gitblit-docker.properties ; \
    echo "web.enableRpcAdministration=true" >> /opt/gitblit-data/gitblit-docker.properties ; \
# Create the gitblit.properties file that the user can use for customization.
    printf '\
''#\n\
''# GITBLIT.PROPERTIES\n\
''#\n\
''# Define your custom settings in this file and/or include settings defined in\n\
''# other properties files.\n\
''#\n\
\n\
''# NOTE: Gitblit will not automatically reload "included" properties.  Gitblit\n\
''# only watches the "gitblit.properties" file for modifications.\n\
''#\n\
''# Paths may be relative to the ${baseFolder} or they may be absolute.\n\
''#\n\
''# ONLY append more files at the END of the "include" line.\n\
''# The present files define the default settings for the docker container. If you\n\
''# remove them or change the order, things may break,\n\
''#\n\
include = defaults.properties,/opt/gitblit/system.properties,gitblit-docker.properties\n\
\n\
''#\n\
''# Define your overrides or custom settings below\n\
''#\n\
\n' > /opt/gitblit-data/gitblit.properties ; \
\
# Remove unneeded scripts.
    rm -f /opt/gitblit/install-service-*.sh ; \
    rm -r /opt/gitblit/service-*.sh ;


# Setup the Docker container environment
ENV PATH /opt/gitblit:$PATH

WORKDIR /opt/gitblit

EXPOSE 8080 8443 9418 29418

# run application
CMD ["java", "-server", "-Xmx1024M", "-Djava.awt.headless=true", "-cp", "gitblit.jar:ext/*", "com.gitblit.GitBlitServer", "--baseFolder", "/opt/gitblit-data"]
