from adoptopenjdk/openjdk8-openj9:slim as package
label maintainer="James Moger <james.moger@gitblit.com>, Florian Zschocke<fzs>" \
      author="Bala Raman <srbala [at] gmail.com>"
# Download and  Install Gitblit & Move the data files to a separate directory
run curl -Lks https://github.com/gitblit/gitblit/releases/download/v1.9.0/gitblit-1.9.0.tar.gz -o /root/gitblit.tar.gz && \
    mkdir -p /opt/gitblit-tmp && \
    tar zxf /root/gitblit.tar.gz -C /opt/gitblit-tmp && \
    mv /opt/gitblit-tmp/gitblit-1.9.0 /opt/gitblit && \
    rm -rf /opt/gitblit-tmp && \
    rm -f /root/gitblit.tar.gz && \
    mkdir -p /opt/gitblit-data && \
    mv /opt/gitblit/data/* /opt/gitblit-data && \
    echo "server.httpPort=80" >> /opt/gitblit-data/gitblit.properties && \
    echo "server.httpsPort=443" >> /opt/gitblit-data/gitblit.properties && \
    echo "server.redirectToHttpsPort=true" >> /opt/gitblit-data/gitblit.properties && \
    echo "web.enableRpcManagement=true" >> /opt/gitblit-data/gitblit.properties && \
    echo "web.enableRpcAdministration=true" >> /opt/gitblit-data/gitblit.properties

# Setup the Docker container environment and run Gitblit
workdir /opt/gitblit
# Adjust the default Gitblit settings to bind to 80, 443, 9418, 29418, and allow RPC administration.
expose 80 443 9418 29418
# run application
cmd ["java", "-server", "-Xmx1024M", "-Djava.awt.headless=true", "-cp", "gitblit.jar:ext/*", "com.gitblit.GitBlitServer", "--baseFolder", "/opt/gitblit-data"]
