variable "name_prefix" {
  description = "Prefix used in resource names and tags"
  type        = string
  default     = "blue"
}

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


variable "public_subnets" {

    default ={
        "ap-south-1a" = "10.0.1.0/24",
        "ap-south-1b" = "10.0.2.0/24",
        "ap-south-1c" = "10.0.3.0/24"
    }
}

variable "private_subnets" {

    default ={
        "ap-south-1a" = "10.0.4.0/24",
        "ap-south-1b" = "10.0.5.0/24",
        "ap-south-1c" = "10.0.6.0/24"
    }
}

# variable "private_subnet_cidr" {
#   description = "CIDR block for the private subnet"
#   type        = string
#   default     = "10.0.2.0/24"
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

variable "eip_name" {
  description = "Optional Name tag for the EIP."
  type        = string
  default     = ""
}
