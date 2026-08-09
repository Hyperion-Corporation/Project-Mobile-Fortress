variable "environment" {
  description = "Deployment environment name (dev, prod)."
  type        = string
  default     = "dev"
}

variable "region" {
  description = "Cloud provider region."
  type        = string
  default     = "us-east-1"
}

variable "db_instance_class" {
  description = "Managed Postgres instance size for the leaderboards/cloud-save backend."
  type        = string
  default     = "db.t4g.micro"
}
