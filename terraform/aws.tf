locals {
  cluster_name = "wiz-code-eks-cluster"
}

module "eks-vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "3.14.2"

  name = "wiz-code-eks-vpc"

  cidr = "10.0.0.0/16"
  azs  = slice(data.aws_availability_zones.available.names, 0, 3)

  private_subnets = ["10.0.11.0/24", "10.0.12.0/24", "10.0.13.0/24"]
  public_subnets  = ["10.0.21.0/24", "10.0.22.0/24", "10.0.23.0/24"]

  enable_nat_gateway   = true
  single_nat_gateway   = true
  enable_dns_hostnames = true

  public_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/elb"                      = 1
  }

  private_subnet_tags = {
    "kubernetes.io/cluster/${local.cluster_name}" = "shared"
    "kubernetes.io/role/internal-elb"             = 1
  }
}

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "18.31.2"

  cluster_name                    = local.cluster_name
  cluster_version                 = "1.30"
  cluster_endpoint_private_access = true
  cluster_endpoint_public_access  = true
  subnet_ids                      = module.eks-vpc.private_subnets
  vpc_id                          = module.eks-vpc.vpc_id

  cluster_addons = {
    vpc-cni = {
      most_recent = true
    }
  }

  node_security_group_additional_rules = {
    ingress_self_all = {
      description = "Node to node all ports/protocols"
      protocol    = "-1"
      from_port   = 0
      to_port     = 0
      type        = "ingress"
      self        = true
    }
    ingress_cluster_all = {
      description                   = "Cluster to node all ports/protocols"
      protocol                      = "-1"
      from_port                     = 0
      to_port                       = 0
      type                          = "ingress"
      source_cluster_security_group = true
    }
    egress_all = {
      description      = "Node all egress"
      protocol         = "-1"
      from_port        = 0
      to_port          = 0
      type             = "egress"
      cidr_blocks      = ["0.0.0.0/0"]
      ipv6_cidr_blocks = ["::/0"]
    }
  }

  eks_managed_node_group_defaults = {
    disk_size      = 50
    instance_types = ["t3.small"]
    iam_role_arn   = "arn:aws:iam::aws:policy/AmazonEC2ContainerRegistryReadOnly"
  }

  eks_managed_node_groups = {
    eks = {
      min_size     = 2
      max_size     = 4
      desired_size = 2

      instance_types = ["t3.small"]
      capacity_type  = "SPOT"
    }
  }

  tags = {
    Environment = "wiz-code-demo-eks"
  }
}

data "aws_eks_cluster_auth" "auth" {
  name = module.eks.cluster_id
}

resource "helm_release" "wiz_integration" {
  name             = "wiz-integration"
  repository       = "https://wiz-sec.github.io/charts"
  chart            = "wiz-kubernetes-integration"
  namespace        = "wiz"
  create_namespace = true

  set {
    name  = "global.wizApiToken.secret.create"
    value = "false"
  }

  set {
    name  = "global.wizApiToken.secret.name"
    value = "wiz-api-token"
  }

  set {
    name  = "global.wizApiToken.clientEndpoint"
    value = ""
  }

  set {
    name  = "wiz-kubernetes-connector.enabled"
    value = "true"
  }

  set {
    name  = "wiz-kubernetes-connector.autoCreateConnector.connectorName"
    value = "wiz-code-eks-cluster"
  }

  set {
    name  = "wiz-kubernetes-connector.broker.enabled"
    value = "true"
  }

  set {
    name  = "wiz-sensor.enabled"
    value = "true"
  }

  set {
    name  = "wiz-sensor.imagePullSecret.create"
    value = "false"
  }

  set {
    name  = "wiz-sensor.imagePullSecret.name"
    value = "sensor-image-pull"
  }

  set {
    name  = "wiz-admission-controller.enabled"
    value = "true"
  }

  set {
    name  = "wiz-admission-controller.kubernetesAuditLogsWebhook.enabled"
    value = "true"
  }

  depends_on = [
    kubernetes_secret.sensor_image_pull,
    kubernetes_secret.wiz_api_token,
    kubernetes_namespace.wiz
  ]
}

# Create the namespace
resource "kubernetes_namespace" "wiz" {
  metadata {
    name = "wiz"
  }
}

# Create the docker-registry secret
resource "kubernetes_secret" "sensor_image_pull" {
  metadata {
    name      = "sensor-image-pull"
    namespace = kubernetes_namespace.wiz.metadata[0].name
  }

  type = "kubernetes.io/dockerconfigjson"

  data = {
    ".dockerconfigjson" = jsonencode({
      auths = {
        "wizio.azurecr.io/sensor" = {
          username = var.sensor_pullkey_username
          password = var.sensor_pullkey_password
        }
      }
    })
  }
    depends_on = [
    kubernetes_namespace.wiz
  ]
}

# Create the generic secret for wiz-api-token
resource "kubernetes_secret" "wiz_api_token" {
  metadata {
    name      = "wiz-api-token"
    namespace = kubernetes_namespace.wiz.metadata[0].name
  }

  data = {
    clientId    = var.wiz_service_account_id
    clientToken = var.wiz_service_account_token
  }
      depends_on = [
    kubernetes_namespace.wiz
  ]
}

