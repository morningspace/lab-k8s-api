# Prepare env

[Main Page](../README.md) | [Explore Kubernetes API](explorer-k8s-api.md) »

## Launch kind

To create the kind cluster:
```
kind create cluster --config kind-config.yaml
```

## Deploy sample application

To deploy httpd as a sample application:
```
kubectl create deployment httpd --image=httpd
```

<!--
---
apiVersion: v1
kind: Deployment
metadata:
  labels:
    app: httpd
  name: httpd
spec:
  containers:
  - image: httpd
    name: httpd
    ports:
    - containerPort: 80

To deploy nginx as a sample application:
kubectl create deployment nginx --image=nginx
-->

## Test sample application

To test application connectivity on worker node:
```
CLUSTER_IP=$(kubectl get pod -o wide | grep httpd | awk '{print $6}')
echo $CLUSTER_IP
docker exec kind-worker curl -s $CLUSTER_IP
```

To install curl inside the pod:
```
POD_NAME=$(kubectl get pod -l="app=httpd" -o name)
echo $POD_NAME
kubectl exec $POD_NAME -- apt update
kubectl exec $POD_NAME -- apt install -y curl
```

Then test application connectivity inside pod:
```
kubectl exec $POD_NAME -- curl -s 127.0.0.1
```

To expose the application as a service:
```
kubectl create service nodeport httpd --node-port=31000 --tcp=80:80
kubectl get svc
```

Then test application connectivity on host machine:
```
curl 127.0.0.1:31000
```
