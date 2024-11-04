# variables.tf

variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-1"
}

variable "user_name" {
  description = "Name of the IAM user"
  type        = string
  default     = "prue_infra"

}
