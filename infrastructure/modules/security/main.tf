# Security Module for E-Commerce Data Warehouse

# Redshift Security Group
resource "aws_security_group" "redshift" {
  name_prefix = "${var.project_name}-${var.environment}-redshift-"
  vpc_id      = var.vpc_id

  description = "Security group for Redshift cluster"

  # Inbound rules
  ingress {
    description = "Redshift port from VPC"
    from_port   = 5439
    to_port     = 5439
    protocol    = "tcp"
    cidr_blocks = [data.aws_vpc.main.cidr_block]
  }

  # Redshift port access will be added via security group rules

  # Outbound rules
  egress {
    description = "All outbound traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-redshift-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Glue Security Group
resource "aws_security_group" "glue" {
  name_prefix = "${var.project_name}-${var.environment}-glue-"
  vpc_id      = var.vpc_id

  description = "Security group for AWS Glue"

  # Self-referencing rule for Glue
  ingress {
    description = "Self-referencing rule"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  # HTTPS outbound for AWS services
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP outbound for package downloads
  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redshift connection will be added via security group rules

  # Self-referencing egress rule
  egress {
    description = "Self-referencing egress"
    from_port   = 0
    to_port     = 65535
    protocol    = "tcp"
    self        = true
  }

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-glue-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Lambda Security Group
resource "aws_security_group" "lambda" {
  name_prefix = "${var.project_name}-${var.environment}-lambda-"
  vpc_id      = var.vpc_id

  description = "Security group for Lambda functions"

  # Outbound rules
  egress {
    description = "HTTPS outbound"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    description = "HTTP outbound"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Redshift connection will be added via security group rules

  tags = merge(var.tags, {
    Name = "${var.project_name}-${var.environment}-lambda-sg"
  })

  lifecycle {
    create_before_destroy = true
  }
}

# Security Group Rules to avoid circular dependencies
resource "aws_security_group_rule" "redshift_from_glue" {
  type                     = "ingress"
  from_port                = 5439
  to_port                  = 5439
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.glue.id
  security_group_id        = aws_security_group.redshift.id
  description              = "Allow Glue to access Redshift"
}

resource "aws_security_group_rule" "glue_to_redshift" {
  type                     = "egress"
  from_port                = 5439
  to_port                  = 5439
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redshift.id
  security_group_id        = aws_security_group.glue.id
  description              = "Allow Glue to connect to Redshift"
}

resource "aws_security_group_rule" "lambda_to_redshift" {
  type                     = "egress"
  from_port                = 5439
  to_port                  = 5439
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.redshift.id
  security_group_id        = aws_security_group.lambda.id
  description              = "Allow Lambda to connect to Redshift"
}

resource "aws_security_group_rule" "redshift_from_lambda" {
  type                     = "ingress"
  from_port                = 5439
  to_port                  = 5439
  protocol                 = "tcp"
  source_security_group_id = aws_security_group.lambda.id
  security_group_id        = aws_security_group.redshift.id
  description              = "Allow Lambda to access Redshift"
}

# Data source for VPC
data "aws_vpc" "main" {
  id = var.vpc_id
}
