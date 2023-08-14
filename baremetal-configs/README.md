# Baremetal configs

1. Start Kafka
    - Get Zookeeper
    - Create zoo.cfg
    - Launch /bin/zk.Server.sh
    - Get Kafka
    - Create server.properties
    - Launch /bin/kafka-server-start.sh
1. Create topic
1. Start Kafka Connect 
    - Create connect-distributed.properties
    - Launch /bin/connect-distributed.sh
1. Create Timescale database
    - Create database
    - Create hypertable
1. Add JDBC connect worker
    - Download camel-postgresql-sink connector
    - Download postgresql-42.6.0.jar driver
    - Create connector.properties
    - Use REST API to launch worker
1. Create messages onto topic
    - Get Kafkacat
    - Create small JSON file
    - Pipe json file into kafkacat
1. See messages in Timescale using psql

