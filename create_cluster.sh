#!/bin/bash

usage(){
  echo "Usage: $0 project_name cluster_name"
  exit 1
}

export PROJECT=$1
export DATABASE_SERVICE_NAME=$2

# OK, let's get redis password
export REDIS_PASSWORD=$(oc get secret -n $PROJECT $DATABASE_SERVICE_NAME -o jsonpath='{.data.database-password}' | base64 -d)

# Reset cluster state
for NODE in $(oc get pods -l app=$DATABASE_SERVICE_NAME -o go-template="{{range .items}}{{.metadata.name}}{{\" \"}}{{end}}")
do
  echo "Reset pod $NODE"
  oc exec -n $PROJECT -t ${NODE} -c redis -- /bin/bash -c "/usr/bin/redis-cli -c -a ${REDIS_PASSWORD} flushall"
  oc exec -n $PROJECT -t ${NODE} -c redis -- /bin/bash -c "/usr/bin/redis-cli -c -a ${REDIS_PASSWORD} cluster reset"
done

# Create cluster
export INITIAL_MASTER_NODE=$(oc get pods -n $PROJECT -l app=$DATABASE_SERVICE_NAME -o go-template='{{range .items}}{{.metadata.name}}{{" "}}{{ .status.podIP}}{{":6379\n"}}{{end}}' | awk 'BEGIN { ORS=" " }; /-0/{print $2}')
export REDIS_CLUSTER_CMD="/usr/bin/redis-cli --cluster create $INITIAL_MASTER_NODE --cluster-yes -a $REDIS_PASSWORD"
echo "Create cluster command: " $REDIS_CLUSTER_CMD
oc exec -n $PROJECT -t ${DATABASE_SERVICE_NAME}-shard-a-0 -c redis -- /bin/bash -c "$REDIS_CLUSTER_CMD"
# Create replicas
for SHARD in a b c
do
  MASTER_IP=$(oc get pod $DATABASE_SERVICE_NAME-shard-${SHARD}-0 -n $PROJECT -o go-template='{{.status.podIP}}')
  SLAVE_IP=$(oc get pod $DATABASE_SERVICE_NAME-shard-${SHARD}-1 -n $PROJECT -o go-template='{{.status.podIP}}')
  oc exec -n $PROJECT -t ${DATABASE_SERVICE_NAME}-shard-${SHARD}-0 -c redis -- /bin/bash -c "/usr/bin/redis-cli --cluster add-node ${SLAVE_IP}:6379 ${MASTER_IP}:6379 --cluster-slave -a ${REDIS_PASSWORD}"
done
