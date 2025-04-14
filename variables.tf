variable "bitbucket_openid_connect_provider_arn" {
  type        = string
  description = "The name of the workspace."
}

variable "bitbucket_workspace_name" {
  type        = string
  description = "The name of the workspace."
}

variable "allowed_subjects" {
  type        = list(string)
  description = "The list of the allowed subjects. You can get this value from Bitbucket Pipeline OpenId Connect page."
}

variable "role_name" {
  type        = string
  description = "The name of the iam role."
}

variable "policy_arns" {
  type        = list(string)
  default     = []
  description = "The arns of policy you want to attach to the role."
}

variable "ecr_repo_name" {
  type        = string
  default     = ""
  description = "The (private ecr) repo name where docker image push to"
}

variable "ecr_repo_names" {
  type        = list(string)
  default     = []
  description = "The (private ecr) repo name where docker image push to"
}

variable "secretmanager_arns" {
  type        = list(string)
  default     = []
  description = "To get secret manager last version uuid"
}

variable "eks_cluster_name" {
  type        = string
  default     = ""
  description = "access to the eks cluster"
}

variable "eks_cluster_names" {
  type        = list(string)
  default     = []
  description = "access to the eks cluster"
}

variable "role_permissions_boundary_arn" {
  type        = string
  default     = null
  description = "The policy ARN that is used to set the permissions boundary for the role"
}

variable "eks_cluster_namespaces" {
  type        = list(string)
  default     = []
  description = "The eks cluster namespace where you will deploy to"
}

locals {
  ecr_list = ((contains(var.ecr_repo_names, var.ecr_repo_name) == false && var.ecr_repo_name != "") ?
    concat(var.ecr_repo_names, [var.ecr_repo_name]) :
    var.ecr_repo_names
  )
  eks_list = ((contains(var.eks_cluster_names, var.eks_cluster_name) == false && var.eks_cluster_name != "") ?
    concat(var.eks_cluster_names, [var.eks_cluster_name]) :
    var.eks_cluster_names
  )
}
