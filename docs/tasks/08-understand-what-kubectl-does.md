# Understand what kubectl does behind

« [Enable TLS with Kong](07-enable-tls-with-kong.md) | [Main Page](../../README.md) | [Put all things together](09-put-all-things-together.md) »

---

By enabling verbose logs when run kubectl, we will be able to understand how kubectl as client communicates with Kubernetes API Server.

## Apply a customer resource for the first time

Run below command when customer resource does not exist:

```shell
kubectl apply -f app2-operator/deploy/crds/cache2.example.com_v1alpha1_memcached_cr.yaml -n memcached --kubeconfig kubeconfig --v=8
```

You will see logs and by going through the logs, the corresponding requests sent to API Server can be summarized as below:

```
    GET https://127.0.0.1:32000/openapi/v2?timeout=32s
    GET https://127.0.0.1:32000/api?timeout=32s
(1) GET https://127.0.0.1:32000/apis?timeout=32s
    GET https://127.0.0.1:32000/apis/charts.helm.k8s.io/v1alpha1?timeout=32s
    GET https://127.0.0.1:32000/apis/networking.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/policy/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/api/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/rbac.authorization.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/rbac.authorization.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiregistration.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/storage.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiregistration.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/extensions/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/storage.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/admissionregistration.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apps/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/events.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/admissionregistration.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/authentication.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiextensions.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/authentication.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiextensions.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/authorization.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/scheduling.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/authorization.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/scheduling.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/coordination.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/autoscaling/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/node.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/coordination.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/autoscaling/v2beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/autoscaling/v2beta2?timeout=32s
    GET https://127.0.0.1:32000/apis/batch/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/batch/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/certificates.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/networking.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/discovery.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/configuration.konghq.com/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/configuration.konghq.com/v1beta1?timeout=32s
(2) GET https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1?timeout=32s
(3) GET https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds/example-memcached
(4) GET https://127.0.0.1:32000/api/v1/namespaces/memcached
(5) POST https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds
memcached.cache2.example.com/example-memcached created
```

1-2. Look for the target custom resource definition from the available resource definition list.

```
GET https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1?timeout=32s
Request Headers:
    Accept: application/json, */*
    User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
Request Headers:
    Accept: application/json, */*
    User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
Response Status: 200 OK in 20 milliseconds
Response Headers:
    Date: Wed, 22 Apr 2020 01:19:01 GMT
    X-Kong-Upstream-Latency: 17
    X-Kong-Proxy-Latency: 0
    Via: kong/2.0.3
    Content-Type: application/json
    Content-Length: 403
Response Body:
{
  "kind": "APIResourceList",
  "apiVersion": "v1",
  "groupVersion": "cache2.example.com/v1alpha1",
  "resources": [
    {
      "name": "memcacheds",
      "singularName": "memcached",
      "namespaced": true,
      "kind": "Memcached",
      "verbs": [
        "delete",
        "deletecollection",
        "get",
        "list",
        "patch",
        "create",
        "update",
        "watch"
      ],
      "storageVersionHash": "FHjR52TBd/U="
    },
    {
      "name": "memcacheds/status",
      "singularName": "",
      "namespaced": true,
      "kind": "Memcached",
      "verbs": [
        "get",
        "patch",
        "update"
      ]
    }
  ]
}
```

3. Look for the target custom resource under the specified namespace:

```
GET https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds/example-memcached
Request Headers:
    Accept: application/json
    User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
Response Status: 404 Not Found in 3 milliseconds
Response Headers:
    Content-Type: application/json
    Content-Length: 262
    Date: Wed, 22 Apr 2020 06:26:29 GMT
    X-Kong-Upstream-Latency: 2
    X-Kong-Proxy-Latency: 0
    Via: kong/2.0.3
Response Body:
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {
    
  },
  "status": "Failure",
  "message": "memcacheds.cache2.example.com \"example-memcached\" not found",
  "reason": "NotFound",
  "details": {
    "name": "example-memcached",
    "group": "cache2.example.com",
    "kind": "memcacheds"
  },
  "code": 404
}
```

4. Request information for the specified namespace:

```
GET https://127.0.0.1:32000/api/v1/namespaces/memcached
Request Headers:
    Accept: application/json
    User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
Response Status: 200 OK in 3 milliseconds
Response Headers:
    Content-Type: application/json
    Content-Length: 291
    Date: Wed, 22 Apr 2020 06:26:29 GMT
    X-Kong-Upstream-Latency: 3
    X-Kong-Proxy-Latency: 0
    Via: kong/2.0.3
Response Body:
{
  "kind": "Namespace",
  "apiVersion": "v1",
  "metadata": {
    "name": "memcached",
    "selfLink": "/api/v1/namespaces/memcached",
    "uid": "2257c65e-3095-4fd2-bd07-cb4e70f9a5ae",
    "resourceVersion": "1909",
    "creationTimestamp": "2020-04-22T00:10:53Z"
  },
  "spec": {
    "finalizers": [
      "kubernetes"
    ]
  },
  "status": {
    "phase": "Active"
  }
}
```

5. Send POST to create the customer resource because it does not exist.

```
POST https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds
Request Headers:
    Content-Type: application/json
    User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
    Accept: application/json
Request Body:
{
  "apiVersion": "cache2.example.com/v1alpha1",
  "kind": "Memcached",
  "metadata": {
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"cache2.example.com/v1alpha1\",\"kind\":\"Memcached\",\"metadata\":{\"annotations\":{},\"name\":\"example-memcached\",\"namespace\":\"memcached\"},\"spec\":{\"size\":1}}\n"
    },
    "name": "example-memcached",
    "namespace": "memcached"
  },
  "spec": {
    "size": 1
  }
}
Response Status: 201 Created in 7 milliseconds
Response Headers:
    Content-Type: application/json
    Content-Length: 630
    Date: Wed, 22 Apr 2020 06:26:29 GMT
    X-Kong-Upstream-Latency: 6
    X-Kong-Proxy-Latency: 1
    Via: kong/2.0.3
Response Body:
{
  "apiVersion": "cache2.example.com/v1alpha1",
  "kind": "Memcached",
  "metadata": {
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"cache2.example.com/v1alpha1\",\"kind\":\"Memcached\",\"metadata\":{\"annotations\":{},\"name\":\"example-memcached\",\"namespace\":\"memcached\"},\"spec\":{\"size\":1}}\n"
    },
    "creationTimestamp": "2020-04-22T06:26:29Z",
    "generation": 1,
    "name": "example-memcached",
    "namespace": "memcached",
    "resourceVersion": "67949",
    "selfLink": "/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds/example-memcached",
    "uid": "19763a30-29a3-4d89-aa8a-5df71460a0e2"
  },
  "spec": {
    "size": 1
  }
}
```

## Apply a customer resource for the second time

Run below command when customer resource has been applied already:

```shell
kubectl apply -f app2-operator/deploy/crds/cache2.example.com_v1alpha1_memcached_cr.yaml -n memcached --kubeconfig kubeconfig --v=8
```

You will see logs and by going through the logs, the corresponding requests sent to API Server can be summarized as below:

```
    GET https://127.0.0.1:32000/openapi/v2?timeout=32s
    GET https://127.0.0.1:32000/api?timeout=32s
    GET https://127.0.0.1:32000/apis?timeout=32s
    GET https://127.0.0.1:32000/apis/charts.helm.k8s.io/v1alpha1?timeout=32s
    GET https://127.0.0.1:32000/api/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiregistration.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/authentication.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiregistration.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/authentication.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/extensions/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/authorization.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apps/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/authorization.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/admissionregistration.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/admissionregistration.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/autoscaling/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiextensions.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/autoscaling/v2beta2?timeout=32s
    GET https://127.0.0.1:32000/apis/batch/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/apiextensions.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/batch/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/scheduling.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/certificates.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/scheduling.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/networking.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/coordination.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/networking.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/policy/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/rbac.authorization.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/rbac.authorization.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/storage.k8s.io/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/storage.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/coordination.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/node.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/discovery.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/configuration.konghq.com/v1?timeout=32s
    GET https://127.0.0.1:32000/apis/configuration.konghq.com/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1?timeout=32s
    GET https://127.0.0.1:32000/apis/events.k8s.io/v1beta1?timeout=32s
    GET https://127.0.0.1:32000/apis/autoscaling/v2beta1?timeout=32s
(1) GET https://127.0.0.1:32000/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds/example-memcached
    memcached.cache2.example.com/example-memcached unchanged
```

1. Found the custom resource, so no need to create it again:

```
GET https://0.0.0.0:6443/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds/example-memcached
Request Headers:
    Accept: application/json
    User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
Response Status: 200 OK in 2 milliseconds
Response Headers:
    Content-Type: application/json
    Content-Length: 688
    Date: Wed, 22 Apr 2020 07:37:05 GMT
Response Body:
{
  "apiVersion": "cache2.example.com/v1alpha1",
  "kind": "Memcached",
  "metadata": {
    "annotations": {
      "kubectl.kubernetes.io/last-applied-configuration": "{\"apiVersion\":\"cache2.example.com/v1alpha1\",\"kind\":\"Memcached\",\"metadata\":{\"annotations\":{},\"name\":\"example-memcached\",\"namespace\":\"memcached\"},\"spec\":{\"size\":1}}\n"
    },
    "creationTimestamp": "2020-04-22T00:10:55Z",
    "generation": 1,
    "name": "example-memcached",
    "namespace": "memcached",
    "resourceVersion": "1986",
    "selfLink": "/apis/cache2.example.com/v1alpha1/namespaces/memcached/memcacheds/example-memcached",
    "uid": "f032f1e4-e9c7-4618-9c44-5b61ab003f56"
  },
  "spec": {
    "size": 1
  },
  "status": {
    "nodes": [
      "example-memcached-7c4df9b7b4-w5677"
    ]
  }
}
```
