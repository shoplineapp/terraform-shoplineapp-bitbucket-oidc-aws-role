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
  name               = var.role_name
  assume_role_policy = data.aws_iam_policy_document.bitbucket_assume_role_policy.json

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
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  type          = "STANDARD"
}

resource "aws_eks_access_policy_association" "this" {
  cluster_name  = var.eks_cluster_name
  principal_arn = aws_iam_role.this.arn
  # Default give the cd role namespace admin, ref: https://docs.aws.amazon.com/eks/latest/userguide/access-policy-permissions.html
  policy_arn = "arn:aws:eks::aws:cluster-access-policy/AmazonEKSAdminPolicy"
  access_scope {
    type       = var.eks_access_entry_scope
    namespaces = var.eks_access_entry_scope == "namespace" ? var.eks_cluster_namespaces : null
  }
}