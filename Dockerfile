ARG BUILDER_IMAGE=golang:1.24
ARG BASE_IMAGE=debian:12-slim

# Build the manager binary
FROM --platform=${BUILDPLATFORM} ${BUILDER_IMAGE} AS builder

COPY / /src
WORKDIR /src

# The TARGETOS and TARGETARCH args are set by docker. We set GOOS and GOARCH to
# these values to ask Go to compile a binary for these architectures. If
# TARGETOS and TARGETOS are different from BUILDPLATFORM, Go will cross compile
# for us (e.g. compile a linux/amd64 binary on a linux/arm64 build machine).
ARG TARGETOS
ARG TARGETARCH

RUN --mount=type=cache,target=/go/pkg --mount=type=cache,target=/root/.cache/go-build  GOARCH=${TARGETARCH}  GOOS=linux CGO_ENABLED=0 make build

FROM  ${BASE_IMAGE}

COPY --from=builder /src/bin/kcl /usr/local/bin/kcl

# Verify KCL installation and basic functionality
RUN kcl version && \
    echo 'a=1' | kcl run -

# Install git for KCL package management
# Use best practices for apt-get commands
RUN apt-get update && \
    apt-get install -y --no-install-recommends git ca-certificates && \
    rm -rf /var/lib/apt/lists/*

# Create the temporary directory
RUN mkdir -p /tmp

# Configure KCL runtime environment
# Set temporary directories for write permissions
ENV KCL_LIB_HOME=/tmp \
    KCL_PKG_PATH=/tmp \
    KCL_CACHE_PATH=/tmp \
    LANG=en_US.utf8
