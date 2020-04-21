# Explore Kubernetes Authentication

« [Explore Kubernetes API](02-explorer-k8s-api.md) | [Main Page](../README.md) | [Deploy sample operator](04-deploy-sample-operator.md) »

---

## Using service account token 

Pick up a service account, e.g.:

```shell
service_account=default
```

Get the corresponding secret:

```shell
secret=$(kubectl get sa $service_account -n kube-system -o json | jq -r .secrets[].name)
echo $secret
```

Dump the ca.crt file from the secret:

```shell
kubectl get secret $secret -n kube-system -o json | jq -r '.data["ca.crt"]' | base64 -d > ca.crt
cat ca.crt
```

Dump the token from the secret:

```shell
sa_token=$(kubectl get secret $secret -n kube-system -o json | jq -r '.data["token"]' | base64 -d)
echo $sa_token
```

Get the current kubernetes context:

```shell
context=$(kubectl config current-context)
echo $context
```

Get the cluster name of the current context:

```shell
cluster_name=$(kubectl config get-contexts $context | awk '{print $3}' | tail -n 1)
echo $cluster_name
```

Get the API Server endpoint for the cluster:

```shell
endpoint=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$cluster_name\")].cluster.server}")
echo $endpoint
```

Send a sample request to API Server with the given token:

```shell
curl -k -XGET  -H "Accept: application/json" -H "Authorization: Bearer $sa_token" "$endpoint/api/v1/pods?limit=1"
```

## Understand the client cert using by kubectl

Get the user name being used in the current context:

```shell
user_name=$(kubectl config get-contexts $context | awk '{print $4}' | tail -n 1)
echo $user_name
```

Get the client certificate data for $user_name:

```shell
kubectl config view --raw -o jsonpath="{.users[?(@.name == \"$user_name\")].user.client-certificate-data}" | base64 -d > client.crt
```

Inspect the ca certificate and client certificate:

```shell
openssl x509 -text -noout -in ca.crt
openssl x509 -text -noout -in client.crt
```

Notice the Issuer is `CN=kubernetes`, and for the client certificate, the Subject is `O=system:masters, CN=kubernetes-admin`, where `system:masters` is the group and `kubernetes-admin` is the user.

Group `system:masters` is used in a clusterrolebinding called `cluster-admin` which links to a clusterrole called `cluster-admin` having full privilege to access the cluster:

```shell
kubectl get clusterrolebindings
kubectl get clusterrolebindings cluster-admin -o yaml
kubectl get clusterrole
kubectl get clusterrole cluster-admin -o yaml
```

When we run `kubectl get pods` and enable the verbose logs:

```shell
kubectl get pods --v=10
```

You will see kubectl actually calls the Kuberentes API and the corresponding curl command is as below:

```shell
curl -k -v -XGET  -H "Accept: application/json;as=Table;v=v1beta1;g=meta.k8s.io, application/json" -H "User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960" 'https://127.0.0.1:32770/api/v1/namespaces/default/pods?limit=500'
```

If we get the client certificate data for $user_name:

```shell
kubectl config view --raw -o jsonpath="{.users[?(@.name == \"$user_name\")].user.client-key-data}" | base64 -d > client.key
```

We can run the curl directly to simulate the kubectl call as below:

```shell
curl -k --cert ./client.crt --key ./client.key -XGET -H "Accept: application/json" "$endpoint/api/v1/namespaces/default/pods?limit=500" | jq .
```
