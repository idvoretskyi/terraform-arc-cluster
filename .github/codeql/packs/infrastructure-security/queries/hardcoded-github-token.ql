/**
 * @name Hardcoded GitHub Token
 * @description Detects potential hardcoded GitHub tokens in source code
 * @kind problem
 * @problem.severity warning
 * @security-severity 8.5
 * @precision medium
 * @id js/hardcoded-github-token
 * @tags security
 *       external/cwe/cwe-798
 *       github-token
 *       secrets
 */

import javascript

from StringLiteral token
where 
  // GitHub personal access token pattern (classic)
  token.getValue().regexpMatch("ghp_[A-Za-z0-9]{36}") or
  // GitHub app token pattern  
  token.getValue().regexpMatch("ghs_[A-Za-z0-9]{36}") or
  // GitHub app installation token pattern
  token.getValue().regexpMatch("ghr_[A-Za-z0-9]{36}") or
  // GitHub refresh token pattern
  token.getValue().regexpMatch("gho_[A-Za-z0-9]{36}") or
  // Generic GitHub token patterns
  (token.getValue().toLowerCase().matches("%github%") and 
   token.getValue().regexpMatch("[A-Za-z0-9]{40}")) or
  // Variable names suggesting GitHub tokens
  (exists(Variable v | 
    v.getName().toLowerCase().matches("%github%token%") or
    v.getName().toLowerCase().matches("%gh%token%") or
    v.getName().toLowerCase().matches("%github%key%")
   ) and token.getValue().length() > 20)

select token, "Potential hardcoded GitHub token detected. Use environment variables or secrets management instead."