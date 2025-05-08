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
  value       = var.install_cert_manager ? helm_release.cert_manager[0].name : null
}

output "arc_release_name" {
  description = "The name of the Actions Runner Controller Helm release"
  value       = helm_release.actions_runner_controller.name
}

output "runner_scale_sets" {
  description = "The deployed runner scale sets"
  value       = [for rss in helm_release.runner_scale_set : rss.name]
}
