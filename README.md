# GitHub Actions Runner Controller (ARC) Terraform Module

Deploy self-hosted GitHub Actions runners on Kubernetes using the latest Actions Runner Controller (ARC).

## Features

- **Latest ARC** with autoscaling runner scale sets
- **Multi-architecture support** (amd64/arm64) 
- **Simple configuration** with sensible defaults
- **Production ready** with proper resource management

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

## Examples

### Basic Configuration
```hcl
module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_token = var.github_token

  runner_deployments = [
    {
      name       = "default-runners"
      repository = "my-org/my-repo"
      replicas   = 2
      labels     = ["self-hosted", "linux", "x64"]
    }
  ]
}
```

### ARM64 Cluster Support
```hcl
module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_token = var.github_token
  
  # ARM64 cluster configuration
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
        limits = {
          cpu    = "2000m"
          memory = "4Gi"
        }
        requests = {
          cpu    = "1000m"
          memory = "2Gi"
        }
      }

      env = [
        {
          name  = "RUNNER_WORKDIR"
          value = "/home/runner/work"
        }
      ]
    }
  ]
}
```

## Repository Structure

```
terraform-arc-cluster/
├── terraform/          # Main Terraform module
│   ├── main.tf         # Core resources
│   ├── variables.tf    # Input variables
│   ├── outputs.tf      # Output values
│   └── versions.tf     # Provider requirements
├── docs/               # Documentation
│   └── QUICKSTART.md
└── README.md          # This file
```

## Requirements

| Tool | Version |
|------|---------|
| Terraform | >= 1.0.0 |
| Kubernetes Provider | >= 2.30.0 |
| Helm Provider | >= 3.0.0 |

> **Note:** This module defaults to the latest stable ARC version. Check [ARC Releases](https://github.com/actions/actions-runner-controller/releases) for newer versions.

## Input Variables

| Name | Description | Type | Default |
|------|-------------|------|---------|
| **github_token** | GitHub Personal Access Token | `string` | `""` |
| **runner_deployments** | Runner configurations | `list(object)` | `[]` |
| namespace | Kubernetes namespace | `string` | `"arc-system"` |
| create_namespace | Create namespace if it doesn't exist | `bool` | `true` |
| helm_chart_version | ARC chart version (defaults to latest stable) | `string` | `"0.12.1"` |
| add_arch_tolerations | Add architecture-specific tolerations | `bool` | `false` |
| node_architecture | Node architecture (amd64/arm64) | `string` | `"amd64"` |

## Outputs

| Name | Description |
|------|-------------|
| namespace | Deployed namespace |
| arc_release_name | ARC Helm release name |
| runner_scale_sets | List of deployed runner scale sets |

## Getting Started

1. **Check the quickstart guide:**
   ```bash
   # View online: https://github.com/idvoretskyi/terraform-arc-cluster/blob/main/docs/QUICKSTART.md
   ```

2. **Use the module directly:**
   ```hcl
   module "arc" {
     source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"
     
     github_token = "ghp_your_token_here"
     
     runner_deployments = [
       {
         name       = "my-runners"
         repository = "your-org/your-repo"
       }
     ]
   }
   ```

## License

Apache License 2.0 - see [LICENSE](LICENSE)

## Author

**Ihor Dvoretskyi** - DevOps Engineer