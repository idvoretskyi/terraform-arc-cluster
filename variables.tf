
variable "namespace" {
  description = "Kubernetes namespace for Actions Runner Controller"
  type        = string
  default     = "arc-system"
}

variable "create_namespace" {
  description = "Whether to create a new namespace for ARC"
  type        = bool
  default     = true
}

variable "github_token" {
  description = "GitHub Personal Access Token with appropriate permissions"
  type        = string
  sensitive   = true
}

variable "helm_chart_version" {
  description = "Version of the ARC Helm chart"
  type        = string
  default     = "0.23.5"
}

variable "helm_values" {
  description = "Additional Helm values for ARC chart (in YAML format)"
  type        = string
  default     = ""
}

variable "runner_deployments" {
  description = "List of runner deployment configurations"
  type = list(object({
    name       = string
    repository = string
    replicas   = number
    labels     = list(string)
    env = list(object({
      name  = string
      value = string
    }))
    resources = object({
      limits = object({
        cpu    = string
        memory = string
      })
      requests = object({
        cpu    = string
        memory = string
      })
    })
  }))
  default = []
}

variable "runner_autoscalers" {
  description = "List of runner autoscaler configurations"
  type = list(object({
    name              = string
    target_deployment = string
    min_replicas      = number
    max_replicas      = number
    metrics           = list(map(any))
  }))
  default = []
}
