import boto3

REGION = "us-east-1"


def lambda_handler(event, context):
    ec2 = boto3.client("ec2", region_name=REGION)
    cloudwatch = boto3.client("cloudwatch", region_name=REGION)
    
    response = ec2.describe_instances(
        Filters=[{"Name": "instance-state-name", "Values": ["running"]}]
    )
    
    running_instances = sum([len(reservation["Instances"]) for reservation in response["Reservations"]])
    
    cloudwatch.put_metric_data(
        Namespace="Custom",
        MetricData=[{
            "MetricName": "RunningInstances",
            "Unit": "Count",
            "Value": running_instances
        }]
    )
    
    return {
        "statusCode": 200,
        "body": f"Running instances count: {running_instances}"
    }
