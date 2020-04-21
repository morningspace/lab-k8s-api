# Deploy two sample controllers with different API groups

« [Deploy sample operator](docs/deploy-sample-operator.md) | [Main Page](../) | [Deploy Kong operator](docs/deploy-kong-operator.md) »

## Deploy the first sample operator, app1-operator

Build and push the docker image, then make it publicly available on quay.io:
```
cd ./app1-operator/
export IMAGE=quay.io/moyingbj/sample-app1:v0.0.1
operator-sdk build $IMAGE
docker push $IMAGE
```

Deploy it:
```
sed -i 's|REPLACE_IMAGE|quay.io/moyingbj/sample-app1:v0.0.1|g' deploy/operator.yaml
make install
```

Check pods are up and running:
```
kubectl get pods --all-namespaces
```

Check CR exists in memcached namespace:
```
kubectl get memcached -n memcached -oyaml
```

## Deploy the second sample operator, app2-operator

Uninstall the first sample operator because both two operators are using the same namespace:
```
make uninstall
```

Build and push the docker image, then make it publicly available on quay.io:
```
cd ../app1-operator/
export IMAGE=quay.io/moyingbj/sample-app2:v0.0.1
operator-sdk build $IMAGE
docker push $IMAGE
```

Deploy it:
```
sed -i 's|REPLACE_IMAGE|quay.io/moyingbj/sample-app2:v0.0.1|g' deploy/operator.yaml
make install
```

Check pods are up and running:
```
kubectl get pods --all-namespaces
```

Check CR exists in memcached namespace:
```
kubectl get memcached -n memcached -oyaml
```
