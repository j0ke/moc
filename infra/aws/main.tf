provider "aws" {
  region = "eu-central-1"
}

resource "aws_s3_bucket" "media_bucket" {
  bucket = "orchardcms-media-bucket"
  acl    = "private"
}

resource "aws_db_instance" "postgres" {
  identifier             = "orchardcms-db"
  allocated_storage      = 20
  engine                = "postgres"
  engine_version        = "14"
  instance_class        = "db.t3.micro"
  username              = "admin"
  password              = "securepassword"
  publicly_accessible   = false
  skip_final_snapshot   = true
}

resource "aws_security_group" "orchard_sg" {
  name        = "orchardcms-sg"
  description = "Security group for OrchardCMS"

  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_ecs_cluster" "orchard_cluster" {
  name = "orchardcms-cluster"
}

resource "aws_ecs_task_definition" "orchard_task" {
  family                   = "orchardcms-task"
  requires_compatibilities = ["FARGATE"]
  network_mode             = "awsvpc"
  cpu                      = "512"
  memory                   = "1024"
  execution_role_arn       = "arn:aws:iam::512130693637:role/ecsTaskExecutionRole-cust"

  container_definitions = jsonencode([
    {
      name      = "orchardcms"
      image     = "your-docker-image-url"
      essential = true
      portMappings = [
        {
          containerPort = 80
          hostPort      = 80
        }
      ]
    }
  ])
}

resource "aws_ecs_service" "orchard_service" {
  name            = "orchardcms-service"
  cluster         = aws_ecs_cluster.orchard_cluster.id
  task_definition = aws_ecs_task_definition.orchard_task.arn
  launch_type     = "FARGATE"

  network_configuration {
    subnets          = ["subnet-12345678"]  # Replace with actual subnet IDs
    security_groups  = [aws_security_group.orchard_sg.id]
    assign_public_ip = true
  }
}

output "s3_bucket_name" {
  value = aws_s3_bucket.media_bucket.id
}

output "db_endpoint" {
  value = aws_db_instance.postgres.endpoint
}

output "ecs_cluster_name" {
  value = aws_ecs_cluster.orchard_cluster.name
}
