# Bitbucket oidc module

Terraform module for create AWS IAM Role to support Bitbucket OIDC.

## Usage

### Upgrade to 3.4.0

If you upgrade to `3.4.0` and do not set `eks_access_entry_kubernetes_groups`, the module behavior remains the same as previous versions.

- when `eks_access_entry_scope = "namespace"`, the module still automatically adds `group-<namespace>-admin`
- when no Kubernetes groups are produced, `kubernetes_groups` remains `null`

This means existing consumers can upgrade without changing their configuration, and only opt in to the new behavior when extra Kubernetes RBAC groups are needed.

### Add custom Kubernetes groups to EKS access entry

From `3.4.0`, this module supports passing additional Kubernetes groups to the generated EKS access entry. This is useful when the CD role needs extra Kubernetes RBAC permissions beyond the default namespace admin groups.

```hcl
module "bitbucket_oidc_aws_role" {
  source  = "shoplineapp/bitbucket-oidc-aws-role/shoplineapp"
  version = "3.4.0"

  bitbucket_openid_connect_provider_arn = aws_iam_openid_connect_provider.bitbucket.arn
  bitbucket_workspace_name              = "shopline"
  allowed_subjects                      = ["{repository_uuid}:{deployment_environment_uuid}:{step_uuid}"]
  role_name                             = "example-cd-role"

  eks_cluster_name       = "example-eks"
  eks_cluster_namespaces = ["production"]

  # Default namespace group `group-production-admin` will still be included.
  eks_access_entry_kubernetes_groups = [
    "ec2nc-manager",
    "custom-deployer",
  ]
}
```

Behavior summary:

- `eks_access_entry_scope = "namespace"`: automatically includes `group-<namespace>-admin`
- `eks_access_entry_scope = "cluster"`: does not generate default namespace admin groups
- `eks_access_entry_kubernetes_groups`: appends any custom groups you provide
- duplicate group names are removed automatically

Examples:

#### Keep existing behavior after upgrading

```hcl
module "bitbucket_oidc_aws_role" {
  source  = "shoplineapp/bitbucket-oidc-aws-role/shoplineapp"
  version = "3.4.0"

  eks_access_entry_scope = "namespace"
  eks_cluster_namespaces = ["prod"]
}
```

Result:

```hcl
["group-prod-admin"]
```

#### Use `eks_access_entry_scope` together with custom groups

```hcl
module "bitbucket_oidc_aws_role" {
  source  = "shoplineapp/bitbucket-oidc-aws-role/shoplineapp"
  version = "3.4.0"

  eks_access_entry_scope = "namespace"
  eks_cluster_namespaces = ["prod", "staging"]

  eks_access_entry_kubernetes_groups = [
    "ec2nc-manager",
    "group-prod-admin",
  ]
}
```

Result:

```hcl
[
  "group-prod-admin",
  "group-staging-admin",
  "ec2nc-manager",
]
```

`group-prod-admin` is only kept once because duplicate group names are removed automatically.

#### Cluster scope with custom groups only

```hcl
module "bitbucket_oidc_aws_role" {
  source  = "shoplineapp/bitbucket-oidc-aws-role/shoplineapp"
  version = "3.4.0"

  eks_access_entry_scope = "cluster"

  eks_access_entry_kubernetes_groups = [
    "ec2nc-manager",
    "custom-deployer",
  ]
}
```

Result:

```hcl
[
  "ec2nc-manager",
  "custom-deployer",
]
```

## Contribution guidelines

1. Directly modify the tf code.
2. Push to feature branch
3. Verify your changes with feature branch
4. After you verified the changes, merge to master.
5. Once you decide to release the changes, merge feature branch to master and give it a tag!
6. Done, everyone can use your changes with new tag.
