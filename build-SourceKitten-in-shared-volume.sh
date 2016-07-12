#!/bin/sh
docker-machine start default && eval $(docker-machine env default)
docker build -f Dockerfile-swift-dev-15.10 -t swift-dev-15.10 .

cd "$(dirname $0)/." || exit

# git submodule update --init --recursive

WORKDIR="`pwd`"
SWIFT_PATH=$WORKDIR/build/buildbot_linux/none-swift_package_sandbox_linux-x86_64/usr/bin
LINUX_SOURCEKIT_LIB_PATH=$WORKDIR/build/buildbot_linux/swift-linux-x86_64/lib

DOCKER_IMAGE="swift-dev-15.10"
DOCKER_RUN_OPTIONS="--privileged -it -v $WORKDIR:$WORKDIR -w $WORKDIR --rm"

if [ ! -f "$SWIFT_PATH/swift" -o ! -f "$LINUX_SOURCEKIT_LIB_PATH/libsourcekitdInProc.so" ]; then
  # Build Swift With libdispatch

  echo docker run $DOCKER_RUN_OPTIONS $DOCKER_IMAGE swift/utils/build-script --preset="buildbot_linux_libdispatch"
  docker run $DOCKER_RUN_OPTIONS $DOCKER_IMAGE swift/utils/build-script --preset="buildbot_linux_libdispatch" || exit 1

  # Build Normal Swift Toolchain & SourceKit

  echo docker run $DOCKER_RUN_OPTIONS $DOCKER_IMAGE swift/utils/build-toolchain local.swift
  docker run $DOCKER_RUN_OPTIONS $DOCKER_IMAGE swift/utils/build-toolchain local.swift || exit 1

fi

# Build SourceKitten
docker run $DOCKER_RUN_OPTIONS \
  -e "LINUX_SOURCEKIT_LIB_PATH=$LINUX_SOURCEKIT_LIB_PATH" \
  -w $WORKDIR/SourceKitten \
  $DOCKER_IMAGE /bin/sh -c "PATH=$SWIFT_PATH:\$PATH swift build" || exit 1

docker run $DOCKER_RUN_OPTIONS \
  -e "LINUX_SOURCEKIT_LIB_PATH=$LINUX_SOURCEKIT_LIB_PATH" \
  -w $WORKDIR/SourceKitten \
  $DOCKER_IMAGE /bin/sh -c "PATH=$SWIFT_PATH:\$PATH swift test" || exit 1
