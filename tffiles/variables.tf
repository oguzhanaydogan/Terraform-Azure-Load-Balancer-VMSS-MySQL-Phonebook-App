variable "prefix" {
  default = "phonebook"
}

# GitHub
variable "token_path" {
  default = "~/Downloads/Key/"
}

variable "token_filename" {
  default = "github_token.txt"
}

variable "repo_name" {
  description = "Should match with 'phonebook-app.py' line #13"
  default     = "terraform-lb-phonebook-app"
}

variable "repo_branch" {
  default = "main"
}

# Resource group
variable "location" {
  default = "eastus"
}

# MySQL Flexible Database
variable "db_server_name" {
  description = "Should be unique"
  default     = "oaydogan-phonebook-app"
}

variable "db_username" {
  description = "Should match with 'phonebook-app.py' line #20"
  default     = "phonebook"
}

variable "db_password" {
  description = "Should match with 'phonebook-app.py' line #21"
  default     = "Password1234"
}

# VMSS
variable "ssh_key_rg" {
  default = "ycetindil"
}

variable "ssh_key_name" {
  default = "oguzhankey"
}

variable "vmss_private_key_path" {
  default = "~/Downloads/Key/"
}

variable "vmss_username" {
  default = "clouduser"
}