import boto3
import os

def lambda_handler(event, context):
    client = boto3.client(service_name='ce', region_name='us-east-1')
    
    response = client.get_cost_and_usage(
        TimePeriod={
            'Start': os.environ['DATE_START'],
            'End': os.environ['DATE_END']
        },
        Granularity='MONTHLY',
        Metrics=[
            'AmortizedCost',
            ]
    )

    print(response)