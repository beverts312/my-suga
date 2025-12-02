terraform {
  required_version = ">= 1.0"

  required_providers {
    google = {
      source  = "hashicorp/google"
      version = "7.4.0"
    }

    corefunc = {
      source  = "northwood-labs/corefunc"
      version = "2.1.0"
    }
  }
}
