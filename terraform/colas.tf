# Almacenamiento en Amazon S3 

resource "aws_s3_bucket" "images" {
  # nombre
  bucket = "${var.project_name}-${var.environment}-images-juancarlosvilca"
}

# Configuración de Lifecycle
resource "aws_s3_bucket_lifecycle_configuration" "images_lifecycle" {
  bucket = aws_s3_bucket.images.id

  # Regla 1: Las imágenes originales (uploads/) se eliminan después de 30 días
  rule {
    id     = "expire-uploads"
    status = "Enabled"
    filter { prefix = "uploads/" }
    expiration { days = 30 }
  }

  # Regla 2: fotos procesadas (processed/) expiran tras 90 dias
  rule {
    id     = "expire-processed"
    status = "Enabled"
    filter { prefix = "processed/" }
    expiration { days = 90 }
  }
}

# AMAZON SQS

# 1. Dead-Letter Queue (Cola de errores)
resource "aws_sqs_queue" "image_dlq" {
  name                      = "${var.project_name}-${var.environment}-image-dlq"
  message_retention_seconds = 1209600 # 14 dias
}

# 2. Cola Principal
resource "aws_sqs_queue" "image_queue" {
  name                      = "${var.project_name}-${var.environment}-image-queue"
  visibility_timeout_seconds = 360 # 6 veces el timeout de la lambda
  message_retention_seconds  = 86400 # 1 día
  receive_wait_time_seconds  = 20    # Long polling

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.image_dlq.arn
    maxReceiveCount     = 3 # Reintentos antes de ir a la DLQ
  })
}

# INTEGRACION: S3 LE ENVÍA AVISO A SQS 

# Autorización para que S3 envíe mensajes a la cola SQS
resource "aws_sqs_queue_policy" "allow_s3_events" {
  queue_url = aws_sqs_queue.image_queue.id
  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
      Action    = "sqs:SendMessage"
      Resource  = aws_sqs_queue.image_queue.arn
      Condition = {
        ArnLike = { "aws:SourceArn" : aws_s3_bucket.images.arn }
      }
    }]
  })
}

# Configuración de notificación
resource "aws_s3_bucket_notification" "s3_notif" {
  bucket = aws_s3_bucket.images.id

  queue {
    queue_arn     = aws_sqs_queue.image_queue.arn
    events        = ["s3:ObjectCreated:*"]
    filter_prefix = "uploads/" # Solo avisar cuando algo cae en uploads/
  }

  depends_on = [aws_sqs_queue_policy.allow_s3_events]
}