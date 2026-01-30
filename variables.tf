variable "GOOGLE_REGION" {
  description = "GCP region for the GKE cluster (e.g. europe-central2)"
  type        = string
  default     = "us-central1"
}

variable "GOOGLE_PROJECT" {
  description = "GCP project ID: silicon-amulet-485722-g6"
  type        = string
}

variable "GKE_NUM_NODES" {
  description = "Number of nodes in the GKE cluster node pool"
  type        = number
  default     = 2
}

variable "GKE_MACHINE_TYPE" {
  description = "Machine type for GKE nodes (e.g. g1-small, e2-small)"
  type        = string
  default     = "g1-small"
}

variable "GKE_DISK_TYPE" {
  description = "Boot disk type: pd-standard (HDD, avoids SSD quota) or pd-balanced/pd-ssd"
  type        = string
  default     = "pd-standard"
}

variable "GKE_DISK_SIZE_GB" {
  description = "Boot disk size in GB per node"
  type        = number
  default     = 30
}
