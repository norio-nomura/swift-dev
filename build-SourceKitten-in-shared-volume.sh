#!/usr/bin/env bash

cd "$(dirname $0)/." || exit

# docker-machine start default && eval $(docker-machine env default)

BASE_IMAGE="swift-dev-15.10"

# swift build environments
docker build -q -f Dockerfile-${BASE_IMAGE} -t ${BASE_IMAGE} .

WORK_DIR="`pwd`"
DOCKER_RUN_OPTIONS="-it -v ${WORK_DIR}:${WORK_DIR} -w ${WORK_DIR} --rm"

SOURCEKIT_IMAGE="sourcekit:30p2"
REVISION="`git rev-parse --short HEAD|tr -d '\n'`"

if [ -z "`docker images -q ${SOURCEKIT_IMAGE}|tr -d '\n'`" ]; then
  SRC_DIR=${WORK_DIR}/swift
  TOOLCHAIN_VERSION="swift-3.0-PREVIEW-2-${REVISION}-with-sourcekit"
  ARCHIVE="${TOOLCHAIN_VERSION}.tar.gz"
  SWIFT_INSTALLABLE_PACKAGE="${SRC_DIR}/${ARCHIVE}"
  SWIFT_INSTALL_DIR="${SRC_DIR}/swift-nightly-install"

  # Build Swift With libdispatch
  docker run ${DOCKER_RUN_OPTIONS} ${BASE_IMAGE} \
    swift/utils/build-script --preset="buildbot_linux_libdispatch" \
    install_destdir="${SWIFT_INSTALL_DIR}" || exit 1

  # Build Normal Swift Toolchain & SourceKit
  docker run ${DOCKER_RUN_OPTIONS} ${BASE_IMAGE} \
    swift/utils/build-script --preset="buildbot_linux" \
    install_destdir="${SWIFT_INSTALL_DIR}" \
    installable_package="${SWIFT_INSTALLABLE_PACKAGE}" || exit 1

  DOCKER_BUILD_DIR="${TMPDIR}$(basename $0)"
  rm -rf ${DOCKER_BUILD_DIR}
  mkdir -p ${DOCKER_BUILD_DIR}
  cp -p ${SWIFT_INSTALLABLE_PACKAGE} ${DOCKER_BUILD_DIR}/
  cat <<-EOF >${DOCKER_BUILD_DIR}/Dockerfile
  FROM ${BASE_IMAGE}
  ADD ${ARCHIVE} /
EOF
  docker build -t ${SOURCEKIT_IMAGE} ${DOCKER_BUILD_DIR} || exit 1

fi

# Build SourceKitten
docker run ${DOCKER_RUN_OPTIONS} \
  -w ${WORK_DIR}/SourceKitten \
  ${SOURCEKIT_IMAGE} /bin/sh -c "swift build && swift test" || exit 1
