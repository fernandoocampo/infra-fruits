.PHONY: localstack/start
localstack/start:
	docker-compose up --build -d

.PHONY: localstack/stop
localstack/stop:
	docker-compose down --volumes

.PHONY: s3/list
s3/list:
	aws s3api list-buckets --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: s3/create
s3/create:
	aws s3api create-bucket --bucket function-bucket --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: s3/function-bucket
s3/function-bucket:
	aws s3 ls s3://function-bucket --recursive --human-readable --summarize --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sns/create
sns/create:
	aws sns create-topic --name fruits --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sns/list
sns/list:
	aws sns list-topics --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sns/subscriptions
sns/subscriptions:
	aws sns list-subscriptions --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sns/signal
sns/signal:
	aws sns publish --topic-arn "arn:aws:sns:us-east-1:000000000000:fruits" --message '{"source_id": "1d952b94-a5db-4d63-a500-b486dd96e8b2","name": "lemon-sns","variety": "lima-sns","price": 2.50}' --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sns/subscribe
sns/subscribe:
	aws sns subscribe --topic-arn arn:aws:sns:us-east-1:000000000000:fruits --protocol sqs --notification-endpoint arn:aws:sqs:us-east-1:000000000000:audit-fruits --attributes '{"RawMessageDelivery": "true"}' --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sns/unsubscribe
sns/unsubscribe:
	aws sns unsubscribe --subscription-arn arn:aws:sns:us-east-1:000000000000:fruits:ccb329c0-c8c4-4144-b9e6-58647f146f9a  --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sqs/create
sqs/create:
	aws sqs create-queue --queue-name audit-fruits --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sqs/list
sqs/list:
	aws sqs list-queues --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sqs/attributes
sqs/attributes:
	aws sqs get-queue-attributes --queue-url http://localhost:4566/000000000000/audit-fruits --attribute-names All --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sqs/signal
sqs/signal:
	aws sqs send-message --queue-url http://localhost:4566/000000000000/audit-fruits --message-body '{"source_id": "1d952b94-a5db-4d63-a500-b486dd96e8b2","name": "lemon-sqs","variety": "lima-sqs","price": 2.50}' --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: sqs/get-message
sqs/get-message:
	aws sqs receive-message --queue-url http://localhost:4566/000000000000/audit-fruits --attribute-names All --message-attribute-names All --max-number-of-messages 4 --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: table/list
table/list:
	aws dynamodb list-tables --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: table/scan-fruits
table/scan-fruits:
	aws dynamodb scan --table-name fruits --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: table/create-audit
table/create-audit:
	aws dynamodb create-table \
	--table-name audit-fruits \
	--attribute-definitions AttributeName=id,AttributeType=S \
	--key-schema AttributeName=id,KeyType=HASH \
	--provisioned-throughput ReadCapacityUnits=5,WriteCapacityUnits=5 \
	--endpoint-url http://localhost:4566 --region us-east-1

.PHONY: table/scan-audit
table/scan-audit:
	aws dynamodb scan --table-name audit-fruits --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: lambda/list
lambda/list:
	aws lambda list-functions --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: lambda/source-map
lambda/source-map:
	aws lambda create-event-source-mapping --function-name gofunction --batch-size 5 --maximum-batching-window-in-seconds 60 --event-source-arn arn:aws:sqs:us-east-1:000000000000:audit-fruits --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: lambda/list-source-map
lambda/list-source-map:
	aws lambda list-event-source-mappings --function-name gofunction --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: lambda/list-source-maps
lambda/list-source-maps:
	aws lambda list-event-source-mappings --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: iam/roles
iam/roles:
	aws iam list-roles --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: iam/policies
iam/policies:
	aws iam list-policies --endpoint-url http://localhost:4566 --region us-east-1

.PHONY: k8s/fruits-app
k8s/fruits-app:
	kubectl get pod -l app=fruits

.PHONY: k8s/topic
k8s/topic:
	kubectl get Topic

.PHONY: k8s/desc-fruits-topic
k8s/desc-fruits-topic:
	kubectl describe Topic fruits

.PHONY: k8s/function
k8s/function:
	kubectl get Function

.PHONY: k8s/desc-function
k8s/desc-function:
	kubectl describe Function gofunction

.PHONY: k8s/contexts
k8s/contexts:
	kubectl config get-contexts

.PHONY: k8s/current-context
k8s/current-context:
	kubectl config current-context

.PHONY: k8s/use-kind-context
k8s/use-kind-context:
	kubectl config use-context kind-kind

.PHONY: k8s/grafana
k8s/grafana:
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

.PHONY: flux/monitoring-portforward
flux/monitoring-portforward:
	kubectl -n monitoring port-forward svc/kube-prometheus-stack-grafana 3000:80

.PHONY: flux/fruits-portforward
flux/fruits-portforward:
	kubectl port-forward svc/fruits-service 9090:8080