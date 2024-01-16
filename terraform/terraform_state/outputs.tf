output "terraform_state_role_arn" {
  value = aws_iam_role.terraform_state_role.arn
}

output "backend_role_arn" {
  value = "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/terraform_state_role"
}