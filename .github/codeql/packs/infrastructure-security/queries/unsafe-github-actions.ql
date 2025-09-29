/**
 * @name Unsafe GitHub Actions Workflow
 * @description Detects potentially unsafe patterns in GitHub Actions workflows  
 * @kind problem
 * @problem.severity warning
 * @security-severity 7.0
 * @precision medium
 * @id yaml/unsafe-github-actions
 * @tags security
 *       github-actions
 *       ci/cd
 *       external/cwe/cwe-094
 */

import javascript

from StringLiteral expr
where 
  // Detect pull_request_target with checkout (potential code injection)
  (expr.getValue().matches("%pull_request_target%") and
   exists(StringLiteral checkout | checkout.getValue().matches("%checkout%"))) or
   
  // Detect usage of github.event.issue.title or similar (potential injection)
  expr.getValue().regexpMatch(".*\\$\\{\\{\\s*github\\.event\\.(issue|pull_request)\\.(title|body|head\\.label).*\\}\\}.*") or
  
  // Detect usage of steps context in run commands (potential injection)
  expr.getValue().regexpMatch(".*\\$\\{\\{\\s*steps\\.[^}]+\\}\\}.*") or
  
  // Detect hardcoded secrets in workflow files
  (expr.getFile().getBaseName().matches("%.yml") or expr.getFile().getBaseName().matches("%.yaml")) and
  (expr.getValue().regexpMatch(".*[Pp]assword.*:.*['\"][^'\"]{8,}['\"].*") or
   expr.getValue().regexpMatch(".*[Tt]oken.*:.*['\"][^'\"]{20,}['\"].*") or
   expr.getValue().regexpMatch(".*[Kk]ey.*:.*['\"][^'\"]{20,}['\"].*"))

select expr, "Potentially unsafe GitHub Actions workflow pattern detected."