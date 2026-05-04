# ============================================
# RANDOM SUFFIX — чтобы имя бакета было уникальным
# S3 bucket names уникальны глобально по всему AWS
# ============================================
resource "random_id" "suffix" {
  byte_length = 4
}

locals {
  bucket_name = "${var.project_name}-${var.environment}-${random_id.suffix.hex}"
}

# ============================================
# S3 BUCKET — хранит наши файлы
# Бакет приватный — никто не может читать напрямую
# ============================================
resource "aws_s3_bucket" "website" {
  bucket = local.bucket_name

  tags = {
    Name        = local.bucket_name
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# Блокируем весь публичный доступ к бакету
# CloudFront будет читать через OAC, не напрямую
resource "aws_s3_bucket_public_access_block" "website" {
  bucket = aws_s3_bucket.website.id

  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# Включаем версионирование — хорошая практика
# Позволяет откатить файл если что-то сломалось
resource "aws_s3_bucket_versioning" "website" {
  bucket = aws_s3_bucket.website.id

  versioning_configuration {
    status = "Enabled"
  }
}

# Загружаем index.html в бакет
# filemd5 — Terraform перезальёт файл только если содержимое изменилось
resource "aws_s3_object" "index" {
  bucket       = aws_s3_bucket.website.id
  key          = "index.html"
  source       = "${path.root}/app/index.html"
  content_type = "text/html"
  etag         = filemd5("${path.root}/app/index.html")
}

# ============================================
# OAC — Origin Access Control
# Это "удостоверение" CloudFront для доступа к S3
# S3 будет принимать запросы только от этого OAC
# ============================================
resource "aws_cloudfront_origin_access_control" "website" {
  name                              = "${local.bucket_name}-oac"
  description                       = "OAC for ${local.bucket_name}"
  origin_access_control_origin_type = "s3"
  signing_behavior                  = "always"
  signing_protocol                  = "sigv4"
}

# ============================================
# CLOUDFRONT DISTRIBUTION
# Это сама CDN "раздача" — глобальная сеть
# ============================================
resource "aws_cloudfront_distribution" "website" {
  enabled             = true
  default_root_object = "index.html"  # что показывать по умолчанию на /
  comment             = "${var.project_name} ${var.environment} website"
  price_class         = "PriceClass_100"  # только EU + NA edge locations (дешевле)

  # Откуда берём файлы — наш S3 бакет
  origin {
    domain_name              = aws_s3_bucket.website.bucket_regional_domain_name
    origin_id                = "S3-${local.bucket_name}"
    origin_access_control_id = aws_cloudfront_origin_access_control.website.id
  }

  # Настройки кэширования по умолчанию
  default_cache_behavior {
    allowed_methods        = ["GET", "HEAD"]
    cached_methods         = ["GET", "HEAD"]
    target_origin_id       = "S3-${local.bucket_name}"
    viewer_protocol_policy = "redirect-to-https"  # HTTP автоматически → HTTPS

    # Managed cache policy от AWS — оптимальные настройки
    cache_policy_id = "658327ea-f89d-4fab-a63d-7e88639e58f6"
  }

  # Что показывать при ошибке 403/404 (файл не найден в S3)
  custom_error_response {
    error_code         = 403
    response_code      = 200
    response_page_path = "/index.html"
  }

  custom_error_response {
    error_code         = 404
    response_code      = 200
    response_page_path = "/index.html"
  }

  # Geo restriction — не блокируем никого
  restrictions {
    geo_restriction {
      restriction_type = "none"
    }
  }

  # SSL сертификат — используем дефолтный CloudFront сертификат
  # Позже можно заменить на свой домен через ACM
  viewer_certificate {
    cloudfront_default_certificate = true
  }

  tags = {
    Name        = "${var.project_name}-${var.environment}-cf"
    Environment = var.environment
    Project     = var.project_name
    ManagedBy   = "terraform"
  }
}

# ============================================
# BUCKET POLICY
# Разрешаем CloudFront читать файлы из S3
# Только этому конкретному CloudFront distribution
# ============================================
resource "aws_s3_bucket_policy" "website" {
  bucket = aws_s3_bucket.website.id

  # depends_on нужен чтобы public_access_block создался раньше policy
  depends_on = [aws_s3_bucket_public_access_block.website]

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Sid    = "AllowCloudFrontServicePrincipal"
        Effect = "Allow"
        Principal = {
          Service = "cloudfront.amazonaws.com"
        }
        Action   = "s3:GetObject"
        Resource = "${aws_s3_bucket.website.arn}/*"
        Condition = {
          StringEquals = {
            # Только наш конкретный CloudFront distribution
            "AWS:SourceArn" = aws_cloudfront_distribution.website.arn
          }
        }
      }
    ]
  })
}