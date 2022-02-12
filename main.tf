locals {
  role_policy_attachments = flatten([
    for role_key, role in var.roles : [
      for policy_key, policy in role.policies : {
        role_key   = role_key
        policy_key = policy_key
        policy_arn = policy.arn
      }
    ]
  ])
}

data "aws_iam_policy_document" "bitbucket_assume_role_policy" {
  for_each = var.roles

  statement {
    actions = ["sts:AssumeRoleWithWebIdentity"]

    principals {
      identifiers = [var.bitbucket_openid_connect_provider_arn]
      type        = "Federated"
    }

    condition {
      test     = "StringLike"
      variable = "api.bitbucket.org/2.0/workspaces/${var.bitbucket_workspace_name}/pipelines-config/identity/oidc:sub"
      values   = each.value.allowed_subjects
    }
  }
}

resource "aws_iam_role" "this" {
  for_each           = data.aws_iam_policy_document.bitbucket_assume_role_policy

  name               = var.roles[each.key].name
  assume_role_policy = each.value.json

  tags = var.roles[each.key].tags
}

resource "aws_iam_role_policy_attachment" "api_service_process_order_event" {
  for_each = {
    for attachment in local.role_policy_attachments : "${attachment.role_key}:${attachment.policy_key}" => attachment
  }

  role       = aws_iam_role.this[each.value.role_key].name
  policy_arn = each.value.policy_arn
}