# SDTD



### To do first:
Clone the repo and add a file named "credentials" in aws_k8s folder in which you will add the credentials to your AWS account, example:

    [default]
    aws_access_key_id=XXXXXXXXX
    aws_secret_access_key=XXXXXXXXX
After that, change the bucket name in the Dockerfile to a name of your choice.

### Building the image
After building the image, launch :

    docker run -it -p 8001:8001 -p 8080:8080 "dockerimagename"


### Kubernetes Dashboard

To launch the dashboard, you should first redirect the cluster to your localhost by launching:

    kubectl proxy --address='0.0.0.0' --accept-hosts='^*$'
After that, you can visit the dashboard on your browser by hitting the link http://localhost:8001/api/v1/namespaces/kube-system/services/https:kubernetes-dashboard:/proxy/
Use the token provided on the console when building the docker image to login.


