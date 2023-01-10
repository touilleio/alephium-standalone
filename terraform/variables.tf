
variable "environment" {
  type = string
  default = "alephium-standalone"
}

variable "vpc_cidr" {
  type = string
  default = "10.200.100.0/24"
}

variable "extra_tags" {
  description = "Additional tags to add to the instance(s) and volume(s)"
  default     = {}
  type        = map(string)
}

variable "instance_count" {
  type = number
}

variable "instance_type" {
  description = "Instance type"
  type        = string
  default     = "t3.medium"
}

variable "alephium_image" {
  description = "Docker image to use, for instance alephium/alephium:v1.5.5"
  type        = string
  default = "touilleio/alephium-standalone:latest"
}

variable "network_id" {
  description = "Network id"
  type        = number
  default     = 0
}

variable "ebs_block_device_size" {
  description = "Size of the data device to attach to the instance"
  type = number
  default = 60
}

variable "ebs_block_device_type" {
  description = "Device type of the data drive"
  type        = string
  default     = "gp3"
}

variable "offset_shift" {
  description = "Instance names have an offset appended to the name prefix, starting at 0 + this offset shift"
  type        = number
  default     = 0
}