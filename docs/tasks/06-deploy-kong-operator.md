# Deploy and test Kong operator

« [Deploy two sample controllers with different API groups](05-deploy-sample-controllers.md) | [Main Page](../../README.md) | [Enable TLS with Kong](07-enable-tls-with-kong.md) »

---

## Deploy Kong operator

Clone kong-operator Git repository:

```shell
git clone https://github.com/Kong/kong-operator.git $HOME/kong-operator
cd $HOME/kong-operator
```

Build and push the docker image, then make it publicly available on quay.io:

```shell
operator-sdk build quay.io/moyingbj/kong-operator:v0.2.2
docker push quay.io/moyingbj/kong-operator:v0.2.2
```

Deploy it:

```shell
sed -i 's|kong-docker-kong-operator.bintray.io/kong-operator:v0.0.0|quay.io/moyingbj/kong-operator:v0.2.2|g' deploy/operator.yaml
kubectl create -f deploy/namespace.yaml
kubectl create -f deploy/crds/charts_v1alpha1_kong_crd.yaml
kubectl create -f deploy/service_account.yaml
kubectl create -f deploy/role.yaml
kubectl create -f deploy/role_binding.yaml
kubectl create -f deploy/operator.yaml
```
<!--
task:cmd
-->

## Test Kong

Create a CR to have Kong operator deploy a sample Kong proxy:

```shell
kubectl create -f deploy/crds/charts_v1alpha1_kong_cr.yaml
```

Make sure example kong pod is run and running:

```shell
kubectl get pods -l="helm.sh/chart=kong-1.5.0"
```
<!--
task:cmd
-->

Get the node port of the kong proxy service for HTTP:

```shell
PROXY_HTTP_NODEPORT=$(kubectl get svc example-kong-kong-proxy -o jsonpath="{.spec.ports[0].nodePort}")
echo $PROXY_HTTP_NODEPORT
```

Access the proxy on master node, which returns 404, and this is expected:

```shell
docker exec kind-control-plane curl -s -i http://127.0.0.1:$PROXY_HTTP_NODEPORT
```

Create a sample ingress:

```shell
cd -
cat samples/ingress-demo.yaml
kubectl apply -f samples/ingress-demo.yaml
```

Access the proxy on master node again, which returns 200:

```shell
docker exec kind-control-plane curl -s -i http://127.0.0.1:$PROXY_HTTP_NODEPORT
```

Get the node port for the kong admin service:

```shell
ADMIN_NODEPORT=$(kubectl get svc example-kong-kong-admin -o jsonpath="{.spec.ports[0].nodePort}")
echo $ADMIN_NODEPORT
```

Access the admin service on master node. It will return the entire Kong configuration:

```shell
docker exec kind-control-plane curl -k https://127.0.0.1:$ADMIN_NODEPORT/ | jq .
```
