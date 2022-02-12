variable "bitbucket_openid_connect_provider_arn" {
  type = string
}

variable "bitbucket_workspace_name" {
  type        = string
  description = "The name of the workspace."
}

variable "roles" {
  default    = {}
  type       = map(object({
    name             = string
    tags             = object({})
    allowed_subjects = list(string)
    policies         = map(object({
      arn = string
    }))
  }))
  description = "A map of roles to create. The roles will be exposed in the output with their same key. Allowed subjects will be matched against the sub claim and they can be specified with wildcard. More info about their format here: https://support.atlassian.com/bitbucket-cloud/docs/deploy-on-aws-using-bitbucket-pipelines-openid-connect/#Using-claims-in-ID-tokens-to-limit-access-to-the-IAM-role-in-AWS. inline_policies_json is a list of json strings to attach as inline policies."
}
