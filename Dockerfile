FROM docker.io/mambaorg/micromamba:1.5.5-bookworm-slim AS micromamba
FROM micromamba AS builder

RUN \
    --mount=type=cache,sharing=private,target=/home/mambauser/.mamba/pkgs,uid=57439,gid=57439 \
    --mount=type=cache,sharing=private,target=/opt/conda/pkgs,uid=57439,gid=57439 \
    micromamba -y -n base install -c conda-forge cmake=3.28.1 ninja=1.10.2 cxx-compiler=1.5.2 git

ARG MAMBA_DOCKERFILE_ACTIVATE=1
RUN mkdir /home/mambauser/ants
RUN git config --global url.'https://'.insteadOf 'git://'
COPY --chown=57439:57439 . /home/mambauser/src

WORKDIR /home/mambauser/build

RUN cmake \
    -GNinja \
    -DBUILD_TESTING=ON \
    -DRUN_LONG_TESTS=OFF \
    -DRUN_SHORT_TESTS=ON \
    -DBUILD_SHARED_LIBS=ON \
    -DCMAKE_INSTALL_PREFIX=/home/mambauser/ants \
    /home/mambauser/src
RUN cmake --build . --parallel
WORKDIR /home/mambauser/build/ANTS-build
RUN cmake --install .

FROM micromamba

RUN \
    --mount=type=cache,sharing=private,target=/home/mambauser/.mamba/pkgs,uid=57439,gid=57439 \
    --mount=type=cache,sharing=private,target=/opt/conda/pkgs,uid=57439,gid=57439 \
    micromamba -y -n base install -c conda-forge libiconv=1.17

COPY --from=builder /home/mambauser/ants /opt/ants
ENV PATH="/opt/ants/bin:$PATH" \
    LD_LIBRARY_PATH="/opt/ants/lib:$LD_LIBRARY_PATH"

LABEL org.opencontainers.image.authors="ANTsX team" \
      org.opencontainers.image.url="https://stnava.github.io/ANTs/" \
      org.opencontainers.image.source="https://github.com/ANTsX/ANTs" \
      org.opencontainers.image.licenses="Apache License 2.0" \
      org.opencontainers.image.title="Advanced Normalization Tools" \
      org.opencontainers.image.description="ANTs is part of the ANTsX ecosystem (https://github.com/ANTsX). \
ANTs Citation: https://pubmed.ncbi.nlm.nih.gov/24879923"
