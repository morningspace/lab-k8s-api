# Deploy two sample controllers with different API groups

« [Deploy sample operator](04-deploy-sample-operator.md) | [Main Page](../../README.md) | [Deploy Kong operator](06-deploy-kong-operator.md) »

---

## Deploy the first sample operator, app1-operator

Set your quay.io user name into $QUAY_USER_NAME, then build the docker image and push to quay.io:
<!--
QUAY_USER_NAME=moyingbj
var::set "Input your quay.io user name" "QUAY_USER_NAME"
var::save "QUAY_USER_NAME"
-->

```shell
docker login quay.io
cd ./app1-operator/
export IMAGE=quay.io/$QUAY_USER_NAME/sample-app1:v0.0.1
operator-sdk build $IMAGE
docker push $IMAGE
```

Go to quay.io to make your image public, then deploy it:

```shell
sed -i "s|REPLACE_IMAGE|quay.io/$QUAY_USER_NAME/sample-app1:v0.0.1|g" deploy/operator.yaml
make install
```

Check pods are up and running:

```shell
kubectl get pods --all-namespaces
```
<!--
task::cmd
-->

Check CR exists in memcached namespace:

```shell
kubectl get memcached -n memcached -oyaml
```

## Deploy the second sample operator, app2-operator

Uninstall the first sample operator because both two operators are using the same namespace:

```shell
make uninstall
```

Build the docker image and push to quay.io:

```shell
cd ../app2-operator/
export IMAGE=quay.io/$QUAY_USER_NAME/sample-app2:v0.0.1
operator-sdk build $IMAGE
docker push $IMAGE
```

Go to quay.io to make your image public, then deploy it:

```shell
sed -i "s|REPLACE_IMAGE|quay.io/$QUAY_USER_NAME/sample-app2:v0.0.1|g" deploy/operator.yaml
make install
```

Check pods are up and running:

```shell
kubectl get pods --all-namespaces
```
<!--
task::cmd
-->

Check CR exists in memcached namespace:

```shell
kubectl get memcached -n memcached -oyaml
```
