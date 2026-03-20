# Trivy Image

This is a trivy image with the vulnerability database pre-cached,
in order to avoid downloading the entire database every time the 
`trivy-image` step executes. It also bakes in a `trivy.yaml`
configuration file with settings that work well in Kargo.

## Build manually

```
TRIVY_VERSION=0.69.3
docker build --build-arg TRIVY_VERSION=$TRIVY_VERSION -t ghcr.io/jessesuen/trivy:$TRIVY_VERSION .
```