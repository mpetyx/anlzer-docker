echo "# Installing Elasticsearch"
wget -q https://download.elasticsearch.org/elasticsearch/elasticsearch/elasticsearch-1.3.4.tar.gz -O /tmp/es.tgz
tar -xzf /tmp/es.tgz -C /opt/
mv /opt/elasticsearch-1.3.4 /opt/elasticsearch
mkdir -p /etc/service/elasticsearch

echo "# Install kopf, kibana3, transport head plugin"
/opt/elasticsearch/bin/plugin -install lmenezes/elasticsearch-kopf
/opt/elasticsearch/bin/plugin -install mobz/elasticsearch-head
/opt/elasticsearch/bin/plugin -install elasticsearch/kibana3
/opt/elasticsearch/bin/plugin -install transport-couchbase \
-url http://packages.couchbase.com.s3.amazonaws.com/releases/elastic-search-adapter/1.3.0/elasticsearch-transport-couchbase-1.3.0.zip

echo "# Disable multicast and dynamic scripting"
sed -i 's/#discovery.zen.ping.multicast.enabled: false/discovery.zen.ping.multicast.enabled: false/g' /opt/elasticsearch/config/elasticsearch.yml
echo "script.disable_dynamic: sandbox" >> /opt/elasticsearch/config/elasticsearch.yml

# make sure are service user has permissions to es
chown -R app:app /opt/elasticsearch

echo "# Cleaning up"
apt-get clean && rm -rf /var/lib/apt/lists/* /tmp/* /var/tmp/* /setup /build
