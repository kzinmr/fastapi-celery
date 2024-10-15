# Provider configuration
provider "aws" {
  region = "ap-northeast-1"
}

# VPC
resource "aws_vpc" "sbcntr_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true

  instance_tenancy = "default"

  tags = {
    Name = "sbcntrVpc"
  }
}

# Private Subnets
## Container Subnets
resource "aws_subnet" "sbcntr_subnet_private_app_1a" {
  vpc_id            = aws_vpc.sbcntr_vpc.id
  cidr_block        = "10.0.8.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "sbcntr-subnet-private-app-1a"
    Type = "Isolated"
  }
}

resource "aws_subnet" "sbcntr_subnet_private_app_1c" {
  vpc_id            = aws_vpc.sbcntr_vpc.id
  cidr_block        = "10.0.9.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "sbcntr-subnet-private-app-1c"
    Type = "Isolated"
  }
}

## DB Subnets
resource "aws_subnet" "sbcntr_subnet_private_db_1a" {
  vpc_id            = aws_vpc.sbcntr_vpc.id
  cidr_block        = "10.0.16.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "sbcntr-subnet-private-db-1a"
    Type = "Isolated"
  }
}

resource "aws_subnet" "sbcntr_subnet_private_db_1c" {
  vpc_id            = aws_vpc.sbcntr_vpc.id
  cidr_block        = "10.0.17.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "sbcntr-subnet-private-db-1c"
    Type = "Isolated"
  }
}

## Egress (VPC Endpoint) Subnets
resource "aws_subnet" "sbcntr_subnet_private_egress_1a" {
  vpc_id            = aws_vpc.sbcntr_vpc.id
  cidr_block        = "10.0.248.0/24"
  availability_zone = data.aws_availability_zones.available.names[0]

  tags = {
    Name = "sbcntr-subnet-private-egress-1a"
    Type = "Isolated"
  }
}

resource "aws_subnet" "sbcntr_subnet_private_egress_1c" {
  vpc_id            = aws_vpc.sbcntr_vpc.id
  cidr_block        = "10.0.249.0/24"
  availability_zone = data.aws_availability_zones.available.names[1]

  tags = {
    Name = "sbcntr-subnet-private-egress-1c"
    Type = "Isolated"
  }
}

# Public Subnets
## Ingress Subnets
resource "aws_subnet" "sbcntr_subnet_public_ingress_1a" {
  vpc_id                  = aws_vpc.sbcntr_vpc.id
  cidr_block              = "10.0.0.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-ingress-1a"
    Type = "Public"
  }
}

resource "aws_subnet" "sbcntr_subnet_public_ingress_1c" {
  vpc_id                  = aws_vpc.sbcntr_vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-ingress-1c"
    Type = "Public"
  }
}

## Management Subnets
resource "aws_subnet" "sbcntr_subnet_public_management_1a" {
  vpc_id                  = aws_vpc.sbcntr_vpc.id
  cidr_block              = "10.0.240.0/24"
  availability_zone       = data.aws_availability_zones.available.names[0]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-management-1a"
    Type = "Public"
  }
}

resource "aws_subnet" "sbcntr_subnet_public_management_1c" {
  vpc_id                  = aws_vpc.sbcntr_vpc.id
  cidr_block              = "10.0.241.0/24"
  availability_zone       = data.aws_availability_zones.available.names[1]
  map_public_ip_on_launch = true

  tags = {
    Name = "sbcntr-subnet-public-management-1c"
    Type = "Public"
  }
}


# Internet Gateway
resource "aws_internet_gateway" "sbcntr_igw" {
  vpc_id = aws_vpc.sbcntr_vpc.id

  tags = {
    Name = "sbcntr-igw"
  }
}

# Route Tables and Associations with Subnets
## Public Subnetで共用のルートテーブル
resource "aws_route_table" "sbcntr_route_public" {
  vpc_id = aws_vpc.sbcntr_vpc.id

  tags = {
    Name = "sbcntr-route-public"
  }
}

## Ingress用ルートテーブルのデフォルトルート
resource "aws_route" "sbcntr_route_ingress_default" {
  route_table_id         = aws_route_table.sbcntr_route_public.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.sbcntr_igw.id

  depends_on = [aws_internet_gateway.sbcntr_igw]
}

resource "aws_route_table_association" "public_1a" {
  subnet_id      = aws_subnet.sbcntr_subnet_public_ingress_1a.id
  route_table_id = aws_route_table.sbcntr_route_public.id
}

resource "aws_route_table_association" "public_1c" {
  subnet_id      = aws_subnet.sbcntr_subnet_public_ingress_1c.id
  route_table_id = aws_route_table.sbcntr_route_public.id
}

resource "aws_route_table_association" "management_1a" {
  subnet_id      = aws_subnet.sbcntr_subnet_public_management_1a.id
  route_table_id = aws_route_table.sbcntr_route_public.id
}

resource "aws_route_table_association" "management_1c" {
  subnet_id      = aws_subnet.sbcntr_subnet_public_management_1c.id
  route_table_id = aws_route_table.sbcntr_route_public.id
}

## Private Subnetのルートテーブル
## コンテナ用ルートテーブル
resource "aws_route_table" "sbcntr_route_app_1a" {
  vpc_id = aws_vpc.sbcntr_vpc.id

  tags = {
    Name = "sbcntr-route-app-1a"
  }
}

resource "aws_route_table" "sbcntr_route_app_1c" {
  vpc_id = aws_vpc.sbcntr_vpc.id

  tags = {
    Name = "sbcntr-route-app-1c"
  }
}

resource "aws_route_table_association" "sbcntr_route_app_association_1a" {
  subnet_id      = aws_subnet.sbcntr_subnet_private_app_1a.id
  route_table_id = aws_route_table.sbcntr_route_app_1a.id
}

resource "aws_route_table_association" "sbcntr_route_app_association_1c" {
  subnet_id      = aws_subnet.sbcntr_subnet_private_app_1c.id
  route_table_id = aws_route_table.sbcntr_route_app_1c.id
}

## DB用のルートテーブル
resource "aws_route_table" "sbcntr_route_db" {
  vpc_id = aws_vpc.sbcntr_vpc.id

  tags = {
    Name = "sbcntr-route-db"
  }
}

resource "aws_route_table_association" "sbcntr_route_db_association_1a" {
  subnet_id      = aws_subnet.sbcntr_subnet_private_db_1a.id
  route_table_id = aws_route_table.sbcntr_route_db.id
}

resource "aws_route_table_association" "sbcntr_route_db_association_1c" {
  subnet_id      = aws_subnet.sbcntr_subnet_private_db_1c.id
  route_table_id = aws_route_table.sbcntr_route_db.id
}

# NAT Gateway
resource "aws_eip" "sbcntr_eip_nat_gateway_1a" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.sbcntr_igw]
}
resource "aws_eip" "sbcntr_eip_nat_gateway_1c" {
  domain     = "vpc"
  depends_on = [aws_internet_gateway.sbcntr_igw]
}

resource "aws_nat_gateway" "sbcntr_nat_gateway_1a" {
  allocation_id = aws_eip.sbcntr_eip_nat_gateway_1a.id
  subnet_id     = aws_subnet.sbcntr_subnet_public_ingress_1a.id

  depends_on = [aws_internet_gateway.sbcntr_igw]

  tags = {
    Name = "sbcntr-nat-gateway-1a"
  }
}
resource "aws_nat_gateway" "sbcntr_nat_gateway_1c" {
  allocation_id = aws_eip.sbcntr_eip_nat_gateway_1c.id
  subnet_id     = aws_subnet.sbcntr_subnet_public_ingress_1c.id

  depends_on = [aws_internet_gateway.sbcntr_igw]

  tags = {
    Name = "sbcntr-nat-gateway-1c"
  }
}

resource "aws_route" "sbcntr_route_app_nat_gateway_1a" {
  route_table_id         = aws_route_table.sbcntr_route_app_1a.id
  nat_gateway_id         = aws_nat_gateway.sbcntr_nat_gateway_1a.id
  destination_cidr_block = "0.0.0.0/0"
}
resource "aws_route" "sbcntr_route_app_nat_gateway_1c" {
  route_table_id         = aws_route_table.sbcntr_route_app_1c.id
  nat_gateway_id         = aws_nat_gateway.sbcntr_nat_gateway_1c.id
  destination_cidr_block = "0.0.0.0/0"
}


# Security Groups
module "sbcntr_sg_ingress" {
  source      = "./security_group"
  name        = "ingress"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security group for ingress"
  tags = {
    Name = "sbcntr-sg-ingress"
  }
}
resource "aws_vpc_security_group_ingress_rule" "http_ipv4_ingress" {
  security_group_id = module.sbcntr_sg_ingress.security_group_id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
  from_port         = 80
  to_port           = 80
}
resource "aws_vpc_security_group_ingress_rule" "https_ipv4_ingress" {
  security_group_id = module.sbcntr_sg_ingress.security_group_id
  cidr_ipv4         = aws_vpc.sbcntr_vpc.cidr_block
  ip_protocol       = "tcp"
  from_port         = 443
  to_port           = 443
}

module "sbcntr_sg_front_app" {
  source      = "./security_group"
  name        = "front-app"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of front app"
  tags = {
    Name = "sbcntr-sg-front-app"
  }
}
module "sbcntr_sg_internal" {
  source      = "./security_group"
  name        = "internal"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of internal load balancer"
  tags = {
    Name = "sbcntr-sg-internal"
  }
}
module "sbcntr_sg_app" {
  source      = "./security_group"
  name        = "app"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of backend app"
  tags = {
    Name = "sbcntr-sg-app"
  }
}
module "sbcntr_sg_redis" {
  source      = "./security_group"
  name        = "redis"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of Redis"
  tags = {
    Name = "sbcntr-sg-redis"
  }
}
module "sbcntr_sg_db" {
  source      = "./security_group"
  name        = "database"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of database"
  tags = {
    Name = "sbcntr-sg-db"
  }
}
module "sbcntr_sg_management" {
  source      = "./security_group"
  name        = "management"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of management server"
  tags = {
    Name = "sbcntr-sg-management"
  }
}
module "sbcntr_sg_egress" {
  source      = "./security_group"
  name        = "egress"
  vpc_id      = aws_vpc.sbcntr_vpc.id
  description = "Security Group of VPC Endpoint"
  tags = {
    Name = "sbcntr-sg-vpce"
  }
}

# Security Group Rules
## Internet (Ingress) LB -> Frontend Container
resource "aws_security_group_rule" "sbcntr_sg_front_app_from_sg_ingress" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_ingress.security_group_id
  security_group_id        = module.sbcntr_sg_front_app.security_group_id
  description              = "HTTP for Ingress"
}
## Front Container -> Internal LB
resource "aws_security_group_rule" "sbcntr_sg_internal_from_sg_front_app" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_front_app.security_group_id
  security_group_id        = module.sbcntr_sg_internal.security_group_id
  description              = "HTTP for front app"
}
## Internal LB -> Backend Container
resource "aws_security_group_rule" "sbcntr_sg_app_from_sg_internal" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_internal.security_group_id
  security_group_id        = module.sbcntr_sg_app.security_group_id
  description              = "HTTP for internal lb"
}
## Backend Container -> Redis
resource "aws_security_group_rule" "sbcntr_sg_redis_from_sg_app" {
  type                     = "ingress"
  from_port                = 6379
  to_port                  = 6379
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_app.security_group_id
  security_group_id        = module.sbcntr_sg_redis.security_group_id
  description              = "Redis protocol from backend App"
}
## Backend Container -> DB
resource "aws_security_group_rule" "sbcntr_sg_db_from_sg_app" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_app.security_group_id
  security_group_id        = module.sbcntr_sg_db.security_group_id
  description              = "DB protocol from backend App"
}

## Management server -> DB
resource "aws_security_group_rule" "sbcntr_sg_db_from_sg_management" {
  type                     = "ingress"
  from_port                = 3306
  to_port                  = 3306
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_management.security_group_id
  security_group_id        = module.sbcntr_sg_db.security_group_id
  description              = "DB protocol from management server"
}
## Management server -> Internal LB
resource "aws_security_group_rule" "sbcntr_sg_internal_from_sg_management" {
  type                     = "ingress"
  from_port                = 80
  to_port                  = 80
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_management.security_group_id
  security_group_id        = module.sbcntr_sg_internal.security_group_id
  description              = "HTTP for management server"
}

## Backend container -> VPC endpoint
resource "aws_security_group_rule" "sbcntr_sg_vpce_from_sg_app" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_app.security_group_id
  security_group_id        = module.sbcntr_sg_egress.security_group_id
  description              = "HTTPS for container app"
}
## Frontend container -> VPC endpoint
resource "aws_security_group_rule" "sbcntr_sg_vpce_from_sg_front_app" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_front_app.security_group_id
  security_group_id        = module.sbcntr_sg_egress.security_group_id
  description              = "HTTPS for frontend container app"
}
## Management server -> VPC endpoint
resource "aws_security_group_rule" "sbcntr_sg_vpce_from_sg_management" {
  type                     = "ingress"
  from_port                = 443
  to_port                  = 443
  protocol                 = "tcp"
  source_security_group_id = module.sbcntr_sg_management.security_group_id
  security_group_id        = module.sbcntr_sg_egress.security_group_id
  description              = "HTTPS for management server"
}


# ECR
resource "aws_ecr_repository" "sbcntr_ecr_repository_backend" {
  name                 = "sbcntr-ecr-backend"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "sbcntr-ecr-backend"
  }
}

resource "aws_ecr_repository" "sbcntr_ecr_repository_frontend" {
  name                 = "sbcntr-ecr-frontend"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "sbcntr-ecr-frontend"
  }
}

resource "aws_ecr_repository" "sbcntr_ecr_repository_base" {
  name                 = "sbcntr-ecr-base"
  image_tag_mutability = "MUTABLE"

  tags = {
    Name = "sbcntr-ecr-base"
  }
}

# VPC Endpoint for ECS & ECR
# See. https://docs.aws.amazon.com/ja_jp/AmazonECR/latest/userguide/vpc-endpoints.html
## for `aws ecr get-login-password`
resource "aws_vpc_endpoint" "sbcntr_vpc_endpoint_ecr_api" {
  vpc_id       = aws_vpc.sbcntr_vpc.id
  service_name = "com.amazonaws.ap-northeast-1.ecr.api"
  vpc_endpoint_type = "Interface"
  security_group_ids = [module.sbcntr_sg_egress.security_group_id]

  tags = {
    Name = "sbcntr-vpc-endpoint-ecr-api"
  }
}
## for `docker image push`
resource "aws_vpc_endpoint" "sbcntr_vpc_endpoint_ecr_dkr" {
  vpc_id       = aws_vpc.sbcntr_vpc.id
  service_name = "com.amazonaws.ap-northeast-1.ecr.dkr"
  vpc_endpoint_type = "Interface"
  security_group_ids = [module.sbcntr_sg_egress.security_group_id]

  tags = {
    Name = "sbcntr-vpc-endpoint-ecr-dkr"
  }
}
## for pulling from S3
resource "aws_vpc_endpoint" "sbcntr_vpc_endpoint_s3" {
  vpc_id       = aws_vpc.sbcntr_vpc.id
  service_name = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids = [
    aws_route_table.sbcntr_route_app_1a.id,
    aws_route_table.sbcntr_route_app_1c.id,
  ]

  tags = {
    Name = "sbcntr-vpc-endpoint-s3"
  }
}
## for CloudWatch Logs from ECS Fargate
resource "aws_vpc_endpoint" "sbcntr_vpc_endpoint_logs" {
  vpc_id       = aws_vpc.sbcntr_vpc.id
  service_name = "com.amazonaws.ap-northeast-1.logs"
  vpc_endpoint_type = "Interface"
  security_group_ids = [module.sbcntr_sg_egress.security_group_id]

  tags = {
    Name = "sbcntr-vpc-endpoint-logs"
  }
}


# S3 for ALB
# https://docs.aws.amazon.com/ja_jp/elasticloadbalancing/latest/classic/enable-access-logs.html#attach-bucket-policy
resource "aws_s3_bucket" "sbcntr_alb_log" {
  bucket        = "sbcntr-alb-log"
  force_destroy = true
}
resource "aws_s3_bucket_public_access_block" "sbcntr_alb_log_public_access" {
  bucket                  = aws_s3_bucket.sbcntr_alb_log.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}
resource "aws_s3_bucket_policy" "sbcntr_alb_log_bucket_policy" {
  bucket = aws_s3_bucket.sbcntr_alb_log.id
  policy = data.aws_iam_policy_document.sbcntr_alb_log_bucket_policy.json
}
data "aws_iam_policy_document" "sbcntr_alb_log_bucket_policy" {
  statement {
    effect    = "Allow"
    actions   = ["s3:PutObject"]
    resources = ["arn:aws:s3:::${aws_s3_bucket.sbcntr_alb_log.id}/*"]

    principals {
      type        = "AWS"
      identifiers = ["582318560864"]
    }
  }
}
resource "aws_s3_bucket_lifecycle_configuration" "sbcntr_alb_log_lifecycle" {
  bucket = aws_s3_bucket.sbcntr_alb_log.id

  rule {
    id     = "log_expiration"
    status = "Enabled"

    expiration {
      days = 180
    }
  }
}

# ALB
resource "aws_lb" "sbcntr_alb" {
  name               = "sbcntr-alb"
  load_balancer_type = "application"
  internal           = false
  idle_timeout       = 60

  enable_deletion_protection = false

  subnets = [
    aws_subnet.sbcntr_subnet_public_ingress_1a.id,
    aws_subnet.sbcntr_subnet_public_ingress_1c.id,
  ]

  access_logs {
    bucket  = aws_s3_bucket.sbcntr_alb_log.id
    enabled = true
  }

  security_groups = [
    module.sbcntr_sg_ingress.security_group_id,
  ]
}

## ALB Listener
resource "aws_lb_listener" "sbcntr_listener_http" {
  load_balancer_arn = aws_lb.sbcntr_alb.arn
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
resource "aws_lb_target_group" "sbcntr_target_group_front_app" {
  name                 = "sbcntr-target-group-front-app"
  target_type          = "ip"
  vpc_id               = aws_vpc.sbcntr_vpc.id
  port                 = 80
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

  depends_on = [aws_lb.sbcntr_alb]
}

## ALB Listener Rule
resource "aws_lb_listener_rule" "sbcntr_listener_rule_http" {
  listener_arn = aws_lb_listener.sbcntr_listener_http.arn
  priority     = 100

  action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.sbcntr_target_group_front_app.arn
  }

  condition {
    path_pattern {
      values = ["/*"]
    }
  }
}


# ECS

## CloudWatch Log Group
resource "aws_cloudwatch_log_group" "sbcntr_log_group" {
  name              = "/ecs/sbcntr"
  retention_in_days = 30
}

## IAM Role and Policy for ECS Task Execution and logging
## from "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
data "aws_iam_policy_document" "sbcntr_ecs_task_execution_policy_document" {
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

module "sbcntr_ecs_task_execution_role" {
  source     = "./iam_roles"
  name       = "sbcntr-ecs-task-execution-role"
  identifier = "ecs-tasks.amazonaws.com"
  policy     = data.aws_iam_policy_document.sbcntr_ecs_task_execution_policy_document.json
}

## Cluster
resource "aws_ecs_cluster" "sbcntr_ecs_cluster" {
  name = "sbcntr-ecs-cluster"
}

## Task Definition
resource "aws_ecs_task_definition" "sbcntr_task_definition" {
  family = "sbcntr-task"
  cpu    = 256
  memory = 512
  runtime_platform {
    operating_system_family = "LINUX"
    cpu_architecture        = "ARM64"
  }
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  container_definitions    = file("task_definition.json")
  execution_role_arn       = module.sbcntr_ecs_task_execution_role.iam_role_arn
}

## Service
resource "aws_ecs_service" "sbcntr_service" {
  name                              = "sbcntr-service"
  cluster                           = aws_ecs_cluster.sbcntr_ecs_cluster.id
  task_definition                   = aws_ecs_task_definition.sbcntr_task_definition.arn
  desired_count                     = 1
  launch_type                       = "FARGATE"
  platform_version                  = "1.4.0"
  health_check_grace_period_seconds = 60
  network_configuration {
    assign_public_ip = false
    security_groups  = [module.sbcntr_sg_front_app.security_group_id]
    subnets = [
      aws_subnet.sbcntr_subnet_private_app_1a.id,
      aws_subnet.sbcntr_subnet_private_app_1c.id,
    ]
  }
  load_balancer {
    target_group_arn = aws_lb_target_group.sbcntr_target_group_front_app.arn
    container_name   = "sbcntr-front-app"
    container_port   = 80
  }
  lifecycle {
    ignore_changes = [task_definition]
  }
}

# KMS Key and SSM Parameter Store
## KMS Key
resource "aws_kms_key" "sbcntr_kms_key" {
  description = "KMS Key for ECS Task Execution"
  enable_key_rotation = true
  is_enabled = true
  deletion_window_in_days = 30
}
resource "aws_kms_alias" "sbcntr_kms_key_alias" {
  name = "alias/sbcntr-kms-key"
  target_key_id = aws_kms_key.sbcntr_kms_key.key_id
}
## KMS Secrets per Environment; See. README.md
## data "aws_kms_secrets" "sbcntr_kms_secrets_dev" {
##   secret {
##     name    = "EXAMPLE_KEY"
##     payload = "AQICAHiVOc0+QxXBi64YqUGPDVl299K4Ex+ZBKQ8s37D08TRRQHeVshV7sH+t4kcm/pvnW8BAAAAeTB3BgkqhkiG9w0BBwagajBoAgEAMGMGCSqGSIb3DQEHATAeBglghkgBZQMEAS4wEQQMfoHjuxmMCP005Ad9AgEQgDbvQEpDEow+Evq8M+ia0gdO0DOyzjsBDsLKIm8n1dQjVrKrhr4SPRFCgbqS9NfAeX1x5O3uiVg="
##   }
## }
## SSM Parameter Store via KMS
## resource "aws_ssm_parameter" "example_key" {
##   name   = "/app/EXAMPLE_KEY"
##   type   = "SecureString"
##   value  = sensitive(data.aws_kms_secrets.sbcntr_kms_secrets_dev.plaintext["EXAMPLE_KEY"])
##   key_id = aws_kms_key.sbcntr_kms_key.arn
## }

# ElastiCache
resource "aws_elasticache_parameter_group" "sbcntr_elasticache_parameter_group" {
  name   = "sbcntr-elasticache-parameter-group"
  family = "redis7"

  parameter {
    name  = "cluster-enabled"
    value = "no"
  }
}

resource "aws_elasticache_subnet_group" "sbcntr_elasticache_subnet_group" {
  name       = "sbcntr-elasticache-subnet-group"
  subnet_ids = [aws_subnet.sbcntr_subnet_private_app_1a.id, aws_subnet.sbcntr_subnet_private_app_1c.id]
}

resource "aws_elasticache_replication_group" "sbcntr_elasticache_replication_group" {
  replication_group_id = "sbcntr-elasticache-replication-group"
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
  security_group_ids = [module.sbcntr_sg_redis.security_group_id]
  parameter_group_name = aws_elasticache_parameter_group.sbcntr_elasticache_parameter_group.name
  subnet_group_name = aws_elasticache_subnet_group.sbcntr_elasticache_subnet_group.name
}




output "alb_dns_name" {
  value = aws_lb.sbcntr_alb.dns_name
}

# Data source for availability zones
data "aws_availability_zones" "available" {
  state = "available"
}
