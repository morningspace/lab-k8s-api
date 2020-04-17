# Deploy and test Kong operator


## Deploy Kong operator

Clone kong-operator Git repository:
```
git clone https://github.com/Kong/kong-operator.git
```

Build and push the docker image, then make it publicly available on quay.io:
```
operator-sdk build quay.io/moyingbj/kong-operator:v0.2.2
docker push quay.io/moyingbj/kong-operator:v0.2.2
```

Deploy it:
```
sed -i 's|kong-docker-kong-operator.bintray.io/kong-operator:v0.0.0|quay.io/moyingbj/kong-operator:v0.2.2|g' deploy/operator.yaml
kubectl create -f deploy/namespace.yaml
kubectl create -f deploy/crds/charts_v1alpha1_kong_crd.yaml
kubectl create -f deploy/service_account.yaml
kubectl create -f deploy/role.yaml
kubectl create -f deploy/role_binding.yaml
kubectl create -f deploy/operator.yaml
kubectl create -f deploy/crds/charts_v1alpha1_kong_cr.yaml
```

## Test Kong

Create a CR to have Kong operator deploy a sample Kong proxy:
```
kubectl create -f deploy/crds/charts_v1alpha1_kong_crd.yaml
```

Make sure example kong pod is run and running:
```
kubectl get pods -l="helm.sh/chart=kong-1.5.0"
```

Get the node port of the kong proxy service for HTTP:
```
PROXY_HTTP_NODEPORT=$(kubectl get svc example-kong-kong-proxy -o jsonpath="{.spec.ports[0].nodePort}")
echo $PROXY_HTTP_NODEPORT
```

Access the proxy on master node, which returns 404, and this is expected:
```
docker exec kind-control-plane curl -s -i http://127.0.0.1:$PROXY_HTTP_NODEPORT
```

Create a sample ingress:
```
echo "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: demo
spec:
  rules:
  - http:
      paths:
      - path: /
        backend:
          serviceName: httpd
          servicePort: 80
" | kubectl apply -f -
```

Access the proxy on master node again, which returns 200:
```
docker exec kind-control-plane curl -s -i http://127.0.0.1:$PROXY_HTTP_NODEPORT
```
