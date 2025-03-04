# GitHub Actions Runner Controller (ARC) Terraform Module

This Terraform module deploys the GitHub Actions Runner Controller (ARC) on an existing Kubernetes cluster using Helm. ARC provides a Kubernetes-native way to host your own GitHub Actions runners, giving you more control over your CI/CD infrastructure.

## Features

- Deploy GitHub Actions Runner Controller via Helm chart
- Configure self-hosted runner deployments with custom settings
- Set up autoscaling for runners based on workflow load
- Customize resource requests and limits for runner pods
- Support for both organization-level and repository-level runners

## Prerequisites

- Terraform >= 1.0.0
- Kubernetes cluster (with kubectl access configured)
- Helm 3.x
- GitHub Personal Access Token (PAT) with appropriate permissions:
  - For organization runners: `admin:org` scope
  - For repository runners: `repo` scope

## Getting Started

1. Clone this repository:

```bash
git clone https://github.com/idvoretskyi/Terraform-ARC-cluster.git
cd Terraform-ARC-cluster
```

2. Create a `terraform.tfvars` file with your configuration:

```hcl
github_token = "ghp_your_github_token"

runner_deployments = [
  {
    name       = "my-org-runner"
    repository = "my-org"
    replicas   = 2
    labels     = ["self-hosted", "linux", "x64"]
    env = [
      {
        name  = "RUNNER_WORKDIR"
        value = "/home/runner/work"
      }
    ]
    resources = {
      limits = {
        cpu    = "1000m"
        memory = "2Gi"
      }
      requests = {
        cpu    = "500m"
        memory = "1Gi"
      }
    }
  }
]

runner_autoscalers = [
  {
    name              = "my-org-autoscaler"
    target_deployment = "my-org-runner"
    min_replicas      = 1
    max_replicas      = 5
    metrics = [
      {
        type                = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
        repositoryNames     = ["my-org/repo1", "my-org/repo2"]
        scaleUpThreshold    = "1"
        scaleDownThreshold  = "0"
        scaleUpFactor       = "2"
        scaleDownFactor     = "0.5"
      }
    ]
  }
]
```

3. Initialize, plan, and apply the Terraform configuration:

```bash
terraform init
terraform plan
terraform apply
```

## Configuration Options

### Required Variables

| Variable | Description |
|----------|-------------|
| `github_token` | GitHub Personal Access Token with appropriate permissions |

### Optional Variables

| Variable | Description | Default |
|----------|-------------|---------|
| `namespace` | Kubernetes namespace for ARC | `"arc-system"` |
| `create_namespace` | Whether to create a new namespace | `true` |
| `helm_chart_version` | Version of the ARC Helm chart | `"0.23.5"` |
| `helm_values` | Additional Helm values in YAML format | `""` |
| `runner_deployments` | List of runner deployment configurations | `[]` |
| `runner_autoscalers` | List of runner autoscaler configurations | `[]` |

## Runner Deployment Configuration

Each runner deployment can be configured with the following parameters:

```hcl
{
  name       = "deployment-name"           # Name of the runner deployment
  repository = "org-name/repo-name"        # GitHub org or repo
  replicas   = 2                           # Number of runner replicas
  labels     = ["self-hosted", "linux"]    # Runner labels
  env = [                                  # Environment variables
    {
      name  = "ENV_VAR_NAME"
      value = "env_var_value"
    }
  ]
  resources = {                            # Resource requirements
    limits = {
      cpu    = "1000m"
      memory = "2Gi"
    }
    requests = {
      cpu    = "500m"
      memory = "1Gi"
    }
  }
}
```

### Important Notes on Runner Configuration

- **Repository format**: 
  - For organization runners: use the organization name (e.g., `"my-organization"`)
  - For repository runners: use the full repo path (e.g., `"my-organization/my-repository"`)
  
- **Labels**: These labels are used in your GitHub Actions workflow files to target specific runners:
  ```yaml
  jobs:
    build:
      runs-on: self-hosted # or any other label you define
  ```

- **Environment Variables**: Common environment variables include:
  - `RUNNER_WORKDIR`: Directory where the runner will store job data
  - `ACTIONS_RUNNER_HOOK_JOB_STARTED`: Script to run when a job starts
  - `ACTIONS_RUNNER_HOOK_JOB_COMPLETED`: Script to run when a job completes

## Runner Autoscaler Configuration

Configure autoscaling for runner deployments with the following parameters:

```hcl
{
  name              = "autoscaler-name"    # Name of the autoscaler
  target_deployment = "deployment-name"    # Target runner deployment
  min_replicas      = 1                    # Minimum replicas
  max_replicas      = 5                    # Maximum replicas
  metrics = [                              # Metrics for scaling
    {
      type                = "TotalNumberOfQueuedAndInProgressWorkflowRuns"
      repositoryNames     = ["org/repo1", "org/repo2"]
      scaleUpThreshold    = "1"
      scaleDownThreshold  = "0"
      scaleUpFactor       = "2"
      scaleDownFactor     = "0.5"
    }
  ]
}
```

### Available Metrics Types

- `TotalNumberOfQueuedAndInProgressWorkflowRuns`: Scales based on total workflow runs in queue and in progress
- `PercentageRunnersBusy`: Scales based on the percentage of busy runners
- `NumberOfRunners`: Scales based on a fixed number of runners
- `TotalNumberOfQueuedAndInProgressJobRuns`: Scales based on job runs instead of workflow runs

## Usage Examples

### Organization-level Runners

```hcl
module "github_runners" {
  source = "path/to/module"

  github_token = "ghp_your_github_token"

  runner_deployments = [
    {
      name       = "org-runner"
      repository = "myorg"
      replicas   = 2
      labels     = ["self-hosted", "linux", "x64"]
      env = []
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    }
  ]
}
```

### Repository-level Runners with Autoscaling

```hcl
module "github_runners" {
  source = "path/to/module"

  github_token = "ghp_your_github_token"

  runner_deployments = [
    {
      name       = "repo-runner"
      repository = "myorg/myrepo"
      replicas   = 1
      labels     = ["self-hosted", "linux", "x64"]
      env = []
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    }
  ]

  runner_autoscalers = [
    {
      name              = "repo-autoscaler"
      target_deployment = "repo-runner"
      min_replicas      = 1
      max_replicas      = 10
      metrics = [
        {
          type               = "PercentageRunnersBusy"
          scaleUpThreshold   = "0.75"
          scaleDownThreshold = "0.25"
          scaleUpFactor      = "2"
          scaleDownFactor    = "0.5"
        }
      ]
    }
  ]
}
```

### Multiple Runner Deployments with Different Capabilities

```hcl
module "github_runners" {
  source = "path/to/module"

  github_token = "ghp_your_github_token"

  runner_deployments = [
    {
      name       = "linux-runner"
      repository = "myorg"
      replicas   = 2
      labels     = ["self-hosted", "linux", "x64"]
      env = []
      resources = {
        limits = {
          cpu    = "1000m"
          memory = "2Gi"
        }
        requests = {
          cpu    = "500m"
          memory = "1Gi"
        }
      }
    },
    {
      name       = "high-memory-runner"
      repository = "myorg"
      replicas   = 1
      labels     = ["self-hosted", "linux", "high-memory"]
      env = []
      resources = {
        limits = {
          cpu    = "2000m"
          memory = "8Gi"
        }
        requests = {
          cpu    = "1000m"
          memory = "4Gi"
        }
      }
    }
  ]
}
```

## Troubleshooting

### Common Issues

1. **Authentication Failures**
   - Verify your GitHub token has the correct permissions
   - Check the token is correctly set in the kubernetes_secret
   - Ensure the token has not expired

2. **Runners Not Registering**
   - Ensure network connectivity from your cluster to GitHub
   - Check runner pod logs with `kubectl logs -n arc-system <runner-pod-name>`
   - Verify the repository name is correct (organization name for org runners)

3. **Autoscaling Not Working**
   - Verify the target deployment name matches exactly
   - Check if metrics-server is installed in your cluster
   - Review the autoscaler logs
   - Make sure you're generating enough activity to trigger scaling

4. **"Failed to sync manifest" Errors**
   - Wait a few minutes after ARC installation before creating runners
   - Verify you're using the correct CRD versions

### Useful Commands

```bash
# Check ARC controller status
kubectl get pods -n arc-system

# Check runner deployments
kubectl get runnerdeployments -n arc-system

# Check autoscalers
kubectl get horizontalrunnerautoscalers -n arc-system

# Check runner pods
kubectl get pods -n arc-system -l actions-runner-controller/runner-deployment-name

# View logs for the controller
kubectl logs -n arc-system -l app=actions-runner-controller-controller

# View logs for a specific runner
kubectl logs -n arc-system <runner-pod-name>

# Describe runner deployment
kubectl describe runnerdeployment -n arc-system <deployment-name>

# Describe autoscaler
kubectl describe horizontalrunnerautoscaler -n arc-system <autoscaler-name>
```

## Architecture

GitHub Actions Runner Controller follows a Kubernetes operator pattern:

1. **Controller**: Manages the lifecycle of runner pods
2. **RunnerDeployment**: Custom resource defining a set of identical runners
3. **HorizontalRunnerAutoscaler**: Custom resource that manages scaling of runner deployments
4. **Runner Pods**: The actual GitHub Actions runners

The controller coordinates with GitHub's API to register/unregister runners and monitor workflow job queues for autoscaling.

## Security Considerations

- Store your GitHub token securely; consider using a vault solution in production
- Runner pods can access your cluster's resources; consider using namespaces and RBAC to restrict access
- If running in production, consider setting up network policies to restrict runner pod communications
- For handling secrets in workflows, consider integrating with a secret management solution

## Upgrade Instructions

To upgrade the Actions Runner Controller:

1. Update the `helm_chart_version` variable to the desired version
2. Run `terraform plan` and `terraform apply` to apply the changes
3. Monitor the controller logs during the upgrade process

## Additional Resources

- [Actions Runner Controller Documentation](https://github.com/actions/actions-runner-controller)
- [GitHub Actions Self-hosted Runners](https://docs.github.com/en/actions/hosting-your-own-runners)
- [GitHub Actions Workflow Syntax](https://docs.github.com/en/actions/using-workflows/workflow-syntax-for-github-actions)
- [Helm Chart Documentation](https://github.com/actions/actions-runner-controller/tree/master/charts/actions-runner-controller)

## License

This project is licensed under the MIT License - see the LICENSE file for details.

## Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
