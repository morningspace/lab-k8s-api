## Prepare env

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
curl -s -X GET $APISERVER/api --header "Authorization: Bearer $TOKEN" --insecure
curl -s -X GET $APISERVER/api/v1/namespaces/default/pods --header "Authorization: Bearer $TOKEN" --insecure
```

## Accessing the API from within a Pod

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
```

Read the ServiceAccount bearer token
```
TOKEN=$(kubectl exec $POD_NAME -- cat ${SERVICEACCOUNT}/token)
```

Reference the internal certificate authority (CA)
```
CACERT=${SERVICEACCOUNT}/ca.crt
```

Explore the API with TOKEN
```
kubectl exec $POD_NAME -- curl -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER_IN_POD}/api
kubectl exec $POD_NAME -- curl -s --cacert ${CACERT} --header "Authorization: Bearer ${TOKEN}" -X GET ${APISERVER_IN_POD}/api/v1/namespaces/default/pods
```
