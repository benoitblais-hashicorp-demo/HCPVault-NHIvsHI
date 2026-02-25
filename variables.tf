variable "github_jwt_audience" {
  type        = string
  description = "(Optional) The JWT audience that GitHub Actions workflows must request when generating an OIDC token. Must match the 'audience' parameter in the 'id-token' step of the workflow."
  default     = "https://vault.hashicorp.cloud"

  validation {
    condition     = can(regex("^https://", var.github_jwt_audience))
    error_message = "`github_jwt_audience` must be a valid HTTPS URL."
  }
}

variable "github_jwt_backend_description" {
  type        = string
  description = "(Optional) The description of the JWT auth backend for the GitHub Actions."
  default     = "JWT/OIDC auth method for GitHub Actions workflows."

  validation {
    condition     = length(var.github_jwt_backend_description) > 0
    error_message = "`github_jwt_backend_description` must not be empty."
  }
}

variable "github_jwt_backend_path" {
  type        = string
  description = "(Optional) Path to mount the JWT auth backend for the GitHub Actions."
  default     = "jwt_github"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.github_jwt_backend_path))
    error_message = "`github_jwt_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "github_jwt_bound_issuer" {
  type        = string
  description = "(Optional) Expected issuer (iss claim) of GitHub Actions OIDC tokens. Must match the issuer of the OIDC discovery endpoint."
  default     = "https://token.actions.githubusercontent.com"

  validation {
    condition     = can(regex("^https://", var.github_jwt_bound_issuer))
    error_message = "`github_jwt_bound_issuer` must be a valid HTTPS URL."
  }
}

variable "github_jwt_discovery_url" {
  type        = string
  description = "(Optional) The OIDC Discovery URL used by Vault to retrieve the GitHub Actions JWKS and validate token signatures."
  default     = "https://token.actions.githubusercontent.com"

  validation {
    condition     = can(regex("^https://", var.github_jwt_discovery_url))
    error_message = "`github_jwt_discovery_url` must be a valid HTTPS URL."
  }
}

variable "github_jwt_role_name" {
  type        = string
  description = "(Optional) Name of the Vault role used by GitHub Actions workflows during JWT login."
  default     = "jwt_github"

  validation {
    condition     = length(var.github_jwt_role_name) > 0
    error_message = "`github_jwt_role_name` must not be empty."
  }
}

variable "github_jwt_policy_name" {
  type        = string
  description = "(Optional) The name of the Vault policy attached to the GitHub Actions JWT role."
  default     = "jwt_github"

  validation {
    condition     = length(var.github_jwt_policy_name) > 0
    error_message = "`github_jwt_policy_name` must not be empty."
  }
}

variable "github_jwt_repository" {
  type        = string
  description = "(Optional) Trusted GitHub repository in 'organization/repository' format (e.g., 'my-org/my-repo'). When set, the GitHub Actions JWT auth method is configured and only workflows from this repository can authenticate. Set to null to skip GitHub auth entirely."
  default     = null

  validation {
    condition     = var.github_jwt_repository == null || can(regex("^[^/]+/[^/]+$", var.github_jwt_repository))
    error_message = "`github_jwt_repository` must be in 'organization/repository' format (e.g., 'my-org/my-repo') or null."
  }
}

variable "github_jwt_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum lifetime of a GitHub Actions Vault token, in seconds."
  default     = 600

  validation {
    condition     = var.github_jwt_token_max_ttl > 0
    error_message = "`github_jwt_token_max_ttl` must be greater than 0."
  }
}

variable "github_jwt_token_ttl" {
  type        = number
  description = "(Optional) Default lifetime of a GitHub Actions Vault token, in seconds."
  default     = 300

  validation {
    condition     = var.github_jwt_token_ttl > 0
    error_message = "`github_jwt_token_ttl` must be greater than 0."
  }
}

variable "hcp_jwt_backend_description" {
  type        = string
  description = "(Optional) The description of the HCP Terraform JWT auth backend."
  default     = "JWT auth method for HCP Terraform workload identity tokens."

  validation {
    condition     = length(var.hcp_jwt_backend_description) > 0
    error_message = "`hcp_jwt_backend_description` must not be empty."
  }
}

variable "hcp_jwt_backend_path" {
  type        = string
  description = "(Optional) Path to mount the JWT auth backend for the HCP Terraform JWT."
  default     = "hcp-terraform"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.hcp_jwt_backend_path))
    error_message = "`hcp_jwt_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "hcp_jwt_bound_issuer" {
  type        = string
  description = "(Optional) Expected issuer (iss claim) of HCP Terraform workload identity JWT tokens."
  default     = "https://app.terraform.io"

  validation {
    condition     = can(regex("^https://", var.hcp_jwt_bound_issuer))
    error_message = "`hcp_jwt_bound_issuer` must be a valid HTTPS URL."
  }
}

variable "hcp_jwt_discovery_url" {
  type        = string
  description = "(Optional) OIDC discovery URL used by Vault to retrieve the HCP Terraform JWKS and validate token signatures."
  default     = "https://app.terraform.io"

  validation {
    condition     = can(regex("^https://", var.hcp_jwt_discovery_url))
    error_message = "`hcp_jwt_discovery_url` must be a valid HTTPS URL."
  }
}

variable "hcp_jwt_role_name" {
  type        = string
  description = "(Optional) Name of the Vault role used by the HCP Terraform workspace during JWT login."
  default     = "hcp-terraform-workspace"

  validation {
    condition     = length(var.hcp_jwt_role_name) > 0
    error_message = "`hcp_jwt_role_name` must not be empty."
  }
}

variable "hcp_jwt_policy_name" {
  type        = string
  description = "(Optional) Name of the Vault policy attached to the HCP Terraform JWT role."
  default     = "hcp-terraform-readonly"

  validation {
    condition     = length(var.hcp_jwt_policy_name) > 0
    error_message = "`hcp_jwt_policy_name` must not be empty."
  }
}

variable "hcp_jwt_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum lifetime of an HCP Terraform Vault token, in seconds."
  default     = 600

  validation {
    condition     = var.hcp_jwt_token_max_ttl > 0
    error_message = "`hcp_jwt_token_max_ttl` must be greater than 0."
  }
}

variable "hcp_jwt_token_ttl" {
  type        = number
  description = "(Optional) Default lifetime of an HCP Terraform Vault token, in seconds."
  default     = 300

  validation {
    condition     = var.hcp_jwt_token_ttl > 0
    error_message = "`hcp_jwt_token_ttl` must be greater than 0."
  }
}

variable "hcp_jwt_workspace_name" {
  type        = string
  description = "(Optional) The HCP Terraform workspace name that is allowed to access the KVv2 secret. When set, the HCP Terraform JWT auth method is configured and only runs from this workspace can authenticate. Set to null to skip HCP Terraform auth entirely."
  default     = null

  validation {
    condition     = var.hcp_jwt_workspace_name == null || length(var.hcp_jwt_workspace_name) > 0
    error_message = "`hcp_jwt_workspace_name` must not be an empty string when set."
  }
}

variable "hi_entity_metadata" {
  type        = map(string)
  description = "(Optional) Metadata key-value pairs attached to the Vault identity entity that represents the human operator identity (e.g., team, owner, environment)."
  default     = {}
}

variable "hi_entity_name" {
  type        = string
  description = "(Optional) Name of the Vault identity entity that represents the human operator identity."
  default     = "hi-demo-operator"

  validation {
    condition     = length(var.hi_entity_name) > 0
    error_message = "`hi_entity_name` must not be empty."
  }
}

variable "hi_github_backend_description" {
  type        = string
  description = "(Optional) The description of the GitHub PAT auth backend."
  default     = "GitHub auth method for human operators using Personal Access Tokens."

  validation {
    condition     = length(var.hi_github_backend_description) > 0
    error_message = "`hi_github_backend_description` must not be empty."
  }
}

variable "hi_github_backend_path" {
  type        = string
  description = "(Optional) Path to mount the GitHub PAT auth backend."
  default     = "github-hi"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.hi_github_backend_path))
    error_message = "`hi_github_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "hi_github_org" {
  type        = string
  description = "(Optional) GitHub organization used by the PAT auth backend. Required when `hi_github_username` is set."
  default     = null

  validation {
    condition     = var.hi_github_org == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.hi_github_org))
    error_message = "`hi_github_org` must be a valid GitHub organization name (alphanumeric and hyphens, no leading or trailing hyphens) or null."
  }
}

variable "hi_github_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum lifetime of a human operator GitHub PAT Vault token, in seconds."
  default     = 14400

  validation {
    condition     = var.hi_github_token_max_ttl > 0
    error_message = "`hi_github_token_max_ttl` must be greater than 0."
  }
}

variable "hi_github_token_ttl" {
  type        = number
  description = "(Optional) Default lifetime of a human operator GitHub PAT Vault token, in seconds."
  default     = 3600

  validation {
    condition     = var.hi_github_token_ttl > 0
    error_message = "`hi_github_token_ttl` must be greater than 0."
  }
}

variable "hi_github_username" {
  type        = string
  description = "(Optional) GitHub username (login) of the operator allowed to authenticate with a PAT. When set, the GitHub PAT auth method is configured. Set to null to skip."
  default     = null

  validation {
    condition     = var.hi_github_username == null || can(regex("^[a-zA-Z0-9][a-zA-Z0-9-]*[a-zA-Z0-9]$", var.hi_github_username))
    error_message = "`hi_github_username` must be a valid GitHub username (alphanumeric and hyphens, no leading or trailing hyphens) or null."
  }
}

variable "hi_kv_secret_data" {
  type        = map(string)
  description = "(Optional) Key-value pairs stored in the KVv2 engine as the Human Identity demo secret."
  sensitive   = true
  default = {
    username    = "hi-operator"
    password    = "hi-demo-p@ssw0rd"
    environment = "demo"
  }
}

variable "hi_kv_secret_name" {
  type        = string
  description = "(Optional) Full name of the secret for the Human Identity demo secret inside the KVv2 mount."
  default     = "demo/hi-credentials"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9/_-]*$", var.hi_kv_secret_name))
    error_message = "`hi_kv_secret_name` must be a non-empty path containing only alphanumeric characters, hyphens, underscores, and forward slashes."
  }
}

variable "hi_policy_name" {
  type        = string
  description = "(Optional) Name of the Vault policy attached to all Human Identity roles."
  default     = "human-readonly"

  validation {
    condition     = length(var.hi_policy_name) > 0
    error_message = "`hi_policy_name` must not be empty."
  }
}

variable "hi_userpass_backend_description" {
  type        = string
  description = "(Optional) The description of the userpass auth backend."
  default     = "Userpass auth method for human operators."

  validation {
    condition     = length(var.hi_userpass_backend_description) > 0
    error_message = "`hi_userpass_backend_description` must not be empty."
  }
}

variable "hi_userpass_backend_path" {
  type        = string
  description = "(Optional) Path to mount the userpass auth backend."
  default     = "userpass"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.hi_userpass_backend_path))
    error_message = "`hi_userpass_backend_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "hi_userpass_password" {
  type        = string
  description = "(Optional) Password for the userpass credential. Required when `hi_userpass_username` is set."
  default     = null
  sensitive   = true

  validation {
    condition     = var.hi_userpass_password == null || length(var.hi_userpass_password) > 0
    error_message = "`hi_userpass_password` must not be an empty string when set."
  }
}

variable "hi_userpass_token_max_ttl" {
  type        = number
  description = "(Optional) Maximum lifetime of a human operator userpass Vault token, in seconds."
  default     = 14400

  validation {
    condition     = var.hi_userpass_token_max_ttl > 0
    error_message = "`hi_userpass_token_max_ttl` must be greater than 0."
  }
}

variable "hi_userpass_token_ttl" {
  type        = number
  description = "(Optional) Default lifetime of a human operator userpass Vault token, in seconds."
  default     = 3600

  validation {
    condition     = var.hi_userpass_token_ttl > 0
    error_message = "`hi_userpass_token_ttl` must be greater than 0."
  }
}

variable "hi_userpass_username" {
  type        = string
  description = "(Optional) Username for the userpass credential. When set, the userpass auth method and user are configured. Set to null to skip."
  default     = null

  validation {
    condition     = var.hi_userpass_username == null || length(var.hi_userpass_username) > 0
    error_message = "`hi_userpass_username` must not be an empty string when set."
  }
}

variable "kv_mount_description" {
  type        = string
  description = "(Optional) Human-friendly description of the mount for the KVv2 secrets engine."
  default     = "KVv2 secrets engine for the Non-Human Identity vs Human Identity demo."

  validation {
    condition     = length(var.kv_mount_description) > 0
    error_message = "`kv_mount_description` must not be empty."
  }
}

variable "kv_mount_path" {
  type        = string
  description = "(Optional) Where the secret backend will be mounted for the KVv2 secrets engine."
  default     = "secret"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9_-]*$", var.kv_mount_path))
    error_message = "`kv_mount_path` must contain only lowercase letters, numbers, hyphens, and underscores, and must start with an alphanumeric character."
  }
}

variable "namespace_path" {
  type        = string
  description = "(Optional) The path of the namespace. Must not have a trailing `/`."
  default     = "nhivshi-demo"

  validation {
    condition     = can(regex("^[a-z0-9][a-z0-9-]*[a-z0-9]$", var.namespace_path))
    error_message = "`namespace_path` must contain only lowercase letters, numbers, and hyphens, and must start and end with an alphanumeric character."
  }
}

variable "nhi_entity_metadata" {
  type        = map(string)
  description = "(Optional) A Map of additional metadata to associate with the Vault identity entity that represents the non-human identity. (e.g., team, application, environment)."
  default     = {}
}

variable "nhi_entity_name" {
  type        = string
  description = "(Optional) Name of the Vault identity entity that represents the non-human identity."
  default     = "nhi-demo-app"

  validation {
    condition     = length(var.nhi_entity_name) > 0
    error_message = "`nhi_entity_name` must not be empty."
  }
}

variable "nhi_kv_secret_data" {
  type        = map(string)
  description = "(Optional) Key-value pairs stored in the KVv2 engine as the Non-Human Identity demo secret."
  sensitive   = true
  default = {
    api_key     = "nhi-demo-api-key"
    environment = "demo"
    service     = "nhi-demo-app"
  }
}

variable "nhi_kv_secret_name" {
  type        = string
  description = "(Optional) Full name of the secret for the Non-Human Identity demo secret inside the KVv2 mount."
  default     = "demo/nhi-credentials"

  validation {
    condition     = can(regex("^[a-zA-Z0-9][a-zA-Z0-9/_-]*$", var.nhi_kv_secret_name))
    error_message = "`nhi_kv_secret_name` must be a non-empty path containing only alphanumeric characters, hyphens, underscores, and forward slashes."
  }
}

