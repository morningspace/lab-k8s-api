# Enable TLS with Kong

« [Deploy Kong operator](deploy-kong-operator.md) | [Main Page](../README.md) | [Put all things together](put-all-things-together.md) »

This is going to enable TLS for Kong for its communication with Kubernetes APIServer as upstream service.

## Create a client certificate for Kong

Generate a key file:
```
openssl genrsa -out kong.key 2048
```

Find the master node IP:
```
MASTER_IP=$(kubectl get node kind-control-plane -o jsonpath="{.status.addresses[0].address}")
echo $MASTER_IP
```

Find the ClusterIP for kuberentes service:
```
MASTER_CLUSTER_IP=$(kubectl get svc kubernetes -o jsonpath="{.spec.clusterIP}")
echo $MASTER_CLUSTER_IP
```

Create a csr configration file:
```
cat << EOF > kong-csr.conf
[ req ]
default_bits = 2048
prompt = no
default_md = sha256
req_extensions = req_ext
distinguished_name = dn

[ dn ]
O = system:masters
CN = kong

[ req_ext ]
subjectAltName = @alt_names

[ alt_names ]
DNS.1 = kubernetes
DNS.2 = kubernetes.default
DNS.3 = kubernetes.default.svc
DNS.4 = kubernetes.default.svc.cluster
DNS.5 = kubernetes.default.svc.cluster.local
IP.1 = ${MASTER_IP}
IP.2 = ${MASTER_CLUSTER_IP}

[ v3_ext ]
authorityKeyIdentifier=keyid,issuer:always
basicConstraints=CA:FALSE
keyUsage=keyEncipherment,dataEncipherment
extendedKeyUsage=serverAuth,clientAuth
subjectAltName=@alt_names
EOF
```

Generate the csr:
```
openssl req -new -key kong.key -out kong.csr -config kong-csr.conf
```

Find ca certificate and key from master node:
```
docker cp kind-control-plane:/etc/kubernetes/pki/ca.crt .
docker cp kind-control-plane:/etc/kubernetes/pki/ca.key .
```

Then, use this csr along with ca certificate and key to generate the certificate for Kong:
```
openssl x509 -req -in kong.csr -CA ca.crt -CAkey ca.key \
   -CAcreateserial -out kong.crt -days 10000 \
   -extensions v3_ext -extfile kong-csr.conf
```

<!--
openssl req -x509 -nodes -days 365 -newkey rsa:2048 \
    -out kong.crt \
    -keyout kong.key \
    -subj "/CN=kong/O=system:masters"
-->

## Verify the certificate

Now, you can verify the generated certificate:
```
openssl x509  -noout -text -in ./kong.crt
```

Note the `Issuer`, `Subject`, and `Subject Alternative Name` fields.

You can also configure your kubectl to use this certificate to test if the certifcate works.

Get the API Server endpoint for the cluster:
```
endpoint=$(kubectl config view -o jsonpath="{.clusters[?(@.name == \"$cluster_name\")].cluster.server}")
echo $endpoint
```

Then, let's create a separated kubeconfig as below:
```
kubectl config set-cluster kind-kind --embed-certs=true --server=$endpoint --certificate-authority=./ca.crt --kubeconfig=config.kong
kubectl config set-credentials kong --client-certificate=kong.crt --client-key=kong.key --embed-certs=true --kubeconfig=config.kong
kubectl config set-context kind-kind --cluster=kind-kind --user=kong --kubeconfig=config.kong
kubectl config use-context kind-kind --kubeconfig=config.kong
```

To view the generated kubeconfig:
```
cat ~/.kube/config
```

And try to use this kubeconfig file to run kubectl:
```
kubectl get node --kubeconfig config.kong
```

## Create secret for Kong certificate

Create a secrete for the generated Kong certificate which will be used by Kong to authenticate itself when it talks to upstream service.
```
kubectl create secret tls kong-ingress-tls --namespace default --key kong.key --cert kong.crt
```

And to list and view the secret that you generated:
```
kubectl get secret
kubectl get secret kong-ingress-tls -o yaml
```

## Configure Kong to use the secret

Add `konghq.com/protocol` annotation to kubernetes service to ensure that Kong will use HTTPs as the protocol to communicate with kubernetes service:
```
kubectl annotate svc kubernetes konghq.com/protocol=https
```

Add `configuration.konghq.com/client-cert` annotation with the value `kong-ingress-tls` to ask Kong to use the certificate secret when authenticate itself to kubernetes service:
```
kubectl annotate svc kubernetes configuration.konghq.com/client-cert=kong-ingress-tls
```

## Test and verify

Now, you should be able to use Kong admin API to check the annotated service.

Get the node port for the Kong admin service:
```
ADMIN_NODEPORT=$(kubectl get svc example-kong-kong-admin -o jsonpath="{.spec.ports[0].nodePort}")
echo $ADMIN_NODEPORT
```

Access the admin service on master node to retrieve the service configuration. Notice the protocol field and client_certificate field for the service named as `default.kubernetes.443`:
```
docker exec kind-control-plane curl -k https://127.0.0.1:$ADMIN_NODEPORT/services | jq .
```

To test the connectivity between Kong and Kubernetes APIServer. You need to create the ingress resource for kubernetes service at first:
```
cat << EOF | oc apply -f -
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: kubernetes-api
  annotations:
    kubernetes.io/ingress.class: "kong"
    konghq.com/protocols: "https"
spec:
  rules:
  - http:
      paths:
      - path: /api
        backend:
          serviceName: kubernetes
          servicePort: 443
EOF
```

Then call Kuberntes API via the HTTPs endpoint exposed by Kong.
```
PROXY_HTTPS_NODEPORT=$(kubectl get svc example-kong-kong-proxy -o jsonpath="{.spec.ports[1].nodePort}")
echo $PROXY_HTTPS_NODEPORT
docker exec kind-control-plane curl -s -i -k https://127.0.0.1:$PROXY_HTTPS_NODEPORT/api
```

Compare the results that you get when call the original Kubernetes APIServer endpoint described in [Explore Kubernetes API](explorer-k8s-api.md). They should be the same.

<!--

BACKUP
======

kube-apiserver 
--advertise-address=172.17.0.3 
--allow-privileged=true 
--authorization-mode=Node,RBAC 
--client-ca-file=/etc/kubernetes/pki/ca.crt 
--enable-admission-plugins=NodeRestriction 
--enable-bootstrap-token-auth=true 
--etcd-cafile=/etc/kubernetes/pki/etcd/ca.crt -
-etcd-certfile=/etc/kubernetes/pki/apiserver-etcd-client.crt 
--etcd-keyfile=/etc/kubernetes/pki/apiserver-etcd-client.key 
--etcd-servers=https://127.0.0.1:2379 
--insecure-port=0 
--kubelet-client-certificate=/etc/kubernetes/pki/apiserver-kubelet-client.crt 
--kubelet-client-key=/etc/kubernetes/pki/apiserver-kubelet-client.key 
--kubelet-preferred-address-types=InternalIP,ExternalIP,Hostname 
--proxy-client-cert-file=/etc/kubernetes/pki/front-proxy-client.crt 
--proxy-client-key-file=/etc/kubernetes/pki/front-proxy-client.key 
--requestheader-allowed-names=front-proxy-client 
--requestheader-client-ca-file=/etc/kubernetes/pki/front-proxy-ca.crt 
--requestheader-extra-headers-prefix=X-Remote-Extra- 
--requestheader-group-headers=X-Remote-Group 
--requestheader-username-headers=X-Remote-User 
--secure-port=6443 
--service-account-key-file=/etc/kubernetes/pki/sa.pub 
--service-cluster-ip-range=10.96.0.0/12 
--tls-cert-file=/etc/kubernetes/pki/apiserver.crt 
--tls-private-key-file=/etc/kubernetes/pki/apiserver.key

kubectl config set-credentials kong --token=$user_token

-->
