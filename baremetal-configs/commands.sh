#!/bin/bash

## JAVA
sudo apt-get install openjdk-11-jre-headless

## ZOOKEEPER
wget https://dlcdn.apache.org/zookeeper/zookeeper-3.9.0/apache-zookeeper-3.9.0-bin.tar.gz\
sudo mkdir /usr/local/zookeeper
sudo chown -R $(whoami) /usr/local/zookeeper
sudo tar \ 
    -xzf apache-zookeeper-3.9.0-bin.tar.gz \
    -C /usr/local/zookeeper/ \
    --strip-components=1

echo "tickTime=2000
dataDir=/var/lib/zookeeper
clientPort=2181 " >> /usr/local/zookeeper/conf/zoo.cfg

sudo /usr/local/zookeeper/bin/zkServer.sh start


## KAFKA

wget https://downloads.apache.org/kafka/3.5.1/kafka_2.13-3.5.1.tgz
sudo mkdir /usr/local/kafka
sudo tar \
    -xzf kafka_2.13-3.5.1.tgz \ 
    -C /usr/local/kafka \
    --strip-components=1

sudo chown -R $(whoami) /usr/local/kafka
/usr/local/kafka/bin/kafka-server-start.sh -daemon /usr/local/kafka/config/server.properties


## KAFKA TOPIC
/usr/local/kafka/bin/kafka-topics.sh \
    --create \
    --topic mytopic \
    --bootstrap-server localhost:9092 \
    --partitions 10


## KAFKA CONNECT

mkdir /usr/local/kafka/plugins /usr/local/kafka/plugins/camel-postgresql-sink-kafka-connector
echo "plugin.path=/usr/local/kafka/plugins" >> /usr/local/kafka/config/connect-distributed.properties

wget https://repo.maven.apache.org/maven2/org/apache/camel/kafkaconnector/camel-postgresql-sink-kafka-connector/3.18.2/camel-postgresql-sink-kafka-connector-3.18.2-package.tar.gz

sudo tar \
    -xzf camel-postgresql-sink-kafka-connector-3.18.2-package.tar.gz \
    -C /usr/local/kafka/plugins/camel-postgresql-sink-kafka-connector \
    --strip-components=1

wget https://jdbc.postgresql.org/download/postgresql-42.6.0.jar
mv postgresql-42.6.0.jar /usr/local/kafka/plugins/camel-postgresql-sink-kafka-connector

/usr/local/kafka/bin/connect-distributed.sh \
    -daemon \
    /usr/local/kafka/config/connect-distributed.properties

echo '{
	"name": "timescale-sink",
	"config": {
		"connector.class":"org.apache.camel.kafkaconnector.postgresqlsink.CamelPostgresqlsinkSinkConnector",
		"errors.tolerance":"all",
		"errors.deadletterqueue.topic.name":"deadletter",
		"tasks.max":10,
		"value.converter":"org.apache.kafka.connect.storage.StringConverter",
		"key.converter":"org.apache.kafka.connect.storage.StringConverter",
		"topics":"mytopic",
		"camel.kamelet.postgresql-sink.databaseName":"tsdb",
		"camel.kamelet.postgresql-sink.password":"password",
		"camel.kamelet.postgresql-sink.query":"INSERT INTO accounts (username,city) VALUES (:#username,:#city)",
		"camel.kamelet.postgresql-sink.serverName":"service.project.tsdb.cloud.timescale.com",
		"camel.kamelet.postgresql-sink.serverPort":"5432",
		"camel.kamelet.postgresql-sink.username":"tsdbadmin"
	}
}' > timescale-sink.properties

cat timescale-sink.properties | curl -X POST -d @- http://localhost:8083/connectors -H "Content-Type: application/json"

curl -X GET https://localhost:8083/connectors


## KAFKACAT

sudo apt-get install kafkacat

echo '{"username":"Mathis","city":"Salt Lake City"}' | kafkacat -P -b localhost:9092 -t mytopic