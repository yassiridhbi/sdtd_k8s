#!/bin/bash

#   CLUSTER PARAMETERS #
DEFAULT_ZONE=eu-west-3a,eu-west-3b,eu-west-3c # Must be compliant with the one specified in ~/.aws/config
NODE_SIZE=t2.large
MASTER_SIZE=t2.large
MASTER_VOLUME_SIZE=50
NODE_VOLUME_SIZE=50

# bucket_name=clusters.kops.k8ssdtd34
#
# export KOPS_STATE_STORE=s3://${bucket_name}
# export KOPS_CLUSTER_NAME=aws.cluster.k8s.local

# echo "bucket_name=clusters.kops.k8ssdtd3423" >> ~/.bashrc
# echo "export KOPS_STATE_STORE=s3://\${bucket_name}" >> ~/.bashrc
# echo "export KOPS_CLUSTER_NAME=aws.cluster.k8s.local" >> ~/.bashrc

# Create bucket for cluster
aws s3 mb s3://${bucket_name} --region eu-west-3
aws s3api put-bucket-versioning --bucket ${bucket_name} --versioning-configuration Status=Enabled


# Add ssh to cluster
ssh-keygen -t rsa -N "" -f /root/.ssh/id_rsa

# Create cluster
kops create cluster --zones ${DEFAULT_ZONE} \
                     --node-size=${NODE_SIZE} \
                      --master-count 3 \
                       --node-count 3 \
                        --master-size=${MASTER_SIZE} \
                         --master-volume-size=${MASTER_VOLUME_SIZE} \
                          --node-volume-size=${NODE_VOLUME_SIZE} --yes \
                           --networking kube-router \
                              --name ${KOPS_CLUSTER_NAME} \
                               --dry-run -oyaml > aws_cluster.yaml

kops create -f aws_cluster.yaml
kops create secret --name ${KOPS_CLUSTER_NAME} sshpublickey admin -i ~/.ssh/id_rsa.pub
kops update cluster --yes
until kops validate cluster; do
  echo Validating cluster...
  sleep 10
done

kubectl create -f https://raw.githubusercontent.com/kubernetes/dashboard/master/aio/deploy/recommended/kubernetes-dashboard.yaml

kubectl create serviceaccount cluster-admin-dashboard

until kubectl create clusterrolebinding cluster-admin-dashboard --clusterrole=cluster-admin --serviceaccount=default:cluster-admin-dashboard; do
  sleep 10
done

echo "==============KUBERNETES DASHBOARD TOKEN"
kubectl describe secret $(kubectl -n kube-system get secret | awk '/^cluster-admin-dashboard-token-/{print $1}') | awk '$1=="token:"{print $2}' | head -n 1
echo "==============END======================="

kubectl create -f ~/spark_config/spark-master-controller.yaml
kubectl create -f ~/spark_config/spark-master-service.yaml
kubectl create -f ~/spark_config/spark-worker-controller.yaml
kubectl create -f ~/cassandra_config/cassandra.yaml
kubectl create -f ~/kafka_config/zookeeper_service.yaml
kubectl create -f ~/kafka_config/zookeeper_headless_service.yaml
kubectl create -f ~/kafka_config/zookeeper_statefulset.yaml
kubectl create -f ~/kafka_config/kafka.yaml

echo "WAITING FOR CASSANDRA POD TO GO UP"
CASSANDRA_READY=$(kubectl get pods -n default cassandra-0 -o jsonpath="{.status.phase}");
until [ $CASSANDRA_READY = "Running" ]
do
	sleep 10
	CASSANDRA_READY=$(kubectl get pods -n default cassandra-0 -o jsonpath="{.status.phase}");
done
echo "CASSANDRA POD IS UP"
kubectl cp ~/scripts/ cassandra-0:/scripts/
echo "IMPORTING DATASET TO CASSANDRA"

until kubectl exec -it cassandra-0 -- cqlsh cassandra-0 -f /scripts/cassandra.cql; do
  sleep 10
done

echo "WAITING FOR KAFKA AND ZOOKEEPER PODS TO GO UP"
ZOOKEEPER_READY=$(kubectl get pods -n default kafka-zookeeper-0 -o jsonpath="{.status.phase}");
KAFKA1_READY=$(kubectl get pods -n default kafka-0 -o jsonpath="{.status.phase}");
KAFKA2_READY=$(kubectl get pods -n default kafka-1 -o jsonpath="{.status.phase}");
until [ $ZOOKEEPER_READY = "Running" ] && [ $KAFKA1_READY = "Running" ] && [ $KAFKA2_READY = "Running" ]
do
	sleep 10
  ZOOKEEPER_READY=$(kubectl get pods -n default kafka-zookeeper-0 -o jsonpath="{.status.phase}");
  KAFKA1_READY=$(kubectl get pods -n default kafka-0 -o jsonpath="{.status.phase}");
  KAFKA2_READY=$(kubectl get pods -n default kafka-1 -o jsonpath="{.status.phase}");
done
echo "KAFKA & ZOOKEEPER PODS ARE UP"
kubectl exec -it kafka-0 -- kafka-topics.sh --create --topic id_users --zookeeper kafka-zookeeper.default.svc.cluster.local:2181 --partitions 3 --replication-factor 2
