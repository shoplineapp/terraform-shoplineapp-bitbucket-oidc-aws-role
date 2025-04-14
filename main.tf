data "aws_iam_policy_document" "bitbucket_assume_role_policy" {
  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [var.bitbucket_openid_connect_provider_arn]
      type        = "Federated"
    }

    condition {
      test     = "StringLike"
      variable = "api.bitbucket.org/2.0/workspaces/${var.bitbucket_workspace_name}/pipelines-config/identity/oidc:sub"
      values   = var.allowed_subjects
    }
  }
}

resource "aws_iam_role" "this" {
  name                 = var.role_name
  assume_role_policy   = data.aws_iam_policy_document.bitbucket_assume_role_policy.json
  permissions_boundary = var.role_permissions_boundary_arn

  tags = {
    Name = var.role_name
  }
}

resource "aws_iam_role_policy_attachment" "this" {
  count = length(var.policy_arns)

  role       = aws_iam_role.this.name
  policy_arn = var.policy_arns[count.index]
}

resource "aws_eks_access_entry" "this" {
  count         = var.create_eks_access_entry == true ? 1 : 0
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  type          = "STANDARD"
  # Use helm chart to create the group by default, please find the group name convention in helm chart repo.
  # ref: https://github.com/shoplineapp/helm-charts/blob/master/eks/templates/role_admin.yaml
  kubernetes_groups = var.eks_access_entry_scope == "namespace" ? [for ns in var.eks_cluster_namespaces : "group-${ns}-admin"] : null
}

resource "aws_eks_access_policy_association" "this" {
  count         = var.create_eks_access_entry == true ? 1 : 0
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  # Give the cd role namespace admin by default, ref: https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  access_scope {
    type       = var.eks_access_entry_scope
    namespaces = var.eks_access_entry_scope == "namespace" ? var.eks_cluster_namespaces : null
  }
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.33.0"
      # aws_eks_access_policy_association required version > 5.33.0
    }
  }
}
