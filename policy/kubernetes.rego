package main

import rego.v1

# Deny privileged containers
deny contains msg if {
  input.kind == "Deployment"
  container := input.spec.template.spec.containers[_]
  container.securityContext.privileged == true
  msg := sprintf("Container '%s' must not run as privileged", [container.name])
}

# Disallow hostNetwork
deny contains msg if {
  input.kind == "Deployment"
  input.spec.template.spec.hostNetwork == true
  msg := "Deployment must not use hostNetwork"
}

# Require resource limits
#deny contains msg if {
#  input.kind == "Deployment"
#  container := input.spec.template.spec.containers[_]
#  not container.resources.limits
#  msg := sprintf("Container '%s' must define resource limits", [container.name])
#}

# Deny latest image tag
#deny contains msg if {
#  input.kind == "Deployment"
#  container := input.spec.template.spec.containers[_]
#  endswith(container.image, ":latest")
#  msg := sprintf("Container '%s' must not use the ':latest' image tag", [container.name])
#}

# Require runAsNonRoot=true
#deny contains msg if {
#  input.kind == "Deployment"
#  container := input.spec.template.spec.containers[_]
#  not container.securityContext.runAsNonRoot
#  msg := sprintf("Container '%s' must set securityContext.runAsNonRoot = true", [container.name])
#}
