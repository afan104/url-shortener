# ecs cluster - groups the ec2 instance and tasks together
resource "aws_ecs_cluster" "main" {
  name = "url-shortener-cluster"
}

# trust policy shared by both task roles below - allows the ecs tasks service
data "aws_iam_policy_document" "ecs_tasks_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ecs-tasks.amazonaws.com"]
    }
  }
}

# execution role - used by the ecs agent to pull the image from ecr and ship
# logs, not by your application code
resource "aws_iam_role" "ecs_task_execution" {
  name               = "url-shortener-ecs-execution-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

# AWS-managed policy covering ecr pull + cloudwatch logs permissions
resource "aws_iam_role_policy_attachment" "ecs_task_execution" {
  role       = aws_iam_role.ecs_task_execution.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy"
}

# task role - used by your application code at runtime (dynamodb calls)
resource "aws_iam_role" "ecs_task" {
  name               = "url-shortener-ecs-task-role"
  assume_role_policy = data.aws_iam_policy_document.ecs_tasks_assume_role.json
}

# permissions the app itself needs, scoped to just this table's arn
data "aws_iam_policy_document" "dynamodb_access" {
  statement {
    actions = [
      "dynamodb:GetItem",
      "dynamodb:PutItem",
    ]
    resources = [aws_dynamodb_table.main.arn]
  }
}

# attaches the dynamodb permissions above inline to the task role
resource "aws_iam_role_policy" "dynamodb_access" {
  name   = "dynamodb-access"
  role   = aws_iam_role.ecs_task.id
  policy = data.aws_iam_policy_document.dynamodb_access.json
}

# task definition - what to run: image, resources, port, which role does what
resource "aws_ecs_task_definition" "main" {
  family                   = "url-shortener"
  requires_compatibilities = ["EC2"]
  network_mode             = "bridge"
  execution_role_arn       = aws_iam_role.ecs_task_execution.arn
  task_role_arn            = aws_iam_role.ecs_task.arn

  container_definitions = jsonencode([
    {
      name      = "url-shortener"
      image     = "${aws_ecr_repository.main.repository_url}:latest"
      cpu       = 256
      memory    = 512
      essential = true
      portMappings = [
        {
          containerPort = 8000
          hostPort      = 8000
        }
      ]
    }
  ])
}

# ecs service - keeps the task running on the cluster
resource "aws_ecs_service" "main" {
  name            = "url-shortener-service"
  cluster         = aws_ecs_cluster.main.id
  task_definition = aws_ecs_task_definition.main.arn
  desired_count   = 1
  launch_type     = "EC2"
}

# ami param for next block
data "aws_ssm_parameter" "ecs_ami" {
  name = "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id"
}

# ec2 image specs. e.g. linux OS (AL2 image)
resource "aws_instance" "ecs" {
  ami                    = data.aws_ssm_parameter.ecs_ami.value
  instance_type          = "t3.micro"
  subnet_id              = aws_subnet.main.id
  vpc_security_group_ids = [aws_security_group.main.id]
  iam_instance_profile   = aws_iam_instance_profile.ec2.name

  # tells the ecs agent on boot which cluster to register this instance with
  user_data = <<-EOF
    #!/bin/bash
    echo ECS_CLUSTER=${aws_ecs_cluster.main.name} >> /etc/ecs/ecs.config
  EOF

  tags = {
    Name = "url-shortener-ec2"
  }
}
