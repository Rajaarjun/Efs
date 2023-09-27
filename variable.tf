variable "ami" {
  default ="ami-0703b5d7f7da98d1e"
}

variable "instance_type" {
  default = "t3.micro"
}

variable "key_name" {
  default = "New_Test_Key"
}

#variable "security_groups" {
#  default = "sg-0ff77f6ee5af75f76"
#}

variable "tags" {
  default = "web_server_1"
}

variable "tag" {
  default = "web_server_2"
}

variable "sg_name" {
  default = "new_sg_sep"
}

variable "sg_description"{
  default = "Allow New_SG_Sep"
}

variable "cidr" {
  default = "10.0.0.0/16"
}


variable "private_key" {
  type        = string
  description = "File path of private key."
  default     = "~/.ssh/id_rsa"
}
