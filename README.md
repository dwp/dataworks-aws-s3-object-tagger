# DO NOT USE THIS REPO - MIGRATED TO GITLAB

# dataworks-aws-s3-object-tagger

## S3 Object tagger application infrastructure

This repo deploys out the infrastructure required for the s3-object-tagger application. This includes an AWS Batch Compute environment, a shared job definition which uses the docker image release of [dataworks-s3-object-tagger](https://github.com/dwp/dataworks-s3-object-tagger)
and finally a batch job queue per service which requires one. (Currently: PDM, Payment Timelines and Clive)

## Configuring the documents to be tagged
Update the data-classification.csv file with the correct information.

## When does the object tagging run
Any of these cases will cause the object tagger to run across the route to live:

1) An update to the data-classification.csv RBAC file.
2) A manual kick off of the pipeline, see the 'object-tagging' pipeline in Concourse.
3) An automatic EventBridge rule, with a target to initiate the AWS Batch job (configured outside of this repo and in the services repo. eg Clives own repo)

Note: The utility tasks handle the functional running of the object tagging, see the 'object-tagging' pipeline in Concourse.
The 's3-object-tagger-infra' pipeline rolls out the infrastructure.