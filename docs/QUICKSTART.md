# Quickstart Guide

Deploy GitHub Actions self-hosted runners on Kubernetes with the Actions Runner Controller (ARC).

## Prerequisites

- Kubernetes cluster with `kubectl` configured
- [Terraform](https://developer.hashicorp.com/terraform/install) >= 1.6.0
- GitHub Personal Access Token with `repo` scope (for repository runners) or `admin:org` (for org runners)

## Step 1: Get Your GitHub Token

1. Go to GitHub → Settings → Developer settings → [Personal access tokens](https://github.com/settings/tokens)
2. Generate a new token with the appropriate scope
3. Keep the token handy for the next step

## Step 2: Create Your Configuration

Create `main.tf` and replace the placeholder values with your token and repository:

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

  github_token = "ghp_your_token_here"

  runner_deployments = [
    {
      name       = "my-runners"
      repository = "my-org/my-repo"
    }
  ]
}
```

## Step 3: Deploy

```bash
terraform init
terraform apply
```

## Step 4: Verify

```bash
kubectl get pods -n arc-system
```

You should see:

- `arc-gha-rs-controller-*` — ARC controller
- `my-runners-*-runner-*` — your runners
- `my-runners-*-listener` — GitHub webhook listener

## Step 5: Test

Add this workflow to your repository to confirm runners are working:

```yaml
# .github/workflows/test.yml
name: Test Self-Hosted Runner
on: workflow_dispatch

jobs:
  test:
    runs-on: self-hosted
    steps:
      - run: echo "Hello from self-hosted runner!"
```

## ARM64 Support

For ARM64 clusters (Apple Silicon, AWS Graviton, etc.):

```hcl
module "arc" {
  source = "github.com/idvoretskyi/terraform-arc-cluster//terraform"

  github_token         = "ghp_your_token_here"
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

## Troubleshooting

**Runners not appearing in GitHub?**

```bash
# Check controller logs
kubectl logs -n arc-system -l app.kubernetes.io/name=gha-runner-scale-set-controller

# Check runner logs
kubectl logs -n arc-system -l actions.github.com/scale-set-name=my-runners
```

For more configuration options, see the [README](../README.md).
