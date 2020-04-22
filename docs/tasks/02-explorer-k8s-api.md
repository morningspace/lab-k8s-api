# Explore Kubernetes API

« [Prepare env](01-prepare-env.md) | [Main Page](../../README.md) | [Explore Kubernetes Authentication](03-explorer-k8s-auth.md) »

---

## Create role binding for service accounts

```shell
kubectl create clusterrolebinding serviceaccounts-cluster-admin --clusterrole=cluster-admin --group=system:serviceaccounts
```

## Access Kubernetes API directly

Get the API Server endpoint for the cluster:

```shell
APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"kind-k8s-kong-lab\")].cluster.server}")
echo $APISERVER
```

Gets the token value

```shell
TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
echo $TOKEN
```

Explore the API with TOKEN

```shell
curl -i -s -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
curl -i -s -X GET $APISERVER/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" --insecure
curl -s -X GET $APISERVER/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" --insecure | jq .items[].metadata.name
```

## Accessing Kubernetes API from within a Pod

Point to the internal API server hostname

```shell
APISERVER_IN_POD=https://kubernetes.default.svc
echo $APISERVER_IN_POD
```

Path to ServiceAccount token

```shell
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
echo $SERVICEACCOUNT
```

Read this Pod's namespace

```shell
POD_NAME=$(kubectl get pod -l="app=httpd" -o name)
NAMESPACE=$(kubectl exec $POD_NAME -- cat ${SERVICEACCOUNT}/namespace)
echo $NAMESPACE
```

Read the ServiceAccount bearer token

```shell
TOKEN=$(kubectl exec $POD_NAME -- cat ${SERVICEACCOUNT}/token)
echo $TOKEN
```

Reference the internal certificate authority (CA)

```shell
CACERT=${SERVICEACCOUNT}/ca.crt
echo $CACERT
```

Explore the API with TOKEN

```shell
kubectl exec $POD_NAME -- curl -i -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER_IN_POD}/api
kubectl exec $POD_NAME -- curl -i -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER_IN_POD}/api/v1/namespaces/default/pods
```
