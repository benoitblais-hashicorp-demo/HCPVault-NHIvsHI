# ------------------------------------------------------------------------------
# Child Namespace
# ------------------------------------------------------------------------------

resource "vault_namespace" "demo" {
  path = var.namespace_path
}

# ------------------------------------------------------------------------------
# NHI Shared Policy
#
# A single policy is shared across all Non-Human Identity auth methods
# (GitHub Actions JWT, HCP Terraform JWT). The policy name matches the NHI
# entity name for consistent identification in Vault audit logs.
# ------------------------------------------------------------------------------

resource "vault_policy" "nhi" {
  count = (var.github_jwt_repository != null || var.hcp_jwt_workspace_name != null) ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  name      = var.nhi_entity_name

  # KVv2 stores secrets under the '<mount>/data/<path>' API endpoint.
  policy = <<-EOT
    path "${var.kv_mount_path}/data/${var.nhi_kv_secret_name}" {
      capabilities = ["read"]
    }

    # Allow the Vault provider to validate its token on initialization.
    path "auth/token/lookup-self" {
      capabilities = ["read"]
    }

    # Allow token self-renewal and self-revocation.
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "auth/token/revoke-self" {
      capabilities = ["update"]
    }
  EOT
}

# ------------------------------------------------------------------------------
# GitHub Actions — JWT Auth
#
# GitHub exposes an OIDC discovery endpoint at:
#   https://token.actions.githubusercontent.com
#
# The auth backend is configured with that discovery URL so Vault can
# automatically retrieve the JWKS and validate token signatures.
#
# Access is restricted to a single repository via the 'repository' bound claim.
# ------------------------------------------------------------------------------

resource "vault_jwt_auth_backend" "jwt_github" {
  count = var.github_jwt_repository != null ? 1 : 0

  namespace          = vault_namespace.demo.path_fq
  description        = var.github_jwt_backend_description
  path               = var.github_jwt_backend_path
  oidc_discovery_url = var.github_jwt_discovery_url
  bound_issuer       = var.github_jwt_bound_issuer
}

resource "vault_jwt_auth_backend_role" "jwt_github" {
  count = length(vault_jwt_auth_backend.jwt_github) > 0 ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  backend   = vault_jwt_auth_backend.jwt_github[0].path
  role_name = var.github_jwt_role_name
  role_type = "jwt"

  # The audience must match the value the workflow requests when calling
  # actions/id-token. Update var.github_jwt_audience in the workflow accordingly.
  bound_audiences = [var.github_jwt_audience]

  # Restrict authentication to the single trusted repository.
  bound_claims = {
    repository = var.github_jwt_repository
  }

  # 'repository' is a stable claim (org/repo) that matches the pre-created
  # entity alias name, enabling consistent identity across workflow runs.
  user_claim = "repository"

  token_policies          = [vault_policy.nhi[0].name]
  token_ttl               = var.github_jwt_token_ttl
  token_max_ttl           = var.github_jwt_token_max_ttl
  token_no_default_policy = true
}

# ------------------------------------------------------------------------------
# HCP Terraform — JWT Auth
#
# HCP Terraform issues workload identity JWT tokens signed by:
#   https://app.terraform.io
#
# The standard audience for Vault dynamic provider credentials is
# "vault.workload.identity". Access is restricted to a single workspace via
# the 'terraform_workspace_name' bound claim.
# ------------------------------------------------------------------------------

resource "vault_jwt_auth_backend" "jwt_hcp" {
  count = var.hcp_jwt_workspace_name != null ? 1 : 0

  namespace          = vault_namespace.demo.path_fq
  description        = var.hcp_jwt_backend_description
  path               = var.hcp_jwt_backend_path
  oidc_discovery_url = var.hcp_jwt_discovery_url
  bound_issuer       = var.hcp_jwt_bound_issuer
}

resource "vault_jwt_auth_backend_role" "jwt_hcp" {
  count = length(vault_jwt_auth_backend.jwt_hcp) > 0 ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  backend   = vault_jwt_auth_backend.jwt_hcp[0].path
  role_name = var.hcp_jwt_role_name
  role_type = "jwt"

  # "vault.workload.identity" is the standard audience for Vault dynamic
  # provider credentials in HCP Terraform and Terraform Enterprise.
  bound_audiences = ["vault.workload.identity"]

  # Restrict authentication to the single trusted HCP Terraform workspace.
  bound_claims = {
    terraform_workspace_name = var.hcp_jwt_workspace_name
  }

  # Use the workspace name as the Vault entity alias for auditability.
  user_claim = "terraform_workspace_name"

  token_policies          = [vault_policy.nhi[0].name]
  token_ttl               = var.hcp_jwt_token_ttl
  token_max_ttl           = var.hcp_jwt_token_max_ttl
  token_no_default_policy = true
}

# ------------------------------------------------------------------------------
# HI Shared Policy
#
# A single policy is shared across all Human Identity auth methods
# (Userpass, GitHub PAT). The policy name matches the HI entity name
# for consistent identification in Vault audit logs.
# ------------------------------------------------------------------------------

resource "vault_policy" "human" {
  count = (var.userpass_username != null || var.github_username != null) ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  name      = var.hi_entity_name

  # KVv2 stores secrets under the '<mount>/data/<path>' API endpoint.
  # Listing and reading metadata is required for the secret name to be
  # visible when browsing the KVv2 mount in the Vault UI.
  policy = <<-EOT
    path "${var.kv_mount_path}/data/${var.hi_kv_secret_name}" {
      capabilities = ["read"]
    }

    path "${var.kv_mount_path}/metadata/*" {
      capabilities = ["list"]
    }

    path "${var.kv_mount_path}/metadata/${var.hi_kv_secret_name}" {
      capabilities = ["read"]
    }

    # Allow token self-renewal and self-revocation.
    path "auth/token/renew-self" {
      capabilities = ["update"]
    }

    path "auth/token/revoke-self" {
      capabilities = ["update"]
    }
  EOT
}

# ------------------------------------------------------------------------------
# Human Identity — Userpass Auth
#
# Classic username/password login for human operators. A dedicated userpass
# backend is enabled and a single user is created. The operator's token is
# scoped to the same read-only policy as the HI roles, demonstrating that the
# human and machine identities converge on the same entity and permissions.
# ------------------------------------------------------------------------------

resource "vault_auth_backend" "userpass" {
  count = var.userpass_username != null ? 1 : 0

  namespace   = vault_namespace.demo.path_fq
  type        = "userpass"
  path        = var.userpass_backend_path
  description = var.userpass_backend_description
}

# Generates a random password for the userpass user so no static secret
# needs to be supplied or stored outside of Terraform state.
resource "random_password" "userpass" {
  count = length(vault_auth_backend.userpass) > 0 ? 1 : 0

  length           = 20
  special          = true
  override_special = "!#$%&*-_=+?"
}

# Creates the userpass user and binds the human policy.
# vault_generic_endpoint is used because no dedicated userpass-user resource
# exists in the Vault provider; the write is idempotent.
resource "vault_generic_endpoint" "userpass" {
  count = length(vault_auth_backend.userpass) > 0 ? 1 : 0

  namespace            = vault_namespace.demo.path_fq
  path                 = "auth/${vault_auth_backend.userpass[0].path}/users/${var.userpass_username}"
  ignore_absent_fields = true

  data_json = jsonencode({
    password       = random_password.userpass[0].result
    token_policies = [vault_policy.human[0].name]
    token_ttl      = var.userpass_token_ttl
    token_max_ttl  = var.userpass_token_max_ttl
  })
}

# ------------------------------------------------------------------------------
# Human Identity — GitHub PAT Auth
#
# Vault's native GitHub auth method validates Personal Access Tokens issued to
# a GitHub user. The operator logs in with 'vault login -method=github
# token=<PAT>'. Access is restricted to a single GitHub username.
# ------------------------------------------------------------------------------

resource "vault_github_auth_backend" "github" {
  count = var.github_username != null ? 1 : 0

  namespace    = vault_namespace.demo.path_fq
  path         = var.github_backend_path
  organization = var.github_org
  description  = var.github_backend_description

  token_ttl     = var.github_token_ttl
  token_max_ttl = var.github_token_max_ttl
}

# Maps the specific GitHub user to the human policy.
resource "vault_github_user" "github" {
  count = length(vault_github_auth_backend.github) > 0 ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  backend   = vault_github_auth_backend.github[0].path
  user      = var.github_username
  policies  = [vault_policy.human[0].name]
}

# ------------------------------------------------------------------------------
# Identity Entities
#
# Two distinct entities are created to clearly separate concerns:
#   - nhi: represents the application/machine identity (GitHub Actions, HCP Terraform)
#   - hi: represents the human operator identity (userpass, GitHub PAT)
# Auth-method-specific aliases are linked to their respective entity so that
# policies, audit logs, and metadata remain cleanly separated.
# ------------------------------------------------------------------------------

# NHI entity — created only when at least one NHI auth method is enabled.
resource "vault_identity_entity" "nhi" {
  count = (var.github_jwt_repository != null || var.hcp_jwt_workspace_name != null) ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  name      = var.nhi_entity_name
  metadata  = var.nhi_entity_metadata
}

# HI entity — created only when at least one HI auth method is enabled.
resource "vault_identity_entity" "hi" {
  count = (var.userpass_username != null || var.github_username != null) ? 1 : 0

  namespace = vault_namespace.demo.path_fq
  name      = var.hi_entity_name
  metadata  = var.hi_entity_metadata
}

# ------------------------------------------------------------------------------
# Identity Entity Aliases
#
# Each alias links an auth-method-specific login identity to the shared entity.
# The alias name must match the value of the role's user_claim at login time:
#   - GitHub Actions : user_claim = "repository"              → value = "org/repo"
#   - HCP Terraform  : user_claim = "terraform_workspace_name" → value = workspace name
#   - Userpass        : alias name = username
#   - GitHub PAT      : alias name = GitHub login (username)
# ------------------------------------------------------------------------------

resource "vault_identity_entity_alias" "jwt_github" {
  count = var.github_jwt_repository != null ? 1 : 0

  namespace      = vault_namespace.demo.path_fq
  name           = var.github_jwt_repository
  mount_accessor = vault_jwt_auth_backend.jwt_github[0].accessor
  canonical_id   = vault_identity_entity.nhi[0].id
}

resource "vault_identity_entity_alias" "jwt_hcp" {
  count = var.hcp_jwt_workspace_name != null ? 1 : 0

  namespace      = vault_namespace.demo.path_fq
  name           = var.hcp_jwt_workspace_name
  mount_accessor = vault_jwt_auth_backend.jwt_hcp[0].accessor
  canonical_id   = vault_identity_entity.nhi[0].id
}

resource "vault_identity_entity_alias" "userpass" {
  count = var.userpass_username != null ? 1 : 0

  namespace      = vault_namespace.demo.path_fq
  name           = var.userpass_username
  mount_accessor = vault_auth_backend.userpass[0].accessor
  canonical_id   = vault_identity_entity.hi[0].id
}

resource "vault_identity_entity_alias" "github" {
  count = var.github_username != null ? 1 : 0

  namespace      = vault_namespace.demo.path_fq
  name           = var.github_username
  mount_accessor = vault_github_auth_backend.github[0].accessor
  canonical_id   = vault_identity_entity.hi[0].id
}

# ------------------------------------------------------------------------------
# KVv2 Secrets Engine
# ------------------------------------------------------------------------------

resource "vault_mount" "kvv2" {
  count = var.kv_mount_path != null ? 1 : 0

  namespace   = vault_namespace.demo.path_fq
  path        = var.kv_mount_path
  type        = "kv"
  description = var.kv_mount_description

  options = {
    version = "2"
  }
}

# NHI demo secret — created only when the KVv2 mount is enabled and at least one NHI auth method is configured.
resource "vault_kv_secret_v2" "nhi" {
  count = length(vault_mount.kvv2) > 0 && (var.github_jwt_repository != null || var.hcp_jwt_workspace_name != null) ? 1 : 0

  namespace           = vault_namespace.demo.path_fq
  mount               = vault_mount.kvv2[0].path
  name                = var.nhi_kv_secret_name
  delete_all_versions = true

  data_json = jsonencode(var.nhi_kv_secret_data)
}

# HI demo secret — created only when the KVv2 mount is enabled and at least one HI auth method is configured.
resource "vault_kv_secret_v2" "hi" {
  count = length(vault_mount.kvv2) > 0 && (var.userpass_username != null || var.github_username != null) ? 1 : 0

  namespace           = vault_namespace.demo.path_fq
  mount               = vault_mount.kvv2[0].path
  name                = var.hi_kv_secret_name
  delete_all_versions = true

  data_json = jsonencode(var.hi_kv_secret_data)
}