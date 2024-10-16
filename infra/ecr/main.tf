
# ecr/variables.tf

variable "repository_name" {
  type        = string
  description = "Name of the ECR repository"
}

variable "image_tag_mutability" {
  type        = string
  description = "Image tag mutability setting for the repository"
  default     = "MUTABLE"
}

variable "scan_on_push" {
  type        = bool
  description = "Indicates whether images are scanned after being pushed to the repository"
  default     = true
}

variable "encryption_type" {
  type        = string
  description = "Encryption type for the repository"
  default     = "KMS"
}

variable "image_count_to_keep" {
  type        = number
  description = "Number of images to keep in the repository"
  default     = 10
}

variable "tags" {
  type        = map(string)
  description = "Tags to be applied to the ECR repository"
  default     = {}
}

# ecr/main.tf

resource "aws_ecr_repository" "repo" {
  name                 = var.repository_name
  image_tag_mutability = var.image_tag_mutability

  image_scanning_configuration {
    scan_on_push = var.scan_on_push
  }

  encryption_configuration {
    encryption_type = var.encryption_type
  }

  tags = merge(
    var.tags,
    {
      Name = var.repository_name
    }
  )
}

resource "aws_ecr_lifecycle_policy" "policy" {
  repository = aws_ecr_repository.repo.name

  policy = jsonencode({
    rules = [
      {
        rulePriority = 1
        description  = "Keep last ${var.image_count_to_keep} images"
        selection = {
          tagStatus     = "any"
          countType     = "imageCountMoreThan"
          countNumber   = var.image_count_to_keep
        }
        action = {
          type = "expire"
        }
      }
    ]
  })
}


# ecr/outputs.tf

output "repository_url" {
  value       = aws_ecr_repository.repo.repository_url
  description = "The URL of the repository"
}

output "repository_arn" {
  value       = aws_ecr_repository.repo.arn
  description = "The ARN of the repository"
}
