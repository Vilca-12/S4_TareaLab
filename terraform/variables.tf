variable "aws_region" {
    description = "Region de AWS de despliegue"
    type        = string
    default     = "us-east-1"
}
variable "environment" {
    description = "Entorno de despliegue (dev, qa, prod)"
    type        = string
}

variable "project_name" {
    description = "Nombre base para los recursos"
    type        = string
    default     = "image-processor"
}

variable "vpc_cidr" {
    description = "Rango de IPs para la VPC"
    type        = string
    default     = "10.0.0.0/16"
}