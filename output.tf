output "pdm_object_tagger_batch" {
  value = {
    job_queue      = aws_batch_job_queue.pdm_object_tagger
    job_definition = aws_batch_job_definition.pdm_object_tagger
  }
}
