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
# EXPOSE 80
# EXPOSE 443

# ### Installing Elasticsearch 0.90.2
RUN mkdir /setup
ADD . /setup
RUN /setup/install.sh
ADD elasticsearch.sh /etc/service/elasticsearch/run
CMD ["/sbin/my_init"]

VOLUME ["/opt/elasticsearch"]

EXPOSE 9200
EXPOSE 9300

RUN apt-get update -qq
RUN apt-get install -q -y openjdk-7-jre-headless

# Cleaning up
RUN apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/*


### Installing Kibana 
# Should a variation of specific nginx  be installed, 1.7 is the proposed
# 
# ADD https://download.elasticsearch.org/kibana/kibana/kibana-3.1.0.tar.gz /tmp/kibana.tar.gz
# ADD run.sh /usr/local/bin/run

# RUN tar zxf /tmp/kibana.tar.gz && mv kibana-3.1.0/* /usr/share/nginx/html

# EXPOSE 80

# CMD ["/usr/local/bin/run"]


### Installing MySQL

RUN apt-get update \
 && apt-get install -y mysql-server \
 && rm -rf /var/lib/mysql/mysql \
 && rm -rf /var/lib/apt/lists/* # 20140918

ADD start /start
RUN chmod 755 /start

EXPOSE 3306

VOLUME ["/var/lib/mysql"]
VOLUME ["/run/mysqld"]

CMD ["/start"]


### Install anlzer dependencies 

# Setting up the python environment
RUN apt-get update
RUN apt-get install -y python-pip
RUN apt-get install -y git
RUN apt-get install -y libpq-dev python-dev
RUN git clone https://github.com/mpetyx/fitman.git /fitman
#RUN pip install virtualenv
#RUN virtualenv --no-site-packages venv
#RUN /bin/bash/source venv/bin/activate
RUN pip install -r /fitman/UIapp/requirements.txt

EXPOSE 8000

