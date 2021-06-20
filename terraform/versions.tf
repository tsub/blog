terraform {
  required_version = "1.0.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "3.46.0"
    }
  }

  backend "remote" {
    hostname     = "app.terraform.io"
    organization = "tsub"

    workspaces {
      name = "blog"
    }
  }
}
