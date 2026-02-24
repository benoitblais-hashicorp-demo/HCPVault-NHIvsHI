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
