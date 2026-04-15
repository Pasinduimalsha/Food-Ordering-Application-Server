variable "region" {
    description = "AWS region to deploy resources"
    type        = string
    default     = "us-east-1"
}

variable "instance_type" {
    description = "Type of EC2 instance to use for Build Server"
    type        = string
    default     = "t3.micro"
}

variable "deploy_instance_type" {
    description = "Type of EC2 instance to use for Deploy Server"
    type        = string
    default     = "t3.small"
}

variable "ami" {
    description = "AMI ID to use for EC2 instances"
    type        = string
    default     = "ami-0ec10929233384c7f"
}

variable "key_name" {
    description = "Name of the AWS key pair to use for EC2 instances"
    type        = string
    default     = "Jenkins"
}

variable "vpc_name" {
    description = "Name of the VPC to use"
    type        = string
    default     = "default"
}