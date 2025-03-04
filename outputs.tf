
output "arc_namespace" {
  description = "Namespace where ARC is deployed"
  value       = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
}

output "helm_release_status" {
  description = "Status of the Helm release"
  value       = helm_release.actions_runner_controller.status
}

output "runner_deployments" {
  description = "List of runner deployment names"
  value       = [for rd in kubernetes_manifest.runner_deployment : rd.manifest.metadata.name]
}

output "runner_autoscalers" {
  description = "List of runner autoscaler names"
  value       = [for ra in kubernetes_manifest.runner_autoscaler : ra.manifest.metadata.name]
}
