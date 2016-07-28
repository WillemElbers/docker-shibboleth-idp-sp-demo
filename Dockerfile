FROM debian:jessie

ENV JAVA_HOME="/usr"
ENV CATALINA_PID="/var/run/tomcat8.pid"
ENV CATALINA_HOME="/usr/share/tomcat8"
ENV CATALINA_BASE="/var/lib/tomcat8"
ENV JAVA_OPTS="-Xmx1024m"

RUN echo "deb http://http.debian.net/debian jessie-backports main" >> /etc/apt/sources.list \
 && apt-get update -y \
 && apt-get install -y openjdk-8-jdk openssl apache2 libapache2-mod-shib2 tomcat8 tomcat8-admin supervisor wget curl vim \
 && a2enmod ssl \
 && a2enmod shib2 \
 && a2enmod proxy \
 && a2enmod proxy_http \
 && a2enmod proxy_ajp \
 && a2enmod headers \
 && a2enmod rewrite \
 && a2enmod cgi

RUN apt-get update -y \
 && apt-get install -y python-dev python-pip libxml2-dev libxslt1-dev zlib1g-dev \
 && pip install lxml requests

#
# SP setup
#

COPY openssl/shibboleth-sp.cert.conf /opt/shibboleth-sp.cert.conf
RUN mkdir -p /etc/shibboleth/certs \
 && openssl req -config /opt/shibboleth-sp.cert.conf -new -x509 -days 365 -keyout /etc/shibboleth/certs/shib.key -out /etc/shibboleth/certs/shib.crt \
 && chmod 0700 /etc/shibboleth/certs/shib.crt \
 && chmod 0700 /etc/shibboleth/certs/shib.key

RUN mkdir -p mkdir -p /var/run/shibboleth
COPY sp/shibboleth2.xml /etc/shibboleth/shibboleth2.xml
COPY sp/attribute-map.xml /etc/shibboleth/attribute-map.xml
COPY sp/attribute-policy.xml /etc/shibboleth/attribute-policy.xml

#
# IDP Setup
#
RUN cd /root \
 && wget http://shibboleth.net/downloads/identity-provider/3.1.2/shibboleth-identity-provider-3.1.2.tar.gz \
 && tar -xf shibboleth-identity-provider-3.1.2.tar.gz \
 && mkdir -p /root/shibboleth-identity-provider-3.1.2/edit-webapp/WEB-INF/lib/ \
 && cd /root/shibboleth-identity-provider-3.1.2/edit-webapp/WEB-INF/lib/ \
 && wget https://build.shibboleth.net/nexus/service/local/repositories/thirdparty/content/javax/servlet/jstl/1.2/jstl-1.2.jar

RUN cd /root/shibboleth-identity-provider-3.1.2/bin \
 && ./install.sh -Didp.sealer.password=notasecurepassword -Didp.src.dir=/root/shibboleth-identity-provider-3.1.2 -Didp.target.dir=/opt/shibboleth-idp -Didp.host.name=localhost -Dentityid=https://localhost/idp/shibboleth -Didp.scope=localhost -Didp.keystore.password=notasecurepassword \
 && sed -i 's/ password/notasecurepassword/g' /opt/shibboleth-idp/conf/idp.properties \
 && rm /root/shibboleth-identity-provider-3.1.2.tar.gz

COPY idp/metadata-providers.xml /opt/shibboleth-idp/conf/metadata-providers.xml
COPY idp/idp.properties /opt/shibboleth-idp/conf/idp.properties
COPY idp/attribute-resolver.xml /opt/shibboleth-idp/conf/attribute-resolver.xml
COPY idp/attribute-filter.xml /opt/shibboleth-idp/conf/attribute-filter.xml
COPY idp/relying-party.xml /opt/shibboleth-idp/conf/relying-party.xml
COPY idp/web.xml /opt/shibboleth-idp/webapp/WEB-INF/web.xml
COPY idp/logback.xml /opt/shibboleth-idp/conf/logback.xml

#
# Tomcat
#
RUN mkdir -p /var/lib/tomcat8/temp \
 && mkdir -p /usr/share/tomcat8/common/classes \
 && mkdir -p /usr/share/tomcat8/server/classes \
 && mkdir -p /usr/share/tomcat8/shared/classes \
 && chown -R tomcat8:tomcat8 /usr/share/tomcat8 \
 && chown -R tomcat8:tomcat8 /var/lib/tomcat8 \
 && rm -rf /var/lib/tomcat8/webapps/ROOT

COPY tomcat/server.xml /etc/tomcat8/server.xml
COPY tomcat/tomcat-users.xml /etc/tomcat8/tomcat-users.xml
COPY tomcat/idp.xml /etc/tomcat8/Catalina/localhost/idp.xml

#
# Apache
#
COPY openssl/apache.cert.conf /opt/apache.cert.conf
COPY apache/default.conf /etc/apache2/sites-available/default.conf
RUN mkdir -p /etc/apache2/certs \
 && openssl req -config /opt/apache.cert.conf -new -x509 -days 365 -keyout /etc/apache2/certs/apache.key -out /etc/apache2/certs/apache.crt \
 && chmod 0700 /etc/apache2/certs/apache.crt \
 && chmod 0700 /etc/apache2/certs/apache.key \
 && a2dissite 000-default \
 && a2ensite default

#
# Supervisor
#
COPY supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf
RUN mkdir -p /var/log/supervisord

#
# Exchange IDP and SP metadata
#
RUN /etc/init.d/shibd start \
 && /etc/init.d/apache2 start \
 && mkdir -p /data/metadata \
 && wget --no-check-certificate -O /data/metadata/sp-metadata.xml https://localhost/Shibboleth.sso/Metadata \
 && cp /opt/shibboleth-idp/metadata/idp-metadata.xml /data/metadata/idp-metadata.xml

COPY aai-debugger-1.1.war ${CATALINA_BASE}/webapps/app.war
COPY AAGregator-1.0.war ${CATALINA_BASE}/webapps/aagregator.war
COPY clarin-aai-debugger-1.1.war ${CATALINA_BASE}/webapps/debugger.war

#COPY sp-aagregator-golang_linux_amd64 /opt/sp-aagregator-golang

#COPY sp-aagregator-cgi-python.py /usr/lib/cgi-bin/sp-aagregator-python.py
#RUN chmod ugo+x /usr/lib/cgi-bin/sp-aagregator-golang-cli.go \
# && chmod ugo+x /usr/lib/cgi-bin/sp-aagregator-python.py

#RUN mkdir -p /var/www/html/hook
COPY sp-aagregator-golang /var/www/html/aa-statistics/clarin-sp-aagregator-golang.go
COPY sp-aagregator-cgi-python.py /var/www/html/aa-statistics/sp-aagregator-python.py
RUN chmod ugo+x /var/www/html/aa-statistics/clarin-sp-aagregator-golang.go \
 && chmod ugo+x /var/www/html/aa-statistics/sp-aagregator-python.py \
 && mkdir -p /var/log/sp-session-hook \
 && chown -R www-data:www-data /var/log/sp-session-hook


EXPOSE 80 443 8009 8080

CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
