data "aws_iam_role" "aws_batch_service_role" {
  name = "aws_batch_service_role"
}

# AWS Batch Instance IAM role & profile

resource "aws_iam_role_policy_attachment" "s3_tagger_ecs_cwasp" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = "arn:aws:iam::aws:policy/CloudWatchAgentServerPolicy"
}

resource "aws_iam_role_policy_attachment" "ec2_for_ssm_attachment" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

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

# Custom policy to allow use of default EBS encryption key by Batch instance role
data "aws_iam_policy_document" "ecs_instance_role_s3_object_tagger_batch_ebs_cmk" {
  statement {
    sid    = "AllowUseDefaultEbsCmk"
    effect = "Allow"
    actions = [
      "kms:Encrypt",
      "kms:Decrypt",
      "kms:ReEncrypt*",
      "kms:GenerateDataKey*",
      "kms:DescribeKey",
    ]
    resources = [data.terraform_remote_state.security_tools.outputs.ebs_cmk.arn]
  }

  statement {
    effect = "Allow"
    sid    = "AllowAccessToConfigBucket"

    actions = [
      "s3:ListBucket",
      "s3:GetBucketLocation",
    ]

    resources = [data.terraform_remote_state.common.outputs.config_bucket.arn]
  }

  statement {
    effect = "Allow"
    sid    = "AllowAccessToConfigBucketObjects"

    actions = ["s3:GetObject"]

    resources = ["${data.terraform_remote_state.common.outputs.config_bucket.arn}/*"]
  }

  statement {
    sid    = "AllowKMSDecryptionOfS3ConfigBucketObj"
    effect = "Allow"

    actions = [
      "kms:Decrypt",
      "kms:GenerateDataKey",
    ]

    resources = [data.terraform_remote_state.common.outputs.config_bucket_cmk.arn]
  }

  statement {
    sid    = "AllowAccessLogGroups"
    effect = "Allow"
    actions = [
      "logs:CreateLogStream",
      "logs:PutLogEvents",
      "logs:DescribeLogStreams"
    ]
    resources = [aws_cloudwatch_log_group.s3_tagger_ecs_cluster.arn] #data.terraform_remote_state.common.outputs.ami_ecs_test_services ? [aws_cloudwatch_log_group.s3_tagger_ecs_cluster.arn, data.terraform_remote_state.common.outputs.ami_ecs_test_log_group_arn] : [aws_cloudwatch_log_group.s3_tagger_ecs_cluster.arn]
  }

  statement {
    sid    = "EnableEC2TaggingHost"
    effect = "Allow"

    actions = [
      "ec2:ModifyInstanceMetadataOptions",
      "ec2:*Tags",
    ]
    resources = ["arn:aws:ec2:${var.region}:${local.account[local.environment]}:instance/*"]
  }

  statement {
    sid    = "ECSListClusters"
    effect = "Allow"

    actions = [
      "ecs:ListClusters",
    ]
    resources = ["*"]
  }

  statement {
    effect = "Allow"

    actions = [
      "ssm:*",
    ]

    resources = [
      "*"
    ]
  }

}


resource "aws_cloudwatch_log_group" "s3_tagger_ecs_cluster" {
  name              = local.cw_agent_log_group_name_s3_tagger_ecs
  retention_in_days = 180
  tags              = local.common_tags
}

resource "aws_iam_policy" "ecs_instance_role_s3_object_tagger_batch_ebs_cmk" {
  name   = "ecs_instance_role_s3_object_tagger_batch_ebs_cmk"
  policy = data.aws_iam_policy_document.ecs_instance_role_s3_object_tagger_batch_ebs_cmk.json
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_s3_object_tagger_batch_ebs_cmk" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = aws_iam_policy.ecs_instance_role_s3_object_tagger_batch_ebs_cmk.arn
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_s3_object_tagger_batch" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

resource "aws_iam_instance_profile" "ecs_instance_role_s3_object_tagger_batch" {
  name = "ecs_instance_role_s3_object_tagger_profile"
  role = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
}

resource "aws_iam_role_policy_attachment" "ecs_instance_role_s3_object_tagger_batch_ecr" {
  role       = aws_iam_role.ecs_instance_role_s3_object_tagger_batch.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
}

resource "aws_security_group_rule" "s3_object_tagger_batch_to_s3" {
  description       = "s3 object tagger Batch to S3"
  type              = "egress"
  prefix_list_ids   = [local.internal_compute_vpc_prefix_list_ids_s3]
  protocol          = "tcp"
  from_port         = 443
  to_port           = 443
  security_group_id = local.internal_compute_vpce_security_group_id
}


resource "aws_security_group_rule" "s3_object_tagger_batch_to_s3_http" {
  description       = "s3 object tagger batch Batch to S3 http for YUM"
  type              = "egress"
  prefix_list_ids   = [local.internal_compute_vpc_prefix_list_ids_s3]
  protocol          = "tcp"
  from_port         = 80
  to_port           = 80
  security_group_id = local.internal_compute_vpce_security_group_id
}


resource "aws_security_group_rule" "s3_object_tagger_egress_internet_proxy" {
  description              = "s3 object tagger batch to Internet Proxy (for ACM-PCA)"
  type                     = "egress"
  source_security_group_id = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
  protocol                 = "tcp"
  from_port                = 3128
  to_port                  = 3128
  security_group_id        = local.internal_compute_vpce_security_group_id
}

resource "aws_security_group_rule" "s3_object_tagger_ingress_internet_proxy" {
  description              = "Allow proxy access from s3 object tagger batch"
  type                     = "ingress"
  from_port                = 3128
  to_port                  = 3128
  protocol                 = "tcp"
  source_security_group_id = local.internal_compute_vpce_security_group_id
  security_group_id        = data.terraform_remote_state.internal_compute.outputs.internet_proxy.sg
}

resource "aws_security_group_rule" "s3_object_tagger_host_outbound_tanium_1" {
  description              = "S3 Object tagger host outbound port 1 to Tanium"
  type                     = "egress"
  from_port                = var.tanium_port_1
  to_port                  = var.tanium_port_1
  protocol                 = "tcp"
  security_group_id        = local.internal_compute_vpce_security_group_id
  source_security_group_id = data.terraform_remote_state.internal_compute.outputs.tanium_service_endpoint.sg
}

resource "aws_security_group_rule" "s3_object_tagger_host_outbound_tanium_2" {
  description              = "S3 Object tagger host outbound port 2 to Tanium"
  type                     = "egress"
  from_port                = var.tanium_port_2
  to_port                  = var.tanium_port_2
  protocol                 = "tcp"
  security_group_id        = local.internal_compute_vpce_security_group_id
  source_security_group_id = data.terraform_remote_state.internal_compute.outputs.tanium_service_endpoint.sg
}

resource "aws_security_group_rule" "s3_object_tagger_host_inbound_tanium_1" {
  description              = "S3 Object tagger host inbound port 1 from Tanium"
  type                     = "ingress"
  from_port                = var.tanium_port_1
  to_port                  = var.tanium_port_1
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.internal_compute.outputs.tanium_service_endpoint.sg
  source_security_group_id = local.internal_compute_vpce_security_group_id
}

resource "aws_security_group_rule" "s3_object_tagger_host_inbound_tanium_2" {
  description              = "S3 Object tagger host inbound port 2 from Tanium"
  type                     = "ingress"
  from_port                = var.tanium_port_2
  to_port                  = var.tanium_port_2
  protocol                 = "tcp"
  security_group_id        = data.terraform_remote_state.internal_compute.outputs.tanium_service_endpoint.sg
  source_security_group_id = local.internal_compute_vpce_security_group_id
}

resource "aws_batch_compute_environment" "s3_object_tagger_batch" {
  compute_environment_name_prefix = "s3_object_tagger_batch"
  service_role                    = data.aws_iam_role.aws_batch_service_role.arn
  type                            = "MANAGED"

  compute_resources {
    instance_role       = aws_iam_instance_profile.ecs_instance_role_s3_object_tagger_batch.arn
    instance_type       = ["optimal"]
    allocation_strategy = "BEST_FIT_PROGRESSIVE"

    min_vcpus     = 0
    desired_vcpus = local.batch_s3_tagger_compute_environment_desired_cpus[local.environment]
    max_vcpus     = local.batch_s3_tagger_compute_environment_max_cpus[local.environment]

    security_group_ids = [local.internal_compute_vpce_security_group_id]
    subnets            = local.internal_compute_subnets.ids
    type               = "EC2"

    launch_template {
      launch_template_id      = aws_launch_template.s3_tagger_ecs_cluster.id
      version                 = aws_launch_template.s3_tagger_ecs_cluster.latest_version
    }

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


resource "aws_launch_template" "s3_tagger_ecs_cluster" {
  name     = local.s3_object_tagger_application_name
  image_id = var.ecs_hardened_ami_id

  user_data = base64encode(templatefile("files/userdata.tpl", {
    region                                           = data.aws_region.current.name
    name                                             = local.s3_object_tagger_application_name
    proxy_port                                       = var.proxy_port
    proxy_host                                       = data.terraform_remote_state.internal_compute.outputs.internet_proxy.host
    hcs_environment                                  = local.hcs_environment[local.environment]
    s3_scripts_bucket                                = data.terraform_remote_state.common.outputs.config_bucket.id
    s3_script_logrotate                              = aws_s3_object.s3_tagger_logrotate_script.id
    s3_script_cloudwatch_shell                       = aws_s3_object.s3_tagger_cloudwatch_script.id
    s3_script_logging_shell                          = aws_s3_object.s3_tagger_logging_script.id
    s3_script_config_hcs_shell                       = aws_s3_object.s3_tagger_config_hcs_script.id
    cwa_namespace                                    = local.cw_agent_namespace_s3_tagger_ecs
    cwa_log_group_name                               = "${local.cw_agent_namespace_s3_tagger_ecs}-${local.environment}"
    cwa_metrics_collection_interval                  = local.cw_agent_metrics_collection_interval
    cwa_cpu_metrics_collection_interval              = local.cw_agent_cpu_metrics_collection_interval
    cwa_disk_measurement_metrics_collection_interval = local.cw_agent_disk_measurement_metrics_collection_interval
    cwa_disk_io_metrics_collection_interval          = local.cw_agent_disk_io_metrics_collection_interval
    cwa_mem_metrics_collection_interval              = local.cw_agent_mem_metrics_collection_interval
    cwa_netstat_metrics_collection_interval          = local.cw_agent_netstat_metrics_collection_interval
    install_tenable                                  = local.tenable_install[local.environment]
    install_trend                                    = local.trend_install[local.environment]
    install_tanium                                   = local.tanium_install[local.environment]
    tanium_server_1                                  = data.terraform_remote_state.internal_compute.outputs.tanium_service_endpoint.dns
    tanium_server_2                                  = local.tanium2
    tanium_env                                       = local.tanium_env[local.environment]
    tanium_port                                      = var.tanium_port_1
    tanium_log_level                                 = local.tanium_log_level[local.environment]
    tenant                                           = local.tenant
    tenantid                                         = local.tenantid
    token                                            = local.token
    policyid                                         = local.policy_id[local.environment]

  }))

  instance_initiated_shutdown_behavior = "terminate"

  tags = merge(
    local.common_tags,
    {
      Name = local.s3_object_tagger_application_name
    }
  )

  tag_specifications {
    resource_type = "instance"

    tags = merge(
      local.common_tags,
      {
        Name                = local.s3_object_tagger_application_name,
        AutoShutdown        = local.s3_tagger_ecs_cluster_asg_autoshutdown[local.environment],
        SSMEnabled          = local.s3_tagger_ecs_cluster_asg_ssmenabled[local.environment],
        Persistence         = "Ignore",
        propagate_at_launch = true,
      }
    )
  }

  tag_specifications {
    resource_type = "volume"

    tags = merge(
      local.common_tags,
      {
        Name = local.s3_object_tagger_application_name,
      }
    )
  }
}
