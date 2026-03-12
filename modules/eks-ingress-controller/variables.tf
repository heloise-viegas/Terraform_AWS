variable "aws_account_id" {
  description = "AWS Account ID for constructing ARNs (used by OIDC provider)"
  type        = string
}

variable "cluster_accessible_from_admin_user" {
  description = "ID returned from eks module representing admin user cluster access; used only for depends_on logic"
  type        = string
}

variable "cluster_name" {
  description = "Name of the EKS cluster the ALB controller will target"
  type        = string
}

variable "region" {
  description = "AWS region where the cluster and VPC live"
  type        = string
}

variable "vpc_id" {
  description = "ID of the VPC containing the EKS cluster"
  type        = string
}