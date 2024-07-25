ARG CI_REGISTRY_IMAGE
ARG TAG
ARG DOCKERFS_TYPE
ARG DOCKERFS_VERSION

FROM ${CI_REGISTRY_IMAGE}/${DOCKERFS_TYPE}:${DOCKERFS_VERSION}${TAG} AS base
LABEL maintainer="paoloemilio.mazzon@unipd.it"

FROM python:3.8-slim AS python-base
FROM buildpack-deps:buster AS base-builder
FROM base-builder AS mrtrix3-builder
# Git commitish from which to build MRtrix3.
ARG MRTRIX3_GIT_COMMITISH="master"
# Command-line arguments for `./configure`
ARG MRTRIX3_CONFIGURE_FLAGS=""
# Command-line arguments for `./build`
ARG MRTRIX3_BUILD_FLAGS="-persistent -nopaginate"

RUN apt-get -qq update \
    && apt-get install -yq --no-install-recommends \
	coreutils \
        libeigen3-dev \
        libfftw3-dev \
        libgl1-mesa-dev \
        libpng-dev \
        libqt5opengl5-dev \
        libqt5svg5-dev \
        libtiff5-dev \
        qt5-default \
        zlib1g-dev \
    && rm -rf /var/lib/apt/lists/*

ARG MAKE_JOBS="8"

ARG MAKE_JOBS
WORKDIR /opt/mrtrix3
RUN git clone -b $MRTRIX3_GIT_COMMITISH --depth 1 https://github.com/MRtrix3/mrtrix3.git . \
    && ./configure $MRTRIX3_CONFIGURE_FLAGS \
    && NUMBER_OF_PROCESSORS=$MAKE_JOBS ./build $MRTRIX3_BUILD_FLAGS \
    && rm -rf tmp

# Download minified ART ACPCdetect (V2.0).
FROM base-builder AS acpcdetect-installer
WORKDIR /opt/art
RUN curl -fsSL https://osf.io/73h5s/download | tar xz --strip-components 1

## Download minified ANTs (2.3.4-2).
FROM base-builder AS ants-installer
WORKDIR /opt/ants
RUN curl -fsSL https://osf.io/yswa4/download | tar xz --strip-components 1

## Download FreeSurfer files.
FROM base-builder AS freesurfer-installer
WORKDIR /opt/freesurfer
RUN curl -fsSLO https://raw.githubusercontent.com/freesurfer/freesurfer/v7.1.1/distribution/FreeSurferColorLUT.txt

## Download minified FSL (6.0.4-2)
FROM base-builder AS fsl-installer
WORKDIR /opt/fsl
RUN curl -fsSL https://osf.io/dtep4/download | tar xz --strip-components 1

## Build final image.
FROM base AS final

## Install runtime system dependencies.
RUN apt-get -qq update \
    && apt-get install -yq --no-install-recommends \
        binutils \
        dc \
        less \
        libgl1-mesa-glx \
        libgomp1 \
        liblapack3 \
        libpng16-16 \
        libqt5core5a \
        libqt5gui5 \
        libqt5network5 \
        libqt5svg5 \
        libqt5widgets5 \
        libquadmath0 \
        python3-distutils \
        libfuse2 \
        fuse \
        procps \
	libtiff5 \
	libfftw3-3 \
    && \
	apt-get clean && \
	rm -rf /var/lib/apt/lists/*

COPY --from=acpcdetect-installer /opt/art /opt/art
COPY --from=ants-installer /opt/ants /opt/ants
COPY --from=freesurfer-installer /opt/freesurfer /opt/freesurfer
COPY --from=fsl-installer /opt/fsl /opt/fsl
COPY --from=mrtrix3-builder /opt/mrtrix3 /opt/mrtrix3

# the below needs to go on the user environment so
# an external .bash_profile is filled with these
# we leave them here as a reference from the mrtrix3 Dockerfile
ARG LD_LIBRARY_PATH
ENV ANTSPATH="/opt/ants/bin" \
    ARTHOME="/opt/art" \
    FREESURFER_HOME="/opt/freesurfer" \
    FSLDIR="/opt/fsl" \
    FSLOUTPUTTYPE="NIFTI_GZ" \
    FSLMULTIFILEQUIT="TRUE" \
    FSLTCLSH="/opt/fsl/bin/fsltclsh" \
    FSLWISH="/opt/fsl/bin/fslwish" \
    LD_LIBRARY_PATH="/opt/fsl/lib:$LD_LIBRARY_PATH" \
    PATH="/opt/mrtrix3/bin:/opt/ants/bin:/opt/art/bin:/opt/fsl/bin:$PATH"

RUN strip --remove-section=.note.ABI-tag /usr/lib/x86_64-linux-gnu/libQt5Core.so.5 \
    && ldconfig

#==========================================================================================

ARG TAG
ARG CARD
ARG APP_NAME
ARG APP_VERSION

LABEL app_version=$APP_VERSION
LABEL app_tag=$TAG

WORKDIR /apps/${APP_NAME}

ENV APP_SPECIAL="terminal"
ENV APP_CMD=""
ENV PROCESS_NAME=""
ENV APP_DATA_DIR_ARRAY=""
ENV DATA_DIR_ARRAY=""
ENV CONFIG_ARRAY=".bash_profile"

HEALTHCHECK --interval=10s --timeout=10s --retries=5 --start-period=30s \
  CMD sh -c "/apps/${APP_NAME}/scripts/process-healthcheck.sh \
  && /apps/${APP_NAME}/scripts/ls-healthcheck.sh /home/${HIP_USER}/nextcloud/"

COPY ./scripts/ scripts/
COPY ./apps/${APP_NAME}/config config/

ENTRYPOINT ["./scripts/docker-entrypoint.sh"]
