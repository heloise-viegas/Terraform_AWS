resource "aws_eks_cluster" "eks" {
  name = var.cluster_name

  access_config {
    authentication_mode = "API"
  }

  role_arn = aws_iam_role.cluster_role.arn
  version  = var.cluster_version

  vpc_config {
    subnet_ids = var.eks_subnet_ids
  }

#   AmazonEKSAutoNodeRole AmazonEKSAutoClusterRole

  # Ensure that IAM Role permissions are created before and deleted
  # after EKS Cluster handling. Otherwise, EKS will not be able to
  # properly delete EKS managed EC2 infrastructure such as Security Groups.
  depends_on = [
    aws_iam_role_policy_attachment.cluster_AmazonEKSClusterPolicy,
  ]
}

resource "aws_iam_role" "cluster_role" {
  name = "${var.name_prefix}-cluster-role"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = [
          "sts:AssumeRole",
          "sts:TagSession"
        ]
        Effect = "Allow"
        Principal = {
          Service = "eks.amazonaws.com"
        }
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "cluster_AmazonEKSClusterPolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSClusterPolicy"
  role       = aws_iam_role.cluster_role.name
}
###############node group

resource "aws_eks_node_group" "ng" {
  cluster_name    = aws_eks_cluster.eks.name
  node_group_name = "${var.name_prefix}-node-group"
  node_role_arn   = aws_iam_role.node_role.arn
  subnet_ids      = var.eks_ng_subnet_ids
  instance_types  = var.node_group_instance_types

  scaling_config {
    desired_size = var.node_group_desired_size
    max_size     = var.node_group_max_size
    min_size     = var.node_group_min_size
  }

  update_config {
    max_unavailable = var.node_group_update_max_unavailable
  }

  # Ensure that IAM Role permissions are created before and deleted after EKS Node Group handling.
  # Otherwise, EKS will not be able to properly delete EC2 Instances and Elastic Network Interfaces.
  depends_on = [
    aws_iam_role_policy_attachment.node_role-AmazonEKSWorkerNodePolicy,
    aws_iam_role_policy_attachment.node_role-AmazonEKS_CNI_Policy,
    aws_iam_role_policy_attachment.node_role-AmazonEC2ContainerRegistryReadOnly,
  ]
}

resource "aws_iam_role" "node_role" {
  name = "${var.name_prefix}-node-role"

  assume_role_policy = jsonencode({
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = {
        Service = "ec2.amazonaws.com"
      }
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEKSWorkerNodePolicy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKSWorkerNodePolicy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEKS_CNI_Policy" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEKS_CNI_Policy"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_role-AmazonEC2ContainerRegistryReadOnly" {
  policy_arn = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  role       = aws_iam_role.node_role.name
}

resource "aws_iam_role_policy_attachment" "node_ssm" {
  role       = aws_iam_role.node_role.name
  policy_arn = "arn:aws:iam::aws:policy/AmazonSSMManagedInstanceCore"
}

##Node Group SG--in vpcmodule?
# resource "aws_security_group" "NG_SG" {
#    name        = "${var.name_prefix}-ng-sg"
#    description = "Security group for EKS Node Group"
#    vpc_id      = aws_eks_cluster.eks.vpc_config[0].vpc_id

#    tags = {
#      Name = "${var.name_prefix}-ng-sg"
#    }

#   # ALB → NodePort
#   ingress {
#     description     = "ALB to NodePort"
#     from_port       = 30000
#     to_port         = 32767
#     protocol        = "tcp"
#     security_groups = [aws_security_group.alb_sg.id]
#   }

#   # Node-to-node
#   ingress {
#     description = "Node to node communication"
#     from_port   = 0
#     to_port     = 65535
#     protocol    = "-1"
#     self        = true
#   }

#   # Outbound internet via NAT
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = "-1"
#     cidr_blocks = ["0.0.0.0/0"]
#   }
# }

#########oidc provider
data "tls_certificate" "tls_certificate" {
  url = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

resource "aws_iam_openid_connect_provider" "oidc" {
  client_id_list  = ["sts.amazonaws.com"]
  thumbprint_list = [data.tls_certificate.tls_certificate.certificates[0].sha1_fingerprint]
  url             = aws_eks_cluster.eks.identity[0].oidc[0].issuer
}

###autoscaler iam role and policy
data "aws_iam_policy_document" "eks_cluster_autoscaler_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]
    effect  = "Allow"

    condition {
      test     = "StringEquals"
      variable = "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub"
      values   = ["system:serviceaccount:kube-system:cluster-autoscaler"]
    }

    principals {
      identifiers = [aws_iam_openid_connect_provider.oidc.arn]
      type        = "Federated"
    }
  }
}

resource "aws_iam_role" "eks_cluster_autoscaler_role" {
  assume_role_policy = data.aws_iam_policy_document.eks_cluster_autoscaler_assume_role_policy.json
  name               = "${var.name_prefix}-eks-cluster-autoscaler-role"  
}

resource "aws_iam_policy" "eks_cluster_autoscaler_policy" {
  name = "${var.name_prefix}-eks-cluster-autoscaler-policy"

  policy = jsonencode({
    Statement = [{
      Action = [
                "autoscaling:DescribeAutoScalingGroups",
                "autoscaling:DescribeAutoScalingInstances",
                "autoscaling:DescribeLaunchConfigurations",
                "autoscaling:DescribeTags",
                "autoscaling:SetDesiredCapacity",
                "autoscaling:TerminateInstanceInAutoScalingGroup",
                "ec2:DescribeLaunchTemplateVersions"
            ]
      Effect   = "Allow"
      Resource = "*"
    }]
    Version = "2012-10-17"
  })
}

resource "aws_iam_role_policy_attachment" "eks_cluster_autoscaler_attach" {
  role       = aws_iam_role.eks_cluster_autoscaler_role.name
  policy_arn = aws_iam_policy.eks_cluster_autoscaler_policy.arn
}

##### Note: The above IAM Role and Policy for Cluster Autoscaler is a basic example. In production, you should scope down the permissions as much as possible.
#without the below code nodes not visible in devops_user account even though they are connected to the eks, this is because we use API access mode
# we need to tell EKS that devops user is admin user and can access the cluster, otherwise only the user who created the cluster will have access to it, and in this case, we are creating the cluster with terraform, so the user who runs terraform will have access to the cluster, but we want devops_user to have access to the cluster as well, so we need to add this resource to give devops_user access to the cluster
resource "aws_eks_access_entry" "admin_user" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = "arn:aws:iam::${var.aws_account_id}:user/${var.admin_user}"
  type          = "STANDARD"
}
resource "aws_eks_access_policy_association" "admin_user_policy" {
  cluster_name  = aws_eks_cluster.eks.name
  principal_arn = aws_eks_access_entry.admin_user.principal_arn
  policy_arn    = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSClusterAdminPolicy"

  access_scope {
    type = "cluster"
  }
}

#######Addons
resource "aws_eks_addon" "eks_addon" {
  for_each= {for addon in var.addons : addon.name => addon} #convert list(object) to map(object) for easier access
  cluster_name                = aws_eks_cluster.eks.name
  addon_name                  = each.key
  addon_version               = each.value.version #e.g., previous version v1.9.3-eksbuild.3 and the new version is v1.10.1-eksbuild.1
  resolve_conflicts_on_update = "PRESERVE"
}
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
        Federated = aws_iam_openid_connect_provider.oidc.arn
      }

      # Required action for IAM Roles for Service Accounts
      Action = "sts:AssumeRoleWithWebIdentity"

      # Restrict role assumption only to this specific service account
      Condition = {
        StringEquals = {
          "${replace(aws_iam_openid_connect_provider.oidc.url, "https://", "")}:sub" = "system:serviceaccount:kube-system:aws-load-balancer-controller"
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
}


############### EKS Auth Data Source
# Generates temporary authentication token for Kubernetes API access
# Equivalent to running: aws eks get-token
data "aws_eks_cluster_auth" "eks" {
  name = aws_eks_cluster.eks.name
}

############### Kubernetes Provider
# Allows Terraform to create Kubernetes resources (service accounts etc.)
provider "kubernetes" {
  host                   = aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)

  # token generated dynamically using aws_eks_cluster_auth
  token                  = data.aws_eks_cluster_auth.eks.token
}

############### Helm Provider
# Helm provider uses the same Kubernetes connection to install Helm charts
provider "helm" {
  kubernetes ={
    host                   = aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

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