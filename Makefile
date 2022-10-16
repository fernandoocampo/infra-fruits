start: run-localstack

run-localstack:
	docker-compose up --build -d

create-bucket:
	aws s3api create-bucket --bucket function-bucket --endpoint-url http://localhost:4566 --region us-east-1

stop-localstack:
	docker-compose down --volumes

list-sns:
	aws sns list-topics --endpoint-url http://localhost:4566 --region us-east-1

list-sqs:
	aws sqs list-queues --endpoint-url http://localhost:4566 --region us-east-1

list-subscriptions:
	aws sns list-subscriptions --endpoint-url http://localhost:4566 --region us-east-1

list-tables:
	aws dynamodb list-tables --endpoint-url http://localhost:4566 --region us-east-1

list-functions:
	aws lambda list-functions --endpoint-url http://localhost:4566 --region us-east-1

list-buckets:
	aws s3api list-buckets --endpoint-url http://localhost:4566 --region us-east-1

list-bucket-files:
	aws s3 ls s3://function-bucket --recursive --human-readable --summarize --endpoint-url http://localhost:4566 --region us-east-1

list-roles:
	aws iam list-roles --endpoint-url http://localhost:4566 --region us-east-1

scan-fruits:
	aws dynamodb scan --table-name fruits --endpoint-url http://localhost:4566 --region us-east-1

scan-audit-fruits:
	aws dynamodb scan --table-name audit-fruits --endpoint-url http://localhost:4566 --region us-east-1

signal-fruit:
	aws sns publish --topic-arn "arn:aws:sns:us-east-1:000000000000:fruits" --message '{"source_id": "1d952b94-a5db-4d63-a500-b486dd96e8b2","name": "lemon","variety": "lima","price": 2.50}' --endpoint-url http://localhost:4566 --region us-east-1

event-source-mapping:
	aws lambda create-event-source-mapping --function-name gofunction --batch-size 5 --maximum-batching-window-in-seconds 60 --event-source-arn arn:aws:sqs:us-east-1:000000000000:audit-fruits --endpoint-url http://localhost:4566 --region us-east-1

list-event-source:
	aws lambda list-event-source-mappings --function-name gofunction --endpoint-url http://localhost:4566 --region us-east-1

get-topic:
	kubectl get Topic

describe-fruits-topic:
	kubectl describe Topic fruits

get-function:
	kubectl get Function

describe-gofunction:
	kubectl describe Function gofunction

queue-attributes:
	aws sqs get-queue-attributes --queue-url http://localhost:4566/000000000000/audit-fruits --attribute-names All --endpoint-url http://localhost:4566 --region us-east-1

receive-message-from-queue:
	aws sqs receive-message --queue-url http://localhost:4566/000000000000/audit-fruits --attribute-names All --message-attribute-names All --max-number-of-messages 1 --endpoint-url http://localhost:4566 --region us-east-1