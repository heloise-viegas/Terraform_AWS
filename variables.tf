variable "vpc_cidr" {
  description = "CIDR block for the VPC"
  type        = string
  default     = "10.0.0.0/16"
}

# variable "public_subnet_cidr" {
#   description = "CIDR block for the public subnet"
#   type        = string
#   default     = "10.0.1.0/24"
# }

# variable "private_subnet_cidr" {
#   description = "CIDR block for the private subnet"
#   type        = string
#   default     = "10.0.2.0/24"
# }

variable "public_subnets" {

  default = {
    "ap-south-1a" = "10.0.1.0/24",
    "ap-south-1b" = "10.0.2.0/24",
    "ap-south-1c" = "10.0.3.0/24"
  }
}

variable "private_subnets" {

  default = {
    "ap-south-1a" = "10.0.4.0/24",
    "ap-south-1b" = "10.0.5.0/24",
    "ap-south-1c" = "10.0.6.0/24"
  }
}

variable "enable_dns_support" {
  description = "Whether to enable DNS support for the VPC"
  type        = bool
  default     = true
}

variable "enable_dns_hostnames" {
  description = "Whether to enable DNS hostnames for the VPC"
  type        = bool
  default     = true
}

variable "name_prefix" {
  description = "Prefix used for resource Names/tags"
  type        = string
  default     = "vpc"
}

# variable "eip_domain" {
#   description = "Domain for the EIP resource"
#   type        = string
#   default     = "vpc"
# }
# variable "ip" {
#   type = string
# }

# variable "availability_zone" {
#   description = "Optional availability zone for subnets (empty = provider default)"
#   type        = string
#   default     = ""
# }

# variable "enable_nat" {
#   description = "Whether to create a NAT gateway"
#   type        = bool
#   default     = true
# }

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

