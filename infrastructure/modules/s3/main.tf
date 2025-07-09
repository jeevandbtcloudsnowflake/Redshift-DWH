# S3 Module for E-Commerce Data Warehouse

# Random suffix for bucket names to ensure uniqueness
resource "random_string" "bucket_suffix" {
  length  = 8
  special = false
  upper   = false
}

# Raw Data Bucket
resource "aws_s3_bucket" "raw_data" {
  bucket = "${var.bucket_prefix}-${var.environment}-raw-data-${random_string.bucket_suffix.result}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-raw-data"
    Purpose     = "Raw data storage"
    DataType    = "Raw"
  })
}

# Processed Data Bucket
resource "aws_s3_bucket" "processed_data" {
  bucket = "${var.bucket_prefix}-${var.environment}-processed-data-${random_string.bucket_suffix.result}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-processed-data"
    Purpose     = "Processed data storage"
    DataType    = "Processed"
  })
}

# Scripts Bucket
resource "aws_s3_bucket" "scripts" {
  bucket = "${var.bucket_prefix}-${var.environment}-scripts-${random_string.bucket_suffix.result}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-scripts"
    Purpose     = "ETL scripts and code"
    DataType    = "Scripts"
  })
}

# Logs Bucket
resource "aws_s3_bucket" "logs" {
  bucket = "${var.bucket_prefix}-${var.environment}-logs-${random_string.bucket_suffix.result}"

  tags = merge(var.tags, {
    Name        = "${var.project_name}-${var.environment}-logs"
    Purpose     = "Application and ETL logs"
    DataType    = "Logs"
  })
}

# Raw Data Bucket Versioning
resource "aws_s3_bucket_versioning" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Processed Data Bucket Versioning
resource "aws_s3_bucket_versioning" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Scripts Bucket Versioning
resource "aws_s3_bucket_versioning" "scripts" {
  bucket = aws_s3_bucket.scripts.id
  versioning_configuration {
    status = "Enabled"
  }
}

# Raw Data Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Processed Data Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Scripts Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Logs Bucket Server-Side Encryption
resource "aws_s3_bucket_server_side_encryption_configuration" "logs" {
  bucket = aws_s3_bucket.logs.id

  rule {
    apply_server_side_encryption_by_default {
      sse_algorithm = "AES256"
    }
    bucket_key_enabled = true
  }
}

# Raw Data Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Processed Data Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Scripts Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "scripts" {
  bucket = aws_s3_bucket.scripts.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Logs Bucket Public Access Block
resource "aws_s3_bucket_public_access_block" "logs" {
  bucket = aws_s3_bucket.logs.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Raw Data Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "raw_data" {
  bucket = aws_s3_bucket.raw_data.id

  rule {
    id     = "raw_data_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 30
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 90
      storage_class = "GLACIER"
    }

    transition {
      days          = 365
      storage_class = "DEEP_ARCHIVE"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 90
    }
  }
}

# Processed Data Bucket Lifecycle Configuration
resource "aws_s3_bucket_lifecycle_configuration" "processed_data" {
  bucket = aws_s3_bucket.processed_data.id

  rule {
    id     = "processed_data_lifecycle"
    status = "Enabled"

    filter {
      prefix = ""
    }

    transition {
      days          = 60
      storage_class = "STANDARD_IA"
    }

    transition {
      days          = 180
      storage_class = "GLACIER"
    }

    noncurrent_version_transition {
      noncurrent_days = 30
      storage_class   = "STANDARD_IA"
    }

    noncurrent_version_expiration {
      noncurrent_days = 60
    }
  }
}
