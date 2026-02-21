module "vpc" {
  source              = "./modules/vpc"
  name_prefix         = var.name_prefix
  vpc_cidr            = var.vpc_cidr
  public_subnets  = var.public_subnets
  private_subnets = var.private_subnets
  # availability_zone   = var.availability_zone
  # enable_nat          = var.enable_nat
}

module "eks" {
  source = "./modules/eks"
  name_prefix = var.name_prefix
  eks_subnet_ids = concat(module.vpc.public_subnet_id, module.vpc.private_subnet_id)
  cluster_name = "${var.name_prefix}-eks-cluster"
  cluster_version = var.cluster_version
  
}