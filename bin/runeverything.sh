#!/bin/sh
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

stopeverything() {
  trap - INT

  echo "Stopping ZoooKeeper.."
  ZOO_LOG_DIR="$ZOO_LOG_DIR" $ZOO_BIN/zkServer.sh stop "$PWD/$ZK_CFGFILE"

  echo "Stopping Kafka.."
  LOG_DIR="$KF_LOG_DIR" $KF_BIN/kafka-server-stop.sh "$PWD/$KF_CFGFILE" 2>/dev/null

  SPARK_LOG_DIR="$SPARK_LOG_DIR" /usr/local/lib/spark/sbin/stop-master.sh

  sleep 10
  killall -9 java 2>/dev/null

  echo "Still running (if any)"
  jps
}

trap stopeverything INT

sudo mkdir -p /var/zookeeper
sudo mkdir -p /var/kafka

sudo chown vagrant:vagrant /var/zookeeper
sudo chown vagrant:vagrant /var/kafka

echo "Starting ZoooKeeper.."

ZOO_BIN='/usr/local/lib/zookeeper/bin'
ZOO_LOG_DIR='/var/zookeeper/1'
ZK_CFGFILE='zoo1.cfg'

mkdir -p "$ZOO_LOG_DIR"

ZOO_LOG_DIR="$ZOO_LOG_DIR" $ZOO_BIN/zkServer.sh start "$PWD/$ZK_CFGFILE"

echo "Starting Kafka.."

KF_BIN='/usr/local/lib/kafka/bin'
KF_DATA_DIR='/var/kafka/1/data'
KF_LOG_DIR='/var/kafka/1/logs'
KF_CFGFILE='kafka1.properties'

mkdir -p /tmp/kafka/1/{data,logs}

LOG_DIR="$KF_LOG_DIR" $KF_BIN/kafka-server-start.sh -daemon "$PWD/$KF_CFGFILE"

#wait for kafka to come alive
sleep 10

echo "Create Kafka topic $KF_TOPIC_NAME.."

KF_TOPIC_NAME="expense.reports"
LOG_DIR="$KF_LOG_DIR" $KF_BIN/kafka-topics.sh \
  --zookeeper node1:2181/expensekafka \
  --create --topic "$KF_TOPIC_NAME" \
  --replication-factor 1 \
  --partitions 1

LOG_DIR="$KF_LOG_DIR" $KF_BIN/kafka-topics.sh \
    --zookeeper node1:2181/expensekafka \
    --create --topic "expense.counts" \
    --replication-factor 1 \
    --partitions 1

echo "Starting Spark.."
SPARK_SBIN="/usr/local/lib/spark/sbin"
SPARK_LOG_DIR=/tmp/spark-log

SPARK_LOG_DIR="$SPARK_LOG_DIR" $SPARK_SBIN/start-master.sh
SPARK_LOG_DIR="$SPARK_LOG_DIR" \
  SPARK_WORKER_DIR="/tmp/spark-work" \
  $SPARK_SBIN/start-slave.sh worker1 spark://node1:7077

sleep 5

printf "${GREEN}Everything is ready${NC} ..\n===================================\n"
jps

echo "Waiting for messages to kafka topic $KF_TOPIC_NAME."
LOG_DIR="$KF_LOG_DIR" $KF_BIN/kafka-simple-consumer-shell.sh \
  --topic "$KF_TOPIC_NAME" \
  --broker-list "node1:9092" \
  --offset -1 \
  --partition 0

#test
#kafka-console-producer.sh --topic "expense.reports" --broker-list node1:9092

stopeverything
