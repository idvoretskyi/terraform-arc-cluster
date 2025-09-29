# Security Policy

## Supported Versions

We currently support security updates for the following versions:

| Version | Supported          |
| ------- | ------------------ |
| main    | :white_check_mark: |
| latest  | :white_check_mark: |

## Reporting a Vulnerability

If you discover a security vulnerability in this Terraform module, please report it by:

1. **Email**: Send details to ihor@linux.com
2. **GitHub Security Advisories**: Use the [GitHub Security Advisory](https://github.com/idvoretskyi/terraform-arc-cluster/security/advisories) feature for sensitive reports

### What to Include

Please include as much of the following information as possible:

- Type of issue (e.g. buffer overflow, SQL injection, cross-site scripting, etc.)
- Full paths of source file(s) related to the manifestation of the issue
- The location of the affected source code (tag/branch/commit or direct URL)
- Any special configuration required to reproduce the issue
- Step-by-step instructions to reproduce the issue
- Proof-of-concept or exploit code (if possible)
- Impact of the issue, including how an attacker might exploit the issue

### Response Timeline

- **Initial response**: Within 48 hours of receipt
- **Detailed response**: Within 7 days, including assessment and timeline for fixes
- **Resolution**: Critical issues will be resolved within 30 days

### Disclosure Policy

- Security vulnerabilities will be disclosed publicly after a fix is available
- We request that you do not publicly disclose the issue until we have had a chance to address it
- We will acknowledge your responsible disclosure in our security advisories (unless you prefer to remain anonymous)

## Security Best Practices

When using this Terraform module:

1. **GitHub Tokens**: Store GitHub tokens in GitHub Secrets, never commit them to code
2. **Kubernetes Access**: Use appropriate RBAC and network policies
3. **Resource Limits**: Set appropriate resource limits for runners
4. **Updates**: Keep the module updated to the latest version
5. **Monitoring**: Monitor runner activities and resource usage

## Automated Security

This repository includes:

- **Dependabot**: Automatic dependency updates
- **CodeQL**: Static code analysis
- **Terraform Security**: tfsec, Trivy, and Checkov scanning
- **Dependency Review**: PR-based dependency vulnerability scanning

## Contact

For security-related questions or concerns, contact:
- **Maintainer**: Ihor Dvoretskyi
- **Email**: ihor@linux.com
- **GitHub**: [@idvoretskyi](https://github.com/idvoretskyi)