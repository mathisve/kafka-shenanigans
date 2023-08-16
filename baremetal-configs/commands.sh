#!/bin/bash

########
# JAVA #
########

sudo apt update
sudo apt install openjdk-11-jre-headless -y

#########
# KAFKA #
#########

wget https://downloads.apache.org/kafka/3.5.1/kafka_2.13-3.5.1.tgz
sudo mkdir /usr/local/kafka
sudo chown -R $(whoami) /usr/local/kafka

tar \
	-xzf kafka_2.13-3.5.1.tgz \
	-C /usr/local/kafka \
	--strip-components=1

# set up kraft
export uuid=$(/usr/local/kafka/bin/kafka-storage.sh random-uuid)

/usr/local/kafka/bin/kafka-storage.sh format \
	-t $uuid \
	-c /usr/local/kafka/config/kraft/server.properties

# start kafka
/usr/local/kafka/bin/kafka-server-start.sh \
	-daemon \
	/usr/local/kafka/config/kraft/server.properties


###############
# KAFKA TOPIC #
###############

/usr/local/kafka/bin/kafka-topics.sh \
    --create \
    --topic mytopic \
    --bootstrap-server localhost:9092 \
    --partitions 10

/usr/local/kafka/bin/kafka-topics.sh \
	--create \
	--topic deadletter \
	--bootstrap-server localhost:9092 \
	--partitions 10


#################
# KAFKA CONNECT #
#################

mkdir /usr/local/kafka/plugins /usr/local/kafka/plugins/camel-postgresql-sink-kafka-connector
echo "plugin.path=/usr/local/kafka/plugins" >> /usr/local/kafka/config/connect-distributed.properties

# download connector
wget https://repo.maven.apache.org/maven2/org/apache/camel/kafkaconnector/camel-postgresql-sink-kafka-connector/3.18.2/camel-postgresql-sink-kafka-connector-3.18.2-package.tar.gz

tar \
    -xzf camel-postgresql-sink-kafka-connector-3.18.2-package.tar.gz \
    -C /usr/local/kafka/plugins/camel-postgresql-sink-kafka-connector \
    --strip-components=1

# download postgresql driver
wget https://jdbc.postgresql.org/download/postgresql-42.6.0.jar
mv postgresql-42.6.0.jar /usr/local/kafka/plugins/camel-postgresql-sink-kafka-connector

# start kafka connect
/usr/local/kafka/bin/connect-distributed.sh \
	-daemon \
    /usr/local/kafka/config/connect-distributed.properties

# loop that waits for kafka connect to come online
# only useful when this file is run as a whole
# disregard when manually executing commands
while true; do
	curl -X GET http://localhost:8083 < /dev/null
	if [ $? -eq 0 ]; then
		break
	fi
	sleep 15
done

# timescale-sink config
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
		"camel.kamelet.postgresql-sink.query":"INSERT INTO accounts (name,city) VALUES (:#name,:#city)",
		"camel.kamelet.postgresql-sink.serverName":"service_id.project_id.tsdb.cloud.timescale.com",
		"camel.kamelet.postgresql-sink.serverPort":"5432",
		"camel.kamelet.postgresql-sink.username":"tsdbadmin"
	}
}' > timescale-sink.properties

# add timescale-sink connector
cat timescale-sink.properties | curl -X POST -d @- http://localhost:8083/connectors -H "Content-Type: application/json"

# validate if connector shows up
curl -X GET http://localhost:8083/connectors


############
# KAFKACAT #
############

sudo apt install kafkacat -y

#send message on topic
echo '{"name":"Mathis","city":"Salt Lake City"}' | kafkacat -P -b localhost:9092 -t mytopic
echo '{"name":"Oliver","city":"Moab"}' | kafkacat -P -b localhost:9092 -t mytopic
echo '{"name":"Mark","city":"Park City"}' | kafkacat -P -b localhost:9092 -t mytopic