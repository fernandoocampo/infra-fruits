start: run-localstack

run-localstack:
	docker-compose up --build -d

create-bucket:
	aws s3api create-bucket --bucket function-bucket --endpoint-url http://localhost:4566 --region us-east-1

clean-localstack:
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

scan-fruits:
	aws dynamodb scan --table-name fruits --endpoint-url http://localhost:4566 --region us-east-1

scan-audit-fruits:
	aws dynamodb scan --table-name audit_fruits --endpoint-url http://localhost:4566 --region us-east-1

signal-fruit:
	aws sns publish --topic-arn "arn:aws:sns:us-east-1:000000000000:fruits" --message '{"source_id": "1d952b94-a5db-4d63-a500-b486dd96e8b2","name": "lemon","variety": "lima","price": 2.50}' --endpoint-url http://localhost:4566 --region us-east-1

get-topic:
	kubectl get Topic

describe-fruits-topic:
	kubectl describe Topic fruits

get-function:
	kubectl get Function

describe-gofunction:
	kubectl describe Function gofunction