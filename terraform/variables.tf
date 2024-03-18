variable "ami_id" {
  description = "Canonical, Ubuntu, 22.04 LTS, arm64 jammy image build on 2024-03-01"
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

variable "script_url" {
  description = "Bootscript from git repo"
  default     = "https://raw.githubusercontent.com/esklv/vpn/main/vpn/script.sh"
}