variable "name" {
  description = "Name for the core IAM User"
  type        = string
}

variable "reset_password" {
  description = "Reset the user password"
  type        = bool
}
