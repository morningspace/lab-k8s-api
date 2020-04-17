# Deploy sample controller

## Install Operator SDK

Run below commands to install Operator SDK to your local machine:
```
RELEASE_VERSION=v0.17.0
curl -LO https://github.com/operator-framework/operator-sdk/releases/download/${RELEASE_VERSION}/operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
chmod +x operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu && sudo mkdir -p $HOME/.local/bin/ && sudo cp operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu $HOME/.local/bin/operator-sdk && rm operator-sdk-${RELEASE_VERSION}-x86_64-linux-gnu
operator-sdk version
```

## Build and deploy the memcached sample operator

Clone the Git repository:
```
git clone https://github.com/operator-framework/operator-sdk-samples.git
cd operator-sdk-samples/go/memcached-operator/
go mod tidy
```

Build the docker image and push to quay.io:
```
docker login quay.io
export IMAGE=quay.io/moyingbj/memcached-operator:v0.0.1
operator-sdk build $IMAGE
docker push $IMAGE
```

Go to quay.io to make your image public.

Deploy the operator:
```
sed -i 's|REPLACE_IMAGE|quay.io/moyingbj/memcached-operator:v0.0.1|g' deploy/operator.yaml
make install
```

Wait for a while and check if the sample operator and its operands have been up and running:
```
kubectl get all -n memcached
```

## Check the actual when deploy

Enable logs when apply the CR for the sample application:
```
kubectl apply -f ./deploy/crds/cache.example.com_v1alpha1_memcached_cr.yaml --v=8
```

Here's an example of how kubectl send the request to API Server behind:
```
I0416 18:45:47.981965   13034 loader.go:375] Config loaded from file:  /home/morningspace/.kube/config
I0416 18:45:47.990393   13034 round_trippers.go:420] GET https://127.0.0.1:32770/openapi/v2?timeout=32s
I0416 18:45:47.990410   13034 round_trippers.go:427] Request Headers:
I0416 18:45:47.990417   13034 round_trippers.go:431]     Accept: application/com.github.proto-openapi.spec.v2@v1.0+protobuf
I0416 18:45:47.990423   13034 round_trippers.go:431]     User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
I0416 18:45:48.014076   13034 round_trippers.go:446] Response Status: 200 OK in 23 milliseconds
I0416 18:45:48.014096   13034 round_trippers.go:449] Response Headers:
I0416 18:45:48.014103   13034 round_trippers.go:452]     Date: Thu, 16 Apr 2020 10:45:48 GMT
I0416 18:45:48.014108   13034 round_trippers.go:452]     Accept-Ranges: bytes
I0416 18:45:48.014113   13034 round_trippers.go:452]     X-Varied-Accept: application/com.github.proto-openapi.spec.v2@v1.0+protobuf
I0416 18:45:48.014121   13034 round_trippers.go:452]     Content-Type: application/octet-stream
I0416 18:45:48.014127   13034 round_trippers.go:452]     Etag: "938117FF173F539C84647E8D84A5478D7A011AE4E9DF94A35686A945932C4DA2CA19AAFC9381CBD76A20CE6DB2795F3C9AF406C181232AA7E22FAA8C0DC47753"
I0416 18:45:48.014136   13034 round_trippers.go:452]     Last-Modified: Thu, 16 Apr 2020 10:31:45 GMT
I0416 18:45:48.014142   13034 round_trippers.go:452]     Vary: Accept-Encoding
I0416 18:45:48.014147   13034 round_trippers.go:452]     Vary: Accept
I0416 18:45:48.160276   13034 request.go:1015] Response Body:
00000000  0a 03 32 2e 30 12 15 0a  0a 4b 75 62 65 72 6e 65  |..2.0....Kuberne|
00000010  74 65 73 12 07 76 31 2e  31 37 2e 30 42 f7 c9 89  |tes..v1.17.0B...|
00000020  01 12 92 27 0a 30 2f 61  70 69 73 2f 6e 65 74 77  |...'.0/apis/netw|
00000030  6f 72 6b 69 6e 67 2e 6b  38 73 2e 69 6f 2f 76 31  |orking.k8s.io/v1|
00000040  2f 77 61 74 63 68 2f 6e  65 74 77 6f 72 6b 70 6f  |/watch/networkpo|
00000050  6c 69 63 69 65 73 12 dd  26 12 d6 04 0a 0d 6e 65  |licies..&.....ne|
00000060  74 77 6f 72 6b 69 6e 67  5f 76 31 1a 79 77 61 74  |tworking_v1.ywat|
00000070  63 68 20 69 6e 64 69 76  69 64 75 61 6c 20 63 68  |ch individual ch|
00000080  61 6e 67 65 73 20 74 6f  20 61 20 6c 69 73 74 20  |anges to a list |
00000090  6f 66 20 4e 65 74 77 6f  72 6b 50 6f 6c 69 63 79  |of NetworkPolicy|
000000a0  2e 20 64 65 70 72 65 63  61 74 65 64 3a 20 75 73  |. deprecated: us|
000000b0  65 20 74 68 65 20 27 77  61 74 63 68 27 20 70 61  |e the 'watch' pa|
000000c0  72 61 6d 65 74 65 72 20  77 69 74 68 20 61 20 6c  |rameter with a  [truncated 14365203 chars]
I0416 18:45:48.215434   13034 round_trippers.go:420] GET https://127.0.0.1:32770/apis/cache.example.com/v1alpha1/namespaces/default/memcacheds/example-memcached
I0416 18:45:48.215464   13034 round_trippers.go:427] Request Headers:
I0416 18:45:48.215472   13034 round_trippers.go:431]     Accept: application/json
I0416 18:45:48.215479   13034 round_trippers.go:431]     User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
I0416 18:45:48.221675   13034 round_trippers.go:446] Response Status: 404 Not Found in 6 milliseconds
I0416 18:45:48.221694   13034 round_trippers.go:449] Response Headers:
I0416 18:45:48.221700   13034 round_trippers.go:452]     Content-Type: application/json
I0416 18:45:48.221706   13034 round_trippers.go:452]     Content-Length: 260
I0416 18:45:48.221711   13034 round_trippers.go:452]     Date: Thu, 16 Apr 2020 10:45:48 GMT
I0416 18:45:48.221734   13034 request.go:1017] Response Body: {"kind":"Status","apiVersion":"v1","metadata":{},"status":"Failure","message":"memcacheds.cache.example.com \"example-memcached\" not found","reason":"NotFound","details":{"name":"example-memcached","group":"cache.example.com","kind":"memcacheds"},"code":404}
I0416 18:45:48.222111   13034 request.go:1017] Request Body: {"apiVersion":"cache.example.com/v1alpha1","kind":"Memcached","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"cache.example.com/v1alpha1\",\"kind\":\"Memcached\",\"metadata\":{\"annotations\":{},\"name\":\"example-memcached\",\"namespace\":\"default\"},\"spec\":{\"size\":3}}\n"},"name":"example-memcached","namespace":"default"},"spec":{"size":3}}
I0416 18:45:48.222147   13034 round_trippers.go:420] POST https://127.0.0.1:32770/apis/cache.example.com/v1alpha1/namespaces/default/memcacheds
I0416 18:45:48.222155   13034 round_trippers.go:427] Request Headers:
I0416 18:45:48.222162   13034 round_trippers.go:431]     Accept: application/json
I0416 18:45:48.222168   13034 round_trippers.go:431]     Content-Type: application/json
I0416 18:45:48.222174   13034 round_trippers.go:431]     User-Agent: kubectl/v1.17.3 (linux/amd64) kubernetes/06ad960
I0416 18:45:48.228949   13034 round_trippers.go:446] Response Status: 201 Created in 6 milliseconds
I0416 18:45:48.228976   13034 round_trippers.go:449] Response Headers:
I0416 18:45:48.228984   13034 round_trippers.go:452]     Content-Type: application/json
I0416 18:45:48.228993   13034 round_trippers.go:452]     Content-Length: 621
I0416 18:45:48.229000   13034 round_trippers.go:452]     Date: Thu, 16 Apr 2020 10:45:48 GMT
I0416 18:45:48.229049   13034 request.go:1017] Response Body: {"apiVersion":"cache.example.com/v1alpha1","kind":"Memcached","metadata":{"annotations":{"kubectl.kubernetes.io/last-applied-configuration":"{\"apiVersion\":\"cache.example.com/v1alpha1\",\"kind\":\"Memcached\",\"metadata\":{\"annotations\":{},\"name\":\"example-memcached\",\"namespace\":\"default\"},\"spec\":{\"size\":3}}\n"},"creationTimestamp":"2020-04-16T10:45:48Z","generation":1,"name":"example-memcached","namespace":"default","resourceVersion":"16599","selfLink":"/apis/cache.example.com/v1alpha1/namespaces/default/memcacheds/example-memcached","uid":"a768fe39-302c-49cf-9487-0b1b469cedc8"},"spec":{"size":3}}
memcached.cache.example.com/example-memcached created
```
