# Put all things together

«  | [Main Page](../../) |  »

Configure Kong to proxy all the request on /apis/cache.example.com to /apis/cache2.example.com.

```
$ echo "
apiVersion: extensions/v1beta1
kind: Ingress
metadata:
  name: demo
spec:
  rules:
  - http:
      paths:
      - path: /apis/cache.example.com
        backend:
          serviceName: kubernetes
          servicePort: 443
" | kubectl apply -f -
ingress.extensions/demo created
```

```
$ echo 'apiVersion: configuration.konghq.com/v1
kind: KongIngress
metadata:
  name: demo-customization
proxy:
  path: /apis/cache2.example.com/' | kubectl apply -f -
kongingress.configuration.konghq.com/demo-customization created
```

Now, let's associate this KongIngress resource to the echo service.
```
$ kubectl patch service kubernetes -p '{"metadata":{"annotations":{"configuration.konghq.com":"demo-customization"}}}'
service/echo patched
```
