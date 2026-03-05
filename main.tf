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