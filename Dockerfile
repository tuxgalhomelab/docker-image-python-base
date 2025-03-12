# syntax=docker/dockerfile:1

ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

ARG PYENV_VERSION
ARG PYENV_SHA256_CHECKSUM
ARG IMAGE_PYTHON_VERSION
ARG PACKAGES_TO_INSTALL

# hadolint ignore=SC3040,SC3044
RUN \
    set -E -e -o pipefail \
    && export HOMELAB_VERBOSE=y \
    # Install dependencies. \
    && homelab install ${PACKAGES_TO_INSTALL:?} \
    # Install python. \
    && homelab install-tar-dist \
        https://github.com/pyenv/pyenv/archive/refs/tags/${PYENV_VERSION:?}.tar.gz \
        ${PYENV_SHA256_CHECKSUM:?} \
        pyenv \
        pyenv-${PYENV_VERSION#"v"} \
        root \
        root \
    && pushd /opt/pyenv \
    && src/configure \
    && make -C src \
    && popd \
    && export PYENV_ROOT="/opt/pyenv" \
    && export PATH="/opt/pyenv/shims:/opt/pyenv/bin:${PATH}" \
    && eval "$(pyenv init -)" \
    && pyenv install ${IMAGE_PYTHON_VERSION:?} \
    && pyenv global ${IMAGE_PYTHON_VERSION:?} \
    # Clean up. \
    && homelab cleanup

ENV PYENV_ROOT="/opt/pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"
