# Copyright 2025 Ihor Dvoretskyi
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.

# Namespace configuration
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

# Authentication configuration
variable "github_token" {
  description = "GitHub Personal Access Token with appropriate permissions"
  type        = string
  sensitive   = true
}

# Helm chart configuration
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

variable "cert_manager_version" {
  description = "Version of cert-manager Helm chart"
  type        = string
  default     = "v1.12.0"
}

variable "cert_manager_values" {
  description = "Values for cert-manager Helm chart"
  type        = string
  default     = ""
}

# Node architecture configuration
variable "add_arch_tolerations" {
  description = "Whether to add architecture-specific tolerations to pods"
  type        = bool
  default     = false
}

variable "node_architecture" {
  description = "Node architecture (amd64 or arm64)"
  type        = string
  default     = "amd64"
  validation {
    condition     = contains(["amd64", "arm64"], var.node_architecture)
    error_message = "The node_architecture must be either amd64 or arm64."
  }
}

# Runner configuration
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

# Remove Kubernetes configuration variables as they should be set in the root module
