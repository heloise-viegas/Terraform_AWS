output "cluster_id" {
  description = "EKS cluster ID"
  value       = aws_eks_cluster.eks.id
}

output "cluster_name" {
  description = "EKS cluster name"
  value       = aws_eks_cluster.eks.name
}

output "cluster_arn" {
  description = "EKS cluster ARN"
  value       = aws_eks_cluster.eks.arn
}

output "cluster_endpoint" {
  description = "EKS cluster API endpoint"
  value       = aws_eks_cluster.eks.endpoint
}

output "cluster_certificate_authority_data" {
  description = "Base64-encoded certificate authority data for the cluster"
  value       = aws_eks_cluster.eks.certificate_authority[0].data
}

output "cluster_role_arn" {
  description = "IAM Role ARN used by the EKS cluster"
  value       = aws_iam_role.cluster_role.arn
}

output "cluster_security_group_ids" {
  description = "Security group IDs attached to the cluster VPC config"
  value       = aws_eks_cluster.eks.vpc_config[0].security_group_ids
}
output "eks_cluster_autoscaler_arn" {
  value = aws_iam_role.eks_cluster_autoscaler_role.arn
}
output "cluster_accessible_from_admin_user" {
  value = aws_eks_access_policy_association.admin_user_policy.id
}