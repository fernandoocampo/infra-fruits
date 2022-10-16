# crossplane

testing crossplane for the fruit project, it contains the crossplane artifacts to build the project infrastructure.

## requirements

1. k8s cluster: minikube or kind (https://kind.sigs.k8s.io)
2. kubectl
3. helm (3)

## Installation

1. brew upgrade
2. brew install kind (or minikube with hyper kit)
3. brew install kubectl
4. brew install helm

kind create cluster --image kindest/node:v1.23.0 --wait 5m

6. kubectl create namespace crossplane-system

7. helm repo add crossplane-stable https://charts.crossplane.io/stable
8. helm repo update

9. helm install crossplane --namespace crossplane-system crossplane-stable/crossplane

```yaml
NAME: crossplane
LAST DEPLOYED: Sun Jul 10 17:53:49 2022
NAMESPACE: crossplane-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
Release: crossplane

Chart Name: crossplane
Chart Description: Crossplane is an open source Kubernetes add-on that enables platform teams to assemble infrastructure from multiple vendors, and expose higher level self-service APIs for application teams to consume.
Chart Version: 1.8.1
Chart Application Version: 1.8.1

Kube Version: v1.23.1
```

10. problem connection refused use this

```log
minikube start --driver=hyperkit
  minikube ssh sudo resolvectl dns eth0 8.8.8.8 8.8.4.4
  minikube ssh sudo resolvectl dns docker0 8.8.8.8 8.8.4.4
  minikube ssh sudo resolvectl dns sit0 8.8.8.8 8.8.4.4
  eval $(minikube -p minikube docker-env)
  docker pull crossplane/crossplane:v1.8.1
```
https://github.com/kubernetes/minikube/issues/13497


```log
sudo resolvectl dns eth0 8.8.8.8 8.8.4.4
sudo resolvectl dns docker0 8.8.8.8 8.8.4.4
sudo resolvectl dns sit0 8.8.8.8 8.8.4.4
  eval $(minikube -p minikube docker-env)
  docker pull crossplane/crossplane:v1.8.1
```

11.
➜  ~ helm list -n crossplane-system
NAME      	NAMESPACE        	REVISION	UPDATED                              	STATUS  	CHART           	APP VERSION
crossplane	crossplane-system	1       	2022-07-10 17:53:49.827497 +0200 CEST	deployed	crossplane-1.8.1	1.8.1

12.
➜  ~ kubectl get all -n crossplane-system
NAME                                           READY   STATUS    RESTARTS   AGE
pod/crossplane-7c88c45998-2qxvm                1/1     Running   0          57m
pod/crossplane-rbac-manager-8466dfb7fc-qm656   1/1     Running   0          57m

NAME                                      READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/crossplane                1/1     1            1           57m
deployment.apps/crossplane-rbac-manager   1/1     1            1           57m

NAME                                                 DESIRED   CURRENT   READY   AGE
replicaset.apps/crossplane-7c88c45998                1         1         1       57m
replicaset.apps/crossplane-rbac-manager-8466dfb7fc   1         1         1       57m

13. install crossplane cli

curl -sL https://raw.githubusercontent.com/crossplane/crossplane/master/install.sh | sh

14. install configuration package, we’ll install the AWS config package

kubectl crossplane install configuration registry.upbound.io/xp/getting-started-with-aws:v1.8.1

15. Get AWS Account Keyfile

```sh
AWS_PROFILE=default && echo -e "[default]\naws_access_key_id = $(aws configure get aws_access_key_id --profile $AWS_PROFILE)\naws_secret_access_key = $(aws configure get aws_secret_access_key --profile $AWS_PROFILE)" > creds.conf
```

16. Create a Provider Secret

```sh
kubectl create secret generic aws-creds -n crossplane-system --from-file=creds=./creds.conf
```

15. add configuration file

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

kubectl apply -f https://raw.githubusercontent.com/crossplane/crossplane/release-1.8/docs/snippets/configure/aws/providerconfig.yaml

16. to connect localstack we must add this entry into the configuration file

https://bytemeta.vip/repo/crossplane/provider-aws/issues/1017
https://github.com/crossplane-contrib/provider-aws/blob/master/examples/providerconfig/localstack.yaml

17. create s3 bucket

https://pet2cattle.com/2022/02/crossplane-aws-provider

```yaml
apiVersion: s3.aws.crossplane.io/v1beta1
kind: Bucket
metadata:
  name: mybucket
  namespace: default
  annotations:
    crossplane.io/external-name: my-bucket-pjrqd-w94db
spec:
  providerConfigRef:
    name: aws-provider
  forProvider:
    locationConstraint: 'eu-west-1'
    acl: private
```


k apply -f s3bucket.yaml
k describe bucket.s3.aws.crossplane.io/mybucket
k delete bucket.s3.aws.crossplane.io/mybucket

kubectl get event --namespace crossplane-system --field-selector involvedObject.name=bucket.s3.aws.crossplane.io/mybucket

18. kind localstack

https://zacharyloeber.com/2020/05/aws-testing-with-localstack-on-kubernetes/

docker run --rm -it --net kind -p 4566:4566 -p 4571:4571 localstack/localstack

get ip address from docker

docker inspect 89bed10decef | grep IPAddress

19. docker network

- to know what network my container is using

docker inspect 92912d795199 -f "{{json .NetworkSettings.Networks }}"

20. check if s3 exists

aws s3api create-bucket --bucket test2 --endpoint=http://localhost:4566 --region us-east-1
aws s3api create-bucket --bucket mybucket --endpoint=http://localhost:4566 --region us-east-1
aws s3api list-buckets --endpoint=http://localhost:4566

aws s3api ls s3://mybucket --recursive | grep your-search | cut -c 32- --endpoint=http://localhost:4566
aws s3api list-objects --bucket=mybucket --endpoint=http://localhost:4566

for an unknown reason if I try to create the s3 bucket with aws cli, it responds

```log
An error occurred (IllegalLocationConstraintException) when calling the CreateBucket operation: The unspecified location constraint is incompatible for the region specific endpoint this request was sent to.
```

temporary solution
Thanks for the quick responses, i changed our tests to use region `us-east-1` with the latest image, which works.

30. crossplane provider doc

https://doc.crds.dev/github.com/crossplane/provider-aws

31. configuration directory

- `crossplane.yaml` - Metadata about the configuration (it seems this one should be at the root level of the directory)
- `definition.yaml` - The XRD.
- `componsition.yaml` - The composition.

see file content on `~/Workspaces/crossplanews/sampletwo`

32. Run the following command

```sh
kubectl crossplane build configuration
# Set this to the Docker Hub username or OCI registry you wish to use.
REG=my-package-repo
kubectl crossplane push configuration ${REG}/getting-started-with-aws:v1.9.0
```

33. get clusters

➜  ~ kind get clusters
kind

34. cluster-info

➜  ~ kubectl cluster-info --context kind-kind
Kubernetes control plane is running at https://127.0.0.1:59524
CoreDNS is running at https://127.0.0.1:59524/api/v1/namespaces/kube-system/services/kube-dns:dns/proxy

To further debug and diagnose cluster problems, use 'kubectl cluster-info dump'.

35. If you lost default kubectl context kind, then use this

➜  ~ k get pods -A
error: You must be logged in to the server (Unauthorized)

kubectl config use-context kind-kind

36. debug aws provider

https://pet2cattle.com/2022/02/debug-crossplane-provider