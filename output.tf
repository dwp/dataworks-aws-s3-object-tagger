output "pdm_object_tagger_batch" {
  value = {
    job_queue      = aws_batch_job_queue.pdm_object_tagger
    job_definition = aws_batch_job_definition.pdm_object_tagger
  }
}

output "pdm_object_tagger_data_classification" {
  value = {
    config_prefix  = local.config_prefix
    config_file    = local.config_filename
    data_s3_prefix = local.data_s3_prefix
  }
}

output "pdm_object_tagger_iam" {
  value = aws_iam_role.pdm_object_tagger
}

output "pt_object_tagger_data_classification" {
  value = {
    config_prefix  = local.config_prefix
    config_file    = local.config_filename
    data_s3_prefix = local.pt_s3_prefix
  }
}
