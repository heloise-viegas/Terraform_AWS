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