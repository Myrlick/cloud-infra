terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

module "static_site" {
  source = "./modules/static-site"

  project_name = var.project_name
  environment  = var.environment
}

module "vpc" {
  source = "./modules/vpc"
}