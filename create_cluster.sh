#!/bin/bash

usage(){
  echo "Usage: $0 project_name cluster_name"
  exit 1
}

export PROJECT=$1
export DATABASE_SERVICE_NAME=$2

# OK, let's get redis password
export REDIS_PASSWORD=$(oc get secret -n $PROJECT $DATABASE_SERVICE_NAME -o jsonpath='{.data.database-password}' | base64 -d)

# Create cluster
export REDIS_CLUSTER_CMD=$(oc get pods -l role=master -n $PROJECT -o go-template="{{\"/usr/bin/redis-cli --cluster create\"}}{{range .items}}{{\" \"}}{{.status.podIP}}{{\":6379\"}}{{end}}{{\" --cluster-yes -a $REDIS_PASSWORD\"}}")
echo "Create cluster command: " $REDIS_CLUSTER_CMD
oc exec -n $PROJECT -t ${DATABASE_SERVICE_NAME}-master-0 -c redis-master -- /bin/bash -c "$REDIS_CLUSTER_CMD"
# Create replicas
for NODE in 0 1 2
do
  MASTER_IP=$(oc get pod $DATABASE_SERVICE_NAME-master-${NODE} -n $PROJECT -o go-template='{{.status.podIP}}')
  SLAVE_IP=$(oc get pod $DATABASE_SERVICE_NAME-slave-${NODE} -n $PROJECT -o go-template='{{.status.podIP}}')
  oc exec -n $PROJECT -t ${DATABASE_SERVICE_NAME}-master-${NODE} -c redis-master -- /bin/bash -c "/usr/bin/redis-cli --cluster add-node ${SLAVE_IP}:6379 ${MASTER_IP}:6379 --cluster-slave -a ${REDIS_PASSWORD}"
done
