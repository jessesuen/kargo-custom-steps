# Grype Image

This is a grype image with the vulnerability database pre-cached,
in order to avoid downloading the entire database every time the 
`grype` step executes.

## Build manually

```
GRYPE_VERSION=0.110.0
docker build --build-arg GRYPE_VERSION=$GRYPE_VERSION -t ghcr.io/jessesuen/grype:$GRYPE_VERSION .
```