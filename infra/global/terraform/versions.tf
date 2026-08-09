terraform {
  required_version = ">= 1.7"

  required_providers {
    # Uncomment and configure the provider you actually use:
    # aws = {
    #   source  = "hashicorp/aws"
    #   version = "~> 5.0"
    # }
    # google = {
    #   source  = "hashicorp/google"
    #   version = "~> 5.0"
    # }
  }

  # backend "s3" {
  #   bucket = "mobile-fortress-tfstate"
  #   key    = "backend/terraform.tfstate"
  #   region = "us-east-1"
  # }
}
