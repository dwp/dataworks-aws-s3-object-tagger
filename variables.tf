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
      development = "0.0.24"
      qa          = "0.0.24"
      integration = "0.0.24"
      preprod     = "0.0.24"
      production  = "0.0.24"
    }
  }
}

variable "ecs_hardened_ami_id" {}

variable "proxy_port" {
  description = "proxy port"
  type        = string
  default     = "3128"
}

variable "tanium_port_1" {
  description = "tanium port 1"
  type        = string
  default     = "16563"
}

variable "tanium_port_2" {
  description = "tanium port 2"
  type        = string
  default     = "16555"
}
