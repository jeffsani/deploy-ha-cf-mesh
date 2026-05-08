terraform {
  # NOTE: Terraform Cloud backend does not support variable interpolation.
  # Replace the values below with your own, or set the TF_CLOUD_ORGANIZATION
  # and TF_WORKSPACE environment variables and remove the literal values.
  cloud {
    organization = "YOUR_TFC_ORG"

    workspaces {
      name = "YOUR_TFC_WORKSPACE"
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
