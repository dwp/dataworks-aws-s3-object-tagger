
data "local_file" "s3_tagger_logrotate_script" {
  filename = "files/s3_tagger.logrotate"
}

resource "aws_s3_object" "s3_tagger_logrotate_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/s3_tagger/s3_tagger.logrotate"
  content    = data.local_file.s3_tagger_logrotate_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn



  tags = merge(
    local.common_tags,
    {
      Name = "s3-tagger-logrotate-script"
    },
  )
}

data "local_file" "s3_tagger_cloudwatch_script" {
  filename = "files/s3_tagger_cloudwatch.sh"
}

resource "aws_s3_object" "s3_tagger_cloudwatch_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/s3_tagger/s3_tagger-cloudwatch.sh"
  content    = data.local_file.s3_tagger_cloudwatch_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "s3-tagger-cloudwatch-script"
    },
  )
}

data "local_file" "s3_tagger_logging_script" {
  filename = "files/logging.sh"
}

resource "aws_s3_object" "s3_tagger_logging_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/s3_tagger/s3_tagger-logging.sh"
  content    = data.local_file.s3_tagger_logging_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "s3-tagger-logging-script"
    },
  )
}

data "local_file" "s3_tagger_config_hcs_script" {
  filename = "files/config_hcs.sh"
}

resource "aws_s3_object" "s3_tagger_config_hcs_script" {
  bucket     = data.terraform_remote_state.common.outputs.config_bucket.id
  key        = "component/s3_tagger/s3_tagger-config-hcs.sh"
  content    = data.local_file.s3_tagger_config_hcs_script.content
  kms_key_id = data.terraform_remote_state.common.outputs.config_bucket_cmk.arn

  tags = merge(
    local.common_tags,
    {
      Name = "s3-tagger-config-hcs-script"
    },
  )
}
