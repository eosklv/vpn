variable "ami_id" {
  description = "AMI ID"
  default     = "ami-0000456e99b2b6a9d"
}

variable "default_vpc_id" {
  description = "Default VPC"
  default     = "vpc-05ad61cf37d2a7d5f"
}

variable "default_bucket" {
  description = "S3 bucket"
  default     = "esklv-vpn"
}

variable "my_ips" {
  type    = list(string)
  default = ["45.9.230.81/32"]
}