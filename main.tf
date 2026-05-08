terraform {
  # Terraform Cloud backend — configure via environment variables:
  #   export TF_CLOUD_ORGANIZATION="YourOrg"
  #   export TF_WORKSPACE="your-workspace"
  cloud {}

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
