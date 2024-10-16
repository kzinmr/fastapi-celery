# providers.tf
provider "aws" {
  region = var.aws_region
}

# variables.tf
variable "aws_region" {
  description = "The AWS region to deploy to"
  default     = "ap-northeast-1"
}

variable "vpc_cidr" {
  description = "The CIDR block for the VPC"
  default     = "10.0.0.0/16"
}

variable "public_subnet_cidrs" {
  description = "The CIDR blocks for the public subnets"
  type        = list(string)
  default     = ["10.0.0.0/24", "10.0.1.0/24"]
}

variable "private_subnet_cidrs" {
  description = "The CIDR blocks for the private subnets"
  type        = list(string)
  default     = ["10.0.8.0/24", "10.0.9.0/24"]
}

variable "project_name" {
  description = "The name of the project"
  default     = "fcdemo"
}

variable "environment" {
  default = "development"
}

# VPC
resource "aws_vpc" "my_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  instance_tenancy = "default"

  tags = {
    Name = "${var.project_name}-vpc"
  }
}

# Private Subnets
## Container Subnets
resource "aws_subnet" "my_subnet_private_app_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidrs[0]
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-subnet-private-app-1a"
    Type = "Isolated"
  }
}

resource "aws_subnet" "my_subnet_private_app_1c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = var.private_subnet_cidrs[1]
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-subnet-private-app-1c"
    Type = "Isolated"
  }
}

## DB Subnets
resource "aws_subnet" "my_subnet_private_db_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.16.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-subnet-private-db-1a"
    Type = "Isolated"
  }
}

resource "aws_subnet" "my_subnet_private_db_1c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.17.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-subnet-private-db-1c"
    Type = "Isolated"
  }
}

## Egress (VPC Endpoint) Subnets
resource "aws_subnet" "my_subnet_private_egress_1a" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.248.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "${var.project_name}-subnet-private-egress-1a"
    Type = "Isolated"
  }
}

resource "aws_subnet" "my_subnet_private_egress_1c" {
  vpc_id            = aws_vpc.my_vpc.id
  cidr_block        = "10.0.249.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "${var.project_name}-subnet-private-egress-1c"
    Type = "Isolated"
  }
}

# Public Subnets
## Ingress Subnets
resource "aws_subnet" "my_subnet_public_ingress_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidrs[0]
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-ingress-1a"
    Type = "Public"
  }
}

resource "aws_subnet" "my_subnet_public_ingress_1c" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = var.public_subnet_cidrs[1]
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-ingress-1c"
    Type = "Public"
  }
}

## Management Subnets
resource "aws_subnet" "my_subnet_public_management_1a" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.240.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-management-1a"
    Type = "Public"
  }
}

resource "aws_subnet" "my_subnet_public_management_1c" {
  vpc_id                  = aws_vpc.my_vpc.id
  cidr_block              = "10.0.241.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "${var.project_name}-subnet-public-management-1c"
    Type = "Public"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "my_igw" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-igw"
  }
}

# Route Tables and Associations with Subnets
## Public Subnetで共用のルートテーブル
resource "aws_route_table" "my_route_public" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-route-public"
  }
}

## Ingress用ルートテーブルのデフォルトルート
resource "aws_route" "my_route_ingress_default" {
  route_table_id         = aws_route_table.my_route_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.my_igw.id

  depends_on = [aws_internet_gateway.my_igw]
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.my_subnet_public_ingress_1a.id
  route_table_id = aws_route_table.my_route_public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.my_subnet_public_ingress_1c.id
  route_table_id = aws_route_table.my_route_public.id
}

resource "aws_route_table_association" "management_1a" {
  subnet_id      = aws_subnet.my_subnet_public_management_1a.id
  route_table_id = aws_route_table.my_route_public.id
}

resource "aws_route_table_association" "management_1c" {
  subnet_id      = aws_subnet.my_subnet_public_management_1c.id
  route_table_id = aws_route_table.my_route_public.id
}

## Private Subnetのルートテーブル
## コンテナ用ルートテーブル
resource "aws_route_table" "my_route_backend_1a" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-route-backend-1a"
  }
}

resource "aws_route_table" "my_route_backend_1c" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-route-backend-1c"
  }
}

resource "aws_route_table_association" "my_route_backend_association_1a" {
  subnet_id      = aws_subnet.my_subnet_private_app_1a.id
  route_table_id = aws_route_table.my_route_backend_1a.id
}

resource "aws_route_table_association" "my_route_backend_association_1c" {
  subnet_id      = aws_subnet.my_subnet_private_app_1c.id
  route_table_id = aws_route_table.my_route_backend_1c.id
}

## DB用のルートテーブル
resource "aws_route_table" "my_route_db" {
  vpc_id = aws_vpc.my_vpc.id

  tags = {
    Name = "${var.project_name}-route-db"
  }
}

resource "aws_route_table_association" "my_route_db_association_1a" {
  subnet_id      = aws_subnet.my_subnet_private_db_1a.id
  route_table_id = aws_route_table.my_route_db.id
}

resource "aws_route_table_association" "my_route_db_association_1c" {
  subnet_id      = aws_subnet.my_subnet_private_db_1c.id
  route_table_id = aws_route_table.my_route_db.id
}

# NAT Gateway
resource "aws_eip" "my_eip_nat_gateway_1a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my_igw]
}
resource "aws_eip" "my_eip_nat_gateway_1c" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.my_igw]
}

resource "aws_nat_gateway" "my_nat_gateway_1a" {
  allocation_id = aws_eip.my_eip_nat_gateway_1a.id
  subnet_id     = aws_subnet.my_subnet_public_ingress_1a.id

  depends_on = [aws_internet_gateway.my_igw]

  tags = {
    Name = "${var.project_name}-nat-gateway-1a"
  }
}
resource "aws_nat_gateway" "my_nat_gateway_1c" {
  allocation_id = aws_eip.my_eip_nat_gateway_1c.id
  subnet_id     = aws_subnet.my_subnet_public_ingress_1c.id

  depends_on = [aws_internet_gateway.my_igw]

  tags = {
    Name = "${var.project_name}-nat-gateway-1c"
  }
}

resource "aws_route" "my_route_backend_nat_gateway_1a" {
  route_table_id         = aws_route_table.my_route_backend_1a.id
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway_1a.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "my_route_backend_nat_gateway_1c" {
  route_table_id         = aws_route_table.my_route_backend_1c.id
  nat_gateway_id         = aws_nat_gateway.my_nat_gateway_1c.id
  destination_cidr_block = "0.0.0.0/0"
}


# Security Groups
module "my_sg_ingress" {
  source      = "./security_group"
  name        = "ingress"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security group for ingress"
  tags = {
    Name = "${var.project_name}-sg-ingress"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http_ipv4_ingress" {
  security_group_id = module.my_sg_ingress.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "https_ipv4_ingress" {
  security_group_id = module.my_sg_ingress.security_group_id
  cidr_ipv4         = aws_vpc.my_vpc.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

module "my_sg_frontend" {
  source      = "./security_group"
  name        = "frontend"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of the frontend"
  tags = {
    Name = "${var.project_name}-sg-frontend"
  }
}
module "my_sg_internal" {
  source      = "./security_group"
  name        = "internal"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of internal load balancer"
  tags = {
    Name = "${var.project_name}-sg-internal"
  }
}
module "my_sg_backend" {
  source      = "./security_group"
  name        = "backend"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of the backend"
  tags = {
    Name = "${var.project_name}-sg-backend"
  }
}
module "my_sg_redis" {
  source      = "./security_group"
  name        = "redis"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of Redis"
  tags = {
    Name = "${var.project_name}-sg-redis"
  }
}
module "my_sg_db" {
  source      = "./security_group"
  name        = "database"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of database"
  tags = {
    Name = "${var.project_name}-sg-db"
  }
}
module "my_sg_management" {
  source      = "./security_group"
  name        = "management"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of management server"
  tags = {
    Name = "${var.project_name}-sg-management"
  }
}
module "my_sg_egress" {
  source      = "./security_group"
  name        = "egress"
  vpc_id      = aws_vpc.my_vpc.id
  description = "Security Group of VPC Endpoint"
  tags = {
    Name = "${var.project_name}-sg-vpce"
  }
}

# Security Group Rules
## Internet (Ingress) LB -> Frontend Container
resource "aws_security_group_rule" "my_sg_frontend_from_sg_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 5174
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_ingress.security_group_id
  security_group_id        = module.my_sg_frontend.security_group_id
  description              = "HTTP for Ingress"
}
## Front Container -> Internal LB
resource "aws_security_group_rule" "my_sg_internal_from_sg_frontend" {
  type                     = "ingress"
  from_port                = 5175
  to_port                  = 5175
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_frontend.security_group_id
  security_group_id        = module.my_sg_internal.security_group_id
  description              = "HTTP for the frontend"
}
## Internal LB -> Backend Container
resource "aws_security_group_rule" "my_sg_backend_from_sg_internal" {
  type                     = "ingress"
  from_port                = 5175
  to_port                  = 5175
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_internal.security_group_id
  security_group_id        = module.my_sg_backend.security_group_id
  description              = "HTTP for internal lb"
}
## Backend Container -> Redis
resource "aws_security_group_rule" "my_sg_redis_from_sg_backend" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_backend.security_group_id
  security_group_id        = module.my_sg_redis.security_group_id
  description              = "Redis protocol from backend App"
}
## Backend Container -> DB
resource "aws_security_group_rule" "my_sg_db_from_sg_backend" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_backend.security_group_id
  security_group_id        = module.my_sg_db.security_group_id
  description              = "DB protocol from backend App"
}

## Management server -> DB
resource "aws_security_group_rule" "my_sg_db_from_sg_management" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_management.security_group_id
  security_group_id        = module.my_sg_db.security_group_id
  description              = "DB protocol from management server"
}
## Management server -> Internal LB
resource "aws_security_group_rule" "my_sg_internal_from_sg_management" {
  type                     = "ingress"
  from_port                = 5175
  to_port                  = 5175
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_management.security_group_id
  security_group_id        = module.my_sg_internal.security_group_id
  description              = "HTTP for management server"
}

## Backend container -> VPC endpoint
resource "aws_security_group_rule" "my_sg_vpce_from_sg_backend" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_backend.security_group_id
  security_group_id        = module.my_sg_egress.security_group_id
  description              = "HTTPS for the backend"
}
## Frontend container -> VPC endpoint
resource "aws_security_group_rule" "my_sg_vpce_from_sg_frontend" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_frontend.security_group_id
  security_group_id        = module.my_sg_egress.security_group_id
  description              = "HTTPS for the frontend"
}
## Management server -> VPC endpoint
resource "aws_security_group_rule" "my_sg_vpce_from_sg_management" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.my_sg_management.security_group_id
  security_group_id        = module.my_sg_egress.security_group_id
  description              = "HTTPS for management server"
}


# ECR
module "ecr_frontend" {
  source          = "./ecr"
  repository_name = "${var.environment}/${var.project_name}/frontend"
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
module "ecr_backend" {
  source          = "./ecr"
  repository_name = "${var.environment}/${var.project_name}/backend"
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
module "ecr_base_nginx" {
  source          = "./ecr"
  repository_name = "${var.environment}/${var.project_name}/base/nginx"
  image_count_to_keep = 3
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}
module "ecr_base_bastion" {
  source          = "./ecr"
  repository_name = "${var.environment}/${var.project_name}/base/bastion"
  image_count_to_keep = 3
  tags = {
    Environment = var.environment
    Project     = var.project_name
  }
}

# VPC Endpoint for ECS & ECR
# See. https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/vpc-endpoints.html
## for `aws ecr get-login-password`
resource "aws_vpc_endpoint" "my_vpc_endpoint_ecr_api" {
  vpc_id       = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.ecr.api"
  vpc_endpoint_type = "Interface"
  security_group_ids = [module.my_sg_egress.security_group_id]

  tags = {
    Name = "${var.project_name}-vpc-endpoint-ecr-api"
  }
}
## for `docker image push`
resource "aws_vpc_endpoint" "my_vpc_endpoint_ecr_dkr" {
  vpc_id       = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.ecr.dkr"
  vpc_endpoint_type = "Interface"
  security_group_ids = [module.my_sg_egress.security_group_id]

  tags = {
    Name = "${var.project_name}-vpc-endpoint-ecr-dkr"
  }
}
## for pulling from S3
resource "aws_vpc_endpoint" "my_vpc_endpoint_s3" {
  vpc_id       = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.my_route_backend_1a.id,
    aws_route_table.my_route_backend_1c.id,
  ]

  tags = {
    Name = "${var.project_name}-vpc-endpoint-s3"
  }
}
## for CloudWatch Logs from ECS Fargate
resource "aws_vpc_endpoint" "my_vpc_endpoint_logs" {
  vpc_id       = aws_vpc.my_vpc.id
  service_name = "com.amazonaws.${var.aws_region}.logs"
  vpc_endpoint_type = "Interface"
  security_group_ids = [module.my_sg_egress.security_group_id]

  tags = {
    Name = "${var.project_name}-vpc-endpoint-logs"
  }
}


# S3 for ALB logging
# https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
resource "aws_s3_bucket" "my_alb_log" {
  bucket        = "${var.project_name}-alb-log"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "my_alb_log_public_access" {
  bucket                  = aws_s3_bucket.my_alb_log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "my_alb_log_bucket_policy" {
  bucket = aws_s3_bucket.my_alb_log.id
  policy = data.aws_iam_policy_document.my_alb_log_bucket_policy.json
}
data "aws_iam_policy_document" "my_alb_log_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.my_alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "my_alb_log_lifecycle" {
  bucket = aws_s3_bucket.my_alb_log.id

  rule {
    id     = "log_expiration"
    status = "Enabled"

    expiration {
      days = 180
    }
  }
}

# ALB
resource "aws_lb" "my_alb" {
  name               = "${var.project_name}-alb"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60

  enable_deletion_protection = false

  subnets = [
    aws_subnet.my_subnet_public_ingress_1a.id,
    aws_subnet.my_subnet_public_ingress_1c.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.my_alb_log.id
    enabled = true
  }

  security_groups = [
    module.my_sg_ingress.security_group_id,
  ]
}

## ALB Listener
resource "aws_lb_listener" "my_listener_http" {
  load_balancer_arn = aws_lb.my_alb.arn
  port              = "80"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "This is HTTP"
      status_code  = "200"
    }
  }
}

## ALB Target Group
resource "aws_lb_target_group" "my_target_group_frontend" {
  name                 = "${var.project_name}-target-group-frontend"
  target_type          = "ip"
  vpc_id               = aws_vpc.my_vpc.id
  port                 = 5174
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.my_alb]
}

## ALB Listener Rule
resource "aws_lb_listener_rule" "my_listener_rule_http" {
  listener_arn = aws_lb_listener.my_listener_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group_frontend.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# Internal ALB
resource "aws_lb" "my_internal_alb" {
  name               = "${var.project_name}-internal-alb"
  load_balancer_type = "application"
  internal           = true
  idle_timeout       = 60

  subnets = [
    aws_subnet.my_subnet_private_app_1a.id,
    aws_subnet.my_subnet_private_app_1c.id,
  ]

  security_groups = [
    module.my_sg_internal.security_group_id,
  ]
}
## Internal ALB Listener
resource "aws_lb_listener" "my_internal_listener_http" {
  load_balancer_arn = aws_lb.my_internal_alb.arn
  port              = "5175"
  protocol          = "HTTP"

  default_action {
    type = "fixed-response"

    fixed_response {
      content_type = "text/plain"
      message_body = "Not Found"
      status_code  = "404"
    }
  }
}
# Internal ALB Target Group
resource "aws_lb_target_group" "my_target_group_backend" {
  name                 = "${var.project_name}-target-group-backend"
  target_type          = "ip"
  vpc_id               = aws_vpc.my_vpc.id
  port                 = 5175
  protocol             = "HTTP"
  deregistration_delay = 300

  health_check {
    path                = "/health"
    healthy_threshold   = 5
    unhealthy_threshold = 2
    timeout             = 5
    interval            = 30
    matcher             = 200
    port                = "traffic-port"
    protocol            = "HTTP"
  }

  depends_on = [aws_lb.my_internal_alb]
}
## Internal ALB Listener Rule
resource "aws_lb_listener_rule" "my_internal_listener_rule" {
  listener_arn = aws_lb_listener.my_internal_listener_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.my_target_group_backend.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}

# ECS
## CloudWatch Log Group
resource "aws_cloudwatch_log_group" "my_log_group" {
  name              = "/ecs/${var.environment}-${var.project_name}-main"
  retention_in_days = 30
}

## IAM Role and Policy for ECS Task Execution and logging
## from "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
data "aws_iam_policy_document" "my_ecs_task_execution_policy_document" {
  statement {
    effect = "Allow"
    actions = [
      "ecr:GetAuthorizationToken",
      "ecr:BatchCheckLayerAvailability",
      "ecr:GetDownloadUrlForLayer",
      "ecr:BatchGetImage",
      "logs:CreateLogStream",
      "logs:PutLogEvents"
    ]
    resources = ["*"]
  }

  statement {
    effect    = "Allow"
    actions   = ["ssm:GetParameters", "kms:Decrypt"]
    resources = ["*"]
  }
}

module "my_ecs_task_execution_role" {
  source     = "./iam_roles"
  name       = "${var.project_name}-ecs-task-execution-role"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.my_ecs_task_execution_policy_document.json
}

## Cluster
resource "aws_ecs_cluster" "my_ecs_cluster" {
  name = "${var.project_name}-ecs-cluster"
}

## Task Definition
resource "aws_ecs_task_definition" "my_frontend_task_definition" {
  family                   = "${var.environment}-${var.project_name}-task"
  cpu                      = 1024
  memory                   = 2048
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = module.my_ecs_task_execution_role.iam_role_arn
  container_definitions    = jsonencode([
    {
      name  = "frontend"
      image = "${module.ecr_frontend.repository_url}:latest"
      cpu   = 512
      memory = 1024
      essential = true
      portMappings = [
        {
          name = "frontend"
          containerPort = 5174
          hostPort      = 5174
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          "name": "ENV",
          "value": "${var.environment}"
        },
        {
          name  = "BACKEND_URL"
          value = "http://${aws_lb.my_internal_alb.dns_name}:5175"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.my_log_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "frontend"
        }
      }
    }
  ])
}
resource "aws_ecs_task_definition" "my_backend_task_definition" {
  family                   = "${var.environment}-${var.project_name}-task"
  cpu                      = 1024
  memory                   = 2048
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  execution_role_arn       = module.my_ecs_task_execution_role.iam_role_arn
  container_definitions    = jsonencode([
    {
      name  = "backend"
      image = "${module.ecr_backend.repository_url}:latest"
      cpu   = 1024
      memory = 1024
      essential = true
      portMappings = [
        {
          containerPort = 5175
          hostPort      = 5175
          protocol      = "tcp"
        }
      ]
      environment = [
        {
          name  = "ENV"
          value = "development"
        }
      ]
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.my_log_group.name
          awslogs-region        = var.aws_region
          awslogs-stream-prefix = "backend"
        }
      }
    }
  ])
}

## ECS Service
resource "aws_ecs_service" "my_ecs_service_frontend" {
  name                              = "${var.project_name}-service-frontend"
  cluster                           = aws_ecs_cluster.my_ecs_cluster.id
  task_definition                   = aws_ecs_task_definition.my_frontend_task_definition.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.my_sg_frontend.security_group_id]
    subnets = [
      aws_subnet.my_subnet_private_app_1a.id,
      aws_subnet.my_subnet_private_app_1c.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group_frontend.arn
    container_name   = "${var.project_name}-frontend"
    container_port   = 5174
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}
resource "aws_ecs_service" "my_ecs_service_backend" {
  name                              = "${var.project_name}-service-backend"
  cluster                           = aws_ecs_cluster.my_ecs_cluster.id
  task_definition                   = aws_ecs_task_definition.my_backend_task_definition.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60

  network_configuration {
    assign_public_ip = false
    security_groups  = [module.my_sg_backend.security_group_id]
    subnets = [
      aws_subnet.my_subnet_private_app_1a.id,
      aws_subnet.my_subnet_private_app_1c.id,
    ]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.my_target_group_backend.arn
    container_name   = "backend"
    container_port   = 5175
  }

  lifecycle {
    ignore_changes = [task_definition]
  }
}

# KMS Key and SSM Parameter Store
## KMS Key
resource "aws_kms_key" "my_kms_key" {
  description = "KMS Key for ECS Task Execution"
  enable_key_rotation = true
  is_enabled = true
  deletion_window_in_days = 30
}
resource "aws_kms_alias" "my_kms_key_alias" {
  name = "alias/${var.project_name}-kms-key"
  target_key_id = aws_kms_key.my_kms_key.key_id
}
## KMS Secrets per Environment; See. README.md
## data "aws_kms_secrets" "my_kms_secrets_dev" {
##   secret {
##     name    = "EXAMPLE_KEY"
##     payload = "AQICAHiVOc0+QxXBi64YqUGPDVl299K4Ex+ZBKQ8s37D08TRRQHeVshV7sH+t4kcm/pvnW8BAAAAeTB3BgkqhkiG9w0BBwagajBoAgEAMGMGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMfoHjuxmMCP005Ad9AgEQgDbvQEpDEow+Evq8M+ia0gdO0DOyzjsBDsLKIm8n1dQjVrKrhr4SPRFCgbqS9NfAeX1x5O3uiVg="
##   }
## }
## SSM Parameter Store via KMS
## resource "aws_ssm_parameter" "example_key" {
##   name   = "/backend/EXAMPLE_KEY"
##   type   = "SecureString"
##   value  = sensitive(data.aws_kms_secrets.my_kms_secrets_dev.plaintext["EXAMPLE_KEY"])
##   key_id = aws_kms_key.my_kms_key.arn
## }

# ElastiCache
resource "aws_elasticache_parameter_group" "my_elasticache_parameter_group" {
  name   = "${var.project_name}-elasticache-parameter-group"
  family = "redis7"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "my_elasticache_subnet_group" {
  name       = "${var.project_name}-elasticache-subnet-group"
  subnet_ids = [aws_subnet.my_subnet_private_app_1a.id, aws_subnet.my_subnet_private_app_1c.id]
}

resource "aws_elasticache_replication_group" "my_elasticache_replication_group" {
  replication_group_id = "${var.project_name}-elasticache-replication-group"
  description = "Redis without cluster"
  engine = "redis"
  engine_version = "7.0"
  node_type = "cache.t3.medium"
  num_cache_clusters = 2
  snapshot_window = "09:10-10:10"
  snapshot_retention_limit = 7
  maintenance_window = "mon:10:40-mon:11:40"
  automatic_failover_enabled = true
  port = 6379
  apply_immediately = true
  security_group_ids = [module.my_sg_redis.security_group_id]
  parameter_group_name = aws_elasticache_parameter_group.my_elasticache_parameter_group.name
  subnet_group_name = aws_elasticache_subnet_group.my_elasticache_subnet_group.name
}


output "alb_dns_name" {
  value = aws_lb.my_alb.dns_name
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
