# Redis 6 Cluster on OpenShift

Tested on OCP 4.6/4.7. **Alpha version/quick and dirty solution**. You should use/write an Operator.

This templates generates a 3 masters + 3 replicas redis 6 cluster. It uses official Redis 6 image found on registry.redhat.io. A valid subscription is needed to access this registry and use provided images.

This template requires 6 PersistentVolumes in order to bind automatically created PersistentVolumeClaim.

## Usage
1. Log into your OCP cluster and Switch to openshift project
        oc project openshift
2. Import Red Hat's Redis 6 official image with 
        oc import-image -n openshift rhel8/redis-6:latest --from=registry.redhat.io/rhel8/redis-6 --confirm
3. Import template
        oc create -f redis-6-cluster-template.yml
4. Create a project to host your Redis cluster
        oc new-project redis-cluster
5. Instantiate a cluster
        oc new-app redis-6-cluster -p DATABASE_SERVICE_NAME=redis
Available parameters are:
- DATABASE_SERVICE_NAME is cluster name (default: redis)
- MEMORY_LIMIT is all pod memory limit (default: 512Mi)
- STORAGE_CLASS_NAME is storage class to use (default: ocs-storagecluster-cephfs
- PERSISTENT_SIZE is PV size (default: 1Gi)
- NAMESPACE is the project that hosts redis 6 ImageStream (default: openshift)
- REDIS_PASSWORD is database password (default: generated)
- REDIS_VERSION is image tag to deploy (default: 1-7)
6. Wait for all pods to be ready
7. Launch cluster creation and replication setup by using:
        create_cluster.sh redis-cluster redis
Where redis-cluster is OCP project name and redis is cluster name
