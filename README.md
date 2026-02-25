<!-- BEGIN_TF_DOCS -->
# Vault Non-Human vs Human Identity Demo

This configuration provisions a self-contained demo environment inside a dedicated **child namespace** of an HCP Vault Dedicated cluster.
It illustrates the difference between Human Identity (HI) and Non-Human Identity (NHI) by showing how each type of identity authenticates
to Vault — and how Vault's **Identity Engine** manages them under the hood.

## What This Demo Demonstrates

A central concept in this demo is the Vault **Identity Entity**. Every principal that authenticates to Vault — whether a GitHub Actions
workflow, an HCP Terraform workspace, a human operator using a password, or a human using a GitHub Personal Access Token — is
automatically or explicitly mapped to an entity. Two distinct entities are created:

- **`nhi-demo-app`** — represents the application / machine identity. GitHub Actions and HCP Terraform aliases are linked to this entity,
  demonstrating that two completely different auth methods resolve to the same non-human principal in Vault's audit logs and policy engine.
- **`hi-demo-operator`** — represents the human operator identity. Userpass and GitHub PAT aliases are linked to this entity, showing
  that a human can authenticate through multiple methods while still being recognised as the same person.

This side-by-side comparison makes the distinction between NHI and HI concrete and visible: NHI tokens are short-lived, cryptographically
bound to a platform context, and never held by a human; HI credentials are static secrets that live somewhere and can be shared, leaked,
or forgotten. Both resolve to Vault entities, making the difference immediately apparent in the Vault UI under **Access → Entities**.

## Demo Components

1. **Terraform Configuration Files**:
   - **main.tf**: Child namespace, identity entities, KVv2 mount, demo secrets, policies, auth backends, roles, and entity aliases.
   - **variables.tf**: All input variables with types, descriptions, and defaults. All variables have defaults to simplify the demo experience.
   - **outputs.tf**: Useful references (namespace path, mount path, auth backend paths, entity IDs) exported after apply.
   - **providers.tf**: Vault provider targeting the parent namespace.
   - **versions.tf**: Terraform and provider version constraints.

2. **All Variables Are Optional** — Every variable has a default value so the demo can be applied with minimal configuration. Override
   only what is needed for your environment:
   - `vault_address`: URL of the HCP Vault Dedicated cluster (supplied via `VAULT_ADDR` environment variable or `providers.tf`).
   - `github_repository`: Trusted repository in `org/repo` format. Set to enable the NHI GitHub Actions auth method.
   - `hcp_terraform_workspace_name`: Workspace name. Set to enable the NHI HCP Terraform auth method.
   - `hi_userpass_username` / `hi_userpass_password`: Set to enable the HI userpass auth method.
   - `hi_github_username` / `hi_github_org`: Set to enable the HI GitHub PAT auth method.

3. **How Non-Human Identities Authenticate (NHI Flow)**:

   **GitHub Actions** — The workflow requests a short-lived OIDC token from GitHub and exchanges it for a Vault token. No static secret
   is stored anywhere.

   ```yaml
   - name: Get Vault secret via OIDC
     uses: hashicorp/vault-action@v3
     with:
       url: ${{ secrets.VAULT_ADDR }}
       namespace: ${{ secrets.VAULT_NAMESPACE }}
       method: jwt
       path: github
       role: github-actions
       jwtGithubAudience: https://vault.hashicorp.cloud
       secrets: secret/data/demo/nhi-credentials *
   ```

   **HCP Terraform** — The workspace uses dynamic provider credentials. HCP Terraform automatically generates and injects a short-lived
   JWT token into each run. No static Vault token is stored in the workspace.

   ```hcl
   # Workspace environment variables (set in HCP Terraform UI or via API):
   # TFC_VAULT_ADDR          = <vault_address>
   # TFC_VAULT_NAMESPACE     = <parent_namespace>/<child_namespace>
   # TFC_VAULT_AUTH_PATH     = hcp-terraform
   # TFC_VAULT_ROLE          = hcp-terraform-workspace
   ```

4. **How Human Identities Authenticate (HI Flow)**:

   **Userpass** — The operator authenticates with a username and password typed directly into the terminal. The password is a static
   secret that must be stored, remembered, and rotated manually.

   ```bash
   vault login -method=userpass \
     -path=userpass \
     username=<hi_userpass_username> \
     password=<hi_userpass_password>

   vault kv get secret/demo/hi-credentials
   ```

   **GitHub Personal Access Token** — The operator authenticates using a PAT generated in the GitHub UI. The token is a static secret
   that can be copied, shared, or accidentally committed to a repository.

   ```bash
   vault login -method=github \
     -path=github-hi \
     token=<github_PAT>

   vault kv get secret/demo/hi-credentials
   ```

## Permissions

### Vault

- Requires capability to create and delete child namespaces (`create`, `update`, `delete` on `sys/namespaces/*`).
- Requires capability to enable and configure secrets engines (`create`, `update`, `read`, `delete` on `sys/mounts/*` and `<namespace>/secret/*`).
- Requires capability to write and delete KVv2 secrets (`create`, `update`, `read`, `delete` on `<namespace>/secret/data/*`).
- Requires capability to create and delete Vault policies (`create`, `update`, `read`, `delete` on `<namespace>/sys/policy/*`).
- Requires capability to enable and configure auth methods (`create`, `update`, `read`, `delete` on `<namespace>/sys/auth/*` and `<namespace>/auth/*`).
- Requires capability to create and manage identity entities and aliases (`create`, `update`, `read`, `delete` on `<namespace>/identity/entity/*` and `<namespace>/identity/entity-alias/*`).

## Authentication

Authentication to Vault can be configured using one of the following methods:

### Static Token

Use environment variables to authenticate with a static Vault token:

- `VAULT_ADDR`: Set to your HCP Vault Dedicated cluster address (e.g., `https://my-cluster.vault.hashicorp.cloud:8200`).
- `VAULT_TOKEN`: Set to a valid Vault token with the permissions listed above.
- `VAULT_NAMESPACE`: Set to the parent namespace (e.g., `admin`) if applicable.

### HCP Terraform Dynamic Credentials (Recommended)

For enhanced security, use HCP Terraform's dynamic provider credentials to authenticate to Vault without storing static tokens.
This method uses workload identity (JWT/OIDC) to generate short-lived Vault tokens automatically.

- `TFC_VAULT_PROVIDER_AUTH`: Set to `true`.
- `TFC_VAULT_ADDR`: Set to your HCP Vault Dedicated cluster address.
- `TFC_VAULT_NAMESPACE`: Set to the parent namespace.
- `TFC_VAULT_RUN_ROLE`: Set to the JWT role name configured in Vault.

Documentation:

- [HCP Terraform Dynamic Credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials)
- [Vault JWT Auth Method](https://developer.hashicorp.com/vault/docs/auth/jwt)

## Features

- **Child namespace isolation** — All resources are created inside a dedicated child namespace, keeping the demo completely separate from other workloads.
- **KVv2 secrets engine** — A versioned key-value secrets engine is mounted in the child namespace with two pre-populated demo secrets: one scoped to NHI (`demo/nhi-credentials`) and one scoped to HI (`demo/hi-credentials`).
- **Two distinct identity entities** — `nhi-demo-app` groups all machine auth methods; `hi-demo-operator` groups all human auth methods. Both are visible in the Vault UI under **Access → Entities**.
- **GitHub Actions JWT auth (NHI)** — Configured against `https://token.actions.githubusercontent.com`. Access is restricted to a single repository via the `repository` bound claim. Token TTL: 5 minutes.
- **HCP Terraform JWT auth (NHI)** — Configured against `https://app.terraform.io`. Access is restricted to a single workspace via the `terraform_workspace_name` bound claim. Token TTL: 5 minutes.
- **Userpass auth (HI)** — Classic username/password login for human operators. Token TTL: 1 hour.
- **GitHub PAT auth (HI)** — Vault's native GitHub auth method validates Personal Access Tokens. Access is restricted to a single GitHub username. Token TTL: 1 hour.
- **Least-privilege policies** — Each identity type (NHI/HI) has its own dedicated policy scoped exclusively to its respective secret path. Default policies are not attached to any role.

## Demo Value Proposition

- ✅ Shows how Vault's Identity Engine unifies multiple auth methods under a single entity.
- ✅ Demonstrates the fundamental difference between NHI (short-lived, context-bound, zero static secrets) and HI (static credentials that must be managed, rotated, and protected).
- ✅ Illustrates least-privilege access with separate secrets and policies per identity type.
- ✅ Provides a repeatable, fully variable-driven configuration that can be applied to any HCP Vault Dedicated cluster.

## Documentation

## Requirements

The following requirements are needed by this module:

- <a name="requirement_terraform"></a> [terraform](#requirement\_terraform) (~> 1.10)

- <a name="requirement_vault"></a> [vault](#requirement\_vault) (~> 5.7)

## Modules

No modules.

## Required Inputs

No required inputs.

## Optional Inputs

The following input variables are optional (have default values):

### <a name="input_github_audience"></a> [github\_audience](#input\_github\_audience)

Description: (Optional) The JWT audience that GitHub Actions workflows must request when generating an OIDC token. Must match the 'audience' parameter in the 'id-token' step of the workflow.

Type: `string`

Default: `"https://vault.hashicorp.cloud"`

### <a name="input_github_jwt_backend_description"></a> [github\_jwt\_backend\_description](#input\_github\_jwt\_backend\_description)

Description: (Optional) The description of the JWT auth backend for the GitHub Actions.

Type: `string`

Default: `"JWT/OIDC auth method for GitHub Actions workflows."`

### <a name="input_github_jwt_backend_path"></a> [github\_jwt\_backend\_path](#input\_github\_jwt\_backend\_path)

Description: (Optional) Path to mount the JWT auth backend for the GitHub Actions.

Type: `string`

Default: `"github"`

### <a name="input_github_jwt_bound_issuer"></a> [github\_jwt\_bound\_issuer](#input\_github\_jwt\_bound\_issuer)

Description: (Optional) Expected issuer (iss claim) of GitHub Actions OIDC tokens. Must match the issuer of the OIDC discovery endpoint.

Type: `string`

Default: `"https://token.actions.githubusercontent.com"`

### <a name="input_github_jwt_discovery_url"></a> [github\_jwt\_discovery\_url](#input\_github\_jwt\_discovery\_url)

Description: (Optional) The OIDC Discovery URL used by Vault to retrieve the GitHub Actions JWKS and validate token signatures.

Type: `string`

Default: `"https://token.actions.githubusercontent.com"`

### <a name="input_github_jwt_role_name"></a> [github\_jwt\_role\_name](#input\_github\_jwt\_role\_name)

Description: (Optional) Name of the Vault role used by GitHub Actions workflows during JWT login.

Type: `string`

Default: `"github-actions"`

### <a name="input_github_policy_name"></a> [github\_policy\_name](#input\_github\_policy\_name)

Description: (Optional) The name of the Vault policy attached to the GitHub Actions JWT role.

Type: `string`

Default: `"github-readonly"`

### <a name="input_github_repository"></a> [github\_repository](#input\_github\_repository)

Description: (Optional) Trusted GitHub repository in 'organization/repository' format (e.g., 'my-org/my-repo'). When set, the GitHub Actions JWT auth method is configured and only workflows from this repository can authenticate. Set to null to skip GitHub auth entirely.

Type: `string`

Default: `null`

### <a name="input_github_token_max_ttl"></a> [github\_token\_max\_ttl](#input\_github\_token\_max\_ttl)

Description: (Optional) Maximum lifetime of a GitHub Actions Vault token, in seconds.

Type: `number`

Default: `600`

### <a name="input_github_token_ttl"></a> [github\_token\_ttl](#input\_github\_token\_ttl)

Description: (Optional) Default lifetime of a GitHub Actions Vault token, in seconds.

Type: `number`

Default: `300`

### <a name="input_hcp_terraform_jwt_backend_description"></a> [hcp\_terraform\_jwt\_backend\_description](#input\_hcp\_terraform\_jwt\_backend\_description)

Description: (Optional) The description of the HCP Terraform JWT auth backend.

Type: `string`

Default: `"JWT auth method for HCP Terraform workload identity tokens."`

### <a name="input_hcp_terraform_jwt_backend_path"></a> [hcp\_terraform\_jwt\_backend\_path](#input\_hcp\_terraform\_jwt\_backend\_path)

Description: (Optional) Path to mount the JWT auth backend for the HCP Terraform JWT.

Type: `string`

Default: `"hcp-terraform"`

### <a name="input_hcp_terraform_jwt_bound_issuer"></a> [hcp\_terraform\_jwt\_bound\_issuer](#input\_hcp\_terraform\_jwt\_bound\_issuer)

Description: (Optional) Expected issuer (iss claim) of HCP Terraform workload identity JWT tokens.

Type: `string`

Default: `"https://app.terraform.io"`

### <a name="input_hcp_terraform_jwt_discovery_url"></a> [hcp\_terraform\_jwt\_discovery\_url](#input\_hcp\_terraform\_jwt\_discovery\_url)

Description: (Optional) OIDC discovery URL used by Vault to retrieve the HCP Terraform JWKS and validate token signatures.

Type: `string`

Default: `"https://app.terraform.io"`

### <a name="input_hcp_terraform_jwt_role_name"></a> [hcp\_terraform\_jwt\_role\_name](#input\_hcp\_terraform\_jwt\_role\_name)

Description: (Optional) Name of the Vault role used by the HCP Terraform workspace during JWT login.

Type: `string`

Default: `"hcp-terraform-workspace"`

### <a name="input_hcp_terraform_policy_name"></a> [hcp\_terraform\_policy\_name](#input\_hcp\_terraform\_policy\_name)

Description: (Optional) Name of the Vault policy attached to the HCP Terraform JWT role.

Type: `string`

Default: `"hcp-terraform-readonly"`

### <a name="input_hcp_terraform_token_max_ttl"></a> [hcp\_terraform\_token\_max\_ttl](#input\_hcp\_terraform\_token\_max\_ttl)

Description: (Optional) Maximum lifetime of an HCP Terraform Vault token, in seconds.

Type: `number`

Default: `600`

### <a name="input_hcp_terraform_token_ttl"></a> [hcp\_terraform\_token\_ttl](#input\_hcp\_terraform\_token\_ttl)

Description: (Optional) Default lifetime of an HCP Terraform Vault token, in seconds.

Type: `number`

Default: `300`

### <a name="input_hcp_terraform_workspace_name"></a> [hcp\_terraform\_workspace\_name](#input\_hcp\_terraform\_workspace\_name)

Description: (Optional) The HCP Terraform workspace name that is allowed to access the KVv2 secret. When set, the HCP Terraform JWT auth method is configured and only runs from this workspace can authenticate. Set to null to skip HCP Terraform auth entirely.

Type: `string`

Default: `null`

### <a name="input_hi_entity_metadata"></a> [hi\_entity\_metadata](#input\_hi\_entity\_metadata)

Description: (Optional) Metadata key-value pairs attached to the Vault identity entity that represents the human operator identity (e.g., team, owner, environment).

Type: `map(string)`

Default: `{}`

### <a name="input_hi_entity_name"></a> [hi\_entity\_name](#input\_hi\_entity\_name)

Description: (Optional) Name of the Vault identity entity that represents the human operator identity.

Type: `string`

Default: `"hi-demo-operator"`

### <a name="input_hi_github_backend_description"></a> [hi\_github\_backend\_description](#input\_hi\_github\_backend\_description)

Description: (Optional) The description of the GitHub PAT auth backend.

Type: `string`

Default: `"GitHub auth method for human operators using Personal Access Tokens."`

### <a name="input_hi_github_backend_path"></a> [hi\_github\_backend\_path](#input\_hi\_github\_backend\_path)

Description: (Optional) Path to mount the GitHub PAT auth backend.

Type: `string`

Default: `"github-hi"`

### <a name="input_hi_github_org"></a> [hi\_github\_org](#input\_hi\_github\_org)

Description: (Optional) GitHub organization used by the PAT auth backend. Required when `hi_github_username` is set.

Type: `string`

Default: `null`

### <a name="input_hi_github_token_max_ttl"></a> [hi\_github\_token\_max\_ttl](#input\_hi\_github\_token\_max\_ttl)

Description: (Optional) Maximum lifetime of a human operator GitHub PAT Vault token, in seconds.

Type: `number`

Default: `14400`

### <a name="input_hi_github_token_ttl"></a> [hi\_github\_token\_ttl](#input\_hi\_github\_token\_ttl)

Description: (Optional) Default lifetime of a human operator GitHub PAT Vault token, in seconds.

Type: `number`

Default: `3600`

### <a name="input_hi_github_username"></a> [hi\_github\_username](#input\_hi\_github\_username)

Description: (Optional) GitHub username (login) of the operator allowed to authenticate with a PAT. When set, the GitHub PAT auth method is configured. Set to null to skip.

Type: `string`

Default: `null`

### <a name="input_hi_kv_secret_data"></a> [hi\_kv\_secret\_data](#input\_hi\_kv\_secret\_data)

Description: (Optional) Key-value pairs stored in the KVv2 engine as the Human Identity demo secret.

Type: `map(string)`

Default:

```json
{
  "environment": "demo",
  "password": "hi-demo-p@ssw0rd",
  "username": "hi-operator"
}
```

### <a name="input_hi_kv_secret_name"></a> [hi\_kv\_secret\_name](#input\_hi\_kv\_secret\_name)

Description: (Optional) Full name of the secret for the Human Identity demo secret inside the KVv2 mount.

Type: `string`

Default: `"demo/hi-credentials"`

### <a name="input_hi_policy_name"></a> [hi\_policy\_name](#input\_hi\_policy\_name)

Description: (Optional) Name of the Vault policy attached to all Human Identity roles.

Type: `string`

Default: `"human-readonly"`

### <a name="input_hi_userpass_backend_description"></a> [hi\_userpass\_backend\_description](#input\_hi\_userpass\_backend\_description)

Description: (Optional) The description of the userpass auth backend.

Type: `string`

Default: `"Userpass auth method for human operators."`

### <a name="input_hi_userpass_backend_path"></a> [hi\_userpass\_backend\_path](#input\_hi\_userpass\_backend\_path)

Description: (Optional) Path to mount the userpass auth backend.

Type: `string`

Default: `"userpass"`

### <a name="input_hi_userpass_password"></a> [hi\_userpass\_password](#input\_hi\_userpass\_password)

Description: (Optional) Password for the userpass credential. Required when `hi_userpass_username` is set.

Type: `string`

Default: `null`

### <a name="input_hi_userpass_token_max_ttl"></a> [hi\_userpass\_token\_max\_ttl](#input\_hi\_userpass\_token\_max\_ttl)

Description: (Optional) Maximum lifetime of a human operator userpass Vault token, in seconds.

Type: `number`

Default: `14400`

### <a name="input_hi_userpass_token_ttl"></a> [hi\_userpass\_token\_ttl](#input\_hi\_userpass\_token\_ttl)

Description: (Optional) Default lifetime of a human operator userpass Vault token, in seconds.

Type: `number`

Default: `3600`

### <a name="input_hi_userpass_username"></a> [hi\_userpass\_username](#input\_hi\_userpass\_username)

Description: (Optional) Username for the userpass credential. When set, the userpass auth method and user are configured. Set to null to skip.

Type: `string`

Default: `null`

### <a name="input_kv_mount_description"></a> [kv\_mount\_description](#input\_kv\_mount\_description)

Description: (Optional) Human-friendly description of the mount for the KVv2 secrets engine.

Type: `string`

Default: `"KVv2 secrets engine for the Non-Human Identity vs Human Identity demo."`

### <a name="input_kv_mount_path"></a> [kv\_mount\_path](#input\_kv\_mount\_path)

Description: (Optional) Where the secret backend will be mounted for the KVv2 secrets engine.

Type: `string`

Default: `"secret"`

### <a name="input_namespace_path"></a> [namespace\_path](#input\_namespace\_path)

Description: (Optional) The path of the namespace. Must not have a trailing `/`.

Type: `string`

Default: `"nhivshi-demo"`

### <a name="input_nhi_entity_metadata"></a> [nhi\_entity\_metadata](#input\_nhi\_entity\_metadata)

Description: (Optional) A Map of additional metadata to associate with the Vault identity entity that represents the non-human identity. (e.g., team, application, environment).

Type: `map(string)`

Default: `{}`

### <a name="input_nhi_entity_name"></a> [nhi\_entity\_name](#input\_nhi\_entity\_name)

Description: (Optional) Name of the Vault identity entity that represents the non-human identity.

Type: `string`

Default: `"nhi-demo-app"`

### <a name="input_nhi_kv_secret_data"></a> [nhi\_kv\_secret\_data](#input\_nhi\_kv\_secret\_data)

Description: (Optional) Key-value pairs stored in the KVv2 engine as the Non-Human Identity demo secret.

Type: `map(string)`

Default:

```json
{
  "api_key": "nhi-demo-api-key",
  "environment": "demo",
  "service": "nhi-demo-app"
}
```

### <a name="input_nhi_kv_secret_name"></a> [nhi\_kv\_secret\_name](#input\_nhi\_kv\_secret\_name)

Description: (Optional) Full name of the secret for the Non-Human Identity demo secret inside the KVv2 mount.

Type: `string`

Default: `"demo/nhi-credentials"`

## Resources

The following resources are used by this module:

- [vault_auth_backend.userpass](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/auth_backend) (resource)
- [vault_generic_endpoint.userpass_user](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/generic_endpoint) (resource)
- [vault_github_auth_backend.hi](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/github_auth_backend) (resource)
- [vault_github_user.hi](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/github_user) (resource)
- [vault_identity_entity.human](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_entity) (resource)
- [vault_identity_entity.nhi](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_entity) (resource)
- [vault_identity_entity_alias.github](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_entity_alias) (resource)
- [vault_identity_entity_alias.github_hi](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_entity_alias) (resource)
- [vault_identity_entity_alias.hcp_terraform](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_entity_alias) (resource)
- [vault_identity_entity_alias.userpass](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/identity_entity_alias) (resource)
- [vault_jwt_auth_backend.github](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend) (resource)
- [vault_jwt_auth_backend.hcp_terraform](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend) (resource)
- [vault_jwt_auth_backend_role.github](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role) (resource)
- [vault_jwt_auth_backend_role.hcp_terraform](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend_role) (resource)
- [vault_kv_secret_v2.hi](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) (resource)
- [vault_kv_secret_v2.nhi](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) (resource)
- [vault_mount.kvv2](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) (resource)
- [vault_namespace.demo](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/namespace) (resource)
- [vault_policy.github](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) (resource)
- [vault_policy.hcp_terraform](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) (resource)
- [vault_policy.human](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) (resource)

## Outputs

The following outputs are exported:

### <a name="output_github_jwt_backend_accessor"></a> [github\_jwt\_backend\_accessor](#output\_github\_jwt\_backend\_accessor)

Description: Accessor of the GitHub Actions JWT auth backend in the child namespace. Null when github\_repository is not set.

### <a name="output_github_jwt_backend_path"></a> [github\_jwt\_backend\_path](#output\_github\_jwt\_backend\_path)

Description: Mount path of the GitHub Actions JWT auth backend in the child namespace. Null when github\_repository is not set.

### <a name="output_github_jwt_role_name"></a> [github\_jwt\_role\_name](#output\_github\_jwt\_role\_name)

Description: Name of the Vault role that GitHub Actions workflows must use during login. Null when github\_repository is not set.

### <a name="output_hcp_terraform_jwt_backend_accessor"></a> [hcp\_terraform\_jwt\_backend\_accessor](#output\_hcp\_terraform\_jwt\_backend\_accessor)

Description: Accessor of the HCP Terraform JWT auth backend in the child namespace. Null when hcp\_terraform\_workspace\_name is not set.

### <a name="output_hcp_terraform_jwt_backend_path"></a> [hcp\_terraform\_jwt\_backend\_path](#output\_hcp\_terraform\_jwt\_backend\_path)

Description: Mount path of the HCP Terraform JWT auth backend in the child namespace. Null when hcp\_terraform\_workspace\_name is not set.

### <a name="output_hcp_terraform_jwt_role_name"></a> [hcp\_terraform\_jwt\_role\_name](#output\_hcp\_terraform\_jwt\_role\_name)

Description: Name of the Vault role that the HCP Terraform workspace must use for dynamic provider credentials. Null when hcp\_terraform\_workspace\_name is not set.

### <a name="output_hi_entity_id"></a> [hi\_entity\_id](#output\_hi\_entity\_id)

Description: ID of the Human Identity Vault entity. Null when no HI auth method is configured.

### <a name="output_hi_entity_name"></a> [hi\_entity\_name](#output\_hi\_entity\_name)

Description: Name of the Human Identity Vault entity. Null when no HI auth method is configured.

### <a name="output_hi_github_backend_accessor"></a> [hi\_github\_backend\_accessor](#output\_hi\_github\_backend\_accessor)

Description: Accessor of the GitHub PAT auth backend in the child namespace. Null when hi\_github\_username is not set.

### <a name="output_hi_github_backend_path"></a> [hi\_github\_backend\_path](#output\_hi\_github\_backend\_path)

Description: Mount path of the GitHub PAT auth backend in the child namespace. Null when hi\_github\_username is not set.

### <a name="output_hi_kv_secret_path"></a> [hi\_kv\_secret\_path](#output\_hi\_kv\_secret\_path)

Description: Full KVv2 API path of the Human Identity demo secret. Null when no HI auth method is configured.

### <a name="output_hi_userpass_backend_accessor"></a> [hi\_userpass\_backend\_accessor](#output\_hi\_userpass\_backend\_accessor)

Description: Accessor of the userpass auth backend in the child namespace. Null when hi\_userpass\_username is not set.

### <a name="output_hi_userpass_backend_path"></a> [hi\_userpass\_backend\_path](#output\_hi\_userpass\_backend\_path)

Description: Mount path of the userpass auth backend in the child namespace. Null when hi\_userpass\_username is not set.

### <a name="output_kv_mount_path"></a> [kv\_mount\_path](#output\_kv\_mount\_path)

Description: Mount path of the KVv2 secrets engine inside the child namespace.

### <a name="output_namespace_path"></a> [namespace\_path](#output\_namespace\_path)

Description: Fully qualified path of the child namespace.

### <a name="output_nhi_entity_id"></a> [nhi\_entity\_id](#output\_nhi\_entity\_id)

Description: ID of the Non-Human Identity Vault entity. Null when no NHI auth method is configured.

### <a name="output_nhi_entity_name"></a> [nhi\_entity\_name](#output\_nhi\_entity\_name)

Description: Name of the Non-Human Identity Vault entity. Null when no NHI auth method is configured.

### <a name="output_nhi_kv_secret_path"></a> [nhi\_kv\_secret\_path](#output\_nhi\_kv\_secret\_path)

Description: Full KVv2 API path of the Non-Human Identity demo secret (for use with the Vault CLI or API).

<!-- markdownlint-enable -->
# External Documentation

The following resources were used to build this configuration:

| Topic | Link |
| --- | --- |
| Vault Namespaces | [https://developer.hashicorp.com/vault/docs/enterprise/namespaces](https://developer.hashicorp.com/vault/docs/enterprise/namespaces) |
| KV Secrets Engine v2 | [https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2](https://developer.hashicorp.com/vault/docs/secrets/kv/kv-v2) |
| JWT/OIDC Auth Method | [https://developer.hashicorp.com/vault/docs/auth/jwt](https://developer.hashicorp.com/vault/docs/auth/jwt) |
| GitHub OIDC Token Claims | [https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token](https://docs.github.com/en/actions/security-for-github-actions/security-hardening-your-deployments/about-security-hardening-with-openid-connect#understanding-the-oidc-token) |
| Configuring Vault with GitHub OIDC | [https://developer.hashicorp.com/vault/docs/auth/jwt/oidc-providers/github-actions](https://developer.hashicorp.com/vault/docs/auth/jwt/oidc-providers/github-actions) |
| HCP Terraform Dynamic Provider Credentials | [https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials) |
| HCP Terraform Vault-backed Dynamic Credentials | [https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/vault-backed](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/vault-backed) |
| HCP Terraform Workload Identity JWT Claims | [https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/workload-identity-tokens](https://developer.hashicorp.com/terraform/cloud-docs/workspaces/dynamic-provider-credentials/workload-identity-tokens) |
| Vault Provider for Terraform | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs](https://registry.terraform.io/providers/hashicorp/vault/latest/docs) |
| `vault_namespace` resource | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/namespace](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/namespace) |
| `vault_mount` resource | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/mount) |
| `vault_kv_secret_v2` resource | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/kv_secret_v2) |
| `vault_jwt_auth_backend` resource | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend) |
| `vault_jwt_auth_backend_role` resource | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend\_role](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/jwt_auth_backend\_role) |
| `vault_policy` resource | [https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy](https://registry.terraform.io/providers/hashicorp/vault/latest/docs/resources/policy) |
<!-- END_TF_DOCS -->