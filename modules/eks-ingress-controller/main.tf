############### ALB Controller IAM Policy
data "http" "alb_policy" {
  url = "https://raw.githubusercontent.com/kubernetes-sigs/aws-load-balancer-controller/main/docs/install/iam_policy.json"
}

# Policy required by AWS Load Balancer Controller to create ALBs,
# manage target groups, listeners, security groups, etc.
resource "aws_iam_policy" "alb_controller_policy" {
  name   = "AWSLoadBalancerControllerIAMPolicy"
  policy = data.http.alb_policy.response_body # official policy downloaded from AWS LB controller repo
}

data "aws_iam_openid_connect_provider" "oidc" {
  arn = "arn:aws:iam::${var.aws_account_id}:oidc-provider/accounts.google.com"
}
############### ALB Controller IAM Role (IRSA)
# IAM role assumed by the Kubernetes service account via OIDC (IRSA)
resource "aws_iam_role" "alb_controller_role" {
  name = "alb-controller-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect = "Allow"

      # OIDC provider created for the EKS cluster
      Principal = {
        Federated = data.aws_iam_openid_connect_provider.oidc.arn
      }

      # Required action for IAM Roles for Service Accounts
      Action = "sts:AssumeRoleWithWebIdentity"

      # Restrict role assumption only to this specific service account
      Condition = {
        StringEquals = {
          "${replace(data.aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
        }
      }
    }]
  })
}

############### Attach IAM Policy to Role
resource "aws_iam_role_policy_attachment" "alb_controller_attach" {
  role       = aws_iam_role.alb_controller_role.name
  policy_arn = aws_iam_policy.alb_controller_policy.arn
}

############### Service Account for ALB Controller
# Kubernetes service account that will assume the IAM role via IRSA
resource "kubernetes_service_account" "alb_controller_sa" {
  metadata {
    name      = "aws-load-balancer-controller"
    namespace = "kube-system"

    annotations = {
      # This annotation connects the Kubernetes SA with the IAM role
      "eks.amazonaws.com/role-arn" = aws_iam_role.alb_controller_role.arn
    }
  }
   depends_on = [
    var.cluster_accessible_from_admin_user
  ]
}


# ############### EKS Auth Data Source
# # Generates temporary authentication token for Kubernetes API access
# # Equivalent to running: aws eks get-token
# data "aws_eks_cluster_auth" "eks" {
#   name = aws_eks_cluster.eks.name
# }

# data "aws_eks_cluster" "eks" {
#   name = aws_eks_cluster.eks.name
# }
# ############### Kubernetes Provider
# # Allows Terraform to create Kubernetes resources (service accounts etc.)
# provider "kubernetes" {
#   host                   = data.aws_eks_cluster.eks.endpoint
#   cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

#   # token generated dynamically using aws_eks_cluster_auth
#   token                  = data.aws_eks_cluster_auth.eks.token
# }

# ############### Helm Provider
# # Helm provider uses the same Kubernetes connection to install Helm charts
# provider "helm" {
#   kubernetes ={
#     host                   = data.aws_eks_cluster.eks.endpoint
#     cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
#     token                  = data.aws_eks_cluster_auth.eks.token
#   }
# }

############### Install AWS Load Balancer Controller via Helm
resource "helm_release" "aws_load_balancer_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"

  namespace = "kube-system"

  set = [
    {
      name  = "clusterName"
      value = var.cluster_name
    },
    {
      name  = "region"
      value = var.region
    },
    {
      name  = "vpcId"
      value = var.vpc_id
    },
    {
      name  = "serviceAccount.create"
      value = "false"
    },
    {
      name  = "serviceAccount.name"
      value = kubernetes_service_account.alb_controller_sa.metadata[0].name
    }
  ]

  depends_on = [
    kubernetes_service_account.alb_controller_sa
  ]
}