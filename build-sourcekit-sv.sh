#!/usr/bin/env bash

cd "$(dirname $0)/." || exit

# docker-machine start default && eval $(docker-machine env default)

UBUNTU_VERSION="${1:-16.04}"
BUILD_BASE_IMAGE="swift-dev:${UBUNTU_VERSION}"
BUILD_BASE_IMAGE_DOCKERFILE="Dockerfile-swift-dev-${UBUNTU_VERSION}"
if [ ! -f "${BUILD_BASE_IMAGE_DOCKERFILE}" ]; then
  echo "${BUILD_BASE_IMAGE_DOCKERFILE} does not exist!"
  exit 1
fi

# swift build environments
docker build -f ${BUILD_BASE_IMAGE_DOCKERFILE} -t ${BUILD_BASE_IMAGE} . || exit 1

WORK_DIR="`pwd`"
DOCKER_RUN_OPTIONS="-it -v ${WORK_DIR}:${WORK_DIR} -w ${WORK_DIR} --rm"

SOURCEKIT_IMAGE="sourcekit:sv"
REVISION="`git rev-parse --short HEAD|tr -d '\n'`"
SRC_DIR=${WORK_DIR}/swift
TOOLCHAIN_VERSION="swift-3.1-RELEASE-${REVISION}-with-sourcekit"
ARCHIVE="${TOOLCHAIN_VERSION}.tar.gz"
SWIFT_INSTALLABLE_PACKAGE="${WORK_DIR}/build/${ARCHIVE}"
SWIFT_INSTALL_DIR="${WORK_DIR}/build/swift-nightly-install"

if [ ! -f "${SWIFT_INSTALLABLE_PACKAGE}" ]; then
  # Build Swift With libdispatch
  # docker run ${DOCKER_RUN_OPTIONS} ${BUILD_BASE_IMAGE} \
  #   swift/utils/build-script \
  #     --preset-file="${WORK_DIR}/build-presets-for-sourcekit-linux.ini" \
  #     --preset="buildbot_linux_libdispatch" \
  #     install_destdir="${SWIFT_INSTALL_DIR}" || exit 1

  # Build Normal Swift Toolchain & SourceKit
  docker run ${DOCKER_RUN_OPTIONS} ${BUILD_BASE_IMAGE} \
    swift/utils/build-script \
      --preset-file="${WORK_DIR}/build-presets-for-sourcekit-linux.ini" \
      --preset="buildbot_linux" \
      -- \
      install_destdir="${SWIFT_INSTALL_DIR}" \
      installable_package="${SWIFT_INSTALLABLE_PACKAGE}" || exit 1
fi

if [ -z "`docker images -q ${SOURCEKIT_IMAGE}|tr -d '\n'`" ]; then
  # Build ${BASE_IMAGE}
  BASE_IMAGE="swift-base:${UBUNTU_VERSION}"
  BASE_IMAGE_DOCKERFILE="sourcekit-builder/Dockerfile-swift-${UBUNTU_VERSION}"
  docker build -f ${BASE_IMAGE_DOCKERFILE} -t ${BASE_IMAGE} . || exit 1

  # Build ${SOURCEKIT_IMAGE}
  DOCKER_BUILD_DIR="${TMPDIR}$(basename $0)"
  rm -rf ${DOCKER_BUILD_DIR}
  mkdir -p ${DOCKER_BUILD_DIR}
  cp -p ${SWIFT_INSTALLABLE_PACKAGE} ${DOCKER_BUILD_DIR}/
  cat <<-EOF >${DOCKER_BUILD_DIR}/Dockerfile
  FROM ${BASE_IMAGE}
  ADD ${ARCHIVE} /
  ENV LD_LIBRARY_PATH /usr/lib/swift/linux/:\${LD_LIBRARY_PATH}
EOF
  docker build -t ${SOURCEKIT_IMAGE} ${DOCKER_BUILD_DIR} || exit 1

fi

# Build SourceKitten
docker run ${DOCKER_RUN_OPTIONS} \
  -w ${WORK_DIR}/SourceKitten \
  ${SOURCEKIT_IMAGE} /bin/sh -c "swift build && swift test" || exit 1
