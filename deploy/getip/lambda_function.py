import json
import logging
import boto3
import os
import sys

def lambda_handler(event, context):
    logger          = logging.getLogger()
    client          = boto3.client('ec2')
    r53_client      = boto3.client('route53')
    hosted_zone_id  = os.environ.get('ZONE_ID')
    vpc_id          = os.environ.get('VPC')
    security_id     = os.environ.get('SECURITY_GROUP_ID')
    record_name     = os.environ.get('ORIGIN')
    codepipeline    = boto3.client('codepipeline')

    # logging
    logger.setLevel(logging.INFO)
    logger.debug(json.dumps(event))

    if hosted_zone_id is None or vpc_id is None or security_id is None:
        logger.exception("ERROR: Badness happens for a reason...")
        sys.exit(1)
    else:
        logger.info("Everything is all cool in the gang")

    # get the IP that Fargate is using as an entry for the task
    response = client.describe_network_interfaces(
        Filters = [
            {
              'Name': 'vpc-id',
              'Values': [vpc_id]
            },
            {
                'Name': 'group-id',
                'Values': [security_id]
            }
        ]
    )
    pub_ips = [eni.get('Association', {}).get('PublicIp') for eni in response.get('NetworkInterfaces', [])]
    pub_ip = pub_ips.pop()

    #update the DNS for the origin adress in Route53
    response = r53_client.change_resource_record_sets(
        HostedZoneId = hosted_zone_id,
        ChangeBatch = {
            "Comment": "Automatic DNS update",
            "Changes": [
                {
                    "Action": "UPSERT",
                    "ResourceRecordSet": {
                        "Name": record_name,
                        "Type": "A",
                        "TTL": 60,
                        "ResourceRecords": [
                            {
                                "Value": pub_ip,
                            },
                        ],
                    },
                },
            ],
        },
    )

    # codepipeline ID
    codepipelineJob = event.get('CodePipeline.job')
    if codepipelineJob is not None:
        job_id = event['CodePipeline.job']['id']
        response = codepipeline.put_job_success_result(jobId=job_id)
        logger.debug(response)

    #print(pub_ip)


