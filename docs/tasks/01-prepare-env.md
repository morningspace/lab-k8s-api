# Prepare env

[Main Page](../../README.md) | [Explore Kubernetes API](02-explorer-k8s-api.md) »

---

## Launch kind

Delete existing kind cluster for this lab if there is any:
```shell
kind delete cluster --name k8s-kong-lab
```

Then create a new kind cluster:

```shell
kind create cluster --name k8s-kong-lab --config kind-config.yaml
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
docker exec k8s-kong-lab-worker curl -s $CLUSTER_IP
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

## Install Operator SDK

Run below commands to install Operator SDK to your local machine:

```shell
RELEASE_VERSION=v0.17.0
curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
chmod +x operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
sudo mkdir -p $HOME/.local/bin/
sudo cp operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu $HOME/.local/bin/operator-sdk
rm operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
operator-sdk version
```
