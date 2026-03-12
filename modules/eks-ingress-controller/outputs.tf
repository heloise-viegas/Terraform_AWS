# Outputs for the eks-ingress-controller module

output "alb_controller_policy_arn" {
  description = "ARN of the IAM policy used by the AWS Load Balancer Controller"
  value       = aws_iam_policy.alb_controller_policy.arn
}

output "alb_controller_role_arn" {
  description = "ARN of the IAM role created for the AWS Load Balancer Controller (IRSA)"
  value       = aws_iam_role.alb_controller_role.arn
}

output "alb_controller_service_account_name" {
  description = "Name of the Kubernetes service account created for the controller"
  value       = kubernetes_service_account.alb_controller_sa.metadata[0].name
}

output "alb_controller_helm_release_name" {
  description = "Name of the Helm release installing the AWS Load Balancer Controller"
  value       = helm_release.aws_load_balancer_controller.name
}