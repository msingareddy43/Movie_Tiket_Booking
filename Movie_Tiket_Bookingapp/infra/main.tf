############################################
#  Terraform AWS ECS + ALB + ECR Setup (Multi-Container Django App)
#  Uses existing IAM Role: movie-ticket-app-task-role
#  No hardcoded credentials (use `aws configure` or env vars)
############################################

terraform {
  required_version = ">= 1.5.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-south-1"
}

###########################################################
# Variables
###########################################################
variable "project" {
  default = "movie-ticket-app"
}

variable "app_port" {
  default     = 8000
  description = "Gunicorn app port"
}

variable "alb_port" {
  default     = 80
  description = "Public ALB port"
}

variable "public_subnets" {
  default = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "private_subnets" {
  default = ["10.0.3.0/24", "10.0.4.0/24"]
}

###########################################################
# VPC + Networking
###########################################################
data "aws_availability_zones" "az" {}

resource "aws_vpc" "main" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = { Name = "${var.project}-vpc" }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-igw" }
}

resource "aws_subnet" "public" {
  for_each = { for idx, cidr in var.public_subnets : idx => cidr }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.az.names[each.key]
  map_public_ip_on_launch = true
  tags = { Name = "${var.project}-public-${each.key}" }
}

resource "aws_subnet" "private" {
  for_each = { for idx, cidr in var.private_subnets : idx => cidr }
  vpc_id                  = aws_vpc.main.id
  cidr_block              = each.value
  availability_zone       = data.aws_availability_zones.az.names[each.key]
  map_public_ip_on_launch = false
  tags = { Name = "${var.project}-private-${each.key}" }
}

###########################################################
# NAT Gateway for private subnets
###########################################################
resource "aws_eip" "nat" {
  count  = 1
  domain = "vpc"
  tags   = { Name = "${var.project}-nat-eip" }
}

resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat[0].id
  subnet_id     = aws_subnet.public[0].id
  depends_on    = [aws_internet_gateway.igw]
  tags          = { Name = "${var.project}-nat" }
}

###########################################################
# Route Tables
###########################################################
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }
  tags = { Name = "${var.project}-public-rt" }
}

resource "aws_route_table_association" "public_assoc" {
  for_each       = aws_subnet.public
  subnet_id      = each.value.id
  route_table_id = aws_route_table.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id
  tags   = { Name = "${var.project}-private-rt" }
}

resource "aws_route" "private_nat" {
  route_table_id         = aws_route_table.private.id
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.nat.id
}

resource "aws_route_table_association" "private_assoc" {
  for_each       = aws_subnet.private
  subnet_id      = each.value.id
  route_table_id = aws_route_table.private.id
}

###########################################################
# Security Groups
###########################################################
resource "aws_security_group" "alb_sg" {
  name   = "${var.project}-alb-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = var.alb_port
    to_port     = var.alb_port
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-alb-sg" }
}

resource "aws_security_group" "ecs_sg" {
  name   = "${var.project}-ecs-sg"
  vpc_id = aws_vpc.main.id

  ingress {
    from_port       = var.app_port
    to_port         = var.app_port
    protocol        = "tcp"
    security_groups = [aws_security_group.alb_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project}-ecs-sg" }
}

###########################################################
# Reuse existing IAM Role
###########################################################
data "aws_iam_role" "ecs_task_role" {
  name = "movie-ticket-app-task-role"
}

###########################################################
# ECR Repository
###########################################################
resource "aws_ecr_repository" "repo" {
  name         = var.project
  force_delete = true
  image_scanning_configuration { scan_on_push = true }
}

###########################################################
# ECS Cluster + Task Definition (Multi-container)
###########################################################
resource "aws_ecs_cluster" "cluster" {
  name = "${var.project}-cluster"
}

resource "aws_ecs_task_definition" "task" {
  family                   = "${var.project}-task"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  cpu                      = "1024"
  memory                   = "2048"
  execution_role_arn       = data.aws_iam_role.ecs_task_role.arn
  task_role_arn            = data.aws_iam_role.ecs_task_role.arn

  container_definitions = jsonencode([
    {
      name      = "postgres_db"
      image     = "postgres:15"
      essential = true
      environment = [
        { name = "POSTGRES_USER", value = "postgres" },
        { name = "POSTGRES_PASSWORD", value = "postgres" },
        { name = "POSTGRES_DB", value = "movie_db" }
      ]
      portMappings = [{ containerPort = 5432, protocol = "tcp" }]
    },
    {
      name      = "django_app"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = true
      command   = ["sh", "-c", "python manage.py migrate && python manage.py collectstatic --noinput && gunicorn Movie_Tiket_Booking.wsgi:application --bind 0.0.0.0:8000"]
      environment = [
        { name = "ALLOWED_HOSTS", value = "movie-ticket-app-alb-197302161.ap-south-1.elb.amazonaws.com,127.0.0.1,localhost" },
        { name = "DEBUG", value = "False" },
        { name = "DJANGO_SETTINGS_MODULE", value = "Movie_Tiket_Booking.settings" }
      ]
      portMappings = [{ containerPort = 8000, protocol = "tcp" }]
      dependsOn    = [{ containerName = "postgres_db", condition = "START" }]
    },
    {
      name      = "nginx_server"
      image     = "nginx:latest"
      essential = false
      portMappings = [{ containerPort = 80, protocol = "tcp" }]
      dependsOn    = [{ containerName = "django_app", condition = "START" }]
    },
    {
      name      = "django_test_runner"
      image     = "${aws_ecr_repository.repo.repository_url}:latest"
      essential = false
      command   = ["sh", "-c", "pytest -v --disable-warnings || tail -f /dev/null"]
      dependsOn = [
        { containerName = "django_app", condition = "START" },
        { containerName = "postgres_db", condition = "START" }
      ]
    }
  ])
}

###########################################################
# Load Balancer + Target Group + Listener
###########################################################
resource "aws_lb" "alb" {
  name               = "${var.project}-alb"
  internal           = false
  load_balancer_type = "application"
  subnets            = [for s in aws_subnet.public : s.id]
  security_groups    = [aws_security_group.alb_sg.id]
}

resource "aws_lb_target_group" "tg" {
  name        = "${var.project}-tg"
  port        = var.app_port
  protocol    = "HTTP"
  target_type = "ip"
  vpc_id      = aws_vpc.main.id
  health_check {
    path                = "/"
    protocol            = "HTTP"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
  }
}

resource "aws_lb_listener" "listener" {
  load_balancer_arn = aws_lb.alb.arn
  port              = var.alb_port
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.tg.arn
  }
}

###########################################################
# ECS Service
###########################################################
resource "aws_ecs_service" "service" {
  name            = "${var.project}-service"
  cluster         = aws_ecs_cluster.cluster.id
  task_definition = aws_ecs_task_definition.task.arn
  launch_type     = "FARGATE"
  desired_count   = 1

  network_configuration {
    subnets         = [for s in aws_subnet.private : s.id]
    assign_public_ip = false
    security_groups  = [aws_security_group.ecs_sg.id]
  }

  load_balancer {
    target_group_arn = aws_lb_target_group.tg.arn
    container_name   = "django_app"
    container_port   = var.app_port
  }

  depends_on = [aws_lb_listener.listener]
}

###########################################################
# Outputs
###########################################################
output "alb_dns_name" {
  value = aws_lb.alb.dns_name
}

output "ecr_repository_url" {
  value = aws_ecr_repository.repo.repository_url
}
# Create IAM user for Jenkins
resource "aws_iam_user" "jenkins" {
  name = "jenkins-user"
}

# Attach policy (AdministratorAccess for simplicity — restrict later)
resource "aws_iam_user_policy_attachment" "jenkins_admin" {
  user       = aws_iam_user.jenkins.name
  policy_arn = "arn:aws:iam::aws:policy/AdministratorAccess"
}

# Create access key for Jenkins
resource "aws_iam_access_key" "jenkins" {
  user = aws_iam_user.jenkins.name
}

# Output access keys
output "jenkins_iam_access_key_id" {
  value     = aws_iam_access_key.jenkins.id
  sensitive = true
}

output "jenkins_iam_secret_access_key" {
  value     = aws_iam_access_key.jenkins.secret
  sensitive = true
}
