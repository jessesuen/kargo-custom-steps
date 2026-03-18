# Kargo Custom Promotion Steps

## Overview

Custom Promotion Steps allow Kargo administrators to easily introduce new promotion steps to Kargo.

## Why custom steps?

While a majority of GitOps promotion workflows can be built entirely using Kargo's built-in, native steps, occasionally these may not be enough. Some use cases include:
* deployments using bespoke, custom tools or scripts
* interfacing with internal systems
* adding support for additional CLI-based tools not officially supported by Kargo

## How it works

To define a new promotion step, it is as simple as registering a `CustomPromotionStep` resource which specifies:
* the container `image` to run
* the `command` to be executed in the container
* how any inputs should be supplied to the command or environment variables

```yaml
apiVersion: ee.kargo.akuity.io/v1alpha1
kind: CustomPromotionStep
metadata:
  name: sleep
spec:
  image: ubuntu
  command: ["sh", "-c", "sleep ${{ config.sleepSeconds }}"]
  env:
  - name: HELLO
    value: ${{ config.sleep }}

```

Once registered, the step can be used like any other kargo step.

```yaml
steps:
- uses: sleep
  config:
    sleepSeconds: 10
```

NOTE: This feature requires the use of pod-based promotions, only available in the Akuity Platform.

## Examples

This repo showcases two real-world examples of custom promotion steps:

* `conftest` - validate Kubernetes manifests using centrally managed OPA rules, before proceeding with promotion.
* `trivy-image` - scan the promoted image for vulnerabilities, before proceeding with promotion.

### Conftest

Conftest is an open-source tool for writing and enforcing policy-as-code tests against structured configuration files (Kubernetes manifests, Dockerfiles, Terraform, etc.) using the Rego policy language.

This example shows how `conftest` can be used to validate Kubernetes deployment YAML against centrally managed rules.

```yaml
apiVersion: ee.kargo.akuity.io/v1alpha1
kind: CustomPromotionStep
metadata:
  name: conftest
spec:
  image: openpolicyagent/conftest:v0.67.0
  command:
  - conftest
  - test
  - --no-color
  - --update=https://raw.githubusercontent.com/jessesuen/kargo-custom-steps/master/policy/kubernetes.rego
  - --policy=/tmp/policy
  - ${{ config.path }}
```

### Trivy

Trivy is an open-source, all-in-one security scanner that detects vulnerabilities, misconfigurations, secrets, and license issues across container images, filesystems, Git repositories, and cloud infrastructure.

The following example shows how a `trivy-image` step can scan an image for `CRITICAL` vulnerabilities before proceeding with the promotion.

> **Note:** The custom image `ghcr.io/jessesuen/trivy` pre-caches the vulnerability databases to avoid downloading them on every promotion run. See [`docker/trivy/README.md`](docker/trivy/README.md) for details.

```yaml
apiVersion: ee.kargo.akuity.io/v1alpha1
kind: CustomPromotionStep
metadata:
  name: trivy-image
spec:
  image: ghcr.io/jessesuen/trivy:0.69.3
  command:
  - trivy
  - image
  - --severity=CRITICAL
  - ${{ config.image }}
```

## Putting it all together

The following `PromotionTask` demonstrates how built-in and custom steps compose into a complete promotion pipeline:

```yaml
apiVersion: kargo.akuity.io/v1alpha1
kind: PromotionTask
metadata:
  name: promote
  namespace: custom-steps
spec:
  vars:
  - name: image
    value: ghcr.io/jessesuen/nginx
  - name: repoURL
    value: https://github.com/jessesuen/kargo-custom-steps.git
  - name: branch
    value: main

  steps:
  # 1. Clone the repo containing Helm charts and environment values
  - uses: git-clone
    config:
      repoURL: ${{ vars.repoURL }}
      checkout:
      - branch: ${{ vars.branch }}
        path: ./src

  # 2. Update the image tag in the environment-specific values file
  - uses: yaml-update
    config:
      path: ./src/env/${{ ctx.stage }}/values.yaml
      updates:
      - key: image.tag
        value: ${{ imageFrom( vars.image ).Tag }}

  # 3. Render Helm templates to produce Kubernetes manifests
  - uses: helm-template
    config:
      path: ./src/charts/app
      releaseName: app
      valuesFiles:
      - ./src/env/${{ ctx.stage }}/values.yaml
      outPath: ./out

  # 4. (Custom) Validate rendered manifests against OPA policy rules
  - uses: conftest
    config:
      path: ./out

  # 5. (Custom) Scan the promoted image for CRITICAL vulnerabilities
  - uses: trivy-image
    config:
      image: ${{ vars.image }}:${{ imageFrom( vars.image ).Tag }}

  # 6. Commit and push the GitOps change to trigger the deploy
  - uses: git-commit
    config:
      path: ./src
      message: Update ${{ ctx.stage }} to ${{ vars.image }}:${{ imageFrom(vars.image).Tag }}

  - uses: git-push
    config:
      path: ./out
```

The custom steps (`conftest` and `trivy-image`) act as policy and security gates — if either fails, the promotion is blocked before any changes are committed.
