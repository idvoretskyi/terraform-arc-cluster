# CodeQL Security Analysis Configuration

This directory contains the CodeQL configuration for comprehensive security analysis of the Terraform ARC Cluster project.

## Files Overview

### Configuration Files
- **`codeql-config.yml`** - Main CodeQL configuration with analysis settings
- **`packs/infrastructure-security/qlpack.yml`** - Custom query pack definition
- **`packs/infrastructure-security/infrastructure-security.qls`** - Query suite configuration

### Custom Security Queries
- **`queries/hardcoded-github-token.ql`** - Detects hardcoded GitHub tokens
- **`queries/unsafe-github-actions.ql`** - Identifies unsafe GitHub Actions patterns

## Security Analysis Coverage

### Languages Analyzed
- **JavaScript/TypeScript** - For YAML/JSON configurations, GitHub Actions
- **Python** - For any Python scripts (future-proofing)

### Security Categories
1. **Secrets Detection**
   - Hardcoded GitHub tokens
   - API keys and passwords
   - Credential leakage

2. **GitHub Actions Security**
   - Pull request target vulnerabilities
   - Code injection in workflows
   - Unsafe context usage

3. **Infrastructure Security**
   - Configuration vulnerabilities
   - Privilege escalation risks
   - Supply chain security

4. **General Security**
   - Command injection
   - Path traversal
   - Prototype pollution
   - XSS and injection flaws

## Query Packs Included

### Built-in Packs
- `codeql/javascript-queries:Security` - Standard JavaScript security queries
- `codeql/python-queries:Security` - Standard Python security queries

### Custom Packs
- `infrastructure-security` - Custom queries for DevOps/Infrastructure code

## Analysis Triggers

The CodeQL analysis runs:
- **On push** to main branch (when relevant files change)
- **On pull requests** to main branch (when relevant files change)
- **Weekly scheduled** (Tuesdays at 4:30 AM UTC)
- **Manual trigger** with language selection options

## File Patterns Analyzed

### Included
- `**/*.js`, `**/*.ts` - JavaScript/TypeScript files
- `**/*.py` - Python files
- `**/*.yml`, `**/*.yaml` - YAML configuration files
- `**/*.json` - JSON configuration files
- `.github/**` - GitHub configuration files
- `terraform/**` - Terraform configuration files

### Excluded
- `**/node_modules/**` - Dependencies
- `**/.terraform/**` - Terraform cache
- `**/build/**`, `**/dist/**` - Build artifacts
- `**/*.min.js`, `**/*.min.css` - Minified files

## Results and Reporting

- **GitHub Security Tab** - All findings are reported in the Security tab
- **SARIF Upload** - Results uploaded in SARIF format for integration
- **PR Comments** - Security findings commented on pull requests
- **Categorization** - Alerts categorized by severity (high/medium/low)

## Customization

To modify the analysis:

1. **Add new queries** - Place `.ql` files in `queries/` directory
2. **Modify query suites** - Edit `.qls` files to include/exclude queries
3. **Update configuration** - Modify `codeql-config.yml` for analysis settings
4. **Add languages** - Update workflow and config for additional languages

## Best Practices

1. **Regular Updates** - Keep CodeQL queries updated with latest security patterns
2. **False Positive Management** - Use alert suppression for confirmed false positives
3. **Custom Rules** - Add project-specific security rules as needed
4. **Integration** - Integrate with other security tools (tfsec, Trivy, etc.)

## Troubleshooting

- **Analysis Timeout** - Increase timeout in workflow if analysis takes too long
- **Memory Issues** - Adjust RAM limit in configuration
- **Query Errors** - Check query syntax and dependencies
- **Missing Results** - Verify file patterns and language detection

For more information, see the [CodeQL documentation](https://docs.github.com/en/code-security/code-scanning/automatically-scanning-your-code-for-vulnerabilities-and-errors).