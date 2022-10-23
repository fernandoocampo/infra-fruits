# infra-fruits

repository to test different infrastructure trends on [fruits](https://github.com/fernandoocampo/fruits) project.

## Content

* terraform practices `./terraform`.
* crossplane practice `./crossplane`.

## Start Infra with Crossplane and Flux.

1. Start localstack to simulate aws.

```sh
make localstack/start
```

2. Install [kind](https://kind.sigs.k8s.io/docs/user/quick-start/#installation) to run local k8s.

3. Check that we are using the kind cluster.

```sh
➜  infra-fruits git:(main) ✗ make k8s/contexts
```

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

4. Install [Flux v2](https://fluxcd.io/flux/installation/).

5. Install [crossplane](https://crossplane.io/docs/v1.9/getting-started/install-configure.html).

to work with localstack you should add this configuration file when you're setting up the cloud provider.

```yaml
apiVersion: aws.crossplane.io/v1beta1
kind: ProviderConfig
metadata:
  name: default
spec:
  credentials:
    source: Secret
    secretRef:
      namespace: crossplane-system
      name: aws-creds
      key: creds
  endpoint:
    hostnameImmutable: true
    url:
      static: http://localstack:4566
      type: Static
```

6. Once you have set up Flux and Crossplane in Kind cluster, let's start the kind container.


```sh
➜  ~ docker ps -a
CONTAINER ID   IMAGE                          COMMAND                   CREATED         STATUS                     PORTS                                                                NAMES
ad3a9a83d926   kindest/node:v1.23.0           "/usr/local/bin/entr…"    3 months ago    Exited (137) 2 days ago                                                                         kind-control-plane
```

```sh
docker start ad3a9a83d926
```

8. Now let's deploy the lambda function we are going to deploy using Pulumi and jenkins.

* install [Jenkins](https://www.jenkins.io/doc/book/installing/).

9. Install plugin for Go and name it `go1.18` and check `Install automatically`, choosing installer from official go web site.

10. Set up a new pipeline for this github project https://github.com/fernandoocampo/infra-fruits/ .

use this pipeline script

```groovy
pipeline {
    agent any
    tools {
        go 'go1.18'
    }

    stages {
        stage ("Install dependencies") {
            steps {
                sh "curl -fsSL https://get.pulumi.com | sh"
                sh "$HOME/.pulumi/bin/pulumi version"
            }
        }
        stage ("Checkout code") {
            steps {
                git url: "git@github.com:fernandoocampo/infra-fruits.git",
                    // Set your credentials id value here.
                    // See https://jenkins.io/doc/book/using/using-credentials/#adding-new-global-credentials
                    // credentialsId: "yourCredentialsId",
                    // You could define a new stage that specifically runs for, say, feature/* branches
                    // and run only "pulumi preview" for those.
                    branch: "main"
            }
        }
        stage ("list files") {
            steps {
                sh "ls -al"
            }
        }

        stage ("Pulumi up") {
            steps {
                withEnv(["PATH+PULUMI=$HOME/.pulumi/bin"]) {
                    sh "cd pulumi && cd gofunction && make clone"
                    sh "cd pulumi && cd gofunction && make build-lambda"
                    sh "cd pulumi && cd gofunction && pulumi stack select dev"
                    sh "cd pulumi && cd gofunction && pulumi refresh --yes"
                    sh "cd pulumi && cd gofunction && pulumi up --yes"
                }
            }
        }
    }
}
```

11. Run the pipeline to deploy [gofunction](https://github.com/fernandoocampo/gofunction).

It should run without any problems.

12. Let's check all our artifacts got deployed within the cluster.

fruits ecosystem has the following components.

* [fruits](https://github.com/fernandoocampo/fruits) service.

```sh
➜  infra-fruits git:(main) ✗ make k8s/fruits-app
kubectl get pod -l app=fruits
NAME                                 READY   STATUS    RESTARTS      AGE
fruits-deployment-7cdd5b768c-5n6zq   1/1     Running   1 (12m ago)   2d22h
```

* fruits table (`dynamodb`).

```sh
➜  infra-fruits git:(main) ✗ make table/list
{
    "TableNames": [
        "audit-fruits",
        "fruits"
    ]
}
```

* fruits topic (`sns`).

```sh
➜  infra-fruits git:(main) ✗ make sns/list
{
    "Topics": [
        {
            "TopicArn": "arn:aws:sns:us-east-1:000000000000:fruits"
        }
    ]
}
```

* audit-fruits queue (`sqs`).

```sh
➜  infra-fruits git:(main) ✗ make sqs/list
{
    "QueueUrls": [
        "http://localhost:4566/000000000000/audit-fruits",
    ]
}
```

* topic subscriptions

```sh
➜  infra-fruits git:(main) ✗ make sns/subscriptions
{
    "Subscriptions": [
        {
            "SubscriptionArn": "arn:aws:sns:us-east-1:000000000000:fruits:0fd267d5-9535-4ef4-98a2-4ec428594589",
            "Owner": "",
            "Protocol": "sqs",
            "Endpoint": "arn:aws:sqs:us-east-1:000000000000:audit-fruits",
            "TopicArn": "arn:aws:sns:us-east-1:000000000000:fruits"
        }
    ]
}
```

* audit-fruits table (`dynamodb`).

```sh
➜  infra-fruits git:(main) ✗ make table/list
{
    "TableNames": [
        "audit-fruits",
        "fruits"
    ]
}
```

* [gofunction](https://github.com/fernandoocampo/gofunction) lambda.

```sh
➜  infra-fruits git:(main) ✗ make table/scan-fruits
{
    "Functions": [
        {
            "FunctionName": "gofunction-98aa2e3",
            "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:gofunction-98aa2e3",
            "Runtime": "go1.x",
            "Role": "arn:aws:iam::000000000000:role/somerole-08fcf50",
            "Handler": "gofunction-amd64-linux",
            "CodeSize": 7184757,
            "Description": "",
            "Timeout": 3,
            "MemorySize": 128,
            "LastModified": "2022-10-23T19:31:56.004+0000",
            "CodeSha256": "X7Z2Hkra5blb/UvqwtX6Tb6Kaf4wkdPTKLpMFnynBeg=",
            "Version": "$LATEST",
            "VpcConfig": {},
            "Environment": {
                "Variables": {
                    "CLOUD_ENDPOINT_URL": "http://localhost:4566",
                    "CLOUD_REGION": "us-east-1"
                }
            },
            "TracingConfig": {
                "Mode": "PassThrough"
            },
            "RevisionId": "f566553a-9724-4c58-9c6c-e8dd4cb19477",
            "State": "Active",
            "LastUpdateStatus": "Successful",
            "PackageType": "Zip",
            "Architectures": [
                "x86_64"
            ]
        }
    ]
}
```

* lambda subscription to queue.

```sh
➜  infra-fruits git:(main) ✗ make lambda/list-source-maps
{
    "EventSourceMappings": [
        {
            "UUID": "3b586ec3-a463-49f2-a372-d676b69a3f25",
            "StartingPosition": "LATEST",
            "BatchSize": 5,
            "ParallelizationFactor": 1,
            "EventSourceArn": "arn:aws:sqs:us-east-1:000000000000:audit-fruits",
            "FunctionArn": "arn:aws:lambda:us-east-1:000000000000:function:gofunction-98aa2e3",
            "LastModified": "2022-10-23T21:32:04.701341+02:00",
            "LastProcessingResult": "OK",
            "State": "Enabled",
            "StateTransitionReason": "User action",
            "Topics": [],
            "MaximumRetryAttempts": -1
        }
    ]
}
```

13. Monitoring [flux](https://fluxcd.io/flux/guides/monitoring/).

http://localhost:3000/d/flux-cluster/flux-cluster-stats?orgId=1&refresh=30s

14. Test publishing a message into fruits topic.

```sh
➜  infra-fruits git:(main) ✗ make sns/signal
{
    "MessageId": "0b681bb9-4fd1-4e85-90a3-48053554a574"
}
```

Let's see if the message was stored in the `audit-fruits` table.

```sh
➜  infra-fruits git:(main) ✗ make table/scan-audit
{
    "Items": [
        {
            "name": {
                "S": "lemon-sns"
            },
            "source_id": {
                "S": "1d952b94-a5db-4d63-a500-b486dd96e8b2"
            },
            "id": {
                "S": "f2564683-13ab-47cf-9c77-7621edc80c83"
            },
            "variety": {
                "S": "lima-sns"
            },
            "price": {
                "N": "2.5"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
} 
```

15. Now let's create a fruit from fruits application.

* let's create first a port forwarding to `fruits` application.

```sh
➜  infra-fruits git:(main) ✗ make flux/fruits-portforward
kubectl port-forward svc/fruits-service 9090:8080
I1023 22:22:27.846973   50448 request.go:665] Waited for 1.079813318s due to client-side throttling, not priority and fairness, request: GET:https://127.0.0.1:59524/apis/autoscaling/v2?timeout=32s
Forwarding from 127.0.0.1:9090 -> 8080
Forwarding from [::1]:9090 -> 8080
Handling connection for 9090
```

* open your rest client and call the endpoint http://localhost:9090/fruit.

```sh
{
	"name":               "Avocado",
	"variety":             "Green",
	"vault":              "Nicosia",
	"year":              2022,
	"price":							 1.46,
	"country":             "Italy",
	"province":            "Sicily & Sardinia",
	"region":             "Etna",
	"finca":             "Etna",
	"description":         "brisk acidity",
	"classification":         "Premium",
	"local_name":          "avocado",
	"wiki_page": "@kerinokeefe"
}
```

* Check that the new fruit was stored in `fruits` table.

```sh
{
    "Items": [
        {
            "country": {
                "S": "Italy"
            },
            "year": {
                "N": "2022"
            },
            "finca": {
                "S": "Etna"
            },
            "description": {
                "S": "brisk acidity"
            },
            "classification": {
                "S": "Premium"
            },
            "local_name": {
                "S": "avocado"
            },
            "province": {
                "S": "Sicily & Sardinia"
            },
            "variety": {
                "S": "Green"
            },
            "price": {
                "N": "1.46"
            },
            "name": {
                "S": "Avocado"
            },
            "id": {
                "S": "e3a7b54a-2c8e-45c0-aef9-ab68b24ecbff"
            },
            "region": {
                "S": "Etna"
            },
            "vault": {
                "S": "Nicosia"
            },
            "wiki_page": {
                "S": "@kerinokeefe"
            }
        }
    ],
    "Count": 1,
    "ScannedCount": 1,
    "ConsumedCapacity": null
}
```

* Let's see if the message was stored in the `audit-fruits` table.

```sh
➜  infra-fruits git:(main) ✗ make table/scan-audit
   {
    "Items": [
        {
            "name": {
                "S": "lemon-sns"
            },
            "source_id": {
                "S": "1d952b94-a5db-4d63-a500-b486dd96e8b2"
            },
            "id": {
                "S": "f2564683-13ab-47cf-9c77-7621edc80c83"
            },
            "variety": {
                "S": "lima-sns"
            },
            "price": {
                "N": "2.5"
            }
        },
        {
            "name": {
                "S": "Avocado"
            },
            "id": {
                "S": "a27ae48f-2b3f-4b4b-9b6d-de087401d490"
            },
            "source_id": {
                "S": "e3a7b54a-2c8e-45c0-aef9-ab68b24ecbff"
            },
            "variety": {
                "S": "Green"
            },
            "price": {
                "N": "1.46"
            }
        }
    ],
    "Count": 2,
    "ScannedCount": 2,
    "ConsumedCapacity": null
}
```