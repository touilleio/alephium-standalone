
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
  default     = "c5n.large"
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
  description = "Size of the data device to attach to the instance. Recommanded value is 40 if node_snapshot_type is pruned, 150 if node_snapshot_type is full"
  type = number
  default = 40
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

variable "ingress_cidr" {
  description = "Ingress range, for instance 1.2.3.4/32 or 0.0.0.0/0 to allow to ssh into the instance. If empty value, https://myip.touille.io is used to detect the public ip of the caller. Could be set via TF_VAR_ingress_cidr environment variable."
  type = string
  default = ""
}

variable "node_snapshot_type" {
  description = "Snapshot type to load, either pruned (default) or full. Could be set via TF_VAR_node_snapshot_type environment variable."
  type = string
  default = "pruned"
}
