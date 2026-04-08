# GitHub Actions Runner Controller (ARC) Terraform Module

Deploy self-hosted GitHub Actions runners on Kubernetes using the Actions Runner Controller (ARC).

## Features

- Autoscaling runner scale sets via the latest ARC Helm charts
- Multi-architecture support (amd64 / arm64)
- GitHub PAT and GitHub App authentication
- Simple configuration with sensible defaults

## Quick Start

```hcl
provider "kubernetes" {
  config_path = "~/.kube/config"
}

provider "helm" {
  kubernetes = {
    config_path = "~/.kube/config"
  }
}

module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_token = "ghp_your_personal_access_token"

  runner_deployments = [
    {
      name       = "my-runners"
      repository = "your-org/your-repo"
    }
  ]
}
```

Then deploy:

```bash
terraform init
terraform apply
```

See the [Quickstart Guide](docs/QUICKSTART.md) for step-by-step instructions including verification and testing.

## Examples

### ARM64 Cluster

```hcl
module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_token         = var.github_token
  add_arch_tolerations = true
  node_architecture    = "arm64"

  runner_deployments = [
    {
      name       = "arm64-runners"
      repository = "my-org/my-repo"
      labels     = ["self-hosted", "linux", "arm64"]
    }
  ]
}
```

### Production Setup

```hcl
module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_token = var.github_token
  namespace    = "github-runners"

  runner_deployments = [
    {
      name       = "production-runners"
      repository = "my-org/my-repo"
      replicas   = 10
      labels     = ["self-hosted", "linux", "x64", "production"]

      resources = {
        limits   = { cpu = "2000m", memory = "4Gi" }
        requests = { cpu = "1000m", memory = "2Gi" }
      }

      env = [
        { name = "RUNNER_WORKDIR", value = "/home/runner/work" }
      ]
    }
  ]
}
```

### GitHub App Authentication

```hcl
module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_app_auth = {
    app_id          = "123456"
    installation_id = "78901234"
    private_key     = file("path/to/private-key.pem")
  }

  runner_deployments = [
    {
      name       = "my-runners"
      repository = "my-org/my-repo"
    }
  ]
}
```

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.6.0 |
| Kubernetes Provider | >= 2.30.0 |
| Helm Provider | >= 3.0.0 |

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| `github_token` | GitHub Personal Access Token | `string` | `""` |
| `github_app_auth` | GitHub App auth (app_id, installation_id, private_key) | `object` | `null` |
| `runner_deployments` | List of runner configurations | `list(object)` | `[]` |
| `namespace` | Kubernetes namespace | `string` | `"arc-system"` |
| `create_namespace` | Create the namespace if it doesn't exist | `bool` | `true` |
| `helm_chart_version` | ARC Helm chart version | `string` | `"0.12.1"` |
| `add_arch_tolerations` | Add architecture-specific tolerations | `bool` | `false` |
| `node_architecture` | Node architecture (`amd64` or `arm64`) | `string` | `"amd64"` |

## Outputs

| Name | Description |
|------|-------------|
| `namespace` | Deployed namespace |
| `arc_release_name` | ARC Helm release name |
| `runner_scale_sets` | List of deployed runner scale set names |

## Repository Structure

```
terraform-arc-cluster/
├── terraform/          # Terraform module
│   ├── main.tf         # Core resources
│   ├── variables.tf    # Input variables
│   ├── outputs.tf      # Output values
│   └── versions.tf     # Provider requirements
├── docs/
│   └── QUICKSTART.md   # Step-by-step guide
└── README.md
```

## License

Apache License 2.0 — see [LICENSE](LICENSE)
