terraform {
  # Backend is NOT configured here — copy one of the backend examples:
  #   cp backend.tf.cloud-example backend.tf   # Terraform Cloud / HCP Terraform
  #   cp backend.tf.local-example backend.tf   # Local state (on-premises)

  required_providers {
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 5.0"
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
