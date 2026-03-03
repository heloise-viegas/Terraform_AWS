variable "name_prefix" {
  description = "Prefix used for resource names"
  type        = string
  default     = "blue"
}

variable "eks_subnet_ids" {
  description = "List of subnet IDs (public and/or private) for the EKS cluster VPC config"
  type        = list(string)
}

variable "cluster_name" {
  description = "Name of the EKS cluster"
  type        = string
  default     = "blue-eks-cluster"
}

variable "cluster_version" {
  description = "Kubernetes version for the EKS cluster"
  type        = string
  default     = "1.35"
}

variable "eks_ng_subnet_ids" {
  description = "List of subnet IDs to use for the EKS node group"
  type        = list(string)
  default     = []
}


variable "node_group_instance_types" {
  description = "EC2 instance types for the node group"
  type        = list(string)
  default     = ["t3.small"]
}

variable "node_group_desired_size" {
  description = "Desired number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_group_max_size" {
  description = "Maximum number of nodes in the node group"
  type        = number
  default     = 2
}

variable "node_group_min_size" {
  description = "Minimum number of nodes in the node group"
  type        = number
  default     = 1
}

variable "node_group_update_max_unavailable" {
  description = "Max unavailable nodes during update for the node group"
  type        = number
  default     = 1
}
variable "cluster_role_name" {
  description = "Name of the IAM Role for EKS cluster"
  type        = string
  default     = "blue-cluster-role"
  
}

variable "aws_account_id" {
  description = "AWS Account ID for IAM role ARN construction"
  type        = string
}

variable "admin_user" {
  description = "IAM user name to grant EKS admin access"
  type        = string
  default     = "devops_user"
}