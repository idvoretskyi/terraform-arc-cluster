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
resource "kubernetes_secret" "github_token" {
  metadata {
    name      = "controller-manager"
    namespace = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
  }

  data = {
    github_token = var.github_token
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

resource "helm_release" "cert_manager" {
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
  name       = "actions-runner-controller"
  repository = "https://actions-runner-controller.github.io/actions-runner-controller"
  chart      = "actions-runner-controller"
  version    = var.helm_chart_version
  namespace  = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace

  set {
    name  = "authSecret.create"
    value = "false"
  }

  set {
    name  = "authSecret.name"
    value = kubernetes_secret.github_token.metadata[0].name
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

  depends_on = [kubernetes_secret.github_token, helm_release.cert_manager]
}

#############################
# Runner Deployments
#############################
resource "kubernetes_manifest" "runner_deployment" {
  count = length(var.runner_deployments)
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "RunnerDeployment"
    metadata = {
      name      = var.runner_deployments[count.index].name
      namespace = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
    }
    spec = {
      replicas = var.runner_deployments[count.index].replicas
      template = {
        spec = merge(
          {
            repository = var.runner_deployments[count.index].repository
            labels     = var.runner_deployments[count.index].labels
            env        = var.runner_deployments[count.index].env
            resources  = var.runner_deployments[count.index].resources
          },
          var.add_arch_tolerations ? { tolerations = local.arch_toleration } : {}
        )
      }
    }
  }

  depends_on = [helm_release.actions_runner_controller]
}

#############################
# Runner Autoscalers
#############################
resource "kubernetes_manifest" "runner_autoscaler" {
  count = length(var.runner_autoscalers)
  manifest = {
    apiVersion = "actions.summerwind.dev/v1alpha1"
    kind       = "HorizontalRunnerAutoscaler"
    metadata = {
      name      = var.runner_autoscalers[count.index].name
      namespace = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
    }
    spec = {
      scaleTargetRef = {
        name = var.runner_autoscalers[count.index].target_deployment
      }
      minReplicas = var.runner_autoscalers[count.index].min_replicas
      maxReplicas = var.runner_autoscalers[count.index].max_replicas
      metrics     = var.runner_autoscalers[count.index].metrics
    }
  }

  depends_on = [kubernetes_manifest.runner_deployment]
}
