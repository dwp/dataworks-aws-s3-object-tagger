# AWS Batch Job IAM role
data "aws_iam_policy_document" "batch_assume_policy" {
  statement {
    sid    = "BatchAssumeRolePolicy"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      identifiers = ["ecs-tasks.amazonaws.com"]

      type = "Service"
    }
  }
}

resource "aws_iam_role" "s3_object_tagger" {
  name               = "s3_object_tagger"
  assume_role_policy = data.aws_iam_policy_document.batch_assume_policy.json
  tags               = local.common_tags
}

data "aws_iam_policy_document" "s3_object_tagger_config_bucket" {
  statement {
    sid    = "AllowS3GetObject"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:ListBucket"
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.config_bucket.arn}/${local.config_prefix}/*",
    ]
  }

  statement {
    sid    = "AllowDecryptConfigBucketObjects"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:DescribeKey",
    ]

    resources = [
      data.terraform_remote_state.common.outputs.config_bucket_cmk.arn,
    ]
  }
}

data "aws_iam_policy_document" "s3_object_tagger_published_bucket" {
  statement {
    sid    = "AllowS3Tagging"
    effect = "Allow"

    actions = [
      "s3:GetObject",
      "s3:GetObjectTagging",
      "s3:PutObjectTagging"
    ]

    resources = [
      "${data.terraform_remote_state.common.outputs.published_bucket.arn}/*",
    ]
  }

  statement {
    sid    = "AllowS3ListObjects"
    effect = "Allow"

    actions = [
      "s3:ListBucket"
    ]

    resources = [
      data.terraform_remote_state.common.outputs.published_bucket.arn,
    ]
  }
}

resource "aws_iam_policy" "s3_object_tagger_config" {
  name   = "s3_object_tagger_config"
  policy = data.aws_iam_policy_document.s3_object_tagger_config_bucket.json
}

resource "aws_iam_policy" "s3_object_tagger_published" {
  name   = "s3_object_tagger_published"
  policy = data.aws_iam_policy_document.s3_object_tagger_published_bucket.json
}

resource "aws_iam_role_policy_attachment" "s3_object_tagger_config" {
  role       = aws_iam_role.s3_object_tagger.name
  policy_arn = aws_iam_policy.s3_object_tagger_config.arn
}

resource "aws_iam_role_policy_attachment" "s3_object_tagger_published" {
  role       = aws_iam_role.s3_object_tagger.name
  policy_arn = aws_iam_policy.s3_object_tagger_published.arn
}

resource "aws_batch_job_queue" "pdm_object_tagger" {
  //  TODO: Move compute environment to fargate once Terraform supports it.
  compute_environments = [aws_batch_compute_environment.s3_object_tagger_batch.arn]
  name                 = "pdm_object_tagger"
  priority             = 10
  state                = "ENABLED"
  tags                 = merge({ "Name" : "pdm_object_tagger_queue" }, local.common_tags)
}

resource "aws_batch_job_queue" "clive_object_tagger" {
  //  TODO: Move compute environment to fargate once Terraform supports it.
  compute_environments = [aws_batch_compute_environment.s3_object_tagger_batch.arn]
  name                 = "clive_object_tagger"
  priority             = 10
  state                = "ENABLED"
  tags                 = merge({ "Name" : "clive_object_tagger_queue" }, local.common_tags)
}

resource "aws_batch_job_queue" "pt_object_tagger" {
  //  TODO: Move compute environment to fargate once Terraform supports it.
  compute_environments = [aws_batch_compute_environment.s3_object_tagger_batch.arn]
  name                 = "pt_object_tagger"
  priority             = 10
  state                = "ENABLED"
  tags                 = merge({ "Name" : "pt_object_tagger_queue" }, local.common_tags)
}

resource "aws_batch_job_definition" "s3_object_tagger" {
  name = "s3_object_tagger_job"
  type = "container"

  container_properties = <<CONTAINER_PROPERTIES
  {
      "command": ["--data-s3-prefix", "Ref::data-s3-prefix", "--csv-location", "Ref::csv-location"],
      "image": "${local.s3_object_tagger_image}",
      "jobRoleArn" : "${aws_iam_role.s3_object_tagger.arn}",
      "memory": 10240,
      "vcpus": 2,
      "environment": [
          {"name": "LOG_LEVEL", "value": "INFO"},
          {"name": "AWS_DEFAULT_REGION", "value": "eu-west-2"},
          {"name": "DATA_BUCKET", "value": "${data.terraform_remote_state.common.outputs.published_bucket.id}"},
          {"name": "ENVIRONMENT", "value": "${local.environment}"},
          {"name": "APPLICATION", "value": "${local.s3_object_tagger_application_name}"}
      ],
      "ulimits": [
        {
          "hardLimit": 1024,
          "name": "nofile",
          "softLimit": 1024
        }
      ]
  }
  CONTAINER_PROPERTIES
}

resource "aws_batch_job_definition" "s3_object_tagger_test_ami" {
  count                = local.environment == "qa" ? 1 : 0
  name                 = "s3_object_tagger_test_ami_job"
  type                 = "container"
  container_properties = <<CONTAINER_PROPERTIES
  {
      "image": "${local.s3_object_tagger_image}",
      "image": "${data.terraform_remote_state.management.outputs.ecr_awscli_url}",
      "jobRoleArn" : "${aws_iam_role.s3_object_tagger.arn}",
      "memory": 128,
      "vcpus": 2,
      "environment": [
          {"name": "LOG_LEVEL", "value": "INFO"},
          {"name": "AWS_DEFAULT_REGION", "value": "eu-west-2"}
      ],
      "ulimits": [
        {
          "hardLimit": 1024,
          "name": "nofile",
          "softLimit": 1024
        }
      ]
  }
  CONTAINER_PROPERTIES
}

resource "aws_batch_job_queue" "s3_object_tagger_test_ami" {
  count                = local.environment == "qa" ? 1 : 0
  compute_environments = [aws_batch_compute_environment.s3_object_tagger_batch.arn]
  name                 = "amitest_s3tagger"
  priority             = 10
  state                = "ENABLED"
}
