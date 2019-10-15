FROM debian:latest

RUN apt-get update && \
    apt-get install -y curl && \  
    curl -LO https://github.com/kubernetes/kops/releases/download/$(curl -s https://api.github.com/repos/kubernetes/kops/releases/latest | grep tag_name | cut -d '"' -f 4)/kops-linux-amd64 && \
    chmod +x kops-linux-amd64 && \
    mv kops-linux-amd64 /usr/local/bin/kops

# # Install kubectl
# RUN apt-get install -y apt-transport-https && \
#         curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add - && \
#         echo "deb http://apt.kubernetes.io/ kubernetes-xenial main" | tee -a /etc/apt/sources.list.d/kubernetes.list && \
#         apt-get update && \
#         apt-get install -y kubectl


WORKDIR /root

#Copy aws configure parameters to container
COPY ./credentials .
COPY ./config .
COPY ./down_cluster.sh .
RUN chmod 755 ./down_cluster.sh

#Place parameters in the right directory
RUN mkdir ~/.aws && mv ./credentials ~/.aws && mv ./config ~/.aws


ENV BUCKET_NAME=clusters.kops.k8sc
ENV KOPS_STATE_STORE=s3://clusters.kops.k8sc
ENV KOPS_CLUSTER_NAME=aws.cluster.k8s.local


CMD [ "/bin/bash", "-c", "source down_cluster.sh && /bin/bash" ]

#up_cluster.sh && /bin/bashs