module "vpc" {
  source          = "./modules/vpc"
  name_prefix     = var.name_prefix
  vpc_cidr        = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  # availability_zone   = var.availability_zone
  # enable_nat          = var.enable_nat
}

module "eks" {
  source                            = "./modules/eks"
  name_prefix                       = var.name_prefix
  eks_subnet_ids                    = concat(module.vpc.public_subnet_id, module.vpc.private_subnet_id)
  cluster_name                      = "${var.name_prefix}-eks-cluster"
  cluster_version                   = var.cluster_version
  eks_ng_subnet_ids                 = module.vpc.private_subnet_id
  node_group_instance_types         = ["t3.small"]
  node_group_desired_size           = 1
  node_group_max_size               = 2
  node_group_min_size               = 1
  node_group_update_max_unavailable = 1
  aws_account_id                    = var.aws_account_id
  admin_user                        = var.admin_user
  addons                            = var.addons
  region                            = module.vpc.vpc_region
  vpc_id                            = module.vpc.vpc_id
}


############### EKS Auth Data Source
# Generates temporary authentication token for Kubernetes API access
# Equivalent to running: aws eks get-token
data "aws_eks_cluster_auth" "eks" {
  name = module.eks.cluster_name
}

data "aws_eks_cluster" "eks" {
  name = module.eks.cluster_name
}
############### Kubernetes Provider
# Allows Terraform to create Kubernetes resources (service accounts etc.)
provider "kubernetes" {
  host                   = data.aws_eks_cluster.eks.endpoint
  cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)

  # token generated dynamically using aws_eks_cluster_auth
  token                  = data.aws_eks_cluster_auth.eks.token
}

############### Helm Provider
# Helm provider uses the same Kubernetes connection to install Helm charts
provider "helm" {
  kubernetes ={
    host                   = data.aws_eks_cluster.eks.endpoint
    cluster_ca_certificate = base64decode(data.aws_eks_cluster.eks.certificate_authority[0].data)
    token                  = data.aws_eks_cluster_auth.eks.token
  }
}

module "eks-ingress-controller" {
  source                     = "./modules/eks-ingress-controller"
  aws_account_id             = var.aws_account_id
  cluster_name               = module.eks.cluster_name
  cluster_accessible_from_admin_user = module.eks.cluster_accessible_from_admin_user
  region                     = module.vpc.vpc_region
  vpc_id                     = module.vpc.vpc_id
  providers = {
    kubernetes = kubernetes
    helm       = helm
  }
  depends_on = [ module.eks ]
}