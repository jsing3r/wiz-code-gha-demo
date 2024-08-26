data "aws_availability_zones" "available" {
  state = "available"
}

data "aws_eks_cluster_auth" "wiz_code" {
  name = module.eks.cluster_id
}
