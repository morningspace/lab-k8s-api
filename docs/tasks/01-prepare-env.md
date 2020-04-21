# Prepare env

[Main Page](../../README.md) | [Explore Kubernetes API](02-explorer-k8s-api.md) »

---

## Launch kind

To create the kind cluster:

```shell
kind create cluster --config kind-config.yaml
```

## Deploy sample application

To deploy httpd as a sample application:

```shell
kubectl create deployment httpd --image=httpd
```
<!--
task::cmd
-->

## Test sample application

To test application connectivity on worker node:

```shell
CLUSTER_IP=$(kubectl get pod -o wide | grep httpd | awk '{print $6}')
echo $CLUSTER_IP
docker exec kind-worker curl -s $CLUSTER_IP
```

To install curl inside the pod:

```shell
POD_NAME=$(kubectl get pod -l="app=httpd" -o name)
echo $POD_NAME
kubectl exec $POD_NAME -- apt update
kubectl exec $POD_NAME -- apt install -y curl
```

Then test application connectivity inside pod:

```shell
kubectl exec $POD_NAME -- curl -s 127.0.0.1
```

To expose the application as a service:

```shell
kubectl create service nodeport httpd --node-port=31000 --tcp=80:80
kubectl get svc
```

Then test application connectivity on host machine:

```shell
curl 127.0.0.1:31000
```
