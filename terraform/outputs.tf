output "ec2_public_ip" {
  value       = aws_instance.ecs.public_ip
  description = "public ip of the ec2 instance running the app - ssh in or curl it here"
}

output "ecr_repository_url" {
  value       = aws_ecr_repository.main.repository_url
  description = "push docker images here"
}

output "dynamodb_table_name" {
  value       = aws_dynamodb_table.main.name
  description = "table name the app should read/write to"
}

output "ecs_cluster_name" {
  value       = aws_ecs_cluster.main.name
  description = "cluster name, useful for aws ecs cli commands"
}