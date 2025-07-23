variable "aws_region" {
  description = "Región de AWS"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Nombre del proyecto"
  type        = string
  default     = "provincial-indicators"
}

variable "vpc_cidr" {
  description = "CIDR para la VPC"
  type        = string
  default     = "10.0.0.0/16"
}

variable "public_subnets" {
  description = "Lista de subnets públicas"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}
