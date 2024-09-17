variable "threetier_region" {
  description = "Value of the Name tag for the region"
  type        = string
  default     = "us-east-1"
}

variable "threetier_vpc" {
  description = "Value of the Name tag for the VPC"
  type        = string
  default     = "Mina VPC"
}

variable "threetier_IGW" {
  description = "Value of the Name tag for the IGW"
  type        = string
  default     = "Mina IGW"
}

variable "threetier_PublicSubnets" {
  description = "Value of the Name tag for the Public Subnets"
  type        = string
  default     = "Mina Public Subnet "
}

variable "threetier_PrivateSubnets" {
  description = "Value of the Name tag for the Private Subnets"
  type        = string
  default     = "Mina Private Subnet "
}

variable "threetier_DBSubnets" {
  description = "Value of the Name tag for the DB Subnets"
  type        = string
  default     = "Mina DB Subnet "
}

variable "threetier_NATGateway" {
  description = "Value of the Name tag for the NAT Gateway"
  type        = string
  default     = "Mina Main NAT Gateway"
}

variable "threetier_PublicRT" {
  description = "Value of the Name tag for the Public Route Table"
  type        = string
  default     = "Mina Public Route Table"
}

variable "threetier_PrivateRT" {
  description = "Value of the Name tag for the Private Route Table"
  type        = string
  default     = "Mina Private Route Table"
}

variable "threetier_externalALB_SG" {
  description = "Value of the Name tag for the external ALB SG"
  type        = string
  default     = "Mina External ALB SG"
}

variable "threetier_internalALB_SG" {
  description = "Value of the Name tag for the internal ALB SG"
  type        = string
  default     = "Mina Internal ALB SG"
}

variable "threetier_PublicEC2_SG" {
  description = "Value of the Name tag for the Public EC2 SG"
  type        = string
  default     = "Mina Public EC2 SG"
}

variable "threetier_PrivateEC2_SG" {
  description = "Value of the Name tag for the Private EC2 SG"
  type        = string
  default     = "Mina Private EC2 SG"
}

variable "threetier_RDS_SG" {
  description = "Value of the Name tag for the RDS SG"
  type        = string
  default     = "Mina RDS SG"
}

variable "threetier_Bastion_SG" {
  description = "Value of the Name tag for the Bastion SG"
  type        = string
  default     = "Mina Bastion SG"
}

variable "threetier_PublicEC2" {
  description = "Value of the Name tag for the Public EC2 Instance"
  type        = string
  default     = "Mina Public EC2"
}

variable "threetier_PrivateEC2" {
  description = "Value of the Name tag for the Private EC2 Instance"
  type        = string
  default     = "Mina Private EC2"
}

variable "threetier_RDS_Subnets" {
  description = "Value of the Name tag for the RDS Subnet Group"
  type        = string
  default     = "Mina RDS Subnets"
}

variable "threetier_RDS_Instance" {
  description = "Value of the Name tag for the RDS Instance"
  type        = string
  default     = "Mina RDS Instance"
}

variable "db_username" {
  description = "Username for the RDS instance"
  type        = string
}

variable "db_password" {
  description = "Password for the RDS instance"
  type        = string
  sensitive   = true
}

variable "threetier_Bastion_Instance" {
  description = "Value of the Name tag for the Bastion Instance"
  type        = string
  default     = "Mina Bastion Instance"
}

variable "threetier_NATEIP" {
  description = "Value of the Name tag for the NAT Elastic IP"
  type        = string
  default     = "Mina NAT Elastic IP"
}

variable "dbname" {
  description = "Value of the Name tag for the RDS DB"
  type        = string
  default     = "MinasDB"
}

variable "threetier_PublicASG_Instances" {
  description = "Value of the Name tag for the Public ASG instances"
  type        = string
  default     = "Mina PublicASGInstance"
}

variable "threetier_PrivateASG_Instances" {
  description = "Value of the Name tag for the Private ASG instances"
  type        = string
  default     = "Mina PrivateASGInstance"
}