ARG TRIVY_VERSION=latest
FROM aquasec/trivy:${TRIVY_VERSION}

ENV TRIVY_CONFIG=/etc/trivy/trivy.yaml
ENV TRIVY_CACHE_DIR=/home/nonroot/.cache/trivy

# Download both DBs, then delete the Java DB to save image size
RUN mkdir -p /home/nonroot/.cache/trivy && \
    trivy image --download-db-only && \
    trivy image --download-java-db-only && \
    rm -f /home/nonroot/.cache/trivy/java-db/trivy-java.db && \
    chown -R 65532:65532 /home/nonroot/.cache/trivy && \
    chmod -R ugo+rx /home/nonroot/.cache/trivy

COPY trivy.yaml /etc/trivy/trivy.yaml

USER 65532
