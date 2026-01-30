variable "GOOGLE_PROJECT" {
  type        = string
  description = "GCP project name"
}

variable "GOOGLE_REGION" {
  type        = string
  description = "GCP region to use"
}

variable "GKE_MACHINE_TYPE" {
  type        = string
  default     = "g1-small"
  description = "Machine type for nodes"
}

variable "GKE_NUM_NODES" {
  type        = number
  default     = 2
  description = "Number of nodes in the pool"
}

variable "GKE_DISK_TYPE" {
  type        = string
  default     = "pd-standard"
  description = "Boot disk type: pd-standard (HDD, no SSD quota) or pd-balanced/pd-ssd (SSD)"
}

variable "GKE_DISK_SIZE_GB" {
  type        = number
  default     = 30
  description = "Boot disk size in GB per node"
}

variable "GKE_CLUSTER_NAME" {
  type        = string
  default     = "main"
  description = "GKE cluster name"
}

variable "GKE_POOL_NAME" {
  type        = string
  default     = "main"
  description = "GKE node pool name"
}
