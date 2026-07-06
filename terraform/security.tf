# placeholder: security group (ports 22, 8000), is (dynamodb, ecr) for ec2

resource "aws_security_group" "main" {
  vpc_id      = aws_vpc.main.id
}

# travel into vpc to ec2 (from anywhere to ec2 through port 22)
resource "aws_vpc_security_group_ingress_rule" "ec2_ssh" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 22
  ip_protocol       = "tcp"
  to_port           = 22
}

# travel into vpc to app (from anywhere to app port 8000)
resource "aws_vpc_security_group_ingress_rule" "app_http" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  from_port         = 8000
  ip_protocol       = "tcp"
  to_port           = 8000
}

# travel out of vpc (to anywhere via any protocol e.g. dynamodb and ecr, rules are stateful so allows back in by same connection)
resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
  security_group_id = aws_security_group.main.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# trust policy: defines WHO is allowed to assume the role below (the EC2 service itself)
data "aws_iam_policy_document" "ec2_assume_role" {
  statement {
    actions = ["sts:AssumeRole"]

    principals {
      type        = "Service"
      identifiers = ["ec2.amazonaws.com"]
    }
  }
}

# the ec2 instance role - only needs permissions for the ecs agent to manage
# cluster membership (register/deregister this instance, report status).
# dynamodb access (task role) and ecr pull access (task execution role) do NOT
# belong here - they get attached to the ecs task definition instead, in
# ecs.tf, since that's what your application code and the container pull
# actually run under, not the ec2 instance itself
resource "aws_iam_role" "ec2" {
  name               = "url-shortener-ec2-role"
  assume_role_policy = data.aws_iam_policy_document.ec2_assume_role.json
}

# AWS-managed policy granting the ecs agent the permissions it needs to
# register/manage this instance as part of the ecs cluster
resource "aws_iam_role_policy_attachment" "ecs_agent" {
  role       = aws_iam_role.ec2.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role"
}

# wraps the role so it can actually be attached to the ec2 instance later
resource "aws_iam_instance_profile" "ec2" {
  name = "url-shortener-ec2-instance-profile"
  role = aws_iam_role.ec2.name
}
