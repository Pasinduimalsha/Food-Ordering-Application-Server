variable "instance_type" {
    default = "t3.micro"
}

variable "region" {
    default = "us-east-1"
}

variable "ami"{
    default = "ami-0ec10929233384c7f"
}

variable "key_name" {
    description = "Name of the AWS key pair to use for EC2 instances"
    type        = string
    default     = "Jenkins"
}