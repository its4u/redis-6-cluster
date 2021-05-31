#!/bin/bash

export REDIS_PASSWORD=$(oc get secret -n $1 redis -o jsonpath='{.data.database-password}' | base64 -d)
export PROJECT=$1
export DATABASE_SERVICE_NAME=$2

# Create cluster
export REDIS_CLUSTER_CMD=$(oc get pods -l role=master -n $PROJECT -o go-template="{{\"/usr/bin/redis-cli --cluster create\"}}{{range .items}}{{\" \"}}{{.status.podIP}}{{\":6379\"}}{{end}}{{\" --cluster-yes -a $REDIS_PASSWORD\"}}")
oc exec -t ${DATABASE_SERVICE_NAME}-master-0 -n $PROJECT -c redis-master -- /bin/bash -c $REDIS_CLUSTER_CMD
# Create replicas
for NODE in 0 1 2
do
  MASTER_IP=$(oc get pod $DATABASE_SERVICE_NAME-master-${NODE} -n $PROJECT -o go-template='{{.status.podIP}}')
  SLAVE_IP=$(oc get pod $DATABASE_SERVICE_NAME-slave-${NODE} -n $PROJECT -o go-template='{{.status.podIP}}')
  oc exec -t ${DATABASE_SERVICE_NAME}-master-${NODE} -n $PROJECT -c redis-master -- /bin/bash -c "/usr/bin/redis-cli --cluster add-node ${SLAVE_IP}:6379 ${MASTER_IP}:6379 --cluster-slave -a ${REDIS_PASSWORD}"
done
