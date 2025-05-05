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

resource "time_sleep" "aws_iam_role_propagation" {
  # To avoid issues with IAM role creation before propagation is complete
  create_duration = "10s"
  depends_on      = [aws_iam_role.this]
}

resource "aws_eks_access_entry" "this" {
  count         = var.create_eks_access_entry == true ? 1 : 0
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  # Use helm chart to create the group by default, please find the group name convention in helm chart repo.
  # ref: https://github.com/shoplineapp/helm-charts/blob/master/eks/templates/role_admin.yaml
  kubernetes_groups = var.eks_access_entry_scope == "namespace" ? [for ns in var.eks_cluster_namespaces : "group-${ns}-admin"] : null
  depends_on        = [time_sleep.aws_iam_role_propagation]
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
  # Add depends_on to avoid, the following error
  # Error: creating EKS Access Policy Association (CLUSTER_NAME#arn:aws:iam::123456789012:role/CD_ROLE_NAME#arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy): operation error EKS: AssociateAccessPolicy, https response error StatusCode: 404, RequestID: abcd1234-ab12-cd56-efg7-087d532fbcf4, ResourceNotFoundException: The specified principalArn could not be found. You can view your available access entries with 'list-access-entries'.
  # See: https://github.com/hashicorp/terraform-provider-aws/issues/40951
  depends_on = [
    aws_eks_access_entry.this
  ]
}

terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 5.33.0"
      # aws_eks_access_policy_association required version > 5.33.0
    }
  }
}
