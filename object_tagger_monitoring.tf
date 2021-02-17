resource "aws_cloudwatch_event_rule" "object_tagging_state_changes" {
  name        = "object-tagging-state-changes"
  description = "Object tagging events when run state changes"

  event_pattern = <<EOF
{
  "detail-type": [
    "Batch Job State Change"
  ],
  "source": [
    "aws.batch"
  ],
  "detail": {
    "jobQueue": "${aws_batch_job_queue.pdm_object_tagger.arn}"
  }
}
EOF
}

resource "aws_cloudwatch_event_target" "object_tagging_state_changes" {
  rule      = aws_cloudwatch_event_rule.object_tagging_state_changes.name
  target_id = "SendSNSMessageToHandlerLambda"
  arn       = data.terraform_remote_state.common.outputs.batch_job_topic.arn
}
