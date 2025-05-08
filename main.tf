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

#############################
# Namespace Configuration
#############################
resource "kubernetes_namespace" "arc_system" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

#############################
# GitHub Authentication
#############################
locals {
  using_github_app = var.github_token == "" && var.github_app_auth != null
}

resource "kubernetes_secret" "github_token" {
  count = var.github_token != "" ? 1 : 0
  
  metadata {
    name      = "controller-manager"
    namespace = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
  }

  data = {
    github_token = var.github_token
  }

  type = "Opaque"
}

resource "kubernetes_secret" "github_app_auth" {
  count = local.using_github_app ? 1 : 0
  
  metadata {
    name      = "controller-manager-github-app"
    namespace = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
  }

  data = {
    github_app_id             = var.github_app_auth.app_id
    github_app_installation_id = var.github_app_auth.installation_id
    github_app_private_key    = var.github_app_auth.private_key
  }

  type = "Opaque"
}

#############################
# Cert Manager Installation
#############################
locals {
  # Only add tolerations if explicitly requested
  arch_toleration = var.add_arch_tolerations ? [
    {
      key      = "kubernetes.io/arch"
      operator = "Equal"
      value    = var.node_architecture
      effect   = "NoSchedule"
    }
  ] : []
}

# Note: cert-manager is no longer strictly required for ARC 0.11.0+
# But we include it as an option as it may be useful for other purposes
resource "helm_release" "cert_manager" {
  count      = var.install_cert_manager ? 1 : 0
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  version    = var.cert_manager_version
  namespace  = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace

  set {
    name  = "installCRDs"
    value = "true"
  }

  # Only add architecture tolerations if requested
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].key"
      value = "kubernetes.io/arch"
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].operator"
      value = "Equal"
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].value"
      value = var.node_architecture
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
    }
  }

  values = [var.cert_manager_values]

  depends_on = [kubernetes_namespace.arc_system]
}

#############################
# Actions Runner Controller
#############################
resource "helm_release" "actions_runner_controller" {
  name       = "gha-runner-scale-set-controller"
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set-controller"
  version    = var.helm_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace

  # GitHub authentication - either token or GitHub App
  dynamic "set" {
    for_each = var.github_token != "" ? [1] : []
    content {
      name  = "authSecret.github_token"
      value = var.github_token
    }
  }

  dynamic "set" {
    for_each = local.using_github_app ? [1] : []
    content {
      name  = "authSecret.create"
      value = "false"
    }
  }

  dynamic "set" {
    for_each = local.using_github_app ? [1] : []
    content {
      name  = "authSecret.name"
      value = kubernetes_secret.github_app_auth[0].metadata[0].name
    }
  }

  # Enable metrics
  set {
    name  = "metrics.enabled"
    value = "true"
  }
  
  # Configure metrics
  set {
    name  = "metrics.serviceMonitor.enabled"
    value = "true"
  }

  # Only add architecture tolerations if requested
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].key"
      value = "kubernetes.io/arch"
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].operator"
      value = "Equal"
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].value"
      value = var.node_architecture
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "tolerations[0].effect"
      value = "NoSchedule"
    }
  }

  values = [var.helm_values]

  # In ARC 0.11.0, cert-manager is no longer required as a prerequisite
  depends_on = var.install_cert_manager ? [helm_release.cert_manager[0], kubernetes_namespace.arc_system] : [kubernetes_namespace.arc_system]
}

#############################
# Runner Scale Sets
#############################
resource "helm_release" "runner_scale_set" {
  count      = length(var.runner_deployments)
  name       = var.runner_deployments[count.index].name
  repository = "oci://ghcr.io/actions/actions-runner-controller-charts"
  chart      = "gha-runner-scale-set"
  version    = var.helm_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace

  set {
    name  = "githubConfigUrl"
    value = "https://github.com/${var.runner_deployments[count.index].repository}"
  }

  # GitHub authentication - either token or GitHub App
  dynamic "set" {
    for_each = var.github_token != "" ? [1] : []
    content {
      name  = "githubConfigSecret.github_token"
      value = var.github_token
    }
  }
  
  dynamic "set" {
    for_each = local.using_github_app ? [1] : []
    content {
      name  = "githubConfigSecret.github_app_id"
      value = var.github_app_auth.app_id
    }
  }
  
  dynamic "set" {
    for_each = local.using_github_app ? [1] : []
    content {
      name  = "githubConfigSecret.github_app_installation_id"
      value = var.github_app_auth.installation_id
    }
  }
  
  dynamic "set" {
    for_each = local.using_github_app ? [1] : []
    content {
      name  = "githubConfigSecret.github_app_private_key"
      value = var.github_app_auth.private_key
    }
  }

  # Configure runner scaling settings
  set {
    name  = "maxRunners"
    value = local.max_runners_value
  }

  set {
    name  = "minRunners"
    value = try(local.runner_deployment_map[var.runner_deployments[count.index].name].min_replicas, 1)
  }

  # Enable metrics for listeners
  set {
    name  = "listenerMetrics.enabled"
    value = "true"
  }
  
  # Configure specific metrics to be collected (required in ARC 0.11.0)
  set {
    name  = "listenerMetrics.prometheusMetrics"
    value = "{gha_desired_runners: true, gha_idle_runners: true, gha_registered_runners: true, gha_job_execution_duration_seconds: true, gha_job_startup_duration_seconds: true}"
  }

  # Set runner labels
  set {
    name  = "labels"
    value = join(",", coalesce(var.runner_deployments[count.index].labels, ["self-hosted", "terraform-managed"]))
  }
  
  # Add runner resources if specified
  dynamic "set" {
    for_each = var.runner_deployments[count.index].resources != null ? [1] : []
    content {
      name  = "template.spec.containers[0].resources.limits.cpu"
      value = var.runner_deployments[count.index].resources.limits.cpu
    }
  }

  dynamic "set" {
    for_each = var.runner_deployments[count.index].resources != null ? [1] : []
    content {
      name  = "template.spec.containers[0].resources.limits.memory"
      value = var.runner_deployments[count.index].resources.limits.memory
    }
  }

  dynamic "set" {
    for_each = var.runner_deployments[count.index].resources != null ? [1] : []
    content {
      name  = "template.spec.containers[0].resources.requests.cpu"
      value = var.runner_deployments[count.index].resources.requests.cpu
    }
  }

  dynamic "set" {
    for_each = var.runner_deployments[count.index].resources != null ? [1] : []
    content {
      name  = "template.spec.containers[0].resources.requests.memory"
      value = var.runner_deployments[count.index].resources.requests.memory
    }
  }

  # Set environment variables
  dynamic "set" {
    for_each = var.runner_deployments[count.index].env != null ? var.runner_deployments[count.index].env : []
    content {
      name  = "template.spec.containers[0].env[${set.key}].name"
      value = set.value.name
    }
  }

  dynamic "set" {
    for_each = var.runner_deployments[count.index].env != null ? var.runner_deployments[count.index].env : []
    content {
      name  = "template.spec.containers[0].env[${set.key}].value"
      value = set.value.value
    }
  }

  # Add architecture tolerations if requested
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "template.spec.tolerations[0].key"
      value = "kubernetes.io/arch"
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "template.spec.tolerations[0].operator"
      value = "Equal"
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "template.spec.tolerations[0].value"
      value = var.node_architecture
    }
  }
  
  dynamic "set" {
    for_each = var.add_arch_tolerations ? [1] : []
    content {
      name  = "template.spec.tolerations[0].effect"
      value = "NoSchedule"
    }
  }

  depends_on = [helm_release.actions_runner_controller]
}
