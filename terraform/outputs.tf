output "api_url" {
  description = "URL del API Gateway para subir imágenes"
  value       = "${aws_apigatewayv2_api.http_api.api_endpoint}/upload"
}

output "s3_bucket_name" {
  description = "Nombre del bucket creado"
  value       = aws_s3_bucket.images.id
}

output "sqs_queue_url" {
  description = "URL de la cola SQS"
  value       = aws_sqs_queue.image_queue.id
}