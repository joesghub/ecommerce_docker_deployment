variable "dockerhub_username" {}
variable "dockerhub_password" {}
variable "aws_access_key" {}
variable "aws_secret_key" {}

variable "db_instance_class" {
  description = "The instance type of the RDS instance"
  default     = "db.t3.micro"
}

variable "db_name" {
  description = "The name of the database to create when the DB instance is created"
  type        = string
  default     = "ecommerce"
}

variable "db_username" {
  description = "Username for the master DB user"
  type        = string
  default     = "userdb"
}

variable "rds_db_pw" {
    description = "password for db user"
    type = string
    default = "abcd1234"
}
