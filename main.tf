terraform {
  # NOTE: Terraform Cloud backend does not support variable interpolation.
  # Update the organization and workspace name below to match your environment,
  # or set them via the TF_CLOUD_ORGANIZATION and TF_WORKSPACE env vars and
  # remove the literal values.
  cloud {
    organization = "JPS_Consulting"

    workspaces {
      name = "deploy-ha-cf-mesh"
    }
  }

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
    }
    local = {
      source  = "hashicorp/local"
      version = "~> 2.5"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }

  required_version = ">= 1.5.0"
}

provider "cloudflare" {
  api_token = var.cloudflare_api_token
}
