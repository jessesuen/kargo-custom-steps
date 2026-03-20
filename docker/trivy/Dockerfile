ARG TRIVY_VERSION=latest
FROM aquasec/trivy:${TRIVY_VERSION}

ENV TRIVY_CONFIG=/etc/trivy/trivy.yaml
ENV TRIVY_CACHE_DIR=/home/nonroot/.cache/trivy
ENV NO_COLOR=true

# Download both DBs, then delete the Java DB to save image size
RUN mkdir -p /home/nonroot/.cache/trivy && \
    trivy image --no-progress --download-db-only && \
    trivy image --no-progress --download-java-db-only && \
    rm -f /home/nonroot/.cache/trivy/java-db/trivy-java.db && \
    chown -R 65532:65532 /home/nonroot/.cache/trivy && \
    chmod -R ugo+rwx /home/nonroot/.cache/trivy

COPY trivy.yaml /etc/trivy/trivy.yaml

USER 65532

# HACK: for efficiency, we pre-scan the images we know we'll be using
# for the demo, which warms up the trivy fs cache and avoids
# repeatedly downloading the entire image during demos
RUN trivy image --exit-code 0 ghcr.io/jessesuen/nginx:1.27.5 && \
    trivy image --exit-code 0 ghcr.io/jessesuen/nginx:1.29.6
