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

# Validation: Ensure at least one authentication method is provided
locals {
  has_github_token = var.github_token != ""
  has_github_app   = var.github_app_auth != null
}

# This check will cause Terraform plan to fail if no authentication is provided
check "authentication_required" {
  assert {
    condition     = local.has_github_token || local.has_github_app
    error_message = "Authentication error: Either 'github_token' or 'github_app_auth' must be provided. Configure one of these authentication methods before applying."
  }
}

locals {
  namespace_name = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
}

# Namespace
resource "kubernetes_namespace" "arc_system" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
      "app.kubernetes.io/name"       = "actions-runner-controller"
    }
  }
}

# Actions Runner Controller
resource "helm_release" "actions_runner_controller" {
  name       = "arc"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.helm_chart_version
  namespace  = local.namespace_name

  # Core configuration via values
  values = [
    yamlencode({
      tolerations = var.add_arch_tolerations ? [
        {
          key      = "kubernetes.io/arch"
          operator = "Equal"
          value    = var.node_architecture
          effect   = "NoSchedule"
        }
      ] : []
    })
  ]

  depends_on = [kubernetes_namespace.arc_system]
}

# Runner Scale Sets
resource "helm_release" "runner_scale_set" {
  count = length(var.runner_deployments)

  name       = var.runner_deployments[count.index].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.helm_chart_version
  namespace  = local.namespace_name

  values = [
    yamlencode({
      githubConfigUrl = "https://github.com/${var.runner_deployments[count.index].repository}"
      maxRunners      = var.runner_deployments[count.index].replicas != null ? var.runner_deployments[count.index].replicas : 10
      minRunners      = 1

      githubConfigSecret = merge(
        var.github_token != "" ? {
          github_token = var.github_token
        } : {},
        var.github_app_auth != null ? {
          github_app_id              = var.github_app_auth.app_id
          github_app_installation_id = var.github_app_auth.installation_id
          github_app_private_key     = var.github_app_auth.private_key
        } : {}
      )

      runnerLabels = var.runner_deployments[count.index].labels != null ? var.runner_deployments[count.index].labels : ["self-hosted", "terraform-managed"]

      template = {
        spec = {
          tolerations = var.add_arch_tolerations ? [
            {
              key      = "kubernetes.io/arch"
              operator = "Equal"
              value    = var.node_architecture
              effect   = "NoSchedule"
            }
          ] : []
        }
      }
    })
  ]

  depends_on = [helm_release.actions_runner_controller]
}