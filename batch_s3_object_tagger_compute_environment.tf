data "aws_iam_role" "aws_batch_service_role" {
  name = "aws_batch_service_role"
}

# AWS Batch Instance IAM role & profile

resource "aws_iam_role" "ecs_instance_role_s3_object_tagger_batch" {
  name = "ecs_instance_role_s3_object_tagger_batch"

  assume_role_policy = <<EOF
{
    "Version": "2012-10-17",
    "Statement": [
      {
        "Action": "sts:AssumeRole",
        "Effect": "Allow",
        "Principal": {
          "Service": "ec2.amazonaws.com"
        }
      }
    ]
}
EOF
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_s3_object_tagger_batch" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role_s3_object_tagger_batch" {
  name = "ecs_instance_role_csc_profile"
  role = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_s3_object_tagger_batch_ecr" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_security_group" "s3_object_tagger_batch_batch" {
  name                   = "s3_object_tagger_batch_batch_security_group"
  description            = "s3 object tagger batch AWS Batch"
  revoke_rules_on_delete = true
  vpc_id                 = local.internal_compute_vpc_id
  tags                   = local.common_tags
}

resource "aws_security_group_rule" "s3_object_tagger_batch_batch_to_s3" {
  description       = "s3 object tagger Batch to S3"
  type              = "egress"
  prefix_list_ids   = [local.internal_compute_vpc_prefix_list_ids_s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = aws_security_group.s3_object_tagger_batch_batch.id
}

resource "aws_security_group_rule" "s3_object_tagger_batch_batch_to_s3_http" {
  description       = "s3 object tagger batch Batch to S3 http for YUM"
  type              = "egress"
  prefix_list_ids   = [local.internal_compute_vpc_prefix_list_ids_s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = aws_security_group.s3_object_tagger_batch_batch.id
}


resource "aws_security_group_rule" "s3_object_tagger_egress_internet_proxy" {
  description              = "s3 object tagger batch to Internet Proxy (for ACM-PCA)"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = aws_security_group.s3_object_tagger_batch_batch.id
}

resource "aws_security_group_rule" "s3_object_tagger_ingress_internet_proxy" {
  description              = "Allow proxy access from s3 object tagger batch"
  type                     = "ingress"
  from_port                = 3128
  to_port                  = 3128
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.s3_object_tagger_batch_batch.id
  security_group_id        = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
}

resource "aws_batch_compute_environment" "s3_object_tagger_batch" {
  compute_environment_name_prefix = "s3_object_tagger_batch"
  service_role                    = data.aws_iam_role.aws_batch_service_role.arn
  type                            = "MANAGED"

  compute_resources {
    image_id            = var.ecs_hardened_ami_id
    instance_role       = aws_iam_instance_profile.ecs_instance_role_s3_object_tagger_batch.arn
    instance_type       = ["optimal"]
    allocation_strategy = "BEST_FIT_PROGRESSIVE"

    min_vcpus     = 0
    desired_vcpus = 0
    max_vcpus     = local.batch_s3_tagger_compute_environment_max_cpus[local.environment]

    security_group_ids = [aws_security_group.s3_object_tagger_batch_batch.id]
    subnets            = local.internal_compute_vpc_id
    type               = "EC2"

    tags = merge(
      local.common_tags,
      {
        Name         = "s3-object-tagger",
        Persistence  = "Ignore",
        AutoShutdown = "False",
      }
    )
  }

  lifecycle {
    ignore_changes        = [compute_resources.0.desired_vcpus]
    create_before_destroy = true
  }
}
