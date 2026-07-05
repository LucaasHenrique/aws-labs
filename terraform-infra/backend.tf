terraform {
  backend "s3" {
    bucket  = "terraform-state-lucass"
    key     = "site/terraform.tfstate"
    region  = "us-east-1"
    encrypt = true
  }
}
