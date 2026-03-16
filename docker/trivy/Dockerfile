ARG TRIVY_VERSION=latest
FROM aquasec/trivy:${TRIVY_VERSION}

# Download the vulnerability DB at build time
RUN trivy image --download-db-only && \
    trivy image --download-java-db-only
