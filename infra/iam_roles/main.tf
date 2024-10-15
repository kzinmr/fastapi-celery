variable "name" {
  description = "The name of the IAM role and policy"
  type        = string
}

variable "policy" {
  description = "The policy document for the IAM policy"
  type        = string
}

variable "identifier" {
  description = "The identifier for the service principal"
  type        = string
}

resource "aws_iam_role" "default" {
  name               = var.name
  assume_role_policy = data.aws_iam_policy_document.assume_role.json

  tags = {
    Name = var.name
  }
}

data "aws_iam_policy_document" "assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = [var.identifier]
    }
  }
}

resource "aws_iam_policy" "default" {
  name   = var.name
  policy = var.policy

  tags = {
    Name = var.name
  }
}

resource "aws_iam_role_policy_attachment" "default" {
  role       = aws_iam_role.default.name
  policy_arn = aws_iam_policy.default.arn
}

output "iam_role_arn" {
  description = "The ARN of the IAM role"
  value       = aws_iam_role.default.arn
}

output "iam_role_name" {
  description = "The name of the IAM role"
  value       = aws_iam_role.default.name
}
