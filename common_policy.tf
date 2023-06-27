

data "aws_eks_cluster" "eks" {
  for_each = toset(local.eks_list)
  name     = each.key
}

data "aws_ecr_repository" "ecr" {
  for_each = toset(local.ecr_list)
  name     = each.key
}

data "aws_iam_policy_document" "ecr_policy" {
  count = length(local.ecr_list) > 0 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "ecr:BatchGetImage",
      "ecr:BatchCheckLayerAvailability",
      "ecr:PutLifecyclePolicy",
      "ecr:PutImageTagMutability",
      "ecr:StartImageScan",
      "ecr:CreateRepository",
      "ecr:PutImageScanningConfiguration",
      "ecr:UploadLayerPart",
      "ecr:PutImage",
      "ecr:UntagResource",
      "ecr:SetRepositoryPolicy",
      "ecr:CompleteLayerUpload",
      "ecr:TagResource",
      "ecr:StartLifecyclePolicyPreview",
      "ecr:InitiateLayerUpload",
      "ecr:ReplicateImage"
    ]
    resources = [
      for ecr in data.aws_ecr_repository.ecr : ecr.arn
    ]
  }

  statement {
    effect = "Allow"
    actions = [
      "ecr:Get*",
      "ecr:List*",
      "ecr:Describe*"
    ]
    resources = ["*"]
  }
}

data "aws_iam_policy_document" "eks_policy" {
  count = length(local.eks_list) > 0 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "eks:ListClusters",
      "eks:DescribeAddonVersions",
      "eks:DescribeCluster"
    ]
    resources = [
      for eks in data.aws_eks_cluster.eks : eks.arn
    ]
  }
}

data "aws_iam_policy_document" "secret_policy" {
  count = length(var.secretmanager_arns) > 0 ? 1 : 0
  statement {
    effect = "Allow"
    actions = [
      "secretsmanager:GetResourcePolicy",
      "secretsmanager:GetSecretValue",
      "secretsmanager:DescribeSecret",
      "secretsmanager:ListSecretVersionIds"
    ]
    resources = var.secretmanager_arns
  }
}

resource "aws_iam_role_policy" "secret_policy" {
  count  = length(var.secretmanager_arns) > 0 ? 1 : 0
  name   = "${var.role_name}-secret-policy"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.secret_policy[count.index].json
}

resource "aws_iam_role_policy" "eks_policy" {
  count  = length(local.eks_list) > 0 ? 1 : 0
  name   = "${var.role_name}-eks-policy"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.eks_policy[count.index].json
}

resource "aws_iam_role_policy" "ecr_policy" {
  count  = length(local.ecr_list) > 0 ? 1 : 0
  name   = "${var.role_name}-ecr-policy"
  role   = aws_iam_role.this.name
  policy = data.aws_iam_policy_document.ecr_policy[count.index].json
}
