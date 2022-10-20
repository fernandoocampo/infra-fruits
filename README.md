# infra-fruits

repository to test different infrastructure trends on [fruits](https://github.com/fernandoocampo/fruits) project.

## Content

* terraform practices `./terraform`.
* crossplane practice `./crossplane`.

## Start Infra with Crossplane and Flux.

1. Start localstack.

```sh
make localstack/start
```

the docker-compose descriptor is creating a bucket called `function-bucket`.

2. Go to [gofunction](https://github.com/fernandoocampo/gofunction) project and push zip file into `function-bucket`.

```sh
➜  ~ cd $GOFUNCTION_PROJECT
➜  gofunction git:(main) ✗ make build-and-push
CGO_ENABLED=0 GOOS=linux GOARCH=amd64 go build -o gofunction-amd64-linux -v .
zip gofunction-amd64-linux.zip gofunction-amd64-linux
updating: gofunction-amd64-linux (deflated 51%)
aws s3 cp ./gofunction-amd64-linux.zip s3://function-bucket --endpoint-url http://localhost:4566 --region us-east-1
upload: ./gofunction-amd64-linux.zip to s3://function-bucket/gofunction-amd64-linux.zip
```

3. Check that the file is inside the bucket.

```sh
➜  infra-fruits git:(main) ✗ make s3/function-bucket
aws s3 ls s3://function-bucket --recursive --human-readable --summarize --endpoint-url http://localhost:4566 --region us-east-1
2022-10-18 21:47:55    6.8 MiB gofunction-amd64-linux.zip

Total Objects: 1
   Total Size: 6.8 MiB
```

4. Start Kind cluster.
5. Check that we are using the kind cluster.

I am looking for `kind-kind`. 

```log
CURRENT   NAME                     CLUSTER                  AUTHINFO
*         kind-kind                kind-kind                kind-kind
```

* Set `kind-kind` as the default context.

```sh
➜  infra-fruits git:(main) ✗ make k8s/use-kind-context
kubectl config use-context kind-kind
Switched to context "kind-kind".
```

* verify that `kind-kind` is the current context we are using.
```sh
➜  infra-fruits git:(main) ✗ make k8s/current-context
kubectl config current-context
kind-kind
```

6. Let's check all our artifacts got deployed within the cluster.

fruits ecosystem has the following components.

* [fruits](https://github.com/fernandoocampo/fruits) service.
* fruits table (`dynamodb`).
* [gofunction](https://github.com/fernandoocampo/gofunction) lambda.
* audit-fruits table (`dynamodb`).
* fruits topic (`sns`).
* audit-fruits queue (`sqs`).

