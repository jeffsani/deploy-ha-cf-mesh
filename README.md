# deploy-ha-cf-mesh

Terraform project that deploys a highly-available [Cloudflare Mesh](https://developers.cloudflare.com/cloudflare-one/networks/connectors/cloudflare-mesh/) (formerly WARP Connector) configuration with auto-generated install scripts for Debian and RHEL hosts.

## What Gets Created

| Resource | Description |
|----------|-------------|
| **Service Token** | Enables headless (non-interactive) device enrollment |
| **Access Policy** | Service Auth policy allowing the service token |
| **Device Enrollment App** | WARP-type Access Application wired to the service auth policy |
| **Custom Device Profile** | "sFlow" profile — MASQUE tunnel, Traffic Only mode, Include split-tunnel for `162.159.65.1/32` |
| **Mesh Connector** | Single connector — install the same token on multiple hosts for HA |
| **Install Scripts** | Per-connector Debian and RHEL bash scripts with firewall rules |

## Prerequisites

- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.5
- A [Terraform Cloud](https://app.terraform.io) account (or modify `main.tf` to use a local backend)
- A Cloudflare API token with the following permissions:
  - `Access: Apps and Policies Write`
  - `Access: Service Tokens Write`
  - `Cloudflare One Connectors Write`
  - `Zero Trust Write`

## Quick Start

### 1. Configure Terraform Cloud

Update the `cloud` block in `main.tf` with your organization and workspace name, **or** set environment variables:

```bash
export TF_CLOUD_ORGANIZATION="YourOrg"
export TF_WORKSPACE="deploy-ha-cf-mesh"
```

### 2. Set Variables

**Option A — Terraform Cloud (recommended):**

Add these as workspace variables in Terraform Cloud (mark sensitive values accordingly):

| Variable | Type | Sensitive |
|----------|------|-----------|
| `cloudflare_account_id` | Terraform | Yes |
| `cloudflare_api_token` | Terraform | Yes |
| `team_name` | Terraform | No |

**Option B — Local development:**

```bash
cp terraform.tfvars.example temp.auto.tfvars
# Edit temp.auto.tfvars with your values
```

### 3. Deploy

```bash
terraform init
terraform plan
terraform apply
```

### 4. Install on Hosts

After `terraform apply`, install scripts are generated in `scripts/generated/`. Run the **same script** on each host for HA:

```bash
# Copy to each replica host and run
for host in host1 host2; do
  scp scripts/generated/install_debian.sh user@${host}:~/
  ssh user@${host} 'chmod +x ~/install_debian.sh && sudo ~/install_debian.sh'
done
```

### 5. Retrieve Sensitive Outputs

```bash
terraform output -raw service_token_client_secret
terraform output -raw connector_token
```

## Variables

| Name | Description | Default |
|------|-------------|---------|
| `cloudflare_account_id` | Cloudflare account ID | — |
| `cloudflare_api_token` | API token with ZT permissions | — |
| `team_name` | Zero Trust team name | — |
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
