terraform {
    required_version = ">= 1.0.0"

    required_providers {
        aws = {
            source  = "hashicorp/aws"
            version = "~> 5.0"
        }
    }
}

provider "aws" {
    region = var.aws_region
    #Etiquetar todos los recursos del proyecto
    default_tags {
        tags = {
            Project     = "ImageProcessor"
            Environment = var.environment
            Owner       = "JuanCarlosVilca"
        }
    }
}