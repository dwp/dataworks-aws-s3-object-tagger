locals {
  internal_compute_vpc_prefix_list_ids_s3 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.prefix_list_ids.s3
  internal_compute_subnets                = data.terraform_remote_state.internal_compute.outputs.compute_environment_subnet
  internal_compute_vpc_id                 = data.terraform_remote_state.internal_compute.outputs.vpc.vpc.vpc.id

  batch_s3_tagger_compute_environment_max_cpus = {
    development = 100
    qa          = 100
    integration = 100
    preprod     = 100
    production  = 650
  }
}
