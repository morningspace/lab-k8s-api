# SandBox: Play with Kong and Kubernetes APIs

## Goal

We have two operators which have some differences for their APIs, e.g. the API Group is different. We want to leverage Kong and Kong ingress controller to make the data transformation at server side to mitigate these difference so that client does not to change their calls made to Kubernetes even the operator behind is changed.


## Scenario

There are two operators: app1-operator vs. app2-operator, having different API groups, cache.example.com vs. cache2.example.com. Both will be deployed in kind along with Kong operator.

Deploy app1-operator first, then have client make the call to create a customer resource: Memcached, using API group cache.example.com.

Uninstall app1-operator, and install app2-operator, then have client make the same call using the same API group. It will still work even the operator at backend has been changed to use different API group.

![](architecture.png)

## Tasks

* [x] [Prepare env](docs/prepare-env.md)
* [x] [Explore Kubernetes API](docs/explorer-k8s-api.md)
* [x] [Deploy sample operator](docs/deploy-sample-operator.md)
* [x] [Deploy two sample controllers with different API groups](docs/deploy-sample-controllers.md)
* [x] [Deploy Kong operator](docs/deploy-kong-operator.md)
* [ ] [Enable TLS with Kong](docs/enable-tls-with-kong.md)
* [ ] [Put all things together](docs/put-all-things-together.md)
