# deploy-ha-cf-mesh

Terraform project that deploys a highly-available [Cloudflare Mesh](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-mesh/) (formerly WARP Connector) configuration with auto-generated install scripts for Debian and RHEL hosts.

## What Gets Created

| Resource | Description |
|----------|-------------|
| **Service Token** | Enables headless (non-interactive) device enrollment |
| **Access Policy** | Service Auth policy allowing the service token |
| **Device Enrollment App** | WARP-type Access Application wired to the service auth policy |
| **Custom Device Profile** | "sFlow" profile — Traffic Only mode, Include split-tunnel for `162.159.65.1/32` |
| **Mesh Connector** | Single connector — install the same token on multiple hosts for HA |
| **Global Device Settings** | Enables unique CGNAT IPs per device and Gateway proxy (TCP/UDP) — both required for Mesh |
| **Install Scripts** | Per-connector Debian and RHEL bash scripts with firewall rules |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- A [Terraform Cloud](https://app.terraform.io) account (or modify `main.tf` to use a local backend)
- A Cloudflare API token with the permissions listed below

### Manual Dashboard Setting (not yet in Terraform)

The following setting **must be enabled manually** in the Cloudflare dashboard before Mesh will work:

1. Go to [Cloudflare One](https://one.dash.cloudflare.com) → **Settings** → **WARP Client** → **Device settings** → **Global settings**
2. Enable **Allow all Cloudflare One traffic to reach enrolled devices**

This setting allows traffic on-ramped via Mesh/WAN to route to enrolled devices. There is currently no Terraform provider attribute for it.

> **Reference:** [Allow all Cloudflare One traffic to reach enrolled devices](https://developers.cloudflare.com/cloudflare-one/team-and-resources/devices/cloudflare-one-client/configure/settings/#allow-all-cloudflare-one-traffic-to-reach-enrolled-devices)

The remaining global settings (unique device IPs, Gateway proxy) are managed automatically by the `cloudflare_zero_trust_device_settings` resource in `global_settings.tf`.

### API Token Permissions

Create a [custom API token](https://dash.cloudflare.com/profile/api-tokens) scoped to your account with the following permissions:

| Permission | Access Level | Used By |
|------------|-------------|---------|
| **Access: Apps and Policies** | Edit | Device enrollment application, access policy |
| **Access: Service Tokens** | Edit | Service token for headless enrollment |
| **Cloudflare One Connectors** | Edit | Mesh connector creation and token retrieval |
| **Zero Trust** | Edit | Custom device profile |
| **Account Settings** | Read | Account-level resource lookups |

### Terraform Cloud Workspace Variables

Add these as **Terraform variables** (not environment variables) in your TFC workspace settings:

| Variable | Category | Sensitive | Description |
|----------|----------|-----------|-------------|
| `cloudflare_account_id` | Terraform | **Yes** | Your Cloudflare account ID |
| `cloudflare_api_token` | Terraform | **Yes** | API token with the permissions above |
| `team_name` | Terraform | No | Zero Trust org name (e.g. `marigold68`) |
| `warp_app_id` | Terraform | No | Existing WARP Access Application ID (see below) |

### Finding the WARP App ID

Every Cloudflare account has exactly one WARP-type Access Application (created automatically). You need its ID for the `warp_app_id` variable:

```bash
curl -s "https://api.cloudflare.com/client/v4/accounts/<ACCOUNT_ID>/access/apps" \
  -H "Authorization: Bearer <API_TOKEN>" | jq '.result[] | select(.type=="warp") | .id'
```

## Quick Start

### 1. Configure Terraform Cloud

Update the `cloud` block in `main.tf` with your organization and workspace name, **or** set environment variables:

```bash
export TF_CLOUD_ORGANIZATION="YourOrg"
export TF_WORKSPACE="deploy-ha-cf-mesh"
```

### 2. Set Variables

Set the Terraform Cloud workspace variables as described in [Terraform Cloud Workspace Variables](#terraform-cloud-workspace-variables) above.

For **local development**, you can alternatively use a tfvars file:

```bash
cp terraform.tfvars.example temp.auto.tfvars
# Edit temp.auto.tfvars with your values (this file is gitignored)
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Retrieve the Connector Token

The connector token is marked as sensitive. To retrieve it:

```bash
terraform init          # required if first time or after backend changes
terraform output -raw connector_token
```

You can also retrieve other sensitive outputs:

```bash
terraform output -raw service_token_client_secret
```

### 5. Install on Hosts

After `terraform apply`, install scripts are generated in `scripts/generated/`. The connector token is baked into the scripts. Copy and run the **same script** on each host for HA:

```bash
# Copy to each replica host and run
for host in host1 host2; do
  scp scripts/generated/install_debian.sh user@${host}:~/
  ssh user@${host} 'chmod +x ~/install_debian.sh && sudo ~/install_debian.sh'
done
```

> **Note:** If you prefer not to bake the token into the script, retrieve it
> separately and pass it as an argument to the install script on each host.

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `cloudflare_account_id` | Cloudflare account ID | — |
| `cloudflare_api_token` | API token with ZT permissions | — |
| `team_name` | Zero Trust team name | — |
| `warp_app_id` | Existing WARP Access Application ID | — |
| `service_token_duration` | Service token TTL | `8760h` |

## Cleanup

```bash
terraform destroy
```

To remove the local init file:

```bash
rm -f temp.auto.tfvars
```

## Project Structure

```
.
├── main.tf                  # Provider & backend config
├── variables.tf             # Input variables
├── outputs.tf               # Outputs (tokens, script paths)
├── service_token.tf         # Service token for headless enrollment
├── access_policy.tf         # Service Auth access policy
├── device_enrollment.tf     # WARP device enrollment application
├── device_profile.tf        # "sFlow" custom device profile
├── global_settings.tf       # Global device settings (CGNAT IPs, Gateway proxy)
├── mesh_connector.tf        # HA mesh connector instances
├── scripts.tf               # Renders install script templates
├── scripts/
│   ├── install_debian.sh.tpl
│   ├── install_rhel.sh.tpl
│   └── generated/           # (created by terraform apply)
├── terraform.tfvars.example
├── .gitignore
└── README.md
```
