provider "aws" {
  region = "us-east-1"
}

resource "aws_vpc" "keshwani_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "keshwaniVPC"
  }
}

resource "aws_internet_gateway" "keshwani_igw" {
  vpc_id = aws_vpc.keshwani_vpc.id
  tags = {
    Name = "keshwaniIGW"
  }
}

resource "aws_route_table" "keshwani_rt" {
  vpc_id = aws_vpc.keshwani_vpc.id
  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.keshwani_igw.id
  }
  tags = {
    Name = "keshwaniRouteTable"
  }
}

resource "aws_subnet" "keshwani_subnet1" {
  vpc_id                  = aws_vpc.keshwani_vpc.id
  cidr_block              = "10.0.1.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "keshwaniSubnet1"
  }
}

resource "aws_subnet" "keshwani_subnet2" {
  vpc_id                  = aws_vpc.keshwani_vpc.id
  cidr_block              = "10.0.2.0/24"
  map_public_ip_on_launch = true
  tags = {
    Name = "keshwaniSubnet2"
  }
}

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.keshwani_subnet1.id
  route_table_id = aws_route_table.keshwani_rt.id
}

resource "aws_route_table_association" "b" {
  subnet_id      = aws_subnet.keshwani_subnet2.id
  route_table_id = aws_route_table.keshwani_rt.id
}

resource "aws_security_group" "keshwani_sg" {
  name        = "keshwaniSecurityGroup"
  description = "Security group for Fargate containers"
  vpc_id      = aws_vpc.keshwani_vpc.id
  ingress {
    from_port   = 5000
    to_port     = 5000
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "keshwani_cluster" {
  name = "keshwaniCluster"
}

resource "aws_iam_role" "ecs_execution_role" {
  name = "ecsExecutionRole"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Principal = {
          Service = "ecs-tasks.amazonaws.com"
        }
        Effect = "Allow"
        Sid    = ""
      },
    ]
  })
}

resource "aws_iam_role_policy_attachment" "ecs_execution_role_policy_attachment" {
  role       = aws_iam_role.ecs_execution_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# AWS CloudWatch Log Group
resource "aws_cloudwatch_log_group" "ecs_logs" {
  name = "/ecs/keshwaniTask"
  retention_in_days = 30
}

# Define the ECS Task Definition with updated log configuration
resource "aws_ecs_task_definition" "keshwani_task" {
  family                   = "keshwaniTask"
  cpu                      = "256"
  memory                   = "512"
  network_mode             = "awsvpc"
  requires_compatibilities = ["FARGATE"]
  execution_role_arn       = aws_iam_role.ecs_execution_role.arn
  container_definitions    = jsonencode([
    {
      name      = "keshwaniContainer"
      image     = "891377269445.dkr.ecr.us-east-1.amazonaws.com/keshwani-repo:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 5000
          hostPort      = 5000
        }
      ],
      logConfiguration = {
        logDriver = "awslogs"
        options = {
          awslogs-group         = aws_cloudwatch_log_group.ecs_logs.name
          awslogs-region        = "us-east-1"
          awslogs-stream-prefix = "ecs"
        }
      }
    }
  ])
}

# Create the ECS Service
resource "aws_ecs_service" "keshwani_service" {
  name            = "keshwaniService"
  cluster         = aws_ecs_cluster.keshwani_cluster.id
  task_definition = aws_ecs_task_definition.keshwani_task.arn
  desired_count   = 1
  launch_type     = "FARGATE"
  network_configuration {
    assign_public_ip = true
    subnets          = [aws_subnet.keshwani_subnet1.id, aws_subnet.keshwani_subnet2.id]
    security_groups  = [aws_security_group.keshwani_sg.id]
  }
}

# Create an Application Load Balancer
resource "aws_lb" "keshwani_alb" {
  name               = "keshwaniALB"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.keshwani_sg.id]
  subnets            = [aws_subnet.keshwani_subnet1.id, aws_subnet.keshwani_subnet2.id]
}

resource "aws_lb_target_group" "keshwani_tg" {
  name     = "keshwaniTG"
  port     = 5000
  protocol = "HTTP"
  vpc_id   = aws_vpc.keshwani_vpc.id
}

resource "aws_lb_listener" "keshwani_listener" {
  load_balancer_arn = aws_lb.keshwani_alb.arn
  port              = "80"
  protocol          = "HTTP"
  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.keshwani_tg.arn
  }
}
