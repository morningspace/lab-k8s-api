# Explore Kubernetes API

## Create role binding for service accounts

```
kubectl create clusterrolebinding serviceaccounts-cluster-admin \
  --clusterrole=cluster-admin \
  --group=system:serviceaccounts
```

<!--
---
kind: ClusterRoleBinding
apiVersion: rbac.authorization.k8s.io/v1beta1
metadata:
  name: cluster-admin-role-binding
subjects:
  - kind: ServiceAccount
    name: default
    namespace: default
roleRef:
  kind: ClusterRole
  name: cluster-admin
  apiGroup: rbac.authorization.k8s.io
-->

## Access Kubernetes API directly

Check all possible clusters, as your .KUBECONFIG may have multiple contexts:
```
kubectl config view -o jsonpath='{"Cluster name\tServer\n"}{range .clusters[*]}{.name}{"\t"}{.cluster.server}{"\n"}{end}'
```

Select name of cluster you want to interact with from above output.
<!--
prompt "Input the cluster name" CLUSTER_NAME
-->

Point to the API server referring the cluster name
```
APISERVER=$(kubectl config view -o jsonpath="{.clusters[?(@.name==\"$CLUSTER_NAME\")].cluster.server}")
echo $APISERVER
```

Gets the token value
```
TOKEN=$(kubectl get secrets -o jsonpath="{.items[?(@.metadata.annotations['kubernetes\.io/service-account\.name']=='default')].data.token}"|base64 --decode)
echo $TOKEN
```

Explore the API with TOKEN
```
curl -i -s -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
curl -i -s -X GET $APISERVER/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" --insecure
curl -s -X GET $APISERVER/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" --insecure
curl -s -X GET $APISERVER/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" --insecure | jq .items[].metadata.name
```

## Accessing Kubernetes API from within a Pod

Point to the internal API server hostname
```
APISERVER_IN_POD=https://kubernetes.default.svc
echo $APISERVER_IN_POD
```

Path to ServiceAccount token
```
SERVICEACCOUNT=/var/run/secrets/kubernetes.io/serviceaccount
echo $SERVICEACCOUNT
```

Read this Pod's namespace
```
NAMESPACE=$(kubectl exec $POD_NAME -- cat ${SERVICEACCOUNT}/namespace)
echo $NAMESPACE
```

Read the ServiceAccount bearer token
```
TOKEN=$(kubectl exec $POD_NAME -- cat ${SERVICEACCOUNT}/token)
echo $TOKEN
```

Reference the internal certificate authority (CA)
```
CACERT=${SERVICEACCOUNT}/ca.crt
echo $CACERT
```

Explore the API with TOKEN
```
kubectl exec $POD_NAME -- curl -i -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER_IN_POD}/api
kubectl exec $POD_NAME -- curl -i -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER_IN_POD}/api/v1/namespaces/default/pods
```
