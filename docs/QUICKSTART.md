# Quickstart Guide: GitHub Actions Runner Controller (ARC)

This guide will walk you through the process of setting up GitHub Actions Runner Controller (ARC) on your Kubernetes cluster using this Terraform module.

## Prerequisites

Before you begin, ensure you have the following:

- A Kubernetes cluster (local like Minikube/k3s or cloud-based)
- [kubectl](https://kubernetes.io/docs/tasks/tools/install-kubectl/) installed and configured
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli) (v1.0.0 or newer)
- [Helm](https://helm.sh/docs/intro/install/) (v3.0.0 or newer)
- A GitHub account with permissions to create Personal Access Tokens

## Step 1: Set Up Your GitHub Token

1. Go to GitHub → Settings → Developer settings → [Personal access tokens](https://github.com/settings/tokens)
2. Click "Generate new token"
3. Give it a name like "ARC Token"
4. Select the following scopes:
   - For repository runners: `repo` (Full control)
   - For organization runners: `admin:org` (Organization administration)
5. Click "Generate token"
6. **Copy your token immediately** - you won't be able to see it again!

## Step 2: Prepare Your Terraform Configuration

Create a new directory for your Terraform configuration:

```bash
mkdir arc-deployment
cd arc-deployment
```

Create a file named `main.tf` with the following content:

```hcl
provider "kubernetes" {
  config_path    = "~/.kube/config"  # Path to your kubeconfig file
  # If you're using a specific context, uncomment this:
  # config_context = "my-context-name"
}

provider "helm" {
  kubernetes {
    config_path    = "~/.kube/config"
    # config_context = "my-context-name"
  }
}

module "arc" {
  source = "github.com/idvoretskyi/Terraform-ARC-cluster"
  
  github_token = "ghp_your_token_here"  # Replace with your actual token
  
  # Optional: Change namespace
  namespace       = "arc-system"
  create_namespace = true
  
  # Optional: Set chart versions
  helm_chart_version  = "0.23.5"
  cert_manager_version = "v1.12.0"
}
```

## Step 3: Initialize and Apply Terraform

Initialize Terraform to download the module:

```bash
terraform init
```

Apply the configuration:

```bash
terraform apply
```

Review the changes and type `yes` to confirm.

## Step 4: Verify the Installation

Check that all the components are running:

```bash
kubectl get pods -n arc-system
```

You should see pods for:
- cert-manager (3 pods)
- actions-runner-controller (at least 1 pod)

## Step 5: Deploy Your First Runner

Create a new file named `runners.tf` with the following content:

```hcl
# Update your module block in main.tf to include this configuration
module "arc" {
  # ...existing configuration...
  
  runner_deployments = [
    {
      name       = "example-runner"
      repository = "your-username/your-repo"  # Change to your repo
      replicas   = 1
      labels     = ["self-hosted", "linux", "x64"]
      env = [
        {
          name  = "RUNNER_WORKDIR"
          value = "/home/runner/work"
        }
      ]
      resources = {
        limits = {
          cpu    = "500m"
          memory = "512Mi"
        }
        requests = {
          cpu    = "250m"
          memory = "256Mi"
        }
      }
    }
  ]
}
```

Apply the updated configuration:

```bash
terraform apply
```

## Step 6: Test Your Runner

1. Go to your GitHub repository settings → Actions → Runners
2. You should see your new runner listed
3. Create a basic workflow in your repository:

```yaml
# .github/workflows/test-runner.yml
name: Test Self-Hosted Runner

on:
  workflow_dispatch:  # Manual trigger

jobs:
  test:
    runs-on: self-hosted  # This will use your self-hosted runner
    
    steps:
      - name: Check out code
        uses: actions/checkout@v3
        
      - name: Run test commands
        run: |
          echo "Hello from self-hosted runner!"
          hostname
          pwd
          ls -la
```

4. Go to Actions tab in your repository and manually trigger the workflow
5. Watch your workflow run on your self-hosted runner!

## Step 7: Set Up Autoscaling (Optional)

Update your configuration to include an autoscaler:

```hcl
module "arc" {
  # ...existing configuration...
  
  runner_deployments = [
    {
      name       = "example-runner"
      repository = "your-username/your-repo"  # Change to your repo
      replicas   = 1  # Base number of replicas
      # ...other settings...
    }
  ]
  
  runner_autoscalers = [
    {
      name              = "example-autoscaler"
      target_deployment = "example-runner"
      min_replicas      = 1
      max_replicas      = 5
      metrics = [
        {
          type = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
          repositoryNames = ["your-username/your-repo"]  # Change to your repo
          scaleUpThreshold = "1"
          scaleDownThreshold = "0"
          scaleUpFactor = "2"
          scaleDownFactor = "0.5"
        }
      ]
    }
  ]
}
```

## Common Issues and Troubleshooting

### Runners Not Connecting to GitHub

If your runners are not showing up in GitHub:
1. Check the runner pod logs:
   ```bash
   kubectl logs -n arc-system -l actions-runner=example-runner
   ```
2. Verify your token has the correct permissions
3. Ensure the repository path is correct

### Pod Scheduling Issues

If pods are not being scheduled:
```bash
kubectl get pods -n arc-system
kubectl describe pod -n arc-system <pod-name>
```

Look for events that indicate why scheduling failed.

### Certificate Manager Issues

If you see certificate-related errors:
```bash
kubectl get pods -n arc-system -l app=cert-manager
kubectl logs -n arc-system -l app=cert-manager
```

## Advanced Configuration

### Using Organization-Level Runners

To deploy runners at the organization level:

```hcl
runner_deployments = [
  {
    name       = "org-runner"
    repository = "your-org"  # Just specify the org name
    replicas   = 2
    # ...other settings...
  }
]
```

### Adding Environment Variables

You can add environment variables to customize your runners:

```hcl
env = [
  {
    name  = "RUNNER_WORKDIR"
    value = "/home/runner/work"
  },
  {
    name  = "ACTIONS_RUNNER_HOOK_JOB_STARTED"
    value = "/home/runner/my-script.sh"
  }
]
```

### Architecture-Specific Configurations

For ARM64-based clusters (e.g., Apple Silicon):

```hcl
module "arc" {
  # ...existing configuration...
  
  add_arch_tolerations = true
  node_architecture    = "arm64"
}
```

## Next Steps

- Look at the [official ARC documentation](https://github.com/actions/actions-runner-controller) for advanced settings
- Configure your CI/CD workflows to use the self-hosted runners
- Monitor your runner performance and adjust resources as needed

## Further Reading

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Terraform Documentation](https://www.terraform.io/docs)
- [Kubernetes Documentation](https://kubernetes.io/docs/)
