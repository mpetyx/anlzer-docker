FROM ubuntu
MAINTAINER Michael Petychakis, mpetyx@gmail.com

ENV CB_VERSION 2.2.0
ENV CB_BASE_URL http://packages.couchbase.com/releases
ENV CB_PACKAGE couchbase-server-community_${CB_VERSION}_x86_64.deb
ENV CB_DOWNLOAD_URL ${CB_BASE_URL}/${CB_VERSION}/${CB_PACKAGE}
ENV CB_LOCAL_PATH /tmp/${CB_PACKAGE}

# User limits
RUN sed -i.bak '/\# End of file/ i\\# Following 4 lines added by docker-couchbase-server' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                hard    memlock          unlimited' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                soft    memlock         unlimited\n' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                hard    nofile          65536' /etc/security/limits.conf
RUN sed -i.bak '/\# End of file/ i\\*                soft    nofile          65536\n' /etc/security/limits.conf
RUN sed -i.bak '/\# end of pam-auth-update config/ i\\# Following line was added by docker-couchbase-server' /etc/pam.d/common-session
RUN sed -i.bak '/\# end of pam-auth-update config/ i\session	required        pam_limits.so\n' /etc/pam.d/common-session

# Locale
RUN locale-gen en_US en_US.UTF-8

# Update & install packages
RUN apt-get -y update
RUN apt-get -y install librtmp0 lsb-release python-httplib2

# Download Couchbase Server package to /tmp & install, stop service
# and remove Couchbase Server lib contents
ADD ${CB_DOWNLOAD_URL} ${CB_LOCAL_PATH}
RUN dpkg -i ${CB_LOCAL_PATH}

# FIXME: No longer necessary
# VOLUME /home/couchbase-server:/opt/couchbase/var
#RUN rm -r /opt/couchbase/var/lib

# Install Dustin's confsed utility
ADD http://cbfs-ext.hq.couchbase.com/dustin/software/confsed/confsed.lin64.gz /usr/local/sbin/confsed.gz
RUN gzip -d /usr/local/sbin/confsed.gz
RUN chmod 755 /usr/local/sbin/confsed

# Install the Couchbase Server Docker start script
ADD bin/couchbase-script /usr/local/sbin/couchbase
RUN chmod 755 /usr/local/sbin/couchbase

# Open rewritten Couchbase Server administration port and others
# (7081 is rewritten as 8091)
EXPOSE 7081 8092 11210

CMD /usr/local/sbin/couchbase

# Install Nginx.
# RUN \
#   add-apt-repository -y ppa:nginx/stable && \
#   apt-get update && \
#   apt-get install -y nginx && \
#   rm -rf /var/lib/apt/lists/* && \
#   echo "\ndaemon off;" >> /etc/nginx/nginx.conf && \
#   chown -R www-data:www-data /var/lib/nginx

# # Define mountable directories.
# VOLUME ["/etc/nginx/sites-enabled", "/etc/nginx/certs", "/etc/nginx/conf.d", "/var/log/nginx", "/var/www/html"]

# # Define working directory.
# WORKDIR /etc/nginx

# # Define default command.
# CMD ["nginx"]

# Expose ports.
EXPOSE 80
EXPOSE 443

### Installing Elasticsearch 0.90.2
RUN sudo apt-get install openjdk-7-jre-headless
RUN wget https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-0.90.2.deb
RUN sudo dpkg -i elasticsearch

EXPOSE 22
EXPOSE 9200
EXPOSE 9300

### Installing Kibana 
# Should a variation of specific nginx  be installed, 1.7 is the proposed
# 
# ADD https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz /tmp/kibana.tar.gz
# ADD run.sh /usr/local/bin/run

# RUN tar zxf /tmp/kibana.tar.gz && mv kibana-3.1.0/* /usr/share/nginx/html

# EXPOSE 80

# CMD ["/usr/local/bin/run"]
