variable "region" {
  description = "The region where resources are going to be deployed."
  type        = string
  default     = "eu-central-1"
}

variable "tags" {
  description = "Tags to apply to all resources"
  type        = map(string)
  default = {
    environment = "Development"
    project     = "Case Study 2"
    owner       = "Aleks Anastasov"
  }
}