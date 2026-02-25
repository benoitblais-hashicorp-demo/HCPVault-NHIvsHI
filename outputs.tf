output "entity_name_hi" {
  description = "Name of the Human Identity Vault entity. Null when no HI auth method is configured."
  value       = try(vault_identity_entity.hi[0].name, null)
}

output "entity_name_nhi" {
  description = "Name of the Non-Human Identity Vault entity. Null when no NHI auth method is configured."
  value       = try(vault_identity_entity.nhi[0].name, null)
}

output "github_backend_path" {
  description = "Mount path of the GitHub PAT auth backend in the child namespace. Null when github_username is not set."
  value       = try(vault_github_auth_backend.github[0].path, null)
}

output "jwt_github_backend_path" {
  description = "Mount path of the GitHub Actions JWT auth backend in the child namespace. Null when github_jwt_repository is not set."
  value       = try(vault_jwt_auth_backend.jwt_github[0].path, null)
}

output "jwt_github_role_name" {
  description = "Name of the Vault role that GitHub Actions workflows must use during login. Null when github_jwt_repository is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_github[0].role_name, null)
}

output "jwt_hcp_backend_path" {
  description = "Mount path of the HCP Terraform JWT auth backend in the child namespace. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend.jwt_hcp[0].path, null)
}

output "jwt_hcp_role_name" {
  description = "Name of the Vault role that the HCP Terraform workspace must use for dynamic provider credentials. Null when hcp_jwt_workspace_name is not set."
  value       = try(vault_jwt_auth_backend_role.jwt_hcp[0].role_name, null)
}

output "kvv2_mount_path" {
  description = "Mount path of the KVv2 secrets engine inside the child namespace. Null when kv_mount_path is not set."
  value       = try(vault_mount.kvv2[0].path, null)
}

output "kvv2_secret_path_hi" {
  description = "Full KVv2 API path of the Human Identity demo secret. Null when the KVv2 mount or no HI auth method is configured."
  value       = length(vault_mount.kvv2) > 0 && (var.userpass_username != null || var.github_username != null) ? "${vault_mount.kvv2[0].path}/data/${var.hi_kv_secret_name}" : null
}

output "kvv2_secret_path_nhi" {
  description = "Full KVv2 API path of the Non-Human Identity demo secret (for use with the Vault CLI or API). Null when the KVv2 mount or no NHI auth method is configured."
  value       = length(vault_mount.kvv2) > 0 && (var.github_jwt_repository != null || var.hcp_jwt_workspace_name != null) ? "${vault_mount.kvv2[0].path}/data/${var.nhi_kv_secret_name}" : null
}

output "namespace_path" {
  description = "Fully qualified path of the child namespace."
  value       = vault_namespace.demo.path_fq
}

output "userpass_backend_path" {
  description = "Mount path of the userpass auth backend in the child namespace. Null when userpass_username is not set."
  value       = try(vault_auth_backend.userpass[0].path, null)
}

output "userpass_password" {
  description = "Generated password for the userpass auth method. Null when userpass_username is not set."
  value       = try(nonsensitive(random_password.userpass[0].result), null)
}

output "userpass_username" {
  description = "Username configured for the userpass auth method. Null when userpass_username is not set."
  value       = var.userpass_username
}

