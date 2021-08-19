variable "assume_role" {
  type        = string
  default     = "ci"
  description = "IAM role assumed by Concourse when running Terraform"
}

variable "region" {
  type    = string
  default = "eu-west-2"
}

variable "image_version" {
  description = "Container tag values."
  default = {
    s3-object-tagger = {
      development = "0.0.22"
      qa          = "0.0.22"
      integration = "0.0.22"
      preprod     = "0.0.22"
      production  = "0.0.19"
    }
  }
}

variable "ecs_hardened_ami_id" {}
