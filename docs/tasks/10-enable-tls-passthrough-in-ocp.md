# Enable TLS Passthrough in OCP

« [Deploy Kong operator](06-deploy-kong-operator.md) | [Main Page](../../README.md) »

---

## Deploy Kong operator

Follow the same steps from task 06 to deploy Kong operator to OCP.
<!--
task::cmd
-->

## Create CR

Create a CR to let Kong operator deploy a sample Kong proxy:
(Before this, you can edit the charts_v1alpha1_kong_cr.yaml to enable Kong admin.)

Set the $KONG_NAMESPACE to the namespace of your deployed kong operator.

```shell
KONG_NAMESPACE=kong
oc adm policy add-scc-to-group anyuid system:serviceaccounts:${KONG_NAMESPACE}
kubectl create -f deploy/crds/charts_v1alpha1_kong_cr.yaml --namespace=${KONG_NAMESPACE}
```

Make sure example kong pod is run and running:

```shell
kubectl -n ${KONG_NAMESPACE} get pods -l="helm.sh/chart=kong-1.5.0"
```
<!--
task::cmd
-->

Get the node port of the kong proxy service for HTTP:

```shell
PROXY_HTTP_NODEPORT=$(kubectl get -n ${KONG_NAMESPACE} svc example-kong-kong-proxy -o jsonpath="{.spec.ports[0].nodePort}")
echo $PROXY_HTTP_NODEPORT
```

To test Connectivity to Kong, set the IP of master node to $MASTER_IP, then making a request to Kong. "HTTP 404 Not Found" is expected:

```shell
curl -i http://$MASTER_IP:$PROXY_HTTP_NODEPORT
```

## Configure Kong for new ports

Edit the CR instance of kong, and add the following configurations to the proxy section.

```shell
kubectl -n ${KONG_NAMESPACE} edit kong example-kong
```

```
      stream:
      - containerPort: 9000
        servicePort: 9000
      - containerPort: 9443
        parameters:
        - ssl
        servicePort: 9443
```


Get the node port of the kong proxy service for TCP stream:

```shell
PROXY_TCP_NODEPORT=$(kubectl get -n ${KONG_NAMESPACE} svc example-kong-kong-proxy -o jsonpath="{.spec.ports[?(@.name == \"stream-9000\"].nodePort}")
echo $PROXY_TCP_NODEPORT
```

## TCP port based routing

Create the following TCPIngress resource into default namespace (the same namespace as service kubernetes):

```shell
echo "apiVersion: configuration.konghq.com/v1beta1
kind: TCPIngress
metadata:
  name: kube-tcpingress
spec:
  rules:
  - port: 9000
    backend:
      serviceName: kubernetes
      servicePort: 80
" | kubectl apply -f -
```

Send a request to the TCP stream port, to quickly verify the TCPIngress. It is expected that the API server responses with "Forbidden". 

```shell
curl -ikX GET "https://$MASTER_IP:PROXY_TCP_NODEPORT/api/v1/namespaces/default/pods?limit=500"
```

Create a Route to the TCPIngress, set the $ROUTE_HOSTNAME to one that can be resolved by DNS.

```shell
echo "apiVersion: route.openshift.io/v1
kind: Route
metadata:
  name: api-proxy
  namespace: kong
spec:
  host: ${ROUTE_HOSTNAME}
  port:
    targetPort: stream-9000
  tls:
    insecureEdgeTerminationPolicy: Redirect
    termination: passthrough
  to:
    kind: Service
    name: example-kong-kong-proxy
    weight: 100
  wildcardPolicy: None
" | kubectl -n ${KONG_NAMESPACE} apply -f -
```

Send a request to $ROUTE_HOSTNAME, to quickly verify the TCPIngress. It is expected that the API server responses with "Forbidden". 

```shell
curl -ikX GET "https://${ROUTE_HOSTNAME}/api/v1/namespaces/default/pods?limit=500"
```

Update kubeconfig to change the server to $ROUTE_HOSTNAME.
