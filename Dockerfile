ARG BASE_IMAGE_NAME
ARG BASE_IMAGE_TAG
FROM ${BASE_IMAGE_NAME}:${BASE_IMAGE_TAG}

SHELL ["/bin/bash", "-c"]

ARG PYENV_VERSION
ARG PYENV_SHA256_CHECKSUM
ARG IMAGE_PYTHON_VERSION
ARG PACKAGES_TO_INSTALL

RUN \
    set -e -o pipefail \
    # Install dependencies. \
    && homelab install ${PACKAGES_TO_INSTALL:?} \
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
    && popd

ENV PYENV_ROOT="/opt/pyenv"
ENV PATH="${PYENV_ROOT}/shims:${PYENV_ROOT}/bin:${PATH}"

RUN \
    eval "$(pyenv init -)" \
    && pyenv install ${IMAGE_PYTHON_VERSION:?} \
    && pyenv global ${IMAGE_PYTHON_VERSION:?} \
    # Clean up. \
    && homelab cleanup
