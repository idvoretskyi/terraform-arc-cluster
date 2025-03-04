
resource "kubernetes_namespace" "arc_system" {
  count = var.create_namespace ? 1 : 0

  metadata {
    name = var.namespace
    labels = {
      "app.kubernetes.io/managed-by" = "terraform"
    }
  }
}

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

  values = var.helm_values

  depends_on = [kubernetes_secret.github_token]
}

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
        spec = {
          repository = var.runner_deployments[count.index].repository
          labels     = var.runner_deployments[count.index].labels
          env        = var.runner_deployments[count.index].env
          resources  = var.runner_deployments[count.index].resources
        }
      }
    }
  }

  depends_on = [helm_release.actions_runner_controller]
}

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
