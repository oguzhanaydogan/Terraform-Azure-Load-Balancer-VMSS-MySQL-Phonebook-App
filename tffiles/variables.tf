# Define variables for the configuration
variable "subscription_id" {
default = "67882e92-6412-4fc5-b9ca-1030aa09d729"
}

variable "resource_group_name" {
default = "phonebook-resource-group"
}

variable "vm_instances" {
default = [
"10.0.1.4",
"10.0.1.5",
]
}

variable "vm_scale_set_name" {
default = "phonebook-vm-scale-set"
}