output "pdm_object_tagger_batch" {
  value = {
    job_queue      = aws_batch_job_queue.pdm_object_tagger
    job_definition = aws_batch_job_definition.s3_object_tagger
  }
}

output "clive_object_tagger_batch" {
  value = {
    job_queue      = aws_batch_job_queue.clive_object_tagger
    job_definition = aws_batch_job_definition.s3_object_tagger
  }
}

output "pt_object_tagger_batch" {
  value = {
    job_queue      = aws_batch_job_queue.pt_object_tagger
    job_definition = aws_batch_job_definition.s3_object_tagger
  }
}

output "s3_object_tagger_batch_job_def" {
  value = {
    clive_job_queue      = aws_batch_job_queue.clive_object_tagger
    pdm_job_queue      = aws_batch_job_queue.pdm_object_tagger
    pt_job_queue      = aws_batch_job_queue.pt_object_tagger
    job_definition = aws_batch_job_definition.s3_object_tagger
  }
}

output "pdm_object_tagger_data_classification" {
  value = {
    config_prefix  = local.config_prefix
    config_file    = local.config_filename
    data_s3_prefix = local.pdm_s3_prefix
  }
}

output "pt_object_tagger_data_classification" {
  value = {
    config_prefix  = local.config_prefix
    config_file    = local.config_filename
    data_s3_prefix = local.pt_s3_prefix
  }
}

output "clive_object_tagger_data_classification" {
  value = {
    config_prefix  = local.config_prefix
    config_file    = local.config_filename
    data_s3_prefix = local.clive_s3_prefix
  }
}

output "s3_object_tagger_iam" {
  value = aws_iam_role.s3_object_tagger
}
