package main

import (
	"fmt"

	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/iam"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/lambda"
	"github.com/pulumi/pulumi-aws/sdk/v5/go/aws/sqs"
	"github.com/pulumi/pulumi/sdk/v3/go/pulumi"
)

func main() {
	pulumi.Run(func(ctx *pulumi.Context) error {
		// Create an IAM role.
		role, err := iam.NewRole(ctx, "somerole", &iam.RoleArgs{
			AssumeRolePolicy: pulumi.String(`{
				"Version": "2012-10-17",
				"Statement": [{
					"Sid": "",
					"Effect": "Allow",
					"Principal": {
						"Service": "lambda.amazonaws.com"
					},
					"Action": "sts:AssumeRole"
				}]
			}`),
		})
		if err != nil {
			return err
		}

		// Attach a policy to allow writing logs to CloudWatch
		logPolicy, err := iam.NewRolePolicy(ctx, "lambda-log-policy", &iam.RolePolicyArgs{
			Role: role.Name,
			Policy: pulumi.String(`{
                "Version": "2012-10-17",
                "Statement": [{
                    "Effect": "Allow",
                    "Action": [
                        "logs:CreateLogGroup",
                        "logs:CreateLogStream",
                        "logs:PutLogEvents"
                    ],
                    "Resource": "arn:aws:logs:*:*:*"
                }]
            }`),
		})
		if err != nil {
			return err
		}

		// Set arguments for constructing the function resource.
		args := &lambda.FunctionArgs{
			Handler: pulumi.String("gofunction-amd64-linux"),
			Role:    role.Arn,
			Environment: &lambda.FunctionEnvironmentArgs{
				Variables: pulumi.StringMap{
					"CLOUD_REGION":       pulumi.String("us-east-1"),
					"CLOUD_ENDPOINT_URL": pulumi.String("http://localhost:4566"),
				},
			},
			PackageType: pulumi.String("Zip"),
			Runtime:     pulumi.String("go1.x"),
			Code:        pulumi.NewFileArchive("./gofunction/gofunction-amd64-linux.zip"),
		}

		// Create the lambda using the args.
		function, err := lambda.NewFunction(
			ctx,
			"gofunction",
			args,
			pulumi.DependsOn([]pulumi.Resource{logPolicy}),
		)
		if err != nil {
			return err
		}

		result, err := sqs.LookupQueue(ctx, &sqs.LookupQueueArgs{
			Name: "audit-fruits",
		}, nil)
		if err != nil {
			return err
		}
		if result.Arn == "" {
			return fmt.Errorf("queue was not found")
		}

		eventSourceMapping, err := lambda.NewEventSourceMapping(ctx, "gofunction-event-sourcing-map", &lambda.EventSourceMappingArgs{
			EventSourceArn:                 pulumi.String(result.Arn),
			FunctionName:                   function.Arn,
			BatchSize:                      pulumi.Int(5),
			MaximumBatchingWindowInSeconds: pulumi.Int(60),
		})
		if err != nil {
			return err
		}

		// Export the lambda ARN.
		ctx.Export("lambda", function.Arn)
		ctx.Export("source-mapping", eventSourceMapping.EventSourceArn)

		return nil
	})
}
