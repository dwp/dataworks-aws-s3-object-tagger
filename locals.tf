locals {
  internal_compute_vpc_prefix_list_ids_s3 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.prefix_list_ids.s3
  internal_compute_subnets                = data.terraform_remote_state.internal_compute.outputs.compute_environment_subnet
  internal_compute_vpc_id                 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id
  internal_compute_vpce_security_group_id = data.terraform_remote_state.internal_compute.outputs.vpce_security_groups.s3_object_tagger_batch_vpce_security_group.id

  s3_object_tagger_image = "${local.account.management}.${data.terraform_remote_state.aws_ingestion.outputs.vpc.vpc.ecr_dkr_domain_name}/dataworks-s3-object-tagger:${var.image_version.s3-object-tagger[local.environment]}"
  s3_object_tagger_application_name = "s3-object-tagger"
  config_prefix                     = "component/rbac"
  config_filename                   = "data_classification.csv"

//  Include trailing slash to prevent S3 listing items outside of destination
  pdm_s3_prefix                     = "data/uc/"
  pt_s3_prefix                      = "data/uc_payment_timelines"
  clive_s3_prefix                   = "data/uc_clive"

  s3_object_tagger_container_vcpu = {
    development = 2
    qa          = 2
    integration = 2
    preprod     = 10
    production  = 50
  }

  s3_object_tagger_container_memory = {
    development = 2048
    qa          = 2048
    integration = 2048
    preprod     = 10240
    production  = 10240
  }

  batch_s3_tagger_compute_environment_desired_cpus = {
    development = 10
    qa          = 10
    integration = 10
    preprod     = 10
    production  = 50
  }

  batch_s3_tagger_compute_environment_max_cpus = {
    development = 100
    qa          = 100
    integration = 100
    preprod     = 100
    production  = 650
  }
}
