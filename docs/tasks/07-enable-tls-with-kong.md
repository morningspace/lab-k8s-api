# Enable TLS with Kong

« [Deploy Kong operator](06-deploy-kong-operator.md) | [Main Page](../../README.md) | [Understand what kubectl does behind](08-understand-what-kubectl-does.md) »

---

This is going to enable TLS for Kong for its communication with Kubernetes APIServer as upstream service.

## Create a client certificate for Kong

Generate a key file:

```shell
openssl genrsa -out kong.key 2048
```

Find the master node IP:

```shell
MASTER_IP=$(kubectl get node k8s-kong-lab-control-plane -o jsonpath="{.status.addresses[0].address}")
echo $MASTER_IP
```

Find the ClusterIP for kuberentes service:

```shell
MASTER_CLUSTER_IP=$(kubectl get svc kubernetes -o jsonpath="{.spec.clusterIP}")
echo $MASTER_CLUSTER_IP
```

Create a csr configration file:

```shell
cat samples/kong-csr.conf.tmpl | sed -e "s|{{MASTER_IP}}|$MASTER_IP|g" -e "s|{{MASTER_CLUSTER_IP}}|$MASTER_CLUSTER_IP|g" > kong-csr.conf
cat kong-csr.conf
```

Generate the csr:

```shell
openssl req -new -key kong.key -out kong.csr -config kong-csr.conf
```

Find ca certificate and key from master node:

```shell
docker cp k8s-kong-lab-control-plane:/etc/kubernetes/pki/ca.crt .
docker cp k8s-kong-lab-control-plane:/etc/kubernetes/pki/ca.key .
```

Then, use this csr along with ca certificate and key to generate the certificate for Kong:

```shell
openssl x509 -req -in kong.csr -CA ca.crt -CAkey ca.key -CAcreateserial -out kong.crt -days 10000 -extensions v3_ext -extfile kong-csr.conf
```

## Verify the certificate

Now, you can verify the generated certificate:

```shell
openssl x509  -noout -text -in ./kong.crt
```

Note the `Issuer`, `Subject`, and `Subject Alternative Name` fields.

You can also configure your kubectl to use this certificate to test if the certifcate works.

Get the API Server endpoint for the cluster:

```shell
endpoint=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"kind-k8s-kong-lab\")].cluster.server}")
echo $endpoint
```

Then, let's create a separated kubeconfig as below:

```shell
# kubectl config set-cluster kind-k8s-kong-lab --embed-certs=true --server=$endpoint --certificate-authority=./ca.crt --kubeconfig=kubeconfig
kubectl config set-cluster kind-k8s-kong-lab --server=$endpoint --insecure-skip-tls-verify=true --kubeconfig=kubeconfig
kubectl config set-credentials kong --client-certificate=kong.crt --client-key=kong.key --embed-certs=true --kubeconfig=kubeconfig
kubectl config set-context kind-k8s-kong-lab --cluster=kind-k8s-kong-lab --user=kong --kubeconfig=kubeconfig
kubectl config use-context kind-k8s-kong-lab --kubeconfig=kubeconfig
```

To view the generated kubeconfig:

```shell
cat kubeconfig
```

And try to use this kubeconfig file to run kubectl:

```shell
kubectl get node --kubeconfig kubeconfig
```

## Create secret for Kong certificate

Create a secrete for the generated Kong certificate which will be used by Kong to authenticate itself when it talks to upstream service.

```shell
kubectl delete secret kong-ingress-tls --namespace default
kubectl create secret tls kong-ingress-tls --namespace default --key kong.key --cert kong.crt
```

And to list and view the secret that you generated:

```shell
kubectl get secret
kubectl get secret kong-ingress-tls -o yaml
```

## Configure Kong to use the secret

Add `konghq.com/protocol` annotation to kubernetes service to ensure that Kong will use HTTPs as the protocol to communicate with kubernetes service:

```shell
kubectl annotate svc kubernetes konghq.com/protocol=https --overwrite
```

Add `configuration.konghq.com/client-cert` annotation with the value `kong-ingress-tls` to ask Kong to use the certificate secret when authenticate itself to kubernetes service:

```shell
kubectl annotate svc kubernetes configuration.konghq.com/client-cert=kong-ingress-tls --overwrite
```
<!--
sleep 3
-->

## Test and verify

Now, you should be able to use Kong admin API to check the annotated service.

Get the node port for the Kong admin service:

```shell
ADMIN_NODEPORT=$(kubectl get svc example-kong-kong-admin -o jsonpath="{.spec.ports[0].nodePort}")
echo $ADMIN_NODEPORT
```

Access the admin service on master node to retrieve the service configuration. Notice the protocol field and client_certificate field for the service named as `default.kubernetes.443`:

```shell
docker exec k8s-kong-lab-control-plane curl -k https://127.0.0.1:$ADMIN_NODEPORT/services | jq .
```

To test the connectivity between Kong and Kubernetes APIServer. You need to create the ingress resource for kubernetes service at first:

```shell
cat samples/ingress-kubernetes-api.yaml
kubectl apply -f samples/ingress-kubernetes-api.yaml
```

And, update the Kubernetes API service to enforce its node port to be 32000, so that can be accessed from localhost:
```shell
kubectl patch svc/example-kong-kong-proxy --type='json' -p='[{"op": "replace", "path": "/spec/ports/1/nodePort", "value":32000}]'
```
<!--
sleep 3
-->

Then call Kuberntes API via the HTTPs endpoint exposed by Kong.

```shell
PROXY_HTTPS_NODEPORT=$(kubectl get svc example-kong-kong-proxy -o jsonpath="{.spec.ports[1].nodePort}")
echo $PROXY_HTTPS_NODEPORT
docker exec k8s-kong-lab-control-plane curl -s -i -k https://127.0.0.1:$PROXY_HTTPS_NODEPORT/api
```

Compare the results that you get when call the original Kubernetes APIServer endpoint described in [Explore Kubernetes API](explorer-k8s-api.md). They should be the same.

### Run kubectl against Kong proxy

To generate a new kubeconfig and point to the Kong proxy exposed as a Kubernetes service to localhost via node port:
```shell
cp kubeconfig{,-kong}
kubectl config set-cluster kind-k8s-kong-lab --server=https://127.0.0.1:$PROXY_HTTPS_NODEPORT --insecure-skip-tls-verify=true --kubeconfig=kubeconfig-kong
cat kubeconfig-kong
```

To run kubectl against Kubernetes APIServer without Kong proxy:
```shell
kubectl get node --kubeconfig kubeconfig --v=8
```

To run kubectl against Kubernetes APIServer with Kong proxy:
```shell
kubectl get node --kubeconfig kubeconfig-kong --v=8
```
