resource "aws_servicecatalogappregistry_application" "cs2_soar" {
  provider    = aws.application
  name        = "CS2SOAR"
  description = "Case Study 2 Security Orchestration, Automation and Response System"
}

provider "aws" {
  default_tags {
    tags = merge(
      var.tags,
      aws_servicecatalogappregistry_application.cs2_soar.application_tag
    )
  }
}

