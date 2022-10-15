# infra-tf-fruits
testing terraform for the fruit project, it contains the terraform artifacts to build the project infrastructure.

## Project structure.

We are going to configure the directory structure based on the technical components of the infrastructure and within each one we are going to organize each application and service that requires these instruments.

```log
infra-tf-fruits
├── README.md
├── main.tf
├── modules
│   ├── messaging
│   │   ├── README.md
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── variables.tf
│   │   └── versions.tf
│   └── storage
│   |   └── README.md
│   │   ├── main.tf
│   │   ├── output.tf
│   │   ├── variables.tf
│   │   └── versions.tf
├── output.tf
├── variables.tf
└── versions.tf
```

## How to test locally?

To test the solution locally, we are mainly using [localstack](https://docs.localstack.cloud/overview/). Below what you need to do to make it work (you can also follow this [tutorial](https://docs.localstack.cloud/integrations/terraform/)).

0. Install terraform as suggested [here](https://learn.hashicorp.com/tutorials/terraform/install-cli). Personally I didn't use `brew` because manual installation is pretty straightforward.

1. specify mock credentials for the aws provider.

./variables.tf
```yml
[default]
aws_access_key_id     = "test"
aws_secret_access_key = "test"
region                = us-east-1
```

2. Second, localstack people say:

> we need to avoid issues with routing and authentication (as we do not need it). Therefore we need to supply some general parameters:

so, in the `versions.tf` file, we are adding this:

```yml
...
provider "aws" {

  access_key = "test"
  secret_key = "test"
  region     = var.aws_region


  # only required for non virtual hosted-style endpoint use case.
  # https://registry.terraform.io/providers/hashicorp/aws/latest/docs#s3_force_path_style
  s3_use_path_style           = true
  skip_credentials_validation = true
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true

  endpoints {
    s3  = "http://s3.localhost.localstack.cloud:4566"
    sns = "http://localhost:4566"
    sqs = "http://localhost:4566"
  }
}
```

3. Run `localstack`.

```sh
docker run --rm -it -p 4566:4566 -p 4571:4571 localstack/localstack
```

4. Go to `./infra/terraform` and run `terraform init`.

> Initializing a configuration directory downloads and installs the providers defined in the configuration, which in this case is the aws provider.

you will see something like this

```log
Terraform has been successfully initialized!

You may now begin working with Terraform. Try running "terraform plan" to see
any changes that are required for your infrastructure. All Terraform commands
should now work.

If you ever set or change modules or backend configuration for Terraform,
rerun this command to reinitialize your working directory. If you forget, other
commands will detect it and remind you to do so if necessary.
```

5. now is the time for the `fmt` command. It is recommended by `terraform` in order to update configurations in the current directory for readability and consistency.

```log
➜  terraform fmt -recursive
main.tf
variables.tf
```

6. Now, let's run the `terraform validate` command.

you will see this:

```log
➜  terraform validate
Success! The configuration is valid.
```

7. Next, run the `terraform plan` command.

```log
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create
...
Plan: 5 to add, 0 to change, 0 to destroy.
```

8. Then, the `terraform apply` to create the infrastructure.

```log
Terraform used the selected providers to generate the following execution plan. Resource actions are indicated with the
following symbols:
  + create
...
Plan: 5 to add, 0 to change, 0 to destroy.

Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes

module.messaging_module.aws_sqs_queue.audit_fruits: Creating...
module.messaging_module.aws_sns_topic.fruits: Creating...
module.messaging_module.aws_sns_topic.fruits: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:fruits]
module.storage_module.aws_dynamodb_table.audit_fruits: Creating...
module.storage_module.aws_dynamodb_table.fruits: Creating...
module.storage_module.aws_dynamodb_table.fruits: Creation complete after 0s [id=fruits]
module.storage_module.aws_dynamodb_table.audit_fruits: Creation complete after 1s [id=audit_fruits]
module.messaging_module.aws_sqs_queue.audit_fruits: Still creating... [10s elapsed]
module.messaging_module.aws_sqs_queue.audit_fruits: Still creating... [20s elapsed]
module.messaging_module.aws_sqs_queue.audit_fruits: Creation complete after 25s [id=http://localhost:4566/000000000000/audit-fruits]
module.messaging_module.aws_sns_topic_subscription.fruits_sqs_audit: Creating...
module.messaging_module.aws_sns_topic_subscription.fruits_sqs_audit: Creation complete after 0s [id=arn:aws:sns:us-east-1:000000000000:fruits:0804b578-5d28-44af-a249-2ca71d9394a7]

Apply complete! Resources: 5 added, 0 changed, 0 destroyed.
```

9. Let's see in `localstack` if the `sns topic` was created.

```log
➜  aws sns list-topics --endpoint-url http://localhost:4566 --region us-east-1

{
    "Topics": [
        {
            "TopicArn": "arn:aws:sns:us-east-1:000000000000:fruits"
        }
    ]
}
```

10. Let's see in `localstack` if the `sqs queue` was created.

```log
➜  aws sqs list-queues --endpoint-url http://localhost:4566 --region us-east-1

{
    "QueueUrls": [
        "http://localhost:4566/000000000000/audit-fruits"
    ]
}
```

11. Let's see in `localstack` if the `sns subscriptions` was created.

```log
aws sns list-subscriptions --endpoint-url http://localhost:4566 --region us-east-1

{
    "Subscriptions": [
        {
            "SubscriptionArn": "arn:aws:sns:us-east-1:000000000000:fruits:0804b578-5d28-44af-a249-2ca71d9394a7",
            "Owner": "",
            "Protocol": "sqs",
            "Endpoint": "arn:aws:sqs:us-east-1:000000000000:audit-fruits",
            "TopicArn": "arn:aws:sns:us-east-1:000000000000:fruits"
        }
    ]
}
```

12. Scan `fruits` table.

```sh
aws dynamodb scan \
--table-name fruits \
--endpoint-url http://localhost:4566 \
--region us-east-1

{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0,
    "ConsumedCapacity": null
}
```

13. Scan `audit_fruits` table.

```sh
aws dynamodb scan \
--table-name audit_fruits \
--endpoint-url http://localhost:4566 \
--region us-east-1

{
    "Items": [],
    "Count": 0,
    "ScannedCount": 0,
    "ConsumedCapacity": null
}
```

12. Finally, just for love at art. the `destroy` command.

```sh
➜  terraform destroy
module.messaging_module.aws_sns_topic.fruits: Refreshing state... [id=arn:aws:sns:us-east-1:000000000000:fruits]
module.messaging_module.aws_sqs_queue.audit_fruits: Refreshing state... [id=http://localhost:4566/000000000000/audit-fruits]
module.messaging_module.aws_sns_topic_subscription.fruits_sqs_audit: Refreshing state... [id=arn:aws:sns:us-east-1:000000000000:fruits:56e743ed-a23f-456a-a651-d6f6e2972546]
...
# module.messaging_module.aws_sns_topic.fruits will be destroyed
...
# module.messaging_module.aws_sns_topic_subscription.fruits_sqs_audit will be destroyed
...
# module.messaging_module.aws_sqs_queue.audit_fruits will be destroyed
...
Plan: 0 to add, 0 to change, 3 to destroy.

Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes

module.storage_module.aws_dynamodb_table.audit_fruits: Destroying... [id=audit_fruits]
module.storage_module.aws_dynamodb_table.fruits: Destroying... [id=fruits]
module.storage_module.aws_dynamodb_table.fruits: Destruction complete after 0s
module.storage_module.aws_dynamodb_table.audit_fruits: Destruction complete after 0s
module.messaging_module.aws_sns_topic_subscription.fruits_sqs_audit: Destroying... [id=arn:aws:sns:us-east-1:000000000000:fruits:0804b578-5d28-44af-a249-2ca71d9394a7]
module.messaging_module.aws_sns_topic_subscription.fruits_sqs_audit: Destruction complete after 1s
module.messaging_module.aws_sqs_queue.audit_fruits: Destroying... [id=http://localhost:4566/000000000000/audit-fruits]
module.messaging_module.aws_sns_topic.fruits: Destroying... [id=arn:aws:sns:us-east-1:000000000000:fruits]
module.messaging_module.aws_sns_topic.fruits: Destruction complete after 0s
module.messaging_module.aws_sqs_queue.audit_fruits: Destruction complete after 1s

Destroy complete! Resources: 5 destroyed
```

checking

```sh
➜  aws sns list-topics --endpoint=http://localhost:4566 --region us-east-1
{
    "Topics": []
}
```