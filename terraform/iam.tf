# Política de asunción de rol para funciones Lambda
resource "aws_iam_role" "lambda_common_role" {
  name = "lambda-base-role-${var.environment}"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action = "sts:AssumeRole"
      Effect = "Allow"
      Principal = { Service = "lambda.amazonaws.com" }
    }]
  })
}

# PERMISOS BASICOS: LOGS Y VPC 
# Permite a las Lambdas crear logs y conectarse a la red privada (VPC)
resource "aws_iam_role_policy_attachment" "lambda_vpc_execution" {
  role       = aws_iam_role.lambda_common_role.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaVPCAccessExecutionRole"
}

# ASIGNACIÓN DE PERMISOS PARA LA LAMBDA UPLOAD 
resource "aws_iam_policy" "upload_policy" {
  name        = "upload-lambda-policy-${var.environment}"
  description = "Permite subir objetos a la carpeta uploads/"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Effect   = "Allow"
      Action   = ["s3:PutObject"]
      Resource = ["${aws_s3_bucket.images.arn}/uploads/*"]
    }]
  })
}

resource "aws_iam_role_policy_attachment" "upload_attach" {
  role       = aws_iam_role.lambda_common_role.name
  policy_arn = aws_iam_policy.upload_policy.arn
}

# PERMISOS ESPECÍFICOS PARA LAMBDA CROP 
resource "aws_iam_policy" "crop_policy" {
  name        = "crop-lambda-policy-${var.environment}"
  description = "Permite leer de uploads/, escribir en processed/ y manejar SQS"

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect   = "Allow"
        Action   = ["s3:GetObject"]
        Resource = ["${aws_s3_bucket.images.arn}/uploads/*"]
      },
      {
        Effect   = "Allow"
        Action   = ["s3:PutObject"]
        Resource = ["${aws_s3_bucket.images.arn}/processed/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "sqs:ReceiveMessage",
          "sqs:DeleteMessage",
          "sqs:GetQueueAttributes"
        ]
        Resource = [aws_sqs_queue.image_queue.arn]
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "crop_attach" {
  role       = aws_iam_role.lambda_common_role.name
  policy_arn = aws_iam_policy.crop_policy.arn
}