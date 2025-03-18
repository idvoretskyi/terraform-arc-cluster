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

output "namespace" {
  description = "The Kubernetes namespace where ARC was deployed"
  value       = var.create_namespace ? kubernetes_namespace.arc_system[0].metadata[0].name : var.namespace
}

output "cert_manager_release_name" {
  description = "The name of the cert-manager Helm release"
  value       = helm_release.cert_manager.name
}

output "arc_release_name" {
  description = "The name of the Actions Runner Controller Helm release"
  value       = helm_release.actions_runner_controller.name
}

output "runner_deployments" {
  description = "The deployed runner deployments"
  value       = [for rd in kubernetes_manifest.runner_deployment : rd.manifest.metadata.name]
}

output "runner_autoscalers" {
  description = "The deployed runner autoscalers"
  value       = [for ra in kubernetes_manifest.runner_autoscaler : ra.manifest.metadata.name]
}
