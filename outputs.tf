output "name" {
  description = "IAM User name"
  value       = aws_iam_user.main.name
}

output "password" {
  description = "IAM User password, '***' if not being reset"
  value       = var.reset_password ? aws_iam_user_login_profile.main.password : "***"
}
