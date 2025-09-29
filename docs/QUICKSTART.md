# Quickstart Guide: GitHub Actions Runner Controller (ARC)

Deploy GitHub Actions self-hosted runners on Kubernetes with ARC 0.12.1.

## Prerequisites

- Kubernetes cluster with `kubectl` configured
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) >= 1.0.0
- GitHub Personal Access Token

## Step 1: Get Your GitHub Token

1. Go to GitHub → Settings → Developer settings → [Personal access tokens](https://github.com/settings/tokens)
2. Generate new token with `repo` scope (for repository runners) or `admin:org` (for organization runners)
3. Copy the token - you'll need it for the next step

## Step 2: Quick Deploy

Create a new file `main.tf` and replace:
- `ghp_your_token_here` with your GitHub token
- `your-org/your-repo` with your repository

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

  github_token = "ghp_your_actual_token_here"

  runner_deployments = [
    {
      name       = "my-runners"
      repository = "my-org/my-repo"
      replicas   = 2
      labels     = ["self-hosted", "linux", "x64"]
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

Check your runners are running:

```bash
kubectl get pods -n arc-system
```

You should see:
- `arc-gha-rs-controller-*` (ARC controller)
- `my-runners-*-runner-*` (Your runners)
- `my-runners-*-listener` (GitHub webhook listener)

## Step 5: Test

Create a simple workflow in your repository:

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
  
  github_token = "ghp_your_token_here"
  
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

**Need more help?** Check the main [README.md](../README.md) for advanced configuration options.
