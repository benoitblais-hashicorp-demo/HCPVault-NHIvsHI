output "hi_entity_id" {
  description = "ID of the Human Identity Vault entity. Null when no HI auth method is configured."
  value       = try(vault_identity_entity.hi[0].id, null)
}

output "hi_entity_name" {
  description = "Name of the Human Identity Vault entity. Null when no HI auth method is configured."
  value       = try(vault_identity_entity.hi[0].name, null)
}

output "nhi_entity_id" {
  description = "ID of the Non-Human Identity Vault entity. Null when no NHI auth method is configured."
  value       = try(vault_identity_entity.nhi[0].id, null)
}

output "nhi_entity_name" {
  description = "Name of the Non-Human Identity Vault entity. Null when no NHI auth method is configured."
  value       = try(vault_identity_entity.nhi[0].name, null)
}

output "github_jwt_backend_accessor" {
  description = "Accessor of the GitHub Actions JWT auth backend in the child namespace. Null when github_jwt_repository is not set."
  value       = try(vault_jwt_auth_backend.jwt_github[0].accessor, null)
}

output "github_jwt_backend_path" {
  description = "Mount path of the GitHub Actions JWT auth backend in the child namespace. Null when github_jwt_repository is not set."
  value       = try(vault_jwt_auth_backend.jwt_github[0].path, null)
}

output "github_jwt_role_name" {
  description = "Name of the Vault role that GitHub Actions workflows must use during login. Null when github_jwt_repository is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_github[0].role_name, null)
}

output "hcp_terraform_jwt_backend_accessor" {
  description = "Accessor of the HCP Terraform JWT auth backend in the child namespace. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend.jwt_hcp[0].accessor, null)
}

output "hcp_terraform_jwt_backend_path" {
  description = "Mount path of the HCP Terraform JWT auth backend in the child namespace. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend.jwt_hcp[0].path, null)
}

output "hcp_terraform_jwt_role_name" {
  description = "Name of the Vault role that the HCP Terraform workspace must use for dynamic provider credentials. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_hcp[0].role_name, null)
}

output "hi_github_backend_accessor" {
  description = "Accessor of the GitHub PAT auth backend in the child namespace. Null when hi_github_username is not set."
  value       = try(vault_github_auth_backend.hi[0].accessor, null)
}

output "hi_github_backend_path" {
  description = "Mount path of the GitHub PAT auth backend in the child namespace. Null when hi_github_username is not set."
  value       = try(vault_github_auth_backend.hi[0].path, null)
}

output "hi_userpass_backend_accessor" {
  description = "Accessor of the userpass auth backend in the child namespace. Null when hi_userpass_username is not set."
  value       = try(vault_auth_backend.userpass[0].accessor, null)
}

output "hi_userpass_backend_path" {
  description = "Mount path of the userpass auth backend in the child namespace. Null when hi_userpass_username is not set."
  value       = try(vault_auth_backend.userpass[0].path, null)
}

output "hi_kv_secret_path" {
  description = "Full KVv2 API path of the Human Identity demo secret. Null when no HI auth method is configured."
  value       = (var.hi_userpass_username != null || var.hi_github_username != null) ? "${var.kv_mount_path}/data/${var.hi_kv_secret_name}" : null
}

output "kv_mount_path" {
  description = "Mount path of the KVv2 secrets engine inside the child namespace."
  value       = vault_mount.kvv2.path
}

output "nhi_kv_secret_path" {
  description = "Full KVv2 API path of the Non-Human Identity demo secret (for use with the Vault CLI or API)."
  value       = "${var.kv_mount_path}/data/${var.nhi_kv_secret_name}"
}

output "github_jwt_policy_name" {
  description = "Name of the Vault policy attached to the GitHub Actions JWT role. Null when github_jwt_repository is not set."
  value       = try(vault_policy.jwt_github[0].name, null)
}

output "hcp_terraform_policy_name" {
  description = "Name of the Vault policy attached to the HCP Terraform JWT role. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_policy.jwt_hcp[0].name, null)
}

output "hi_policy_name" {
  description = "Name of the Vault policy attached to all Human Identity roles. Null when no HI auth method is configured."
  value       = try(vault_policy.human[0].name, null)
}

output "hi_userpass_password" {
  description = "Password configured for the userpass auth method. Null when hi_userpass_password is not set."
  value       = nonsensitive(var.hi_userpass_password)
}

output "hi_userpass_username" {
  description = "Username configured for the userpass auth method. Null when hi_userpass_username is not set."
  value       = var.hi_userpass_username
}

output "namespace_path" {
  description = "Fully qualified path of the child namespace."
  value       = vault_namespace.demo.path_fq
}

