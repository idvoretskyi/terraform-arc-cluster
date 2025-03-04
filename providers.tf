
provider "kubernetes" {
  # Configuration options can be provided here or via environment variables/config files
  # config_path    = "~/.kube/config"
  # config_context = "my-context"
}

provider "helm" {
  kubernetes {
    # Configuration options can be provided here or via environment variables/config files
    # config_path    = "~/.kube/config"
    # config_context = "my-context"
  }
}
