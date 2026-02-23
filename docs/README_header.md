# Module Lifecycle Demo

This demo focuses on the consumer experience after a Terraform module has been provisioned, illustrating the "day 2" lifecycle. It
demonstrates how users interact with modules that are managed and potentially deprecated by a platform team, including the steps and
user experience when a module is marked as deprecated or revoked. The demo highlights best practices for module consumption,
communication of deprecation, and safe migration strategies in real-world infrastructure as code workflows.

## What This Demo Demonstrates

Key Integration Points

- **Module Registry Integration**: Demonstrates how consumers source modules from a central registry.
- **Deprecation/Revocation Workflow**: Illustrates the process and user experience when a module is marked as deprecated or revoked,
including notifications and migration guidance.
- **Documentation and Communication**: Highlights the importance of clear documentation and communication channels between platform and
consumer teams regarding module lifecycle events.

## Demo Components

1. **Terraform Configuration Files**:
   - **main.tf**: Contains the primary resources and module usage.
   - **variables.tf**: Defines input variables for customizing the module.
   - **outputs.tf**: Specifies outputs that are exported after applying the configuration.

2. **Required Variables**:
   - `repository_name`: The name of the repository to be managed or created.
   - `repository_description`: A description for the repository.

3. **Notifications and Workspace Configuration**:
To fully experience the module lifecycle (including deprecation and revocation events), configure notifications in your Terraform
workspace. For example, enable email notifications for run events or policy checks to receive timely updates about module status changes.

Refer to your Terraform Cloud or Enterprise documentation for instructions on setting up email notifications or integrating with other
notification channels (e.g., Slack, webhooks).

## How Module Lifecycle Works in This Demo

When a module is deprecated, Terraform displays a warning such as:

> Warning: Deprecated modules found, consider installing an updated version. The following modules have been deprecated: ...

The module remains usable, but consumers are encouraged to upgrade to a supported version.

When a module is revoked, the behavior is as follows:

> This run will continue because it references a revoked module version that has been used previously in this workspace. Net new
workspaces that reference this module version will be blocked from making new runs.

This means existing workspaces that have already used the revoked version can continue to run, but new workspaces cannot use the revoked
version. This ensures a smooth transition while enforcing compliance for new deployments.

In addition, when a module is deprecated or revoked, a Change Request can be generated in the workspace where the module is used. This
allows teams to formally request, review, and track the necessary updates or migrations, ensuring that changes are managed and audited
according to organizational processes.

### The Workflow

1. **Provisioning**: The consumer provisions a GitHub repository using a specific version of the module.
2. **Deprecation**: The platform team marks this module version as deprecated. Terraform displays a warning, but the consumer can
continue to use the version. It is recommended to upgrade to a supported version.
3. **Revocation**: The platform team marks the new version as revoked. Existing workspaces that have previously used this version can
continue to run, but new workspaces will be blocked from using the revoked version.
4. **Upgrade**: The consumer updates their configuration to use the new, recommended version of the module.

This workflow demonstrates the full lifecycle of a module from initial provisioning, through deprecation (with warnings), to revocation
(with enforcement for new workspaces), ensuring a safe and well-communicated upgrade path for consumers.

## Demo Value Proposition

- ✅ Provides a hands-on example of Terraform module best practices.
- ✅ Demonstrates safe and repeatable infrastructure changes.
- ✅ Helps teams understand module versioning and lifecycle management.
- ✅ Serves as a template for building robust, reusable Terraform modules.
