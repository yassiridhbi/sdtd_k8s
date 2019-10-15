FROM yassidhbi/awskubectl:latest

#Copy aws configure parameters to container
COPY ./credentials .
COPY ./config .
COPY ./up_cluster.sh .
COPY ./spark_config ./spark_config
COPY ./cassandra_config ./cassandra_config
COPY ./kafka_config ./kafka_config
COPY ./scripts ./scripts
COPY ./app ./app

ARG bucket_name=clusters.kops.k8ssdtd34
ENV KOPS_STATE_STORE=s3://${bucket_name}
ENV KOPS_CLUSTER_NAME=aws.cluster.k8s.local

RUN chmod 755 ./up_cluster.sh

#Place parameters in the right directory
RUN mkdir ~/.aws && mv ./credentials ~/.aws && mv ./config ~/.aws && mv ./spark_config/ ~/spark_config/ && mv ./cassandra_config/ ~/cassandra_config/ && mv ./kafka_config/ ~/kafka_config/ && mv ./scripts/ ~/scripts/

RUN ls ~/spark_config

RUN dos2unix /up_cluster.sh && /up_cluster.sh



#up_cluster.sh && /bin/bashs

EXPOSE 8001 8080
