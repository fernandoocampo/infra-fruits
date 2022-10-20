# crossplane

testing crossplane for the fruit project, it contains the crossplane artifacts to build the project infrastructure.

## requirements

1. k8s cluster: minikube or kind (https://kind.sigs.k8s.io)
2. kubectl
3. helm (3)

## Installation

1. Follow crossplane [Install & Configure](https://crossplane.io/docs/v1.9/getting-started/install-configure.html) guide.

2. to work with localstack you should add this configuration file when you're setting up the cloud provider.

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